public with sharing class OpportunityCloseDateValidator implements BeforeInsert.Validator {
    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.lessThan(Opportunity.CloseDate, Date.today());
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return 'Close Date ' + newOpportunity.CloseDate.format() + ' is in the past. Pick today or a later date.';
    }
}
