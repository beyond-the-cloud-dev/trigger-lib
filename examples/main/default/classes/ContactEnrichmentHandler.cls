public with sharing class ContactEnrichmentHandler implements TriggerHandler.RelationshipEnrichment, TriggerHandler.AfterUpdate {
    public static List<String> log = new List<String>();

    public Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{
            Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name, Account.Industry),
            Contact.OwnerId => TriggerHandler.FieldSelection.with(User.Name, User.Email)
        };
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
        Contact contact = (Contact) record.getNewSObject();

        log.add('qualifiesWhen | Account.Name = ' + contact.Account?.Name);

        return true;
    }

    public void onAfterUpdate(SObject newRecord, SObject oldRecord) {
        Contact newContact = (Contact) newRecord;
        Contact oldContact = (Contact) oldRecord;

        log.add('enriched      | Account.Name = ' + newContact.Account?.Name + ' | Account.Industry = ' + newContact.Account?.Industry);
        log.add('enriched      | Owner.Name = ' + newContact.Owner?.Name + ' | Owner.Email = ' + newContact.Owner?.Email);
        log.add('own fields    | LastName = ' + newContact.LastName + ' | CreatedDate = ' + newContact.CreatedDate);
        log.add('old record    | Description = ' + oldContact.Description);
        log.add('new record    | Description = ' + newContact.Description);
        log.add('Trigger.new   | Account still null = ' + (Trigger.newMap.get(newContact.Id).getSObject('Account') == null));
    }
}
