@isTest
private class OpportunityTriggerTest {

    @testSetup
    static void setup() {
        // Create Solar Book for the main test path
        Pricebook2 solarPB = new Pricebook2(Name = 'Solar Book', IsActive = true);
        insert solarPB;

        Account acc = new Account(Name = 'Test Acc');
        insert acc;
    }

    @isTest
    static void testQuoteCreationWithSolarBook() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(Name = 'Solar Deal', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;

        Test.startTest();
        opp.StageName = 'Proposal/Price Quote';
        update opp;
        Test.stopTest();

        Quote q = [SELECT Pricebook2Id FROM Quote WHERE OpportunityId = :opp.Id];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Solar Book' LIMIT 1];
        System.assertEquals(pb.Id, q.Pricebook2Id, 'Should use Solar Book when available');
    }

    @isTest
    static void testQuoteCreationFallback() {
        // THE TRICK: Delete the Solar Book to force the 'else' branch coverage
        Pricebook2 solarPB = [SELECT Id FROM Pricebook2 WHERE Name = 'Solar Book' LIMIT 1];
        delete solarPB;

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = new Opportunity(Name = 'Fallback Deal', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;

        Test.startTest();
        opp.StageName = 'Proposal/Price Quote';
        update opp;
        Test.stopTest();

        Quote q = [SELECT Pricebook2Id FROM Quote WHERE OpportunityId = :opp.Id];
        System.assertEquals(Test.getStandardPricebookId(), q.Pricebook2Id, 'Should fall back to Standard PB');
    }
}