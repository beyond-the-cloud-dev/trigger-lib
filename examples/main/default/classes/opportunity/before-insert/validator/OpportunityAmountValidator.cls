public with sharing class OpportunityAmountValidator implements BeforeInsert.Validator {
    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isNotNull(Opportunity.Amount) && record.lessThanOrEqualTo(Opportunity.Amount, 0);
    }

    public void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record) {
        record.addError(Opportunity.Amount, 'Amount must be greater than zero. Leave it empty until the deal value is known.');
    }
}
