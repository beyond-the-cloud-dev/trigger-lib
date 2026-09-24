public with sharing class AccountBillingCountryValidator implements BeforeUpdate.Validator {
    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        return record.isChanged(Account.BillingCountry) && record.isBlank(Account.BillingCountry) && String.isNotBlank(oldAccount.BillingCountry);
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        record.addError(Account.BillingCountry, 'Billing Country cannot be cleared. It is currently ' + oldAccount.BillingCountry + '; replace it with another country instead.');
    }
}
