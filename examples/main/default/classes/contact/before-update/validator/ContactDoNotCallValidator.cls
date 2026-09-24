public with sharing class ContactDoNotCallValidator implements BeforeUpdate.Validator {
    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Contact.DoNotCall, true) && record.isBlank(Contact.Description);
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        record.addError(Contact.Description, 'Record who asked for Do Not Call, and when, in Description before ticking it.');
    }
}
