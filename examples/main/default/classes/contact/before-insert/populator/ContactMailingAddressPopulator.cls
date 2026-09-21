public with sharing class ContactMailingAddressPopulator implements BeforeInsert.Populator, BeforeInsert.NewRecordEnrichment {
    public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnBeforeInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{
            Contact.AccountId => TriggerHandler.ParentFields
                .with(Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode)
                .with(Account.BillingCountry)
        };
    }

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isNotNull(Contact.AccountId) && record.isBlank(Contact.MailingStreet) && record.isBlank(Contact.MailingCity);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        Account accountRecord = (Account) record.getNewRelated('Account');

        if (accountRecord == null) {
            return;
        }

        record.put(Contact.MailingStreet, accountRecord.BillingStreet);
        record.put(Contact.MailingCity, accountRecord.BillingCity);
        record.put(Contact.MailingState, accountRecord.BillingState);
        record.put(Contact.MailingPostalCode, accountRecord.BillingPostalCode);
        record.put(Contact.MailingCountry, accountRecord.BillingCountry);
    }
}
