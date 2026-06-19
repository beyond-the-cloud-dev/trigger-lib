public with sharing class ContactTriggerHandler implements TriggerHandler.RelationshipEnrichment, TriggerHandler.BeforeInsert {
    public Map<SObjectField, TriggerHandler.SelectEntity> enrichParentRelationships() {
        return new Map<SObjectField, TriggerHandler.SelectEntity>{
            Contact.AccountId => TriggerHandler.SelectEntity
                .with(Account.Name, Account.Industry)
                .with('CreatedBy', User.Name, User.Email),
            Contact.CreatedById => TriggerHandler.SelectEntity
                .with(User.Name, User.Email)
        };
    }

    public Boolean qualifyOnBeforeInsertWhen(SObject record) {
        return ((Contact)record).LastName == 'Smith';
    }

    public void beforeInsert(SObject record) {
        Contact contact = (Contact)record;
    
    }
}
