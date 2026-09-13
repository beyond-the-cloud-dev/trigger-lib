public with sharing class AccountBillingCountryValidator implements BeforeUpdate.Validator {
    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        return record.isChanged(Account.BillingCountry) && record.isBlank(Account.BillingCountry) && String.isNotBlank(oldAccount.BillingCountry);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        return 'Billing Country cannot be cleared. It is currently ' + oldAccount.BillingCountry + '; replace it with another country instead.';
    }
}
