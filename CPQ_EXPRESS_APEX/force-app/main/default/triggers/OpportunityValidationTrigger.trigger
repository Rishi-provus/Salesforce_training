trigger OpportunityValidationTrigger on Opportunity (before insert, before update) {
    
    for(Opportunity opp : Trigger.new){
        
        if(opp.Amount != null 
           && opp.Amount > 1000000 
           && opp.StageName == 'Closed Won' 
           && opp.Approved_c__c == false){
            
            opp.addError('Approval is required for opportunities above ₹10,00,000 before closing as Won.');
        }
    }
}