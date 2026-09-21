public with sharing class ContactOwnerAlignmentHandler implements AfterInsert.Handler, AfterInsert.NewRecordEnrichment, AfterInsert.Bypassable, AfterInsert.Finalizer {
    public static Boolean isDisabled = false;

    private List<Contact> contactsToReassign = new List<Contact>();

    public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.OwnerId).with('Owner', User.IsActive) };
    }

    public Boolean bypassOnAfterInsertWhen() {
        return ContactOwnerAlignmentHandler.isDisabled;
    }

    public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
        Contact contactRecord = (Contact) record.getNewSObject();
        Account accountRecord = (Account) record.getNewRelated('Account');

        return accountRecord?.Owner?.IsActive == true && accountRecord.OwnerId != contactRecord.OwnerId;
    }

    public void onAfterInsert(TriggerHandler.InsertRecord record) {
        Account accountRecord = (Account) record.getNewRelated('Account');

        this.contactsToReassign.add(new Contact(Id = record.getId(), OwnerId = accountRecord.OwnerId));
    }

    public void finalizeAfterInsert() {
        update this.contactsToReassign;
    }
}
