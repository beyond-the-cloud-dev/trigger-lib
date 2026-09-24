public with sharing class ContactReachabilityValidator implements BeforeInsert.Validator, BeforeInsert.Bypassable {
    public static Boolean isBypassed = false;

    public Boolean bypassOnBeforeInsertWhen() {
        return ContactReachabilityValidator.isBypassed || System.isBatch();
    }

    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isBlank(Contact.Email) && record.isBlank(Contact.Phone) && record.isBlank(Contact.MobilePhone);
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        record.addError('A contact needs at least one way to be reached. Fill in Email, Phone or Mobile.');
    }
}
