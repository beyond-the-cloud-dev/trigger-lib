public with sharing class AccountParentMoveValidator implements BeforeUpdate.Validator, BeforeUpdate.NewRecordEnrichment, BeforeUpdate.OldRecordEnrichment {
    public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.ParentId => TriggerHandler.ParentFields.with(Account.Name, Account.BillingCountry) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> oldFieldsToEnrichOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.ParentId => TriggerHandler.ParentFields.with(Account.Name, Account.BillingCountry) };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        if (!record.isChanged(Account.ParentId) || !record.startsWith(Account.Type, 'Customer')) {
            return false;
        }

        Account previousParent = (Account) record.getOldRelated('Parent');
        Account newParent = (Account) record.getNewRelated('Parent');

        return previousParent != null && newParent != null && previousParent.BillingCountry != newParent.BillingCountry;
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        Account previousParent = (Account) record.getOldRelated('Parent');
        Account newParent = (Account) record.getNewRelated('Parent');

        return 'Moving this customer from "' +
            previousParent.Name +
            '" (' +
            previousParent.BillingCountry +
            ') to "' +
            newParent.Name +
            '" (' +
            newParent.BillingCountry +
            ') changes the invoicing entity. Raise a finance request for the transfer.';
    }
}
