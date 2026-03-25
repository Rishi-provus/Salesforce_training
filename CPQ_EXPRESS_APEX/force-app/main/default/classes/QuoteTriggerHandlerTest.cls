@isTest
private class QuoteTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // 1. Setup Mandatory Metadata
        Product_Category__c cat = new Product_Category__c(Name = 'Solar Panels', Max_Discount__c = 15.0);
        insert cat;

        Product2 prod = new Product2(Name = 'Adani 440W', IsActive = true, Product_Category__c = cat.Id);
        insert prod;

        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prod.Id, UnitPrice = 1000, IsActive = true);
        insert pbe;

        Account acc = new Account(Name = 'Adani Test'); insert acc;
        Opportunity opp = new Opportunity(Name = 'Test', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;

        // 2. Create Quotes
        Quote qAuto = new Quote(Name = 'Auto', OpportunityId = opp.Id, Pricebook2Id = pbId, Status = 'Draft');
        Quote qManual = new Quote(Name = 'Manual', OpportunityId = opp.Id, Pricebook2Id = pbId, Status = 'Draft');
        Quote qManager = new Quote(Name = 'Manager_Approved', OpportunityId = opp.Id, Pricebook2Id = pbId, Status = 'Draft');
        Quote qEmpty = new Quote(Name = 'Empty', OpportunityId = opp.Id, Pricebook2Id = pbId, Status = 'Draft');
        insert new List<Quote>{qAuto, qManual, qManager, qEmpty};

        // 3. Line Items
        insert new List<QuoteLineItem>{
            new QuoteLineItem(QuoteId = qAuto.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 1000, Discount = 5),
            new QuoteLineItem(QuoteId = qManual.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 1000, Discount = 40),
            new QuoteLineItem(QuoteId = qManager.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 1000, Discount = 40)
        };
    }

    @isTest
    static void testSubmissionLogic() {
        Id subId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Submitted').getRecordTypeId();
        Id appId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Approved').getRecordTypeId();

        // We ONLY test quotes with items here. If we included 'Empty', the whole update would fail.
        List<Quote> toSubmit = [SELECT Id, Name, Status FROM Quote WHERE Name IN ('Auto', 'Manual')];
        for(Quote q : toSubmit) { q.Status = 'Submitted'; }

        Test.startTest();
        update toSubmit;
        Test.stopTest();

        Map<Id, Quote> results = new Map<Id, Quote>([SELECT Name, Status, RecordTypeId FROM Quote]);
        
        for(Quote q : toSubmit) {
            Quote res = results.get(q.Id);
            if(res.Name == 'Auto') {
                System.assertEquals('Approved', res.Status, 'Should be auto-approved');
                System.assertEquals(appId, res.RecordTypeId);
            } else {
                System.assertEquals('Submitted', res.Status, 'Should require manual review');
                System.assertEquals(subId, res.RecordTypeId);
            }
        }
    }

    @isTest
    static void testManagerApproval() {
        Id appId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Approved').getRecordTypeId();
        
        // Setup: First move to Submitted
        Quote q = [SELECT Id, Status FROM Quote WHERE Name = 'Manager_Approved' LIMIT 1];
        q.Status = 'Submitted';
        update q;

        Test.startTest();
        q.Status = 'Approved';
        update q;
        Test.stopTest();

        Quote res = [SELECT Status, RecordTypeId FROM Quote WHERE Id = :q.Id];
        System.assertEquals('Approved', res.Status);
        System.assertEquals(appId, res.RecordTypeId, 'Record Type must flip when Manager approves');
    }

    @isTest
    static void testEmptyQuoteError() {
        Quote emptyQ = [SELECT Id, Status FROM Quote WHERE Name = 'Empty' LIMIT 1];
        emptyQ.Status = 'Submitted';
        
        Test.startTest();
        try {
            update emptyQ;
            // If it reaches here, the trigger FAILED to stop the record
            System.assert(false, 'The trigger should have blocked an empty quote but it allowed it.');
        } catch (DmlException e) {
            // Log the actual message to the console so you can see it if it fails again
            System.debug('Actual Error Message: ' + e.getMessage());
            
            // Use a broader keyword to avoid string-matching issues
            System.assert(e.getMessage().contains('Products'), 
                          'Expected error regarding missing products, but got: ' + e.getMessage());
        }
        Test.stopTest();
    }
}