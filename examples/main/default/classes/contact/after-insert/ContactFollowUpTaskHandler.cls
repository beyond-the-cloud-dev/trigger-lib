public with sharing class ContactFollowUpTaskHandler implements AfterInsert.Handler, AfterInsert.NewRecordEnrichment, AfterInsert.Finalizer, AfterInsert.ContinueOnError {
    private static final Integer DAYS_TO_FOLLOW_UP = 2;

    private List<Task> followUps = new List<Task>();

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name) };
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
                ActivityDate = Date.today().addDays(ContactFollowUpTaskHandler.DAYS_TO_FOLLOW_UP),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }

    public void finalizeAfterInsert() {
        insert this.followUps;
    }
}
