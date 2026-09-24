public with sharing class OpportunityReopenValidator implements BeforeUpdate.Validator, BeforeUpdate.Bypassable {
    public static Boolean isBypassed = false;

    public Boolean bypassOnBeforeUpdateWhen() {
        return OpportunityReopenValidator.isBypassed;
    }

    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedFrom(Opportunity.StageName, 'Closed Won');
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        record.addError(
            Opportunity.StageName,
            'A Closed Won Opportunity cannot be moved back to ' + newOpportunity.StageName + '. Raise a new Opportunity for the follow-up business.'
        );
    }
}
