/**
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.1
 *
 * PMD False Positives:
 * - ExcessivePublicCount: It is a library class and exposes all necessary methods to evaluate a trigger record
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE class
 * - ExcessiveParameterList: Fixed arity overloads spare the caller from building a list for the common cases
 * - PropertyNamingConventions: It was intentional to make the lib more fluent and readable
 * - FieldNamingConventions: It was intentional to make the lib more fluent and readable
 * - FieldDeclarationsShouldBeAtStart: Developer who uses lib should see what's important at start
 **/
@SuppressWarnings(
    'PMD.ExcessivePublicCount,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessiveParameterList,PMD.PropertyNamingConventions,PMD.FieldNamingConventions,PMD.FieldDeclarationsShouldBeAtStart'
)
public with sharing class TriggerHandler {
    public static ParentFields ParentFields {
        get {
            return new LookupSelector();
        }
    }

    public interface InsertRecord {
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

        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

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

        Id getId();

        SObject getNewSObject();

        SObject getNewParent(String relationshipName);

        TriggerHandler.RelatedRecords getRelated(String providerName);

        void put(SObjectField field, Object value);
    }

    public interface RejectableInsertRecord {
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

        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

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

        Id getId();

        SObject getNewSObject();

        SObject getNewParent(String relationshipName);

        TriggerHandler.RelatedRecords getRelated(String providerName);

        void addError(String error);
        void addError(SObjectField field, String error);
    }

    public interface UpdateRecord {
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

        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

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

        Id getId();

        SObject getNewSObject();
        SObject getOldSObject();

        SObject getNewParent(String relationshipName);
        SObject getOldParent(String relationshipName);

        TriggerHandler.RelatedRecords getRelated(String providerName);

        void put(SObjectField field, Object value);
    }

    public interface RejectableUpdateRecord {
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

        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

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

        Id getId();

        SObject getNewSObject();
        SObject getOldSObject();

        SObject getNewParent(String relationshipName);
        SObject getOldParent(String relationshipName);

        TriggerHandler.RelatedRecords getRelated(String providerName);

        void addError(String error);
        void addError(SObjectField field, String error);
    }

    public interface DeleteRecord {
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

        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

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

        Id getId();

        SObject getOldSObject();

        SObject getOldParent(String relationshipName);

        TriggerHandler.RelatedRecords getRelated(String providerName);
    }

    public interface UndeleteRecord {
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

        Boolean isTrue(SObjectField field);
        Boolean isFalse(SObjectField field);

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

        Id getId();

        SObject getNewSObject();

        SObject getNewParent(String relationshipName);

        TriggerHandler.RelatedRecords getRelated(String providerName);
    }

    public interface ParentFields {
        ParentFields with(SObjectField field);
        ParentFields with(SObjectField field1, SObjectField field2);
        ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3);
        ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        ParentFields with(Iterable<SObjectField> fields);
        // Relationship fields
        ParentFields with(String relationshipName, SObjectField field);
        ParentFields with(String relationshipName, SObjectField field1, SObjectField field2);
        ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3);
        ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4);
        ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5);
        ParentFields with(String relationshipName, Iterable<SObjectField> fields);

        // for private use only
        List<String> getFields();
    }

    public interface RelatedRecords {
        SObject getFirstWhereKeyEquals(Object key);

        List<SObject> getAllWhereKeyEquals(Object key);
        List<SObject> getRecords();

        Boolean isEmpty();
    }

    public interface UnitOfWork {
        UnitOfWork toInsert(SObject record);
        UnitOfWork toInsert(DML.Record record);

        UnitOfWork toUpdate(SObject record);
        UnitOfWork toUpdate(DML.Record record);

        UnitOfWork toUpsert(SObject record, SObjectField externalIdField);

        UnitOfWork toDelete(SObject record);

        UnitOfWork toPublish(SObject event);
    }

    public interface InsertRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);

        List<TriggerHandler.InsertRecord> getRecords();

        Integer size();
    }

    public interface UpdateRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);
        Set<Id> getOldIdsOf(SObjectField field);
        Set<Id> getOldIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);
        Set<String> getOldValuesOf(SObjectField field);
        Set<String> getOldValuesOf(String relationshipName, SObjectField field);

        List<TriggerHandler.UpdateRecord> getRecords();

        Integer size();
    }

    public interface DeleteRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);

        List<TriggerHandler.DeleteRecord> getRecords();

        Integer size();
    }

    public interface UndeleteRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);

        List<TriggerHandler.UndeleteRecord> getRecords();

        Integer size();
    }

    // Implementation

    @TestVisible
    private static RandomIdGenerator IdGenerator = new RandomIdGenerator();
    private static RecordTypesInfo RecordTypesInfo = new RecordTypesInfo();
    private static RecordsAggregator RecordsAggregator = new RecordsAggregator();

    public static List<TriggerRecord> getTriggerRecordsFrom(List<SObject> newRecords, List<SObject> oldRecords) {
        List<TriggerRecord> triggerRecords = new List<TriggerRecord>();

        Integer recordCount = (newRecords ?? oldRecords)?.size() ?? 0;

        for (Integer i = 0; i < recordCount; i++) {
            triggerRecords.add(new TriggerRecord(newRecords?.get(i), oldRecords?.get(i)));
        }

        return triggerRecords;
    }

    public class LookupSelector implements ParentFields {
        private List<String> fields = new List<String>();

        public ParentFields with(SObjectField field) {
            this.fields.add(field.toString());
            return this;
        }

        public ParentFields with(SObjectField field1, SObjectField field2) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            return this;
        }

        public ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            this.fields.add(field3.toString());
            return this;
        }

        public ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            this.fields.add(field3.toString());
            this.fields.add(field4.toString());
            return this;
        }

        public ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.fields.add(field1.toString());
            this.fields.add(field2.toString());
            this.fields.add(field3.toString());
            this.fields.add(field4.toString());
            this.fields.add(field5.toString());
            return this;
        }

        public ParentFields with(Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                this.fields.add(field.toString());
            }
            return this;
        }

        public ParentFields with(String relationshipName, SObjectField field) {
            this.fields.add(relationshipName + '.' + field.toString());
            return this;
        }

        public ParentFields with(String relationshipName, SObjectField field1, SObjectField field2) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            return this;
        }

        public ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            this.fields.add(relationshipName + '.' + field3.toString());
            return this;
        }

        public ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            this.fields.add(relationshipName + '.' + field3.toString());
            this.fields.add(relationshipName + '.' + field4.toString());
            return this;
        }

        public ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5) {
            this.fields.add(relationshipName + '.' + field1.toString());
            this.fields.add(relationshipName + '.' + field2.toString());
            this.fields.add(relationshipName + '.' + field3.toString());
            this.fields.add(relationshipName + '.' + field4.toString());
            this.fields.add(relationshipName + '.' + field5.toString());
            return this;
        }

        public ParentFields with(String relationshipName, Iterable<SObjectField> fields) {
            for (SObjectField field : fields) {
                this.fields.add(relationshipName + '.' + field.toString());
            }
            return this;
        }

        public List<String> getFields() {
            return this.fields;
        }
    }

    public class ProvidedRecords implements RelatedRecords {
        private List<SObject> records = new List<SObject>();
        private Map<String, List<SObject>> recordsByKey = new Map<String, List<SObject>>();

        public ProvidedRecords(List<SObject> records) {
            this.records = records ?? new List<SObject>();
        }

        public void groupUnderKey(String key, SObject record) {
            if (key == null) {
                return;
            }

            if (!this.recordsByKey.containsKey(key)) {
                this.recordsByKey.put(key, new List<SObject>());
            }

            this.recordsByKey.get(key).add(record);
        }

        public SObject getFirstWhereKeyEquals(Object key) {
            List<SObject> found = this.getAllWhereKeyEquals(key);
            return found.isEmpty() ? null : found[0];
        }

        public List<SObject> getAllWhereKeyEquals(Object key) {
            return this.recordsByKey.get(String.valueOf(key)) ?? new List<SObject>();
        }

        public List<SObject> getRecords() {
            return this.records;
        }

        public Boolean isEmpty() {
            return this.records.isEmpty();
        }
    }

    public class InsertTriggerRecords implements InsertRecords {
        private List<TriggerRecord> records;

        public InsertTriggerRecords(List<TriggerRecord> records) {
            this.records = records;
        }

        public Set<Id> getIds() {
            return RecordsAggregator.ids(this.records);
        }

        public Set<Id> getIdsOf(SObjectField field) {
            return RecordsAggregator.idsOf(this.records, field);
        }

        public Set<Id> getIdsOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.idsOf(this.records, relationshipName, field);
        }

        public Set<String> getValuesOf(SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, field);
        }

        public Set<String> getValuesOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, relationshipName, field);
        }

        public List<TriggerHandler.InsertRecord> getRecords() {
            return (List<TriggerHandler.InsertRecord>) this.records;
        }

        public Integer size() {
            return this.records.size();
        }
    }

    public class UpdateTriggerRecords implements UpdateRecords {
        private List<TriggerRecord> records;

        public UpdateTriggerRecords(List<TriggerRecord> records) {
            this.records = records;
        }

        public Set<Id> getIds() {
            return RecordsAggregator.ids(this.records);
        }

        public Set<Id> getIdsOf(SObjectField field) {
            return RecordsAggregator.idsOf(this.records, field);
        }

        public Set<Id> getIdsOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.idsOf(this.records, relationshipName, field);
        }

        public Set<Id> getOldIdsOf(SObjectField field) {
            return RecordsAggregator.oldIdsOf(this.records, field);
        }

        public Set<Id> getOldIdsOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.oldIdsOf(this.records, relationshipName, field);
        }

        public Set<String> getValuesOf(SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, field);
        }

        public Set<String> getValuesOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, relationshipName, field);
        }

        public Set<String> getOldValuesOf(SObjectField field) {
            return RecordsAggregator.oldValuesOf(this.records, field);
        }

        public Set<String> getOldValuesOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.oldValuesOf(this.records, relationshipName, field);
        }

        public List<TriggerHandler.UpdateRecord> getRecords() {
            return (List<TriggerHandler.UpdateRecord>) this.records;
        }

        public Integer size() {
            return this.records.size();
        }
    }

    public class DeleteTriggerRecords implements DeleteRecords {
        private List<TriggerRecord> records;

        public DeleteTriggerRecords(List<TriggerRecord> records) {
            this.records = records;
        }

        public Set<Id> getIds() {
            return RecordsAggregator.ids(this.records);
        }

        public Set<Id> getIdsOf(SObjectField field) {
            return RecordsAggregator.idsOf(this.records, field);
        }

        public Set<Id> getIdsOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.idsOf(this.records, relationshipName, field);
        }

        public Set<String> getValuesOf(SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, field);
        }

        public Set<String> getValuesOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, relationshipName, field);
        }

        public List<TriggerHandler.DeleteRecord> getRecords() {
            return (List<TriggerHandler.DeleteRecord>) this.records;
        }

        public Integer size() {
            return this.records.size();
        }
    }

    public class UndeleteTriggerRecords implements UndeleteRecords {
        private List<TriggerRecord> records;

        public UndeleteTriggerRecords(List<TriggerRecord> records) {
            this.records = records;
        }

        public Set<Id> getIds() {
            return RecordsAggregator.ids(this.records);
        }

        public Set<Id> getIdsOf(SObjectField field) {
            return RecordsAggregator.idsOf(this.records, field);
        }

        public Set<Id> getIdsOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.idsOf(this.records, relationshipName, field);
        }

        public Set<String> getValuesOf(SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, field);
        }

        public Set<String> getValuesOf(String relationshipName, SObjectField field) {
            return RecordsAggregator.valuesOf(this.records, relationshipName, field);
        }

        public List<TriggerHandler.UndeleteRecord> getRecords() {
            return (List<TriggerHandler.UndeleteRecord>) this.records;
        }

        public Integer size() {
            return this.records.size();
        }
    }

    public class TriggerRecord implements TriggerHandler.InsertRecord, TriggerHandler.RejectableInsertRecord, TriggerHandler.UpdateRecord, TriggerHandler.RejectableUpdateRecord, TriggerHandler.DeleteRecord, TriggerHandler.UndeleteRecord {
        private SObject newRecord;
        private SObject oldRecord;

        private Map<String, SObject> newParents = new Map<String, SObject>();
        private Map<String, SObject> oldParents = new Map<String, SObject>();

        private Map<String, RelatedRecords> providedRecords = new Map<String, RelatedRecords>();

        private SObjectType sObjectType;

        public TriggerRecord(SObject newRecord, SObject oldRecord) {
            this.newRecord = newRecord;
            this.oldRecord = oldRecord;
            this.sObjectType = (newRecord ?? oldRecord).getSObjectType();
        }

        public Boolean isRecordTypeEqual(String recordTypeDeveloperName) {
            if (!RecordTypesInfo.hasRecordTypes(this.sObjectType)) {
                throw new TriggerHandlerException(this.sObjectType.toString() + ' has no record types, so isRecordTypeEqual cannot be used on it.');
            }

            return RecordTypesInfo.getId(this.sObjectType, recordTypeDeveloperName) == (this.newRecord ?? this.oldRecord).get('RecordTypeId');
        }

        public Boolean isRecordTypeNotEqual(String recordTypeDeveloperName) {
            if (!RecordTypesInfo.hasRecordTypes(this.sObjectType)) {
                throw new TriggerHandlerException(this.sObjectType.toString() + ' has no record types, so isRecordTypeNotEqual cannot be used on it.');
            }

            return RecordTypesInfo.getId(this.sObjectType, recordTypeDeveloperName) != (this.newRecord ?? this.oldRecord).get('RecordTypeId');
        }

        public Boolean equals(SObjectField field, Object value) {
            return this.getNewFieldValue(field) == value;
        }

        public Boolean doesNotEqual(SObjectField field, Object value) {
            return !this.equals(field, value);
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
            return !this.isNull(field);
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

        public Boolean lessThan(SObjectField field, Long value) {
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

        public Boolean lessThanOrEqualTo(SObjectField field, Long value) {
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
            return value == null ? null : Decimal.valueOf(value.toString());
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

        public SObject getNewParent(String relationshipName) {
            return this.newParents.get(relationshipName);
        }

        public SObject getOldParent(String relationshipName) {
            return this.oldParents.get(relationshipName);
        }

        public RelatedRecords getRelated(String providerName) {
            if (!this.providedRecords.containsKey(providerName)) {
                throw new TriggerHandlerException(
                    'No related records provider is registered under ' + providerName + '. Return it from the RelatedQuery method of the context first.'
                );
            }

            return this.providedRecords.get(providerName);
        }

        public void put(SObjectField field, Object value) {
            this.newRecord.put(field, value);
        }

        public void addError(String error) {
            this.newRecord.addError(error);
        }

        public void addError(SObjectField field, String error) {
            this.newRecord.addError(field, error);
        }

        // Internal use only

        public SObject getSObject() {
            return this.newRecord ?? this.oldRecord;
        }

        public SObject getParent(String relationshipName) {
            return this.newRecord == null ? this.oldParents.get(relationshipName) : this.newParents.get(relationshipName);
        }

        public void enrichNew(String relationshipName, SObject relatedRecord) {
            this.newParents.put(relationshipName, relatedRecord);
        }

        public Id getNewParentId(SObjectField parentField) {
            return this.newRecord?.isSet(parentField) == true ? (Id) this.newRecord.get(parentField) : null;
        }

        public Id getOldParentId(SObjectField parentField) {
            return this.oldRecord?.isSet(parentField) == true ? (Id) this.oldRecord.get(parentField) : null;
        }

        public void enrichOld(String relationshipName, SObject relatedRecord) {
            this.oldParents.put(relationshipName, relatedRecord);
        }

        public void setProvidedRecords(Map<String, RelatedRecords> providedRecords) {
            this.providedRecords = providedRecords;
        }
    }

    private class RecordsAggregator {
        public Set<Id> ids(List<TriggerRecord> records) {
            Set<Id> ids = new Set<Id>();

            for (TriggerRecord record : records) {
                if (record.getId() != null) {
                    ids.add(record.getId());
                }
            }

            return ids;
        }

        public Set<Id> idsOf(List<TriggerRecord> records, SObjectField field) {
            return this.idsFrom(this.rowsOf(records), field);
        }

        public Set<Id> idsOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.idsFrom(this.relatedOf(records, relationshipName), field);
        }

        public Set<Id> oldIdsOf(List<TriggerRecord> records, SObjectField field) {
            return this.idsFrom(this.oldRowsOf(records), field);
        }

        public Set<Id> oldIdsOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.idsFrom(this.oldRelatedOf(records, relationshipName), field);
        }

        public Set<String> valuesOf(List<TriggerRecord> records, SObjectField field) {
            return this.valuesFrom(this.rowsOf(records), field);
        }

        public Set<String> valuesOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.valuesFrom(this.relatedOf(records, relationshipName), field);
        }

        public Set<String> oldValuesOf(List<TriggerRecord> records, SObjectField field) {
            return this.valuesFrom(this.oldRowsOf(records), field);
        }

        public Set<String> oldValuesOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.valuesFrom(this.oldRelatedOf(records, relationshipName), field);
        }

        private List<SObject> rowsOf(List<TriggerRecord> records) {
            List<SObject> rows = new List<SObject>();

            for (TriggerRecord record : records) {
                rows.add(record.getSObject());
            }

            return rows;
        }

        private List<SObject> oldRowsOf(List<TriggerRecord> records) {
            List<SObject> rows = new List<SObject>();

            for (TriggerRecord record : records) {
                rows.add(record.getOldSObject());
            }

            return rows;
        }

        private List<SObject> relatedOf(List<TriggerRecord> records, String relationshipName) {
            List<SObject> related = new List<SObject>();

            for (TriggerRecord record : records) {
                related.add(this.walk(record.getParent(relationshipName.substringBefore('.')), relationshipName));
            }

            return related;
        }

        private List<SObject> oldRelatedOf(List<TriggerRecord> records, String relationshipName) {
            List<SObject> related = new List<SObject>();

            for (TriggerRecord record : records) {
                related.add(this.walk(record.getOldParent(relationshipName.substringBefore('.')), relationshipName));
            }

            return related;
        }

        private SObject walk(SObject related, String relationshipName) {
            List<String> path = relationshipName.split('\\.');

            for (Integer i = 1; i < path.size() && related != null; i++) {
                related = related.getSObject(path[i]);
            }

            return related;
        }

        private Set<Id> idsFrom(List<SObject> sources, SObjectField field) {
            Set<Id> ids = new Set<Id>();

            for (SObject source : sources) {
                Object value = source?.get(field);

                if (value != null) {
                    ids.add((Id) value);
                }
            }

            return ids;
        }

        private Set<String> valuesFrom(List<SObject> sources, SObjectField field) {
            Set<String> values = new Set<String>();

            for (SObject source : sources) {
                Object value = source?.get(field);

                if (value != null) {
                    values.add(String.valueOf(value));
                }
            }

            return values;
        }
    }

    private without sharing class RecordTypesInfo {
        private final Map<SObjectType, Map<String, Schema.RecordTypeInfo>> OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME = new Map<SObjectType, Map<String, Schema.RecordTypeInfo>>();

        public Id getId(SObjectType objectType, String recordTypeDeveloperName) {
            return this.byDeveloperName(objectType, recordTypeDeveloperName)?.getRecordTypeId();
        }

        public Boolean hasRecordTypes(SObjectType objectType) {
            if (!this.OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.containsKey(objectType)) {
                this.load(objectType);
            }

            return this.OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.get(objectType).size() > 1;
        }

        public Schema.RecordTypeInfo byDeveloperName(SObjectType objectType, String recordTypeDeveloperName) {
            if (!this.OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.containsKey(objectType)) {
                this.load(objectType);
            }

            return this.OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.get(objectType).get(recordTypeDeveloperName);
        }

        private void load(SObjectType objectType) {
            Schema.DescribeSObjectResult describe = objectType.getDescribe(SObjectDescribeOptions.DEFERRED);

            this.OBJECT_TYPE_TO_RECORD_TYPE_BY_DEVELOPER_NAME.put(objectType, describe.getRecordTypeInfosByDeveloperName());
        }
    }

    public class RandomIdGenerator {
        private final String RANDOM_STRING_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';

        public Id get(SObjectType objectType) {
            return this.get(objectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix());
        }

        public Id get(String prefix) {
            String randomPart = '';

            while (randomPart.length() < 8) {
                Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), this.RANDOM_STRING_CHARACTERS.length());
                randomPart += this.RANDOM_STRING_CHARACTERS.substring(idx, idx + 1);
            }

            return Id.valueOf(prefix + '0000' + randomPart);
        }
    }

    public class TriggerHandlerException extends Exception {
    }
}
