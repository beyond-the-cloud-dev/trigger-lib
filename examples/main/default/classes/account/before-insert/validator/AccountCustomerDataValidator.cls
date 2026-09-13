public with sharing class AccountCustomerDataValidator implements BeforeInsert.Validator {
    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer') && (record.isBlank(Account.Industry) || record.isBlank(Account.BillingCountry));
    }

    public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
        List<String> missingFields = new List<String>();

        if (record.isBlank(Account.Industry)) {
            missingFields.add('Industry');
        }

        if (record.isBlank(Account.BillingCountry)) {
            missingFields.add('Billing Country');
        }

        return 'A customer account requires ' + String.join(missingFields, ' and ') + '.';
    }
}
