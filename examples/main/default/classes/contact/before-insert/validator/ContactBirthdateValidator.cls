public with sharing class ContactBirthdateValidator implements BeforeInsert.Validator {
    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        if (record.isNull(Contact.Birthdate)) {
            return false;
        }

        return record.greaterThan(Contact.Birthdate, Date.today()) || record.lessThan(Contact.Birthdate, Date.today().addYears(-120));
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        return 'Birthdate must be in the past and less than 120 years ago. Check the year.';
    }
}
