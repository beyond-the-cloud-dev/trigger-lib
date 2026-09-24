public with sharing class ContactEmailFormatValidator implements BeforeInsert.Validator {
    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        if (record.isBlank(Contact.Email)) {
            return false;
        }

        return record.doesNotContain(Contact.Email, '@') || this.isSharedMailbox(record);
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        if (record.doesNotContain(Contact.Email, '@')) {
            record.addError(Contact.Email, 'Email must be a full address, for example jane.doe@example.com.');
            return;
        }

        record.addError(Contact.Email, 'A shared mailbox cannot be used as a contact email. Use the person\'s own address.');
    }

    private Boolean isSharedMailbox(TriggerTypes.InsertRecord record) {
        for (String prefix : new List<String>{ 'info@', 'sales@', 'support@', 'contact@', 'admin@', 'noreply@', 'no-reply@' }) {
            if (record.startsWith(Contact.Email, prefix)) {
                return true;
            }
        }

        return false;
    }
}
