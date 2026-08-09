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

    public void onBeforeInsert(TriggerHandler.Record record) {

        // record.Description = 'This contact was created by a trigger handler.';
        
        Contact contact = (Contact) record.getNewSObject();

        // record.get(Contact.AccountId);
        // record.get(Contact.CreatedById);
        // record.get('Account.Name');
        // record.get('Account.Industry');

        // record.get(Contact.Name);
        // record.get('Account.Name');
        contact.Description = 'This contact was created by a trigger handler.';
    }
}
