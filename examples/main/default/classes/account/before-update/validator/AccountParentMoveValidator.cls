public with sharing class AccountParentMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.ParentId => TriggerTypes.ParentFields.with(Account.Name, Account.BillingCountry) };
    }

    public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.ParentId => TriggerTypes.ParentFields.with(Account.Name, Account.BillingCountry) };
    }

    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        if (!record.isChanged(Account.ParentId) || !record.startsWith(Account.Type, 'Customer')) {
            return false;
        }

        Account oldParent = (Account) record.getOldParent(Account.ParentId);
        Account newParent = (Account) record.getNewParent(Account.ParentId);

        return oldParent != null && newParent != null && oldParent.BillingCountry != newParent.BillingCountry;
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        Account oldParent = (Account) record.getOldParent(Account.ParentId);
        Account newParent = (Account) record.getNewParent(Account.ParentId);

        record.addError(
            Account.ParentId,
            'Moving this customer from "' +
                oldParent.Name +
                '" (' +
                oldParent.BillingCountry +
                ') to "' +
                newParent.Name +
                '" (' +
                newParent.BillingCountry +
                ') changes the invoicing entity. Raise a finance request for the transfer.'
        );
    }
}
