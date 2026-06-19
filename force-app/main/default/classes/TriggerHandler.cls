public with sharing class TriggerHandler {
    public interface BeforeInsert { 
        Boolean qualifyOnBeforeInsertWhen(SObject record);
        void beforeInsert(SObject record); 
    }
        
    public interface AfterInsert {
        Boolean isQualifiedAfterInsert(SObject record);
        void afterInsert(SObject record);
    }

    public interface BeforeUpdate {
        Boolean isQualifiedBeforeUpdate(SObject record);
        void beforeUpdate(SObject newRecord, SObject oldRecord);
    }

    public interface AfterUpdate {
        Boolean isQualifiedAfterUpdate(SObject record);
        void afterUpdate(SObject newRecord, SObject oldRecord);
    }

    public interface BeforeDelete {
        Boolean isQualifiedBeforeDelete(SObject record);
        void beforeDelete(SObject oldRecord);
    }

    public interface AfterDelete {
        Boolean isQualifiedAfterDelete(SObject record);
        void afterDelete(SObject oldRecord);
    }

    public interface BeforeUndelete {
        Boolean isQualifiedBeforeUndelete(SObject record);
        void beforeUndelete(SObject newRecord);
    }

    public interface AfterUndelete {
        Boolean isQualifiedAfterUndelete(SObject record);
        void afterUndelete(SObject newRecord);
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
        Map<SObjectField, SelectEntity> enrichParentRelationships();
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