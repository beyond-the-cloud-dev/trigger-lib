public with sharing class OpportunityAccountMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Opportunity.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Opportunity.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.equals(Opportunity.StageName, 'Closed Won') && record.isChanged(Opportunity.AccountId);
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        Account oldAccount = (Account) record.getOldParent(Opportunity.AccountId);
        Account newAccount = (Account) record.getNewParent(Opportunity.AccountId);

        record.addError(
            Opportunity.AccountId,
            'This Opportunity is Closed Won and stays with ' +
                (oldAccount?.Name ?? 'its original Account') +
                '. It cannot be moved to ' +
                (newAccount?.Name ?? 'another Account') +
                '.'
        );
    }
}
