@isTest
private class QuoteLineItemTriggerTest {

    @testSetup
    static void setupData() {
        // 1. Create Categories
        Product_Category__c lowCat = new Product_Category__c(Name = 'Standard', Max_Discount__c = 15.0);
        Product_Category__c highCat = new Product_Category__c(Name = 'Clearance', Max_Discount__c = 80.0);
        insert new List<Product_Category__c>{lowCat, highCat};

        // 2. Create Products
        Product2 prodLow = new Product2(Name = 'Standard Panel', IsActive = true, Product_Category__c = lowCat.Id);
        Product2 prodHigh = new Product2(Name = 'Old Stock', IsActive = true, Product_Category__c = highCat.Id);
        insert new List<Product2>{prodLow, prodHigh};

        // 3. Pricebook Setup
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbeLow = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodLow.Id, UnitPrice = 1000, IsActive = true);
        PricebookEntry pbeHigh = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodHigh.Id, UnitPrice = 1000, IsActive = true);
        insert new List<PricebookEntry>{pbeLow, pbeHigh};

        // 4. Account, Opp, and Quote
        Account acc = new Account(Name = 'Discount Test'); insert acc;
        Opportunity opp = new Opportunity(Name = 'Opp', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;
        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Pricebook2Id = pbId);
        insert q;
    }

    @isTest
    static void testDiscountValidation() {
        // Re-query data to ensure IDs are fresh
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        
        // We query the PBEs and ensure we have the Product2Id for the QLI
        PricebookEntry pbeLow = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name = 'Standard Panel' LIMIT 1];
        PricebookEntry pbeHigh = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2.Name = 'Old Stock' LIMIT 1];

        Test.startTest();

        // SCENARIO 1: ALLOWED (Under 50% Hard Cap)
        // 20% > 15% (Category), but 20% is NOT > 50%. So it should PASS.
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = q.Id, 
            PricebookEntryId = pbeLow.Id, 
            Product2Id = pbeLow.Product2Id, // Explicitly setting Product2Id helps triggers
            Quantity = 1, 
            UnitPrice = 1000, 
            Discount = 20
        );
        insert qli1;
        System.assertNotEquals(null, qli1.Id, '20% should be allowed as it is under the 50% global cap');

        // SCENARIO 2: BLOCKED (Over 50% AND over Category Max)
        // 55% > 50% AND 55% > 15%. This MUST fail.
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id, 
            PricebookEntryId = pbeLow.Id, 
            Product2Id = pbeLow.Product2Id,
            Quantity = 1, 
            UnitPrice = 1000, 
            Discount = 55
        );
        
        Boolean exceptionThrown = false;
        try {
            insert qli2;
        } catch (DmlException e) {
            exceptionThrown = true;
            // The pure truth: Check if the error message we defined is actually there
            System.debug('Error Message: ' + e.getMessage());
            System.assert(e.getMessage().contains('Policy Violation'), 'Error message was: ' + e.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'The trigger should have blocked 55% on a 15% category');

        // SCENARIO 3: ALLOWED (Over 50% but Category allows it)
        // 55% > 50%, but 55% is NOT > 80% (Category Max). So it should PASS.
        QuoteLineItem qli3 = new QuoteLineItem(
            QuoteId = q.Id, 
            PricebookEntryId = pbeHigh.Id, 
            Product2Id = pbeHigh.Product2Id,
            Quantity = 1, 
            UnitPrice = 1000, 
            Discount = 55
        );
        insert qli3;
        System.assertNotEquals(null, qli3.Id, '55% should be allowed because Category Max is 80%');

        Test.stopTest();
    }
}