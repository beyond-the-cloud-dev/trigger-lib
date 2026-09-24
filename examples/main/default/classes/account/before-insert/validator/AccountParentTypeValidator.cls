public with sharing class AccountParentTypeValidator implements BeforeInsert.Validator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.ParentId => TriggerTypes.ParentFields.with(Account.Name, Account.Type) };
    }

    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        Account parent = (Account) record.getNewParent('Parent');

        return record.isNotNull(Account.ParentId) && parent?.Type == 'Prospect';
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        Account parent = (Account) record.getNewParent('Parent');

        record.addError(Account.ParentId, 'Parent account "' + parent.Name + '" is still a Prospect and cannot head a hierarchy. Qualify it first.');
    }
}
