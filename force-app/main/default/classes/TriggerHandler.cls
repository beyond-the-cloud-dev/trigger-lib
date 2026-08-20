public with sharing class TriggerHandler {
    public static FieldSelection FieldSelection {
        get {
            return new SelectionClass(); //TODO rename it
        }
    }

    // Before Context

    public interface BeforeInsert {  // Maybe BeforeInsertPopulator?
        Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record);
        void onBeforeInsert(TriggerHandler.Record record); 
    }
        
    public interface BeforeUpdate { // Maybe BeforeUpdatePopulator?
        Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record);
        void onBeforeUpdate(TriggerHandler.Record record);
    }

    public interface BeforeDelete {
        Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.Record record);
        void onBeforeDelete(TriggerHandler.Record record);
    }

    public interface BeforeUndelete {
        Boolean qualifiesForBeforeUndeleteWhen(TriggerHandler.Record record);
        void onBeforeUndelete(TriggerHandler.Record record);
    }

    // After Context

    public interface AfterInsert {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record);
        void onAfterInsert(TriggerHandler.Record record);
        // void finalizeAfterInsert(); TODO? 
    }

    public interface AfterUpdate {
        Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record);
        void onAfterUpdate(TriggerHandler.Record record);
        // void finalizeAfterInsert(); TODO?
    }

    public interface AfterDelete {
        Boolean qualifiesForAfterDeleteWhen(TriggerHandler.Record record);
        void onAfterDelete(TriggerHandler.Record record);
        // void finalizeAfterInsert(); TODO?
    }

    public interface AfterUndelete {
        Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.Record record);
        void onAfterUndelete(TriggerHandler.Record record);
        // void finalizeAfterInsert(); TODO?
    }

    // Additional

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
        // Record Type
        Boolean isRecordTypeEqual(String recordTypeDeveloperName);
        Boolean isRecordTypeNotEqual(String recordTypeDeveloperName);
        
        Boolean equals(SObjectField field, Object value);
        Boolean doesNotEqual(SObjectField field, Object value);

        Boolean contains(SObjectField field, String value);
        Boolean doesNotContain(SObjectField field, String value);
        Boolean startsWith(SObjectField field, String value);
        Boolean endsWith(SObjectField field, String value);

        Boolean isNull(SObjectField field);
        Boolean isNotNull(SObjectField field);

        Boolean isEmpty(SObjectField field);
        Boolean isNotEmpty(SObjectField field);

        Boolean isBlank(SObjectField field);
        Boolean isNotBlank(SObjectField field);

        // Change Methods
        Boolean isChanged(SObjectField field);

        Boolean isAnyChanged(SObjectField field1, SObjectField field2);
        Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3);
        Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        Boolean isAnyChanged(Iterable<SObjectField> fields);

        Boolean areAllChanged(SObjectField field1, SObjectField field2);
        Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3);
        Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        Boolean areAllChanged(Iterable<SObjectField> fields);

        Boolean isChangedTo(SObjectField field, Object expectedValue);
        Boolean isChangedFrom(SObjectField field, Object priorValue); 
        Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue);

        // Checkboxes
        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

        // Numbers and dates
        Boolean greaterThan(SObjectField field, Integer value);
        Boolean greaterThan(SObjectField field, DateTime value);
        Boolean greaterThan(SObjectField field, Date value);
        Boolean greaterThan(SObjectField field, Double value);
        Boolean greaterThan(SObjectField field, Decimal value);
        Boolean greaterThan(SObjectField field, Long value);

        Boolean greaterThanOrEqualTo(SObjectField field, Integer value);
        Boolean greaterThanOrEqualTo(SObjectField field, DateTime value);
        Boolean greaterThanOrEqualTo(SObjectField field, Date value);
        Boolean greaterThanOrEqualTo(SObjectField field, Double value);
        Boolean greaterThanOrEqualTo(SObjectField field, Decimal value);
        Boolean greaterThanOrEqualTo(SObjectField field, Long value);

        Boolean lessThan(SObjectField field, Integer value);
        Boolean lessThan(SObjectField field, DateTime value);
        Boolean lessThan(SObjectField field, Date value);
        Boolean lessThan(SObjectField field, Double value);
        Boolean lessThan(SObjectField field, Decimal value);
        Boolean lessThan(SObjectField field, Long value);

        Boolean lessThanOrEqualTo(SObjectField field, Integer value);
        Boolean lessThanOrEqualTo(SObjectField field, DateTime value);
        Boolean lessThanOrEqualTo(SObjectField field, Date value);
        Boolean lessThanOrEqualTo(SObjectField field, Double value);
        Boolean lessThanOrEqualTo(SObjectField field, Decimal value);
        Boolean lessThanOrEqualTo(SObjectField field, Long value);

        // Additional
        Id getId();
        
        SObject getNewSObject();
        SObject getOldSObject();

        // Parent Records Access
        SObject getNewRelated(String relationshipName);
        SObject getOldRelated(String relationshipName);

        // Populate
        Record put(SObjectField field, Object value);
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

        // for private use only
        List<String> getFields();
    }

    // Implementation 

    private static RecordTypesInfo RecordTypesInfo = new RecordTypesInfo();

    public class SelectionClass implements FieldSelection {
        private List<String> fields = new List<String>();

        public FieldSelection with(SObjectField field) {
            this.fields.add(field.toString());
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            this.fields.add(field3.toString());
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            this.fields.add(field3.toString());
            this.fields.add(field4.toString());
            return this;
        }

        public FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            this.fields.add(field3.toString());
            this.fields.add(field4.toString());
            this.fields.add(field5.toString());
            return this;
        }

        public FieldSelection with(Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                this.fields.add(field.toString());
            }
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field) {
            this.fields.add(relationshipName + '.' + field.toString());
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            this.fields.add(relationshipName + '.' + field3.toString());
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            this.fields.add(relationshipName + '.' + field3.toString());
            this.fields.add(relationshipName + '.' + field4.toString());
            return this;
        }

        public FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            this.fields.add(relationshipName + '.' + field3.toString());
            this.fields.add(relationshipName + '.' + field4.toString());
            this.fields.add(relationshipName + '.' + field5.toString());
            return this;
        }

        public FieldSelection with(String relationshipName, Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                this.fields.add(relationshipName + '.' + field.toString());
            }
            return this;
        }

        public List<String> getFields() {
            return this.fields;
        }
    } 

    public class TriggerRecord implements TriggerHandler.Record {
        private SObject newRecord;
        private SObject oldRecord;

        private Map<String, SObject> newRelatedRecords = new Map<String, SObject>();
        private Map<String, SObject> oldRelatedRecords = new Map<String, SObject>();

        private SObjectType sObjectType;

        public TriggerRecord(SObject record) {
            this.newRecord = record;
            this.sObjectType = record.getSObjectType();
        }

        public TriggerRecord(SObject newRecord, SObject oldRecord) {
            this.newRecord = newRecord;
            this.oldRecord = oldRecord;
            // Delete contexts have no new record, so the type comes from the deleted row.
            this.sObjectType = (newRecord ?? oldRecord).getSObjectType();
        }

        public Boolean isRecordTypeEqual(String recordTypeDeveloperName) {
            return RecordTypesInfo.getId(this.sObjectType, recordTypeDeveloperName) == (this.newRecord ?? this.oldRecord).get('RecordTypeId');
        }

        public Boolean isRecordTypeNotEqual(String recordTypeDeveloperName) {
            return RecordTypesInfo.getId(this.sObjectType, recordTypeDeveloperName) != (this.newRecord ?? this.oldRecord).get('RecordTypeId');
        }

        public Boolean equals(SObjectField field, Object value) {
            return this.getNewFieldValue(field) == value;
        }

        public Boolean doesNotEqual(SObjectField field, Object value) {
            return this.getNewFieldValue(field) != value;
        }

        public Boolean contains(SObjectField field, String value) {
            return this.isNotNull(field) && this.getNewFieldValue(field).toString().contains(value);
        }

        public Boolean doesNotContain(SObjectField field, String value) {
            return this.getNewFieldValue(field) == null || !this.getNewFieldValue(field).toString().contains(value);
        }

        public Boolean startsWith(SObjectField field, String value) {
            return this.isNotNull(field) && this.getNewFieldValue(field).toString().startsWith(value);
        }

        public Boolean endsWith(SObjectField field, String value) {
            return this.isNotNull(field) && this.getNewFieldValue(field).toString().endsWith(value);
        }

        public Boolean isNull(SObjectField field) {
            return this.getNewFieldValue(field) == null;
        }

        public Boolean isNotNull(SObjectField field) {
            return this.getNewFieldValue(field) != null;
        }

        public Boolean isEmpty(SObjectField field) {
            return this.isNull(field) || String.isEmpty(this.getNewFieldValue(field).toString());
        }

        public Boolean isNotEmpty(SObjectField field) {
            return !this.isEmpty(field);
        }

        public Boolean isBlank(SObjectField field) {
            return this.isNull(field) || String.isBlank(this.getNewFieldValue(field).toString());
        }

        public Boolean isNotBlank(SObjectField field) {
            return !this.isBlank(field);
        }

        public Boolean isChanged(SObjectField field) {
            return this.getNewFieldValue(field) != this.getOldFieldValue(field);
        }

        public Boolean isAnyChanged(SObjectField field1, SObjectField field2) {
            return this.isAnyChanged(new List<SObjectField>{ field1, field2 });
        }

        public Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3) {
            return this.isAnyChanged(new List<SObjectField>{ field1, field2, field3 });
        }

        public Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            return this.isAnyChanged(new List<SObjectField>{ field1, field2, field3, field4 });
        }

        public Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            return this.isAnyChanged(new List<SObjectField>{ field1, field2, field3, field4, field5 });
        }

        public Boolean isAnyChanged(Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                if (this.isChanged(field)) {
                    return true;
                }
            }

            return false;
        }

        public Boolean areAllChanged(SObjectField field1, SObjectField field2) {
            return this.areAllChanged(new List<SObjectField>{ field1, field2 });
        }

        public Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3) {
            return this.areAllChanged(new List<SObjectField>{ field1, field2, field3 });
        }

        public Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            return this.areAllChanged(new List<SObjectField>{ field1, field2, field3, field4 });
        }

        public Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            return this.areAllChanged(new List<SObjectField>{ field1, field2, field3, field4, field5 });
        }

        public Boolean areAllChanged(Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                if (!this.isChanged(field)) {
                    return false;
                }
            }

            return true;
        }

        public Boolean isChangedTo(SObjectField field, Object value) {
            return this.getNewFieldValue(field) == value && this.getOldFieldValue(field) != value;
        }

        public Boolean isChangedFrom(SObjectField field, Object value) {
            return this.getNewFieldValue(field) != value && this.getOldFieldValue(field) == value;
        }

        public Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue) {
            return this.getNewFieldValue(field) == toValue && this.getOldFieldValue(field) == fromValue;
        }

        public Boolean isTrue(SObjectField field) {
            return this.getNewFieldValue(field) == true;
        }

        public Boolean isFalse(SObjectField field) {
            return this.getNewFieldValue(field) == false;
        }

        public Boolean greaterThan(SObjectField field, Integer value) {
            return this.isGreaterThan(field, value);
        }

        public Boolean greaterThan(SObjectField field, Long value) {
            return this.isGreaterThan(field, value);
        }

        public Boolean greaterThan(SObjectField field, Double value) {
            return this.isGreaterThan(field, value);
        }

        public Boolean greaterThan(SObjectField field, Decimal value) {
            return this.isGreaterThan(field, value);
        }

        public Boolean greaterThan(SObjectField field, DateTime value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) > value;
        }

        public Boolean greaterThan(SObjectField field, Date value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((Date) fieldValue) > value;
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Integer value) {
            return this.isGreaterThanOrEqualTo(field, value);
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Long value) {
            return this.isGreaterThanOrEqualTo(field, value);
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Double value) {
            return this.isGreaterThanOrEqualTo(field, value);
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Decimal value) {
            return this.isGreaterThanOrEqualTo(field, value);
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, DateTime value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) >= value;
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Date value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((Date) fieldValue) >= value;
        }

        public Boolean lessThan(SObjectField field, Integer value) {
            return this.isLessThan(field, value);
        }

        public Boolean lessThan(SObjectField field, Double value) {
            return this.isLessThan(field, value);
        }

        public Boolean lessThan(SObjectField field, Decimal value) {
            return this.isLessThan(field, value);
        }

        public Boolean lessThan(SObjectField field, DateTime value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) < value;
        }

        public Boolean lessThan(SObjectField field, Date value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((Date) fieldValue) < value;
        }

        public Boolean lessThanOrEqualTo(SObjectField field, Integer value) {
            return this.isLessThanOrEqualTo(field, value);
        }

        public Boolean lessThanOrEqualTo(SObjectField field, Double value) {
            return this.isLessThanOrEqualTo(field, value);
        }

        public Boolean lessThanOrEqualTo(SObjectField field, Decimal value) {
            return this.isLessThanOrEqualTo(field, value);
        }

        public Boolean lessThanOrEqualTo(SObjectField field, DateTime value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) <= value;
        }

        public Boolean lessThanOrEqualTo(SObjectField field, Date value) {
            Object fieldValue = this.getNewFieldValue(field);
            return fieldValue != null && ((Date) fieldValue) <= value;
        }

        private Boolean isGreaterThan(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getNewFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue > value;
        }

        private Boolean isGreaterThanOrEqualTo(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getNewFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue >= value;
        }

        private Boolean isLessThan(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getNewFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue < value;
        }

        private Boolean isLessThanOrEqualTo(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getNewFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue <= value;
        }

        private Decimal getNewFieldValueAsDecimal(SObjectField field) {
            Object value = this.getNewFieldValue(field);
            return this.isNull(field) ? null : Decimal.valueOf(String.valueOf(value));
        }

        private Object getNewFieldValue(SObjectField field) {
            return (this.newRecord ?? this.oldRecord).get(field);
        }

        private Object getOldFieldValue(SObjectField field) {
            return this.oldRecord.get(field);
        }

        public Id getId() {
            return (this.newRecord ?? this.oldRecord).Id;
        }

        public SObject getNewSObject() {
            return this.newRecord;
        }

        public SObject getOldSObject() {
            return this.oldRecord;
        }

        public SObject getNewRelated(String relationshipName) {
            return this.newRelatedRecords.get(relationshipName);
        }

        public SObject getOldRelated(String relationshipName) {
            return this.oldRelatedRecords.get(relationshipName);
        }

        public Record put(SObjectField field, Object value) {
            this.newRecord.put(field, value);
            return this;
        }

        // Internal use only

        public void enrichNew(String relationshipName, SObject relatedRecord) {
            this.newRelatedRecords.put(relationshipName, relatedRecord);
        }

        public void enrichOld(String relationshipName, SObject relatedRecord) {
            this.oldRelatedRecords.put(relationshipName, relatedRecord);
        }
    }

    private without sharing class RecordTypesInfo {
        private final Map<SObjectType, Map<String, Schema.RecordTypeInfo>> OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME = new Map<SObjectType, Map<String, Schema.RecordTypeInfo>>();

        public Id getId(SObjectType objectType, String recordTypeDeveloperName) {
            return byDeveloperName(objectType, recordTypeDeveloperName)?.getRecordTypeId();
        }

        public Schema.RecordTypeInfo byDeveloperName(SObjectType objectType, String recordTypeDeveloperName) {
            if (
                !OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.containsKey(objectType) ||
                !OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.get(objectType).containsKey(recordTypeDeveloperName)
            ) {
                load(objectType);
            }

            return OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.get(objectType).get(recordTypeDeveloperName);
        }

        private void load(SObjectType objectType) {
            Schema.DescribeSObjectResult describe = objectType.getDescribe(SObjectDescribeOptions.DEFERRED);

            OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.put(objectType, describe.getRecordTypeInfosByDeveloperName());
        }
    }
}