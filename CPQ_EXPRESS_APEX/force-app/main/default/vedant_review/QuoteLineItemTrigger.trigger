trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update) {
    QuoteLineItemHandler.handleBefore(Trigger.new);
}