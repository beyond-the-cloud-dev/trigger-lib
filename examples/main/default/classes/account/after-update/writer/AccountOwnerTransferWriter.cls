public with sharing class AccountOwnerTransferWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery, AfterUpdate.RelatedQuery, AfterUpdate.Bypassable {
    public static Boolean isDisabled = false;

    public Boolean bypassOnAfterUpdateWhen() {
        return isDisabled || System.isBatch();
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.Name) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.Name) };
    }

    public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
        return new Map<String, AfterUpdate.RecordsProvider>{ 'openOpportunities' => new AccountOpenOpportunitiesProvider() };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.OwnerId);
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Account accountRecord = (Account) record.getNewSObject();
        User previousOwner = (User) record.getOldParent('Owner');
        User newOwner = (User) record.getNewParent('Owner');
        String handoverNote = Date.today().format() + ' - accountRecord handed over from ' + previousOwner?.Name + ' to ' + newOwner?.Name;

        for (SObject relatedRecord : record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId())) {
            Opportunity opportunityRecord = (Opportunity) relatedRecord;

            unitOfWork.toUpdate(
                new Opportunity(Id = opportunityRecord.Id, OwnerId = accountRecord.OwnerId, Description = this.notedDescription(handoverNote, opportunityRecord.Description))
            );
        }
    }

    private String notedDescription(String handoverNote, String description) {
        return String.isBlank(description) ? handoverNote : handoverNote + '\n' + description;
    }

    private with sharing class AccountOpenOpportunitiesProvider implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerHandler.UpdateRecords records) {
            return [
                SELECT Id, AccountId, Description
                FROM Opportunity
                WHERE AccountId IN :records.getIds() AND IsClosed = FALSE
            ];
        }

        public String keyOf(SObject record) {
            return ((Opportunity) record).AccountId;
        }
    }
}
