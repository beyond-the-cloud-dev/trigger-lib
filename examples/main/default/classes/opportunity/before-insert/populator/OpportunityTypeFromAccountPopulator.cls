public with sharing class OpportunityTypeFromAccountPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery, BeforeInsert.Bypassable {
    public static Boolean isBypassed = false;

    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Opportunity.AccountId => TriggerTypes.ParentFields.with(Account.Type) };
    }

    public Boolean bypassOnBeforeInsertWhen() {
        return OpportunityTypeFromAccountPopulator.isBypassed || System.isBatch();
    }

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isBlank(Opportunity.Type) && record.isNotNull(Opportunity.AccountId);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Account account = (Account) record.getNewParent(Opportunity.AccountId);
        Boolean isCustomerAccount = account?.Type?.startsWith('Customer') == true;

        record.put(Opportunity.Type, isCustomerAccount ? 'Existing Customer - Upgrade' : 'New Customer');
    }
}
