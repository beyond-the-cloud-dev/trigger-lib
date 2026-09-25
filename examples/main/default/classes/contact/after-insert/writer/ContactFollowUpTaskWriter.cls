public with sharing class ContactFollowUpTaskWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.ContinueOnError {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
        return record.equals(Contact.LeadSource, 'Web') && record.isNotBlank(Contact.Email);
    }

    public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Contact newContact = (Contact) record.getNewSObject();
        Account account = (Account) record.getNewParent(Contact.AccountId);

        unitOfWork.toInsert(
            new Task(
                WhoId = record.getId(),
                WhatId = newContact.AccountId,
                OwnerId = newContact.OwnerId,
                Subject = 'Follow up with new web contact' + (account == null ? '' : ' from ' + account.Name),
                ActivityDate = Date.today().addDays(2),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }
}
