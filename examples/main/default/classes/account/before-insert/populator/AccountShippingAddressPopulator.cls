public with sharing class AccountShippingAddressPopulator implements BeforeInsert.Populator, BeforeInsert.Bypassable {
    public static Boolean isDisabled = false;

    public Boolean bypassOnBeforeInsertWhen() {
        return isDisabled || System.isBatch();
    }

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isNotBlank(Account.BillingCountry) &&
            record.isBlank(Account.ShippingStreet) &&
            record.isBlank(Account.ShippingCity) &&
            record.isBlank(Account.ShippingCountry);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        Account accountRecord = (Account) record.getNewSObject();

        record.put(Account.ShippingStreet, accountRecord.BillingStreet);
        record.put(Account.ShippingCity, accountRecord.BillingCity);
        record.put(Account.ShippingState, accountRecord.BillingState);
        record.put(Account.ShippingPostalCode, accountRecord.BillingPostalCode);
        record.put(Account.ShippingCountry, accountRecord.BillingCountry);
    }
}
