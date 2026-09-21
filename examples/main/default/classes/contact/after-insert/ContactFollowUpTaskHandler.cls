public with sharing class ContactFollowUpTaskHandler implements AfterInsert.Handler, AfterInsert.NewRecordEnrichment, AfterInsert.Finalizer, AfterInsert.ContinueOnError {
    private List<Task> followUps = new List<Task>();

    public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
        return record.equals(Contact.LeadSource, 'Web') && record.isNotBlank(Contact.Email);
    }

    public void onAfterInsert(TriggerHandler.InsertRecord record) {
        Contact contactRecord = (Contact) record.getNewSObject();
        Account accountRecord = (Account) record.getNewRelated('Account');

        this.followUps.add(
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

    public void finalizeAfterInsert() {
        insert this.followUps;
    }
}
