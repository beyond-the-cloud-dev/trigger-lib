public with sharing class ContactEmailNormalizationPopulator implements BeforeInsert.Populator {
    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isNotBlank(Contact.Email);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        Contact contactRecord = (Contact) record.getNewSObject();

        record.put(Contact.Email, contactRecord.Email.trim().toLowerCase());
    }
}
