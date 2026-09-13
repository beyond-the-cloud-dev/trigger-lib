public with sharing class OpportunityAccountTypeHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.RecursionGuard, AfterUpdate.Finalizer {
    private static final String CLOSED_WON = 'Closed Won';
    private static final String CUSTOMER_TYPE = 'Customer - Direct';

    private Map<Id, Account> accountsToPromote = new Map<Id, Account>();

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Opportunity.AccountId => TriggerHandler.FieldSelection.with(Account.Type) };
    }

    public Integer maxRecursionDepthOnAfterUpdate() {
        return 1;
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        Account parentAccount = (Account) record.getNewRelated('Account');

        return record.isChangedTo(Opportunity.StageName, CLOSED_WON) && parentAccount != null && parentAccount.Type != CUSTOMER_TYPE;
    }

    public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        this.accountsToPromote.put(newOpportunity.AccountId, new Account(Id = newOpportunity.AccountId, Type = CUSTOMER_TYPE));
    }

    public void finalizeAfterUpdate() {
        update this.accountsToPromote.values();
    }
}
