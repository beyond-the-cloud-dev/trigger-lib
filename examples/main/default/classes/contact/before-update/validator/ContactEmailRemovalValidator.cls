public with sharing class ContactEmailRemovalValidator implements BeforeUpdate.Validator {
    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Contact.Email) && record.isBlank(Contact.Email) && record.isFalse(Contact.HasOptedOutOfEmail);
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        record.addError(Contact.Email, 'Email cannot be cleared while the contact is still opted in. Tick Email Opt Out first, then remove the address.');
    }
}
