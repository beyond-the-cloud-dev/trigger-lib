public with sharing class OpportunityTypeFromAccountPopulator implements BeforeInsert.Populator, BeforeInsert.NewRecordEnrichment, BeforeInsert.Bypassable {
    public static Boolean isBypassed = false;

    public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnBeforeInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Type) };
    }

    public Boolean bypassOnBeforeInsertWhen() {
        return isBypassed || System.isBatch();
    }

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isBlank(Opportunity.Type) && record.isNotNull(Opportunity.AccountId);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        Account parentAccount = (Account) record.getNewRelated('Account');
        Boolean isCustomerAccount = parentAccount?.Type?.startsWith('Customer') == true;

        record.put(Opportunity.Type, isCustomerAccount ? 'Existing Customer - Upgrade' : 'New Customer');
    }
}
