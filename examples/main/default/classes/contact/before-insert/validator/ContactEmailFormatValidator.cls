public with sharing class ContactEmailFormatValidator implements BeforeInsert.Validator {
    private static final List<String> SHARED_MAILBOX_PREFIXES = new List<String>{ 'info@', 'sales@', 'support@', 'contact@', 'admin@', 'noreply@', 'no-reply@' };

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        if (record.isBlank(Contact.Email)) {
            return false;
        }

        return record.doesNotContain(Contact.Email, '@') || this.isSharedMailbox(record);
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        if (record.doesNotContain(Contact.Email, '@')) {
            return 'Email must be a full address, for example jane.doe@example.com.';
        }

        return 'A shared mailbox cannot be used as a contact email. Use the person\'s own address.';
    }

    private Boolean isSharedMailbox(TriggerHandler.InsertRecord record) {
        for (String prefix : ContactEmailFormatValidator.SHARED_MAILBOX_PREFIXES) {
            if (record.startsWith(Contact.Email, prefix)) {
                return true;
            }
        }

        return false;
    }
}
