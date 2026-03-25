public class QuoteTriggerHandler {
    
    public static void handleBeforeUpdate(List<Quote> newQuotes, Map<Id, Quote> oldMap) {
        
        Id submittedId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Submitted').getRecordTypeId();
        Id approvedId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Approved').getRecordTypeId();

        Set<Id> submittedQuoteIds = new Set<Id>();

        // 1. Handle Manager Approval & Identify Submissions
        for (Quote q : newQuotes) {
            Quote oldQ = oldMap.get(q.Id);

            // CASE A: Manager manual approval
            if (q.Status == 'Approved' && oldQ.Status == 'Submitted') {
                q.RecordTypeId = approvedId;
            }
            
            // CASE B: Initial Submission
            if (q.Status == 'Submitted' && oldQ.Status != 'Submitted') {
                submittedQuoteIds.add(q.Id);
            }
        }

        // 2. Query Line Items for those being submitted
        if (!submittedQuoteIds.isEmpty()) {
            List<QuoteLineItem> items = [SELECT Id, QuoteId, Approval_Required_Flag__c 
                                         FROM QuoteLineItem 
                                         WHERE QuoteId IN :submittedQuoteIds];

            Map<Id, Boolean> hasItems = new Map<Id, Boolean>();
            Map<Id, Boolean> manualReq = new Map<Id, Boolean>();

            for (QuoteLineItem item : items) {
                hasItems.put(item.QuoteId, true);
                if (item.Approval_Required_Flag__c == true) manualReq.put(item.QuoteId, true);
            }

            // 3.Apply logic directly to records in Trigger.new
            for (Quote q : newQuotes) {
                if (!submittedQuoteIds.contains(q.Id)) continue;

                // ERROR CHECK: Block save if empty
                if (!hasItems.containsKey(q.Id)) {
                    q.addError('Error: You cannot submit a Quote without any Products.');
                    continue; 
                }

                if (!manualReq.containsKey(q.Id)) {
                    // AUTO-APPROVE
                    q.Status = 'Approved';
                    q.RecordTypeId = approvedId;
                    q.Is_Automated_c__c = true;
                } else {
                    // MANUAL REVIEW
                    q.RecordTypeId = submittedId;
                }
            }
        }
    }
}