public with sharing class AccountAddressCascadeWriter implements AfterUpdate.Writer, AfterUpdate.RelatedQuery, AfterUpdate.ContinueOnError, AfterUpdate.RecursionGuard {
    public Integer maxRecursionDepthOnAfterUpdate() {
        return 1;
    }

    public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
        return new Map<String, AfterUpdate.RecordsProvider>{ 'contacts' => new AccountContactsProvider() };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isAnyChanged(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry);
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Account newAddress = (Account) record.getNewSObject();
        Account previousAddress = (Account) record.getOldSObject();

        for (SObject relatedRecord : record.getRelated('contacts').getAllWhereKeyEquals(record.getId())) {
            Contact contactRecord = (Contact) relatedRecord;

            if (!this.mailingFollowedAccount(contactRecord, previousAddress)) {
                continue;
            }

            unitOfWork.toUpdate(
                new Contact(
                    Id = contactRecord.Id,
                    MailingStreet = newAddress.BillingStreet,
                    MailingCity = newAddress.BillingCity,
                    MailingState = newAddress.BillingState,
                    MailingPostalCode = newAddress.BillingPostalCode,
                    MailingCountry = newAddress.BillingCountry
                )
            );
        }
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

    private with sharing class AccountContactsProvider implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerHandler.UpdateRecords records) {
            return [
                SELECT Id, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                FROM Contact
                WHERE AccountId IN :records.getIds()
            ];
        }

        public String keyOf(SObject record) {
            return ((Contact) record).AccountId;
        }
    }
}
