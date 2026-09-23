public with sharing class OpportunityCloseDateValidator implements BeforeInsert.Validator {
    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.lessThan(Opportunity.CloseDate, Date.today());
    }

    public void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        record.addError(Opportunity.CloseDate, 'Close Date ' + newOpportunity.CloseDate.format() + ' is in the past. Pick today or a later date.');
    }
}
