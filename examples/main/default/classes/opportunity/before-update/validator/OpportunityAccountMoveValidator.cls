public with sharing class OpportunityAccountMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.NewRecordEnrichment, BeforeUpdate.OldRecordEnrichment {
    public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> oldFieldsToEnrichOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.equals(Opportunity.StageName, 'Closed Won') && record.isChanged(Opportunity.AccountId);
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
