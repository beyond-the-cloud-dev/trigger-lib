public with sharing class AccountAddressCascadeWriter implements AfterUpdate.Writer, AfterUpdate.RelatedQuery, AfterUpdate.ContinueOnError, AfterUpdate.RecursionGuard {
    public Integer maxRunsPerRecordOnAfterUpdate() {
        return 1;
    }

    public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
        return new Map<String, AfterUpdate.RecordsProvider>{ 'contacts' => new AccountContactsProvider() };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isAnyChanged(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry);
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Account newAccount = (Account) record.getNewSObject();
        Account oldAccount = (Account) record.getOldSObject();

        for (SObject row : record.getRelated('contacts').getAllWhereKeyEquals(record.getId())) {
            Contact contact = (Contact) row;

            if (!this.mailingFollowedAccount(contact, oldAccount)) {
                continue;
            }

            unitOfWork.toUpdate(
                new Contact(
                    Id = contact.Id,
                    MailingStreet = newAccount.BillingStreet,
                    MailingCity = newAccount.BillingCity,
                    MailingState = newAccount.BillingState,
                    MailingPostalCode = newAccount.BillingPostalCode,
                    MailingCountry = newAccount.BillingCountry
                )
            );
        }
    }

    private Boolean mailingFollowedAccount(Contact contact, Account oldAccount) {
        if (String.isBlank(contact.MailingStreet) && String.isBlank(contact.MailingCity)) {
            return true;
        }

        return contact.MailingStreet == oldAccount.BillingStreet &&
            contact.MailingCity == oldAccount.BillingCity &&
            contact.MailingPostalCode == oldAccount.BillingPostalCode &&
            contact.MailingCountry == oldAccount.BillingCountry;
    }

    private with sharing class AccountContactsProvider implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return [
                SELECT Id, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                FROM Contact
                WHERE AccountId IN :records.getIds()
            ];
        }

        public String keyOf(SObject row) {
            return ((Contact) row).AccountId;
        }
    }
}
