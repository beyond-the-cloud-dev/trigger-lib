public with sharing class AccountOwnerTransferWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery, AfterUpdate.RelatedQuery, AfterUpdate.Bypassable {
    public static Boolean isBypassed = false;

    public Boolean bypassOnAfterUpdateWhen() {
        return AccountOwnerTransferWriter.isBypassed || System.isBatch();
    }

    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.OwnerId => TriggerTypes.ParentFields.with(User.Name) };
    }

    public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.OwnerId => TriggerTypes.ParentFields.with(User.Name) };
    }

    public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
        return new Map<String, AfterUpdate.RecordsProvider>{ 'openOpportunities' => new AccountOpenOpportunitiesProvider() };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Account.OwnerId);
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Account newAccount = (Account) record.getNewSObject();
        User oldOwner = (User) record.getOldParent(Account.OwnerId);
        User newOwner = (User) record.getNewParent(Account.OwnerId);
        String handoverNote = Date.today().format() + ' - account handed over from ' + oldOwner?.Name + ' to ' + newOwner?.Name;

        for (SObject row : record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId())) {
            Opportunity opportunity = (Opportunity) row;

            unitOfWork.toUpdate(new Opportunity(Id = opportunity.Id, OwnerId = newAccount.OwnerId, Description = this.notedDescription(handoverNote, opportunity.Description)));
        }
    }

    private String notedDescription(String handoverNote, String description) {
        return String.isBlank(description) ? handoverNote : handoverNote + '\n' + description;
    }

    private with sharing class AccountOpenOpportunitiesProvider implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return [
                SELECT Id, AccountId, Description
                FROM Opportunity
                WHERE AccountId IN :records.getIds() AND IsClosed = FALSE
            ];
        }

        public String keyOf(SObject row) {
            return ((Opportunity) row).AccountId;
        }
    }
}
