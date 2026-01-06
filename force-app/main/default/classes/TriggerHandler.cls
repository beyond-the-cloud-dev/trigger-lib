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

    // TODO Allow for custom query to enrich data, because there can be some conditions
    public interface RelationshipEnrichment {
        Map<SObjectField, SelectEntity> getFieldsToPull(); // TODO: Change method name
    }

    public interface SelectEntity {
        SelectEntity with(SObjectField field); 
        SelectEntity with(SObjectField field1, SObjectField field2);
        SelectEntity with(SObjectField field1, SObjectField field2, SObjectField field3);
        SelectEntity with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        SelectEntity with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        SelectEntity with(Iterable<SObjectField> fields);
        // Relationship fields
        SelectEntity with(String relationshipName, SObjectField field);
        SelectEntity with(String relationshipName, SObjectField field1, SObjectField field2);
        SelectEntity with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3);
        SelectEntity with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        SelectEntity with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        SelectEntity with(String relationshipName, Iterable<SObjectField> fields);
    }
}