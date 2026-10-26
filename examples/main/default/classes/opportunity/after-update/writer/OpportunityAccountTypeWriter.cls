public with sharing class OpportunityAccountTypeWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.RecursionGuard {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Opportunity.AccountId => TriggerTypes.ParentFields.with(Account.Type) };
    }

    public Integer maxRunsPerRecordOnAfterUpdate() {
        return 1;
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        if (!record.isChangedTo(Opportunity.StageName, 'Closed Won')) {
            return false;
        }

        Account account = (Account) record.getNewParent(Opportunity.AccountId);

        return account != null && account.Type != 'Customer - Direct';
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        unitOfWork.toUpdate(new Account(Id = newOpportunity.AccountId, Type = 'Customer - Direct'));
    }
}
