public class QuoteLineItemHandler {
    public static void handleBefore(List<QuoteLineItem> newItems) {
        Set<Id> productIds = new Set<Id>();
        for (QuoteLineItem qli : newItems) {
            if (qli.Product2Id != null) productIds.add(qli.Product2Id);
        }

        if (productIds.isEmpty()) return;

       // We MUST query the category info because it's not in the trigger context
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Product_Category__r.Max_Discount__c 
            FROM Product2 
            WHERE Id IN :productIds
        ]);

        for (QuoteLineItem qli : newItems) {
            Product2 prod = productMap.get(qli.Product2Id);
            
            if (prod != null && prod.Product_Category__r != null) {
                Decimal catMax = prod.Product_Category__r.Max_Discount__c != null ? prod.Product_Category__r.Max_Discount__c : 0;
                Decimal userDiscount = qli.Discount != null ? qli.Discount : 0;

                System.debug('>>> CHECKING QLI: User Discount: ' + userDiscount + ' | Category Max: ' + catMax);

                // LOGIC: Block if User > 50 AND User > Category Max
                if (userDiscount > 50 && userDiscount > catMax) {
                    System.debug('>>> BLOCKING SAVE - ERROR ADDED');
                    qli.addError('Policy Violation: You cannot exceed 50% discount unless the Category specifically allows it (Category Max: ' + catMax + '%).');
                }
            } else {
                System.debug('>>> SKIP: Product or Category Info Missing in Map');
            }
        }
    }
}