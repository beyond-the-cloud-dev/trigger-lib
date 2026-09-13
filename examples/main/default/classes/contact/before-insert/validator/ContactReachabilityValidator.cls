public with sharing class ContactReachabilityValidator implements BeforeInsert.Validator, BeforeInsert.Bypassable {
    public static Boolean isDisabled = false;

    public Boolean bypassOnBeforeInsertWhen() {
        return ContactReachabilityValidator.isDisabled || System.isBatch();
    }

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isBlank(Contact.Email) && record.isBlank(Contact.Phone) && record.isBlank(Contact.MobilePhone);
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        return 'A contact needs at least one way to be reached. Fill in Email, Phone or Mobile.';
    }
}
