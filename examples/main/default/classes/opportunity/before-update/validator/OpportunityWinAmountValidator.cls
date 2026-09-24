public with sharing class OpportunityWinAmountValidator implements BeforeUpdate.Validator {
    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Won') && (record.isNull(Opportunity.Amount) || record.lessThanOrEqualTo(Opportunity.Amount, 0));
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        record.addError(Opportunity.Amount, 'Set a positive Amount before moving this Opportunity to Closed Won.');
    }
}
