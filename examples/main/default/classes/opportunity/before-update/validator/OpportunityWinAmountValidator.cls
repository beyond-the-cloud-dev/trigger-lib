public with sharing class OpportunityWinAmountValidator implements BeforeUpdate.Validator {
    private static final String CLOSED_WON = 'Closed Won';

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, CLOSED_WON) && (record.isNull(Opportunity.Amount) || record.lessThanOrEqualTo(Opportunity.Amount, 0));
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        return 'Set a positive Amount before moving this Opportunity to ' + CLOSED_WON + '.';
    }
}
