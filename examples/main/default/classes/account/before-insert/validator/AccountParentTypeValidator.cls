public with sharing class AccountParentTypeValidator implements BeforeInsert.Validator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.ParentId => TriggerHandler.ParentFields.with(Account.Name, Account.Type) };
    }

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        Account parent = (Account) record.getNewParent('Parent');

        return record.isNotNull(Account.ParentId) && parent?.Type == 'Prospect';
    }

    public void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record) {
        Account parent = (Account) record.getNewParent('Parent');

        record.addError(Account.ParentId, 'Parent account "' + parent.Name + '" is still a Prospect and cannot head a hierarchy. Qualify it first.');
    }
}
