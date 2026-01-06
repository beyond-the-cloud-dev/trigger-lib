public with sharing class ContactTriggerHandler implements TriggerHandler.RelationshipEnrichment {
    public Map<SObjectField, List<SObject>> getFieldsToPull() {
        return new Map<SObjectField, List<SObject>>{
            Contact.AccountId => TriggerHandler.RelationshipEnrichment
                .with(Account.Name, Account.Industry)
                .with('CreatedBy', User.Name, User.Email),
            Contact.CreatedById => TriggerHandler.RelationshipEnrichment
                .with(User.Name, User.Email)
        };
    }
}