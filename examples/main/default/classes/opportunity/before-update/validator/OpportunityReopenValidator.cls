public with sharing class OpportunityReopenValidator implements BeforeUpdate.Validator, BeforeUpdate.Bypassable {
    public static Boolean isBypassed = false;

    private static final String CLOSED_WON = 'Closed Won';

    public Boolean bypassOnBeforeUpdateWhen() {
        return isBypassed;
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedFrom(Opportunity.StageName, CLOSED_WON);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return 'A Closed Won Opportunity cannot be moved back to ' + newOpportunity.StageName + '. Raise a new Opportunity for the follow-up business.';
    }
}
