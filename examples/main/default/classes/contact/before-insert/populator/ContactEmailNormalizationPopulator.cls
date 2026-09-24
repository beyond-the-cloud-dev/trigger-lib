public with sharing class ContactEmailNormalizationPopulator implements BeforeInsert.Populator {
    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotBlank(Contact.Email);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Contact newContact = (Contact) record.getNewSObject();

        record.put(Contact.Email, newContact.Email.trim().toLowerCase());
    }
}
