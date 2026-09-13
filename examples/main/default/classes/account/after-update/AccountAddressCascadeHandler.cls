public with sharing class AccountAddressCascadeHandler implements AfterUpdate.Handler, AfterUpdate.Finalizer, AfterUpdate.ContinueOnError, AfterUpdate.RecursionGuard {
    private Map<Id, Account> newAddressByAccountId = new Map<Id, Account>();
    private Map<Id, Account> oldAddressByAccountId = new Map<Id, Account>();

    public Integer maxRecursionDepthOnAfterUpdate() {
        return 1;
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isAnyChanged(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry);
    }

    public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
        this.newAddressByAccountId.put(record.getId(), (Account) record.getNewSObject());
        this.oldAddressByAccountId.put(record.getId(), (Account) record.getOldSObject());
    }

    public void finalizeAfterUpdate() {
        List<Contact> contactsToRealign = new List<Contact>();

        for (Contact contactRecord : [
            SELECT Id, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
            FROM Contact
            WHERE AccountId IN :this.newAddressByAccountId.keySet()
        ]) {
            if (!this.mailingFollowedAccount(contactRecord, this.oldAddressByAccountId.get(contactRecord.AccountId))) {
                continue;
            }

            Account accountRecord = this.newAddressByAccountId.get(contactRecord.AccountId);

            contactRecord.MailingStreet = accountRecord.BillingStreet;
            contactRecord.MailingCity = accountRecord.BillingCity;
            contactRecord.MailingState = accountRecord.BillingState;
            contactRecord.MailingPostalCode = accountRecord.BillingPostalCode;
            contactRecord.MailingCountry = accountRecord.BillingCountry;

            contactsToRealign.add(contactRecord);
        }

        if (contactsToRealign.isEmpty()) {
            return;
        }

        update contactsToRealign;
    }

    private Boolean mailingFollowedAccount(Contact contactRecord, Account previousAddress) {
        if (String.isBlank(contactRecord.MailingStreet) && String.isBlank(contactRecord.MailingCity)) {
            return true;
        }

        return contactRecord.MailingStreet == previousAddress.BillingStreet &&
            contactRecord.MailingCity == previousAddress.BillingCity &&
            contactRecord.MailingPostalCode == previousAddress.BillingPostalCode &&
            contactRecord.MailingCountry == previousAddress.BillingCountry;
    }
}
