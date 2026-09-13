public with sharing class OpportunityTypeFromAccountPopulator implements BeforeInsert.Populator, BeforeInsert.NewRecordEnrichment, BeforeInsert.Bypassable {
    public static Boolean isBypassed = false;

    private static final String CUSTOMER_ACCOUNT_PREFIX = 'Customer';
    private static final String EXISTING_CUSTOMER_TYPE = 'Existing Customer - Upgrade';
    private static final String NEW_CUSTOMER_TYPE = 'New Customer';

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Opportunity.AccountId => TriggerHandler.FieldSelection.with(Account.Type) };
    }

    public Boolean bypassOnBeforeInsertWhen() {
        return isBypassed || System.isBatch();
    }

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isBlank(Opportunity.Type) && record.isNotNull(Opportunity.AccountId);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        Account parentAccount = (Account) record.getNewRelated('Account');
        Boolean isCustomerAccount = parentAccount?.Type?.startsWith(CUSTOMER_ACCOUNT_PREFIX) == true;

        record.put(Opportunity.Type, isCustomerAccount ? EXISTING_CUSTOMER_TYPE : NEW_CUSTOMER_TYPE);
    }
}
