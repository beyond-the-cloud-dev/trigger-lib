public with sharing class AccountCustomerDataValidator implements BeforeInsert.Validator {
    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer') && (record.isBlank(Account.Industry) || record.isBlank(Account.BillingCountry));
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        if (record.isBlank(Account.Industry)) {
            record.addError(Account.Industry, 'A customer account requires Industry.');
        }

        if (record.isBlank(Account.BillingCountry)) {
            record.addError(Account.BillingCountry, 'A customer account requires Billing Country.');
        }
    }
}
