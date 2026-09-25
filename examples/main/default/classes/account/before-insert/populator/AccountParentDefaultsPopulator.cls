public with sharing class AccountParentDefaultsPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.ParentId => TriggerTypes.ParentFields.with(Account.Industry, Account.AccountSource) };
    }

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotNull(Account.ParentId) && (record.isBlank(Account.Industry) || record.isBlank(Account.AccountSource));
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Account parent = (Account) record.getNewParent(Account.ParentId);

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
