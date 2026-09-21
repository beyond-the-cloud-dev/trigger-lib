public with sharing class ContactAccountTransferPopulator implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery, BeforeUpdate.RecursionGuard {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Integer maxRecursionDepthOnBeforeUpdate() {
        return 1;
    }

    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Contact.AccountId) && !record.isChangedFrom(Contact.AccountId, null);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        Contact contactRecord = (Contact) record.getNewSObject();
        Account previousAccount = (Account) record.getOldRelated('Account');
        Account currentAccount = (Account) record.getNewRelated('Account');

        String auditLine = Date.today().format() + ' - transferred from ' + (previousAccount?.Name ?? 'a deleted account') + ' to ' + (currentAccount?.Name ?? 'no account') + '.';

        record.put(Contact.Description, String.isBlank(contactRecord.Description) ? auditLine : contactRecord.Description + '\n' + auditLine);
    }
}
