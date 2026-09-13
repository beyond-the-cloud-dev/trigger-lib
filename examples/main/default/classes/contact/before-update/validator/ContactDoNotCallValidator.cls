public with sharing class ContactDoNotCallValidator implements BeforeUpdate.Validator {
    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Contact.DoNotCall, true) && record.isBlank(Contact.Description);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        return 'Record who asked for Do Not Call, and when, in Description before ticking it.';
    }
}
