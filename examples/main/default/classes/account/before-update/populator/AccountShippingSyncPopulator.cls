public with sharing class AccountShippingSyncPopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        Boolean billingMoved = record.isAnyChanged(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry);

        return billingMoved && this.shippingFollowedBilling((Account) record.getOldSObject());
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        Account newAccount = (Account) record.getNewSObject();

        record.put(Account.ShippingStreet, newAccount.BillingStreet);
        record.put(Account.ShippingCity, newAccount.BillingCity);
        record.put(Account.ShippingState, newAccount.BillingState);
        record.put(Account.ShippingPostalCode, newAccount.BillingPostalCode);
        record.put(Account.ShippingCountry, newAccount.BillingCountry);
    }

    private Boolean shippingFollowedBilling(Account oldAccount) {
        if (String.isBlank(oldAccount.ShippingStreet) && String.isBlank(oldAccount.ShippingCity)) {
            return true;
        }

        return oldAccount.ShippingStreet == oldAccount.BillingStreet &&
            oldAccount.ShippingCity == oldAccount.BillingCity &&
            oldAccount.ShippingPostalCode == oldAccount.BillingPostalCode &&
            oldAccount.ShippingCountry == oldAccount.BillingCountry;
    }
}
