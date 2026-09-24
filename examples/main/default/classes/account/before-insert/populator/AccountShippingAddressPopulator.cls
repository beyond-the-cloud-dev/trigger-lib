public with sharing class AccountShippingAddressPopulator implements BeforeInsert.Populator, BeforeInsert.Bypassable {
    public static Boolean isBypassed = false;

    public Boolean bypassOnBeforeInsertWhen() {
        return AccountShippingAddressPopulator.isBypassed || System.isBatch();
    }

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotBlank(Account.BillingCountry) &&
            record.isBlank(Account.ShippingStreet) &&
            record.isBlank(Account.ShippingCity) &&
            record.isBlank(Account.ShippingCountry);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Account newAccount = (Account) record.getNewSObject();

        record.put(Account.ShippingStreet, newAccount.BillingStreet);
        record.put(Account.ShippingCity, newAccount.BillingCity);
        record.put(Account.ShippingState, newAccount.BillingState);
        record.put(Account.ShippingPostalCode, newAccount.BillingPostalCode);
        record.put(Account.ShippingCountry, newAccount.BillingCountry);
    }
}
