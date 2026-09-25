/**
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.4
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
public with sharing class TriggerTypes {
    public static ParentFields ParentFields {
        get {
            return new TriggerParentFields();
        }
    }

    public interface InsertRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);

        void put(SObjectField field, Object value);
    }

    public interface RejectableInsertRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);

        void addError(String error);
        void addError(SObjectField field, String error);
    }

    public interface UpdateRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);

        void put(SObjectField field, Object value);
    }

    public interface RejectableUpdateRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);

        void addError(String error);
        void addError(SObjectField field, String error);
    }

    public interface DeleteRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);
    }

    public interface RejectableDeleteRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);

        void addError(String error);
        void addError(SObjectField field, String error);
    }

    public interface UndeleteRecord {
        Boolean isRecordType(String recordTypeDeveloperName);
        Boolean isNotRecordType(String recordTypeDeveloperName);

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

        TriggerTypes.RelatedRecords getRelated(String providerName);
    }

    public interface InsertRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);

        List<TriggerTypes.InsertRecord> getRecords();

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

        List<TriggerTypes.UpdateRecord> getRecords();

        Integer size();
    }

    public interface DeleteRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);

        List<TriggerTypes.DeleteRecord> getRecords();

        Integer size();
    }

    public interface UndeleteRecords {
        Set<Id> getIds();

        Set<Id> getIdsOf(SObjectField field);
        Set<Id> getIdsOf(String relationshipName, SObjectField field);

        Set<String> getValuesOf(SObjectField field);
        Set<String> getValuesOf(String relationshipName, SObjectField field);

        List<TriggerTypes.UndeleteRecord> getRecords();

        Integer size();
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

    // Implementation

    private static RecordTypesInfo RecordTypesInfo = new RecordTypesInfo();
    private static RecordsAggregator RecordsAggregator = new RecordsAggregator();

    public static List<TriggerRecord> toTriggerRecords(List<SObject> newRecords, List<SObject> oldRecords) {
        List<TriggerRecord> triggerRecords = new List<TriggerRecord>();

        Integer recordCount = (newRecords ?? oldRecords)?.size() ?? 0;

        for (Integer i = 0; i < recordCount; i++) {
            triggerRecords.add(new TriggerRecord(newRecords?.get(i), oldRecords?.get(i)));
        }

        return triggerRecords;
    }

    public class TriggerRecord implements TriggerTypes.InsertRecord, TriggerTypes.RejectableInsertRecord, TriggerTypes.UpdateRecord, TriggerTypes.RejectableUpdateRecord, TriggerTypes.DeleteRecord, TriggerTypes.RejectableDeleteRecord, TriggerTypes.UndeleteRecord {
        private SObject newRecord;
        private SObject oldRecord;

        private Map<String, SObject> newParents = new Map<String, SObject>();
        private Map<String, SObject> oldParents = new Map<String, SObject>();

        private Map<String, RelatedRecords> relatedByProviderName = new Map<String, RelatedRecords>();

        private SObjectType sObjectType;

        public TriggerRecord(SObject newRow, SObject oldRow) {
            this.newRecord = newRow;
            this.oldRecord = oldRow;
            this.sObjectType = (newRow ?? oldRow).getSObjectType();
        }

        public Boolean isRecordType(String recordTypeDeveloperName) {
            if (!RecordTypesInfo.hasRecordTypes(this.sObjectType)) {
                throw new TriggerLibException(this.sObjectType.toString() + ' has no record types, so isRecordType cannot be used on it.');
            }

            return RecordTypesInfo.getId(this.sObjectType, recordTypeDeveloperName) == (this.newRecord ?? this.oldRecord).get('RecordTypeId');
        }

        public Boolean isNotRecordType(String recordTypeDeveloperName) {
            if (!RecordTypesInfo.hasRecordTypes(this.sObjectType)) {
                throw new TriggerLibException(this.sObjectType.toString() + ' has no record types, so isNotRecordType cannot be used on it.');
            }

            return RecordTypesInfo.getId(this.sObjectType, recordTypeDeveloperName) != (this.newRecord ?? this.oldRecord).get('RecordTypeId');
        }

        public Boolean equals(SObjectField field, Object value) {
            return this.getFieldValue(field) == value;
        }

        public Boolean doesNotEqual(SObjectField field, Object value) {
            return !this.equals(field, value);
        }

        public Boolean contains(SObjectField field, String value) {
            return this.isNotNull(field) && this.getFieldValue(field).toString().contains(value);
        }

        public Boolean doesNotContain(SObjectField field, String value) {
            return this.getFieldValue(field) == null || !this.getFieldValue(field).toString().contains(value);
        }

        public Boolean startsWith(SObjectField field, String value) {
            return this.isNotNull(field) && this.getFieldValue(field).toString().startsWith(value);
        }

        public Boolean endsWith(SObjectField field, String value) {
            return this.isNotNull(field) && this.getFieldValue(field).toString().endsWith(value);
        }

        public Boolean isNull(SObjectField field) {
            return this.getFieldValue(field) == null;
        }

        public Boolean isNotNull(SObjectField field) {
            return !this.isNull(field);
        }

        public Boolean isEmpty(SObjectField field) {
            return this.isNull(field) || String.isEmpty(this.getFieldValue(field).toString());
        }

        public Boolean isNotEmpty(SObjectField field) {
            return !this.isEmpty(field);
        }

        public Boolean isBlank(SObjectField field) {
            return this.isNull(field) || String.isBlank(this.getFieldValue(field).toString());
        }

        public Boolean isNotBlank(SObjectField field) {
            return !this.isBlank(field);
        }

        public Boolean isChanged(SObjectField field) {
            return this.getFieldValue(field) != this.getOldFieldValue(field);
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
            return this.getFieldValue(field) == value && this.getOldFieldValue(field) != value;
        }

        public Boolean isChangedFrom(SObjectField field, Object value) {
            return this.getFieldValue(field) != value && this.getOldFieldValue(field) == value;
        }

        public Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue) {
            return this.getFieldValue(field) == toValue && this.getOldFieldValue(field) == fromValue;
        }

        public Boolean isTrue(SObjectField field) {
            return this.getFieldValue(field) == true;
        }

        public Boolean isFalse(SObjectField field) {
            return this.getFieldValue(field) == false;
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
            Object fieldValue = this.getFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) > value;
        }

        public Boolean greaterThan(SObjectField field, Date value) {
            Object fieldValue = this.getFieldValue(field);
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
            Object fieldValue = this.getFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) >= value;
        }

        public Boolean greaterThanOrEqualTo(SObjectField field, Date value) {
            Object fieldValue = this.getFieldValue(field);
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
            Object fieldValue = this.getFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) < value;
        }

        public Boolean lessThan(SObjectField field, Date value) {
            Object fieldValue = this.getFieldValue(field);
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
            Object fieldValue = this.getFieldValue(field);
            return fieldValue != null && ((DateTime) fieldValue) <= value;
        }

        public Boolean lessThanOrEqualTo(SObjectField field, Date value) {
            Object fieldValue = this.getFieldValue(field);
            return fieldValue != null && ((Date) fieldValue) <= value;
        }

        private Boolean isGreaterThan(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue > value;
        }

        private Boolean isGreaterThanOrEqualTo(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue >= value;
        }

        private Boolean isLessThan(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue < value;
        }

        private Boolean isLessThanOrEqualTo(SObjectField field, Decimal value) {
            Decimal fieldValue = this.getFieldValueAsDecimal(field);
            return fieldValue != null && fieldValue <= value;
        }

        private Decimal getFieldValueAsDecimal(SObjectField field) {
            Object value = this.getFieldValue(field);
            return value == null ? null : Decimal.valueOf(value.toString());
        }

        private Object getFieldValue(SObjectField field) {
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
            if (!this.relatedByProviderName.containsKey(providerName)) {
                throw new TriggerLibException('No related records provider named ' + providerName + ' is declared. Return it from the queryRelatedOn method of the handler first.');
            }

            return this.relatedByProviderName.get(providerName);
        }

        public void put(SObjectField field, Object value) {
            this.newRecord.put(field, value);
        }

        public void addError(String error) {
            (this.newRecord ?? this.oldRecord).addError(error);
        }

        public void addError(SObjectField field, String error) {
            (this.newRecord ?? this.oldRecord).addError(field, error);
        }

        // Internal use only

        public SObject getSObject() {
            return this.newRecord ?? this.oldRecord;
        }

        public SObject getParent(String relationshipName) {
            return this.newRecord == null ? this.oldParents.get(relationshipName) : this.newParents.get(relationshipName);
        }

        public Id getNewParentId(SObjectField lookupField) {
            return this.newRecord?.isSet(lookupField) == true ? (Id) this.newRecord.get(lookupField) : null;
        }

        public Id getOldParentId(SObjectField lookupField) {
            return this.oldRecord?.isSet(lookupField) == true ? (Id) this.oldRecord.get(lookupField) : null;
        }

        public void setNewParent(String relationshipName, SObject parent) {
            this.newParents.put(relationshipName, parent);
        }

        public void setOldParent(String relationshipName, SObject parent) {
            this.oldParents.put(relationshipName, parent);
        }

        public void setRelated(Map<String, RelatedRecords> relatedByProviderName) {
            this.relatedByProviderName = relatedByProviderName;
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

        public List<TriggerTypes.InsertRecord> getRecords() {
            return (List<TriggerTypes.InsertRecord>) this.records;
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

        public List<TriggerTypes.UpdateRecord> getRecords() {
            return (List<TriggerTypes.UpdateRecord>) this.records;
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

        public List<TriggerTypes.DeleteRecord> getRecords() {
            return (List<TriggerTypes.DeleteRecord>) this.records;
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

        public List<TriggerTypes.UndeleteRecord> getRecords() {
            return (List<TriggerTypes.UndeleteRecord>) this.records;
        }

        public Integer size() {
            return this.records.size();
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
            return this.idsFrom(this.parentsOf(records, relationshipName), field);
        }

        public Set<Id> oldIdsOf(List<TriggerRecord> records, SObjectField field) {
            return this.idsFrom(this.oldRowsOf(records), field);
        }

        public Set<Id> oldIdsOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.idsFrom(this.oldParentsOf(records, relationshipName), field);
        }

        public Set<String> valuesOf(List<TriggerRecord> records, SObjectField field) {
            return this.valuesFrom(this.rowsOf(records), field);
        }

        public Set<String> valuesOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.valuesFrom(this.parentsOf(records, relationshipName), field);
        }

        public Set<String> oldValuesOf(List<TriggerRecord> records, SObjectField field) {
            return this.valuesFrom(this.oldRowsOf(records), field);
        }

        public Set<String> oldValuesOf(List<TriggerRecord> records, String relationshipName, SObjectField field) {
            return this.valuesFrom(this.oldParentsOf(records, relationshipName), field);
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

        private List<SObject> parentsOf(List<TriggerRecord> records, String relationshipName) {
            List<SObject> parents = new List<SObject>();

            for (TriggerRecord record : records) {
                parents.add(this.walk(record.getParent(relationshipName.substringBefore('.')), relationshipName));
            }

            return parents;
        }

        private List<SObject> oldParentsOf(List<TriggerRecord> records, String relationshipName) {
            List<SObject> parents = new List<SObject>();

            for (TriggerRecord record : records) {
                parents.add(this.walk(record.getOldParent(relationshipName.substringBefore('.')), relationshipName));
            }

            return parents;
        }

        private SObject walk(SObject parent, String relationshipName) {
            List<String> path = relationshipName.split('\\.');

            for (Integer i = 1; i < path.size() && parent != null; i++) {
                parent = parent.getSObject(path[i]);
            }

            return parent;
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

    private class TriggerParentFields implements ParentFields {
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

        public ProvidedRecords(List<SObject> rows) {
            this.records = rows ?? new List<SObject>();
        }

        public void groupUnderKey(String key, SObject row) {
            if (key == null) {
                return;
            }

            if (!this.recordsByKey.containsKey(key)) {
                this.recordsByKey.put(key, new List<SObject>());
            }

            this.recordsByKey.get(key).add(row);
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

    public class TriggerLibException extends Exception {
    }
}
