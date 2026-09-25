public with sharing class ContactAccountTransferPopulator implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery, BeforeUpdate.RecursionGuard {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Integer maxRunsPerRecordOnBeforeUpdate() {
        return 1;
    }

    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Contact.AccountId) && !record.isChangedFrom(Contact.AccountId, null);
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        Contact newContact = (Contact) record.getNewSObject();
        Account oldAccount = (Account) record.getOldParent(Contact.AccountId);
        Account newAccount = (Account) record.getNewParent(Contact.AccountId);

        String auditLine = Date.today().format() + ' - transferred from ' + (oldAccount?.Name ?? 'a deleted account') + ' to ' + (newAccount?.Name ?? 'no account') + '.';

        record.put(Contact.Description, String.isBlank(newContact.Description) ? auditLine : newContact.Description + '\n' + auditLine);
    }
}
