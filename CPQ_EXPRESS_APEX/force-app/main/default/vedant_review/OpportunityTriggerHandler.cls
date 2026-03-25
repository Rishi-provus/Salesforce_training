public class OpportunityTriggerHandler {
    public static void handleAfter(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        List<Quote> quotesToInsert = new List<Quote>();
        Set<Id> oppsToProcess = new Set<Id>();

        for (Opportunity opp : newOpps) {
            Boolean wasChanged = (oldMap == null || opp.StageName != oldMap.get(opp.Id).StageName);
            if (opp.StageName == 'Proposal/Price Quote' && wasChanged) {
                oppsToProcess.add(opp.Id);
            }
        }

        if (oppsToProcess.isEmpty()) return;

        // Fetch Target Pricebook
        Id targetPbId = getTargetPricebookId();

        Map<Id, Opportunity> existingQuotesMap = new Map<Id, Opportunity>([
            SELECT Id, (SELECT Id FROM Quotes LIMIT 1) 
            FROM Opportunity WHERE Id IN :oppsToProcess
        ]);

        for (Opportunity opp : newOpps) {
            if (oppsToProcess.contains(opp.Id) && existingQuotesMap.get(opp.Id).Quotes.isEmpty()) {
                quotesToInsert.add(new Quote(
                    Name = opp.Name + ' - Proposal',
                    OpportunityId = opp.Id,
                    Pricebook2Id = opp.Pricebook2Id != null ? opp.Pricebook2Id : targetPbId,
                    Status = 'Draft'
                ));
            }
        }
        if (!quotesToInsert.isEmpty()) insert quotesToInsert;
    }

    // Helper method to ensure we can test the fallback path
    private static Id getTargetPricebookId() {
        List<Pricebook2> solarPB = [SELECT Id FROM Pricebook2 WHERE Name = 'Solar Book' AND IsActive = true LIMIT 1];
        if (!solarPB.isEmpty()) {
            return solarPB[0].Id;
        }
        // This is the line you were missing coverage on
        return Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    }
}