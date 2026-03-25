trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if (Trigger.isAfter) {
        OpportunityTriggerHandler.handleAfter(Trigger.new, Trigger.oldMap);
    }
}