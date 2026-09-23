public with sharing class ContactOwnerAlignmentWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.Bypassable {
    public static Boolean isDisabled = false;

    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.OwnerId).with('Owner', User.IsActive) };
    }

    public Boolean bypassOnAfterInsertWhen() {
        return ContactOwnerAlignmentWriter.isDisabled;
    }

    public Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
        Contact contactRecord = (Contact) record.getNewSObject();
        Account accountRecord = (Account) record.getNewParent('Account');

        return accountRecord?.Owner?.IsActive == true && accountRecord.OwnerId != contactRecord.OwnerId;
    }

    public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Account accountRecord = (Account) record.getNewParent('Account');

        unitOfWork.toUpdate(new Contact(Id = record.getId(), OwnerId = accountRecord.OwnerId));
    }
}
