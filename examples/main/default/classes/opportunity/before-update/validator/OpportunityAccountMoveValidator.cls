public with sharing class OpportunityAccountMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.NewRecordEnrichment, BeforeUpdate.OldRecordEnrichment {
    private static final String CLOSED_WON = 'Closed Won';

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Opportunity.AccountId => TriggerHandler.FieldSelection.with(Account.Name) };
    }

    public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Opportunity.AccountId => TriggerHandler.FieldSelection.with(Account.Name) };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.equals(Opportunity.StageName, CLOSED_WON) && record.isChanged(Opportunity.AccountId);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        Account previousAccount = (Account) record.getOldRelated('Account');
        Account currentAccount = (Account) record.getNewRelated('Account');

        return 'This Opportunity is Closed Won and stays with ' +
            (previousAccount?.Name ?? 'its original Account') +
            '. It cannot be moved to ' +
            (currentAccount?.Name ?? 'another Account') +
            '.';
    }
}
