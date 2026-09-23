public with sharing class ContactFollowUpTaskWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.ContinueOnError {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
        return record.equals(Contact.LeadSource, 'Web') && record.isNotBlank(Contact.Email);
    }

    public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Contact contactRecord = (Contact) record.getNewSObject();
        Account accountRecord = (Account) record.getNewParent('Account');

        unitOfWork.toInsert(
            new Task(
                WhoId = record.getId(),
                WhatId = contactRecord.AccountId,
                OwnerId = contactRecord.OwnerId,
                Subject = 'Follow up with new web contactRecord' + (accountRecord == null ? '' : ' from ' + accountRecord.Name),
                ActivityDate = Date.today().addDays(2),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }
}
