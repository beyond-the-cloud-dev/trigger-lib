public with sharing class OpportunityAccountMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.equals(Opportunity.StageName, 'Closed Won') && record.isChanged(Opportunity.AccountId);
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        Account previousAccount = (Account) record.getOldParent('Account');
        Account currentAccount = (Account) record.getNewParent('Account');

        record.addError(
            Opportunity.AccountId,
            'This Opportunity is Closed Won and stays with ' +
                (previousAccount?.Name ?? 'its original Account') +
                '. It cannot be moved to ' +
                (currentAccount?.Name ?? 'another Account') +
                '.'
        );
    }
}
