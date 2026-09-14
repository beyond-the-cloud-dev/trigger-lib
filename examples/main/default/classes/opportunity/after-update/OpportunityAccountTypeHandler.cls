public with sharing class OpportunityAccountTypeHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.RecursionGuard, AfterUpdate.Finalizer {
    private Map<Id, Account> accountsToPromote = new Map<Id, Account>();

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Opportunity.AccountId => TriggerHandler.FieldSelection.with(Account.Type) };
    }

    public Integer maxRecursionDepthOnAfterUpdate() {
        return 1;
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        Account parentAccount = (Account) record.getNewRelated('Account');

        return record.isChangedTo(Opportunity.StageName, 'Closed Won') && parentAccount != null && parentAccount.Type != 'Customer - Direct';
    }

    public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        this.accountsToPromote.put(newOpportunity.AccountId, new Account(Id = newOpportunity.AccountId, Type = 'Customer - Direct'));
    }

    public void finalizeAfterUpdate() {
        update this.accountsToPromote.values();
    }
}
