public with sharing class ContactMailingAddressPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{
            Contact.AccountId => TriggerTypes.ParentFields
                .with(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode)
                .with(Account.BillingCountry)
        };
    }

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotNull(Contact.AccountId) && record.isBlank(Contact.MailingStreet) && record.isBlank(Contact.MailingCity);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Account account = (Account) record.getNewParent(Contact.AccountId);

        if (account == null) {
            return;
        }

        record.put(Contact.MailingStreet, account.BillingStreet);
        record.put(Contact.MailingCity, account.BillingCity);
        record.put(Contact.MailingState, account.BillingState);
        record.put(Contact.MailingPostalCode, account.BillingPostalCode);
        record.put(Contact.MailingCountry, account.BillingCountry);
    }
}
