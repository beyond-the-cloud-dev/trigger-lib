public with sharing class AccountParentDefaultsPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.ParentId => TriggerHandler.ParentFields.with(Account.Industry, Account.AccountSource) };
    }

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isNotNull(Account.ParentId) && (record.isBlank(Account.Industry) || record.isBlank(Account.AccountSource));
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        Account parent = (Account) record.getNewParent('Parent');

        if (parent == null) {
            return;
        }

        if (record.isBlank(Account.Industry)) {
            record.put(Account.Industry, parent.Industry);
        }

        if (record.isBlank(Account.AccountSource)) {
            record.put(Account.AccountSource, parent.AccountSource);
        }
    }
}
