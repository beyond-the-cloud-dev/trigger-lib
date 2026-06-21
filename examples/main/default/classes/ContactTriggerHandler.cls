public with sharing class ContactTriggerHandler implements TriggerHandler.RelationshipEnrichment, TriggerHandler.BeforeInsert {
    public Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{
            Contact.AccountId => TriggerHandler.FieldSelection
                .with(Account.Name, Account.Industry)
                .with('CreatedBy', User.Name, User.Email),
            Contact.CreatedById => TriggerHandler.FieldSelection
                .with(User.Name, User.Email)
        };
    }

    public Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record) {
        return record.isRecordTypeEqual('Business_Contact');
    }

    public void onBeforeInsert(SObject record) {
        Contact contact = (Contact) record;
    }
}
