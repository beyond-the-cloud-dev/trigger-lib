public with sharing class OpportunityAccountTypeWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.RecursionGuard {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Type) };
    }

    public Integer maxRecursionDepthOnAfterUpdate() {
        return 1;
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        Account parentAccount = (Account) record.getNewParent('Account');

        return record.isChangedTo(Opportunity.StageName, 'Closed Won') && parentAccount != null && parentAccount.Type != 'Customer - Direct';
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        unitOfWork.toUpdate(new Account(Id = newOpportunity.AccountId, Type = 'Customer - Direct'));
    }
}
