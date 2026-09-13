public with sharing class AccountShippingSyncPopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Boolean billingMoved = record.isAnyChanged(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry);

        return billingMoved && this.shippingFollowedBilling((Account) record.getOldSObject());
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        Account accountRecord = (Account) record.getNewSObject();

        record.put(Account.ShippingStreet, accountRecord.BillingStreet);
        record.put(Account.ShippingCity, accountRecord.BillingCity);
        record.put(Account.ShippingState, accountRecord.BillingState);
        record.put(Account.ShippingPostalCode, accountRecord.BillingPostalCode);
        record.put(Account.ShippingCountry, accountRecord.BillingCountry);
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
