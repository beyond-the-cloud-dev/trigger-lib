public with sharing class TriggerHandler {
    public static FieldSelection FieldSelection {
        get {
            return new SelectionClass(); //TODO rename it
        }
    }

    public interface BeforeInsert {  // Maybe BeforeInsertPopulator?
        Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record);
        void onBeforeInsert(SObject record); 
    }
        
    public interface AfterInsert {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record);
        void onAfterInsert(SObject record);
    }

    public interface BeforeUpdate { // Maybe BeforeUpdatePopulator?
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

    public interface Bypassable {
        Boolean bypassWhen();
    }

    // send email interface
    // validator interface?

    // TODO Maybe additional interfaces
    // set required permissions, bypass permission, etc 

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

        SObject getNewSObject();
        SObject getOldSObject();
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

    public class TriggerRecord implements TriggerHandler.Record {
        private SObject newRecord;
        private SObject oldRecord;

        public TriggerRecord(SObject record) {
            this.newRecord = record;
        }

        public TriggerRecord(SObject newRecord, SObject oldRecord) {
            this.newRecord = newRecord;
            this.oldRecord = oldRecord;
        }

        public Boolean isRecordTypeEqual(String recordTypeDeveloperName) {
            return false;
        }

        public Boolean isRecordTypeNotEqual(String recordTypeDeveloperName) {
            return false;
        }

        public Boolean equals(SObjectField field, Object value) {
            return false;
        }

        public Boolean doesNotEqual(SObjectField field, Object value) {
            return false;
        }

        public Boolean contains(SObjectField field, Object value) {
            return false;
        }

        public Boolean doesNotContain(SObjectField field, Object value) {
            return false;
        }

        public Boolean contains(SObjectField field, Iterable<Object> values) {
            return false;
        }

        public Boolean doesNotContain(SObjectField field, Iterable<Object> values) {
            return false;
        }

        public Boolean startsWith(SObjectField field, Object value) {
            return false;
        }

        public Boolean endsWith(SObjectField field, Object value) {
            return false;
        }

        public Boolean isNull(SObjectField field) {
            return false;
        }

        public Boolean isNotNull(SObjectField field) {
            return false;
        }

        public Boolean isEmpty(SObjectField field) {
            return false;
        }

        public Boolean isNotEmpty(SObjectField field) {
            return false;
        }

        public Boolean isBlank(SObjectField field) {
            return false;
        }

        public Boolean isNotBlank(SObjectField field) {
            return false;
        }

        public Boolean isChanged(SObjectField field) {
            return false;
        }

        public Boolean isAnyChanged(Iterable<SObjectField> fields) {
            return false;
        }

        public Boolean areAllChanged(Iterable<SObjectField> fields) {
            return false;
        }

        public Boolean isChangedTo(SObjectField field, Object value) {
            return false;
        }

        public Boolean isChangedFrom(SObjectField field, Object value) {
            return false;
        }

        public Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue) {
            return false;
        }

        public Boolean isTrue(SObjectField field) {
            return false;
        }

        public Boolean isFalse(SObjectField field) {
            return false;
        }

        public Boolean greaterThan(SObjectField field, Object value) {
            return false;
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Object value) {
            return false;
        }

        public Boolean lessThan(SObjectField field, Object value) {
            return false;
        }

        public Boolean lessThanOrEqualTo(SObjectField field, Object value) {
            return false;
        }

        public SObject getNewSObject() {
            return this.newRecord;
        }

        public SObject getOldSObject() {
            return this.oldRecord;
        }
    }
}