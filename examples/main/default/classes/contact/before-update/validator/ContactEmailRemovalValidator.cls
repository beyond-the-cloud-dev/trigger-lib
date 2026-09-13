public with sharing class ContactEmailRemovalValidator implements BeforeUpdate.Validator {
    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Contact.Email) && record.isBlank(Contact.Email) && record.isFalse(Contact.HasOptedOutOfEmail);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        return 'Email cannot be cleared while the contact is still opted in. Tick Email Opt Out first, then remove the address.';
    }
}
