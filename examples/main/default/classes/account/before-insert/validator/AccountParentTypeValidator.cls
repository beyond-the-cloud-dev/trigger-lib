public with sharing class AccountParentTypeValidator implements BeforeInsert.Validator, BeforeInsert.NewRecordEnrichment {
    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Account.ParentId => TriggerHandler.FieldSelection.with(Account.Name, Account.Type) };
    }

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        Account parent = (Account) record.getNewRelated('Parent');

        return record.isNotNull(Account.ParentId) && parent?.Type == 'Prospect';
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        Account parent = (Account) record.getNewRelated('Parent');

        return 'Parent account "' + parent.Name + '" is still a Prospect and cannot head a hierarchy. Qualify it first.';
    }
}
