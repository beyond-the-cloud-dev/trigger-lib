public with sharing class AccountParentMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.ParentId => TriggerHandler.ParentFields.with(Account.Name, Account.BillingCountry) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.ParentId => TriggerHandler.ParentFields.with(Account.Name, Account.BillingCountry) };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        if (!record.isChanged(Account.ParentId) || !record.startsWith(Account.Type, 'Customer')) {
            return false;
        }

        Account previousParent = (Account) record.getOldParent('Parent');
        Account newParent = (Account) record.getNewParent('Parent');

        return previousParent != null && newParent != null && previousParent.BillingCountry != newParent.BillingCountry;
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        Account previousParent = (Account) record.getOldParent('Parent');
        Account newParent = (Account) record.getNewParent('Parent');

        record.addError(
            Account.ParentId,
            'Moving this customer from "' +
                previousParent.Name +
                '" (' +
                previousParent.BillingCountry +
                ') to "' +
                newParent.Name +
                '" (' +
                newParent.BillingCountry +
                ') changes the invoicing entity. Raise a finance request for the transfer.'
        );
    }
}
