public with sharing class OpportunityReopenValidator implements BeforeUpdate.Validator, BeforeUpdate.Bypassable {
    public static Boolean isBypassed = false;

    public Boolean bypassOnBeforeUpdateWhen() {
        return isBypassed;
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedFrom(Opportunity.StageName, 'Closed Won');
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        record.addError(
            Opportunity.StageName,
            'A Closed Won Opportunity cannot be moved back to ' + newOpportunity.StageName + '. Raise a new Opportunity for the follow-up business.'
        );
    }
}
