public with sharing class ContactOwnerAlignmentWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.Bypassable {
    public static Boolean isBypassed = false;

    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.OwnerId).with('Owner', User.IsActive) };
    }

    public Boolean bypassOnAfterInsertWhen() {
        return ContactOwnerAlignmentWriter.isBypassed;
    }

    public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
        Contact newContact = (Contact) record.getNewSObject();
        Account account = (Account) record.getNewParent('Account');

        return account?.Owner?.IsActive == true && account.OwnerId != newContact.OwnerId;
    }

    public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Account account = (Account) record.getNewParent('Account');

        unitOfWork.toUpdate(new Contact(Id = record.getId(), OwnerId = account.OwnerId));
    }
}
