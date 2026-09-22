public with sharing class AccountOwnerTransferHandler implements AfterUpdate.Handler, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery, AfterUpdate.Bypassable, AfterUpdate.Finalizer {
    public static Boolean isDisabled = false;

    private Map<Id, Id> newOwnerIdByAccountId = new Map<Id, Id>();
    private Map<Id, String> handoverNoteByAccountId = new Map<Id, String>();

    public Boolean bypassOnAfterUpdateWhen() {
        return isDisabled || System.isBatch();
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.Name) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.Name) };
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.OwnerId);
    }

    public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
        Account accountRecord = (Account) record.getNewSObject();
        User previousOwner = (User) record.getOldParent('Owner');
        User newOwner = (User) record.getNewParent('Owner');

        this.newOwnerIdByAccountId.put(record.getId(), accountRecord.OwnerId);
        this.handoverNoteByAccountId.put(record.getId(), Date.today().format() + ' - accountRecord handed over from ' + previousOwner?.Name + ' to ' + newOwner?.Name);
    }

    public void finalizeAfterUpdate() {
        List<Opportunity> opportunitiesToTransfer = new List<Opportunity>();

        for (Opportunity opportunityRecord : [
            SELECT Id, AccountId, OwnerId, Description
            FROM Opportunity
            WHERE AccountId IN :this.newOwnerIdByAccountId.keySet() AND IsClosed = FALSE
        ]) {
            opportunityRecord.OwnerId = this.newOwnerIdByAccountId.get(opportunityRecord.AccountId);
            opportunityRecord.Description = this.notedDescription(this.handoverNoteByAccountId.get(opportunityRecord.AccountId), opportunityRecord.Description);

            opportunitiesToTransfer.add(opportunityRecord);
        }

        if (opportunitiesToTransfer.isEmpty()) {
            return;
        }

        update opportunitiesToTransfer;
    }

    private String notedDescription(String handoverNote, String description) {
        return String.isBlank(description) ? handoverNote : handoverNote + '\n' + description;
    }
}
