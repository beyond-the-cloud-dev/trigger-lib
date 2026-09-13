public with sharing class ContactBirthdateValidator implements BeforeInsert.Validator {
    private static final Integer MAX_AGE_IN_YEARS = 120;

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        if (record.isNull(Contact.Birthdate)) {
            return false;
        }

        return record.greaterThan(Contact.Birthdate, Date.today()) || record.lessThan(Contact.Birthdate, Date.today().addYears(-ContactBirthdateValidator.MAX_AGE_IN_YEARS));
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        return 'Birthdate must be in the past and less than ' + ContactBirthdateValidator.MAX_AGE_IN_YEARS + ' years ago. Check the year.';
    }
}
