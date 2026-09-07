public with sharing class ContactEnrichmentHandler implements TriggerHandler.NewRecordEnrichment, TriggerHandler.OldRecordEnrichment, TriggerHandler.AfterUpdate {
    public static List<String> log = new List<String>();

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrich() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{
            Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name, Account.Industry),
            Contact.OwnerId => TriggerHandler.FieldSelection.with(User.Name, User.Email)
        };
    }

    // The handler reads getOldRelated('Account'), so the old side declares that lookup too.
    public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrich() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{
            Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name, Account.Industry)
        };
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
        log.add('qualifiesWhen | Account related = ' + record.getNewRelated('Account'));

        return true;
    }

    public void onAfterUpdate(TriggerHandler.Record record) {
        Contact contact = (Contact) record.getNewSObject();
        Contact oldContact = (Contact) record.getOldSObject();
        Account account = (Account) record.getNewRelated('Account');
        User owner = (User) record.getNewRelated('Owner');

        log.add('enriched      | Account.Name = ' + account?.Name + ' | Account.Industry = ' + account?.Industry);
        log.add('enriched      | Owner.Name = ' + owner?.Name + ' | Owner.Email = ' + owner?.Email);
        log.add('own fields    | LastName = ' + contact.LastName + ' | CreatedDate = ' + contact.CreatedDate);
        log.add('old record    | Description = ' + oldContact?.Description);
        log.add('new record    | Description = ' + contact.Description);
        log.add('old related   | Account = ' + record.getOldRelated('Account'));
    }
}
