trigger QuoteTrigger on Quote (before update) {
    // We switched to 'before' to save on DML statements 
    // and avoid recursion issues.
    QuoteTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
}