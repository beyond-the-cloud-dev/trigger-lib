public with sharing class TriggerHandler {
    public interface BeforeInsert { 
        Boolean qualifyOnBeforeInsertWhen(Record record);
        void beforeInsert(List<SObject> newRecords); 
    }
        
    public interface AfterInsert {
        Boolean isQualifiedAfterInsert(Record record);
        void afterInsert(List<SObject> newRecords);
    }

    public interface BeforeUpdate {
        Boolean isQualifiedBeforeUpdate(Record record);
        void beforeUpdate(List<SObject> newRecords, List<SObject> oldRecords);
    }

    public interface AfterUpdate {
        Boolean isQualifiedAfterUpdate(Record record);
        void afterUpdate(List<SObject> newRecords, List<SObject> oldRecords);
    }

    public interface BeforeDelete {
        Boolean isQualifiedBeforeDelete(Record record);
        void beforeDelete(List<SObject> oldRecords);
    }

    public interface AfterDelete {
        Boolean isQualifiedAfterDelete(Record record);
        void afterDelete(List<SObject> oldRecords);
    }

    public interface BeforeUndelete {
        Boolean isQualifiedBeforeUndelete(Record record);
        void beforeUndelete(List<SObject> newRecords);
    }

    public interface AfterUndelete {
        Boolean isQualifiedAfterUndelete(Record record);
        void afterUndelete(List<SObject> newRecords);
    }

    public interface Enricher {
        // TODO Allow for custom query to enrich data, because there can be some conditions
        EnrichGroup enrich();
    }

    public interface Record {
        Boolean equals(SObjectField field, Object value);
        Boolean doesNotEqual(SObjectField field, Object value);
        Boolean contains(SObjectField field, Object value);
        Boolean doesNotContain(SObjectField field, Object value);
        Boolean contains(SObjectField field, Iterable<Object> values);
        Boolean doesNotContain(SObjectField field, Iterable<Object> values);
        Boolean startsWith(SObjectField field, Object value);
        Boolean endsWith(SObjectField field, Object value);
        Boolean isChanged(SObjectField field);
        Boolean isNull(SObjectField field);
        Boolean isNotNull(SObjectField field);
        Boolean isEmpty(SObjectField field);
        Boolean isNotEmpty(SObjectField field);
        Boolean isBlank(SObjectField field);
        Boolean isNotBlank(SObjectField field);
        // TODO It does make sense only for booleans
        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);
        // TODO It does make sense only for numbers and dates
        Boolean greaterThan(SObjectField field, Object value);
        Boolean greaterThanOrEqualTo(SObjectField field, Object value);
        Boolean lessThan(SObjectField field, Object value);
        Boolean lessThanOrEqualTo(SObjectField field, Object value);
    }

    public interface EnrichGroup {
        EnrichGroup add(EnrichEntity entity);
    }

    public interface EnrichEntity {
        // OBJECT
        EnrichEntity enrich(SObjectField field); // TODO Validation it has to be lookup field
        EnrichEntity enrich(SObjectField relationshipField, String relationshipName); // TODO Validation it has to be lookup field
        // FiELDS
        EnrichEntity with(SObjectField field); 
        EnrichEntity with(SObjectField field1, SObjectField field2);
        EnrichEntity with(SObjectField field1, SObjectField field2, SObjectField field3);
        EnrichEntity with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        EnrichEntity with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        EnrichEntity with(Iterable<SObjectField> fields);
    }

}

/*
public class MyEnrichment implements TriggerHandler.Enricher {
    public TriggerHandler.EnrichBucket enrich() {
        return TriggerHandler.EnrichGroup
            .add(TriggerHandler.enrichFor(Contact.AccountId).with(Account.Name, Account.Industry));
            .add(TriggerHandler.enrichFor(Contact.AccountId).with(Account.Name, Account.Industry));
    }

    // OR

     public Map<String, List<SObject>> enrich() {
        return new Map<String, List<SObject>>{
            'Account' => new List<SObject>{ Account.Name, Account.Industry },
            'Contact' => new List<SObject>{ Contact.FirstName, Contact.LastName }
        };
    }
}

*/
