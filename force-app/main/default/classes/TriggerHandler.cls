public with sharing class TriggerHandler {
    public interface BeforeInsert { 
        Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record);
        void onBeforeInsert(SObject record); 
    }
        
    public interface AfterInsert {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record);
        void onAfterInsert(SObject record);
    }

    public interface BeforeUpdate {
        Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record);
        void onBeforeUpdate(SObject newRecord, SObject oldRecord);
    }

    public interface AfterUpdate {
        Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record);
        void onAfterUpdate(SObject newRecord, SObject oldRecord);
    }

    public interface BeforeDelete {
        Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.Record record);
        void onBeforeDelete(SObject oldRecord);
    }

    public interface AfterDelete {
        Boolean qualifiesForAfterDeleteWhen(TriggerHandler.Record record);
        void onAfterDelete(SObject oldRecord);
    }

    public interface BeforeUndelete {
        Boolean qualifiesForBeforeUndeleteWhen(TriggerHandler.Record record);
        void onBeforeUndelete(SObject newRecord);
    }

    public interface AfterUndelete {
        Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.Record record);
        void onAfterUndelete(SObject newRecord);
    }

    public interface RelationshipEnrichment {
        Map<SObjectField, FieldSelection> fieldsToEnrich();
    }

    public static FieldSelection FieldSelection {
        get {
            return new SelectionClass(); //TODO rename it
        }
    }

    public interface Record {
        Boolean isRecordTypeEqual(String recordTypeDeveloperName);
        Boolean isRecordTypeNotEqual(String recordTypeDeveloperName);
        
        Boolean equals(SObjectField field, Object value);
        Boolean doesNotEqual(SObjectField field, Object value);

        Boolean contains(SObjectField field, Object value);
        Boolean doesNotContain(SObjectField field, Object value);
        Boolean contains(SObjectField field, Iterable<Object> values);
        Boolean doesNotContain(SObjectField field, Iterable<Object> values);
        Boolean startsWith(SObjectField field, Object value);
        Boolean endsWith(SObjectField field, Object value);

        Boolean isNull(SObjectField field);
        Boolean isNotNull(SObjectField field);
        Boolean isEmpty(SObjectField field);
        Boolean isNotEmpty(SObjectField field);
        Boolean isBlank(SObjectField field);
        Boolean isNotBlank(SObjectField field);

        Boolean isChanged(SObjectField field);
        Boolean isAnyChanged(Iterable<SObjectField> fields);
        Boolean areAllChanged(Iterable<SObjectField> fields);
        Boolean isChangedTo(SObjectField field, Object value);
        Boolean isChangedFrom(SObjectField field, Object value); 
        Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue);
  
        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

        Boolean greaterThan(SObjectField field, Object value);
        Boolean greaterThanOrEqualTo(SObjectField field, Object value);
        Boolean lessThan(SObjectField field, Object value);
        Boolean lessThanOrEqualTo(SObjectField field, Object value);

        SObject getSObject();
    }

    public interface FieldSelection {
        FieldSelection with(SObjectField field); 
        FieldSelection with(SObjectField field1, SObjectField field2);
        FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3);
        FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        FieldSelection with(Iterable<SObjectField> fields);
        // Relationship fields
        FieldSelection with(String relationshipName, SObjectField field);
        FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2);
        FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3);
        FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        FieldSelection with(String relationshipName, Iterable<SObjectField> fields);
    }

    // Implementation 

    public class SelectionClass implements FieldSelection {
        private SOQL query;

        public FieldSelection with(SObjectField field) {
            this.query.with(field);
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2) {
            this.query.with(field1, field2);
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.query.with(field1, field2, field3);
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.query.with(field1, field2, field3, field4);
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.query.with(field1, field2, field3, field4, field5);
            return this;
        }

        public FieldSelection with(Iterable<SObjectField> fields) {
            this.query.with(fields);
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field) {
            this.query.with(relationshipName, field);
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2) {
            this.query.with(relationshipName, field1, field2);
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
            this.query.with(relationshipName, field1, field2, field3);
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.query.with(relationshipName, field1, field2, field3, field4);
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.query.with(relationshipName, field1, field2, field3, field4, field5);
            return this;
        }

        public FieldSelection with(String relationshipName, Iterable<SObjectField> fields) {
            this.query.with(relationshipName, fields);
            return this;
        }
    } 
}