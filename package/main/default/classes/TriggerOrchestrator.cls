/**
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.4
 *
 * PMD False Positives:
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE class
 * - NcssMethodCount: Parent enrichment resolves the new and the old side in one pass to keep it to a single query
 * - CyclomaticComplexity: Dispatch has to branch over all seven trigger contexts
 * - StdCyclomaticComplexity: Dispatch has to branch over all seven trigger contexts
 * - CognitiveComplexity: Dispatch has to branch over all seven trigger contexts
 * - AvoidNonRestrictiveQueries: The bypass configuration is custom metadata, it is read once and does not count against SOQL limits
 * - FieldDeclarationsShouldBeAtStart: Developer who uses lib should see what's important at start
 **/
@SuppressWarnings(
    'PMD.ExcessiveClassLength,PMD.NcssTypeCount,PMD.NcssMethodCount,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.AvoidNonRestrictiveQueries,PMD.FieldDeclarationsShouldBeAtStart'
)
global with sharing class TriggerOrchestrator {
    global interface BeforeInsert {
        List<BeforeInsert.Handler> beforeInsertHandlers();
    }

    global interface AfterInsert {
        List<AfterInsert.Handler> afterInsertHandlers();
    }

    global interface BeforeUpdate {
        List<BeforeUpdate.Handler> beforeUpdateHandlers();
    }

    global interface AfterUpdate {
        List<AfterUpdate.Handler> afterUpdateHandlers();
    }

    global interface BeforeDelete {
        List<BeforeDelete.Handler> beforeDeleteHandlers();
    }

    global interface AfterDelete {
        List<AfterDelete.Handler> afterDeleteHandlers();
    }

    global interface AfterUndelete {
        List<AfterUndelete.Handler> afterUndeleteHandlers();
    }

    global interface Logger {
        void log(TriggerOrchestrator.Error error);
        void flush();
    }

    global interface Error {
        String getHandlerName();
        SObjectType getSObjectType();
        System.Exception getException();
        System.TriggerOperation getOperation();
        Set<Id> getRecordIds();
    }

    global static void run(Object orchestrator) {
        new TriggerOrchestrator(orchestrator).run();
    }

    global static Bypassable bypass() {
        return TriggerOrchestrator.triggerBypass;
    }

    global interface Bypassable {
        Bypassable sObject(SObjectType sObjectType);
        Bypassable orchestrator(System.Type orchestrator);
        Bypassable handler(System.Type handler);
        void all();
        void clear();
    }

    global static Mockable mock() {
        return TriggerOrchestrator.triggerMock;
    }

    global static void runTestFor(Object handlerOrOrchestrator) {
        TriggerOrchestrator.triggerMock.nextContextFor(handlerOrOrchestrator).run(handlerOrOrchestrator);
    }

    global interface Mockable {
        BeforeInsertMockable beforeInsertFor(System.Type handlerOrOrchestratorType);
        AfterInsertMockable afterInsertFor(System.Type handlerOrOrchestratorType);
        BeforeUpdateMockable beforeUpdateFor(System.Type handlerOrOrchestratorType);
        AfterUpdateMockable afterUpdateFor(System.Type handlerOrOrchestratorType);
        BeforeDeleteMockable beforeDeleteFor(System.Type handlerOrOrchestratorType);
        AfterDeleteMockable afterDeleteFor(System.Type handlerOrOrchestratorType);
        AfterUndeleteMockable afterUndeleteFor(System.Type handlerOrOrchestratorType);
    }

    global interface BeforeInsertMockable {
        BeforeInsertMockable with(SObject row);
        BeforeInsertMockable with(List<SObject> rows);
        BeforeInsertMockable withParent(SObjectField lookupField, SObject parent);
        BeforeInsertMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    global interface AfterInsertMockable {
        AfterInsertMockable with(SObject row);
        AfterInsertMockable with(List<SObject> rows);
        AfterInsertMockable withParent(SObjectField lookupField, SObject parent);
        AfterInsertMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    global interface BeforeUpdateMockable {
        BeforeUpdateMockable with(SObject newRow, SObject oldRow);
        BeforeUpdateMockable with(List<SObject> newRows, List<SObject> oldRows);
        BeforeUpdateMockable withParent(SObjectField lookupField, SObject parent);
        BeforeUpdateMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    global interface AfterUpdateMockable {
        AfterUpdateMockable with(SObject newRow, SObject oldRow);
        AfterUpdateMockable with(List<SObject> newRows, List<SObject> oldRows);
        AfterUpdateMockable withParent(SObjectField lookupField, SObject parent);
        AfterUpdateMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    global interface BeforeDeleteMockable {
        BeforeDeleteMockable with(SObject row);
        BeforeDeleteMockable with(List<SObject> rows);
        BeforeDeleteMockable withParent(SObjectField lookupField, SObject parent);
        BeforeDeleteMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    global interface AfterDeleteMockable {
        AfterDeleteMockable with(SObject row);
        AfterDeleteMockable with(List<SObject> rows);
        AfterDeleteMockable withParent(SObjectField lookupField, SObject parent);
        AfterDeleteMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    global interface AfterUndeleteMockable {
        AfterUndeleteMockable with(SObject row);
        AfterUndeleteMockable with(List<SObject> rows);
        AfterUndeleteMockable withParent(SObjectField lookupField, SObject parent);
        AfterUndeleteMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    // Implementations

    @TestVisible
    private static TriggerLogger triggerLogger = new TriggerLogger();
    private static MetadataBypass metadataBypass = new MetadataBypass();
    private static TriggerBypass triggerBypass = new TriggerBypass();
    private static TriggerStack triggerStack = new TriggerStack();
    private static RunCounter runCounter = new RunCounter();
    private static TriggerMock triggerMock = new TriggerMock();

    @TestVisible
    private TriggerContext context;
    public Object orchestrator;
    public ParentLoader parentLoader;
    public UnitOfWork sharedUnitOfWork;

    @TestVisible
    private TriggerOrchestrator(Object orchestrator) {
        this.orchestrator = orchestrator;
        this.context = new TriggerContext();
        this.parentLoader = new ParentLoader(this.context);
        this.sharedUnitOfWork = new UnitOfWork();
    }

    @TestVisible
    private void run() {
        Operation operation;

        try {
            if (this.context.triggerOperation == null) {
                throw new TriggerTypes.TriggerLibException('Called outside of a trigger context.');
            }

            if (TriggerOrchestrator.triggerBypass.isRunBypassed(this)) {
                return;
            }

            if (TriggerOrchestrator.metadataBypass.isSObjectTriggerBypassed(this.context)) {
                return;
            }

            if (this.context.triggerOperation == System.TriggerOperation.BEFORE_INSERT && this.orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                operation = new BeforeInsert.Operation();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_INSERT && this.orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                operation = new AfterInsert.Operation();
            } else if (this.context.triggerOperation == System.TriggerOperation.BEFORE_UPDATE && this.orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                operation = new BeforeUpdate.Operation();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_UPDATE && this.orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                operation = new AfterUpdate.Operation();
            } else if (this.context.triggerOperation == System.TriggerOperation.BEFORE_DELETE && this.orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                operation = new BeforeDelete.Operation();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_DELETE && this.orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                operation = new AfterDelete.Operation();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_UNDELETE && this.orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                operation = new AfterUndelete.Operation();
            } else {
                return;
            }

            TriggerOrchestrator.triggerStack.push(operation);

            operation.execute(this);
        } finally {
            this.finalizeTransactionChunk(operation);
        }
    }

    private void finalizeTransactionChunk(Operation operation) {
        if (operation == null) {
            return;
        }

        TriggerOrchestrator.triggerStack.popLast();

        if (TriggerOrchestrator.triggerStack.isMainTransactionChunkCompleted()) {
            TriggerOrchestrator.triggerLogger.flush();
        }
    }

    private class TriggerContext {
        public System.TriggerOperation triggerOperation = Trigger.operationType;

        public List<SObject> newRecords = Trigger.new;
        public List<SObject> oldRecords = Trigger.old;

        public SObjectType sObjectType {
            get {
                if (this.sObjectType == null) {
                    this.sObjectType = (this.newRecords ?? this.oldRecords)?.getSObjectType();
                }
                return this.sObjectType;
            }
            private set;
        }

        public List<TriggerTypes.TriggerRecord> triggerRecords {
            get {
                if (this.triggerRecords == null) {
                    this.triggerRecords = TriggerTypes.toTriggerRecords(this.newRecords, this.oldRecords);
                }
                return this.triggerRecords;
            }
            private set;
        }
    }

    private class TriggerBypass implements Bypassable {
        private Set<String> bypassed = new Set<String>();

        public Bypassable sObject(SObjectType sObjectType) {
            this.bypassed.add(sObjectType.toString().toLowerCase());
            return this;
        }

        public Bypassable orchestrator(System.Type orchestratorType) {
            this.bypassed.add(orchestratorType.getName().toLowerCase());
            return this;
        }

        public Bypassable handler(System.Type handlerType) {
            this.bypassed.add(handlerType.getName().toLowerCase());
            return this;
        }

        public void all() {
            this.bypassed.add('ALL');
        }

        public void clear() {
            this.bypassed.clear();
        }

        public Boolean isRunBypassed(TriggerOrchestrator orchestrator) {
            return this.bypassed.contains('ALL') ||
                this.bypassed.contains(orchestrator.context.sObjectType?.toString()?.toLowerCase()) ||
                this.bypassed.contains(orchestrator.orchestrator?.toString()?.substringBefore(':')?.toLowerCase());
        }

        public Boolean isHandlerBypassed(String handlerName) {
            return this.bypassed.contains('ALL') || this.bypassed.contains(handlerName.toLowerCase());
        }
    }

    @TestVisible
    private class MetadataBypass {
        private Map<String, ObjectMetadata> metadataByObjectName = this.resolveObjectMetadata();

        public Boolean isSObjectTriggerBypassed(TriggerContext context) {
            return this.metadataByObjectName.get(context.sObjectType.toString().toLowerCase())?.objectRow.Bypass__c == true;
        }

        public Boolean isHandlerBypassed(TriggerContext context, String handlerName) {
            return this.metadataByObjectName.get(context.sObjectType.toString().toLowerCase())?.handlerRowByName.get(handlerName.toLowerCase())?.Bypass__c == true;
        }

        private Map<String, ObjectMetadata> resolveObjectMetadata() {
            Map<String, ObjectMetadata> metadataByObjectName = new Map<String, ObjectMetadata>();
            String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');

            for (
                TriggerObject__mdt triggerObject : (List<TriggerObject__mdt>) SOQL.of(TriggerObject__mdt.SObjectType)
                    .with(TriggerObject__mdt.ObjectAPIName__c, TriggerObject__mdt.Bypass__c)
                    .with(SOQL.SubQuery.of(namespacePrefix + 'TriggerHandlers__r').with(TriggerHandler__mdt.ApexClassName__c, TriggerHandler__mdt.Bypass__c))
                    .systemMode()
                    .mockId('TriggerObject__mdt')
                    .toList()
            ) {
                metadataByObjectName.put(triggerObject.ObjectAPIName__c.trim().toLowerCase(), new ObjectMetadata(triggerObject));
            }

            return metadataByObjectName;
        }
    }

    @TestVisible
    private class ObjectMetadata {
        public TriggerObject__mdt objectRow = new TriggerObject__mdt();
        public Map<String, TriggerHandler__mdt> handlerRowByName = new Map<String, TriggerHandler__mdt>();

        public ObjectMetadata(TriggerObject__mdt triggerObject) {
            this.objectRow = triggerObject;
            this.addHandlerRows();
        }

        private void addHandlerRows() {
            for (TriggerHandler__mdt triggerHandler : this.objectRow.TriggerHandlers__r ?? new List<TriggerHandler__mdt>()) {
                this.addHandlerRow(triggerHandler);
            }
        }

        private void addHandlerRow(TriggerHandler__mdt triggerHandler) {
            String handlerName = triggerHandler.ApexClassName__c.trim().toLowerCase();

            this.handlerRowByName.put(handlerName, triggerHandler);

            if (handlerName.contains('.')) {
                this.handlerRowByName.put(handlerName.substringAfterLast('.'), triggerHandler);
            }
        }
    }

    private class TriggerStack {
        private List<Operation> executionStack = new List<Operation>();

        public void push(Operation operation) {
            this.executionStack.add(operation);
        }

        public void popLast() {
            this.executionStack.remove(this.executionStack.size() - 1);
        }

        public Boolean isMainTransactionChunkCompleted() {
            return this.executionStack.isEmpty();
        }
    }

    @TestVisible
    private class TriggerLogger {
        @TestVisible
        private Logger logger = this.resolveLogger();

        public void log(Error error) {
            this.logger?.log(error);
        }

        public void flush() {
            this.logger?.flush();
        }

        private Logger resolveLogger() {
            List<ApexTypeImplementor> implementors = SOQL.of('ApexTypeImplementor')
                .with(ApexTypeImplementor.ClassName, ApexTypeImplementor.ClassNamespacePrefix)
                .whereAre(SOQL.Filter.with(ApexTypeImplementor.InterfaceName).equal('TriggerOrchestrator.Logger'))
                .whereAre(SOQL.Filter.with(ApexTypeImplementor.InterfaceNamespacePrefix).equal(TriggerOrchestrator.class.getName().substringBetween('', '.')))
                .whereAre(SOQL.Filter.with(ApexTypeImplementor.IsConcrete).isTrue())
                .systemMode()
                .setLimit(2)
                .mockId('ApexTypeImplementor')
                .toList();

            if (implementors.size() > 1) {
                throw new TriggerTypes.TriggerLibException('Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.');
            }

            if (implementors.isEmpty()) {
                return null;
            }

            return (Logger) Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();
        }
    }

    private class TriggerError implements Error {
        public String handlerName;
        public SObjectType sObjectType;
        public System.Exception thrownException;
        public System.TriggerOperation triggerOperation;
        public Set<Id> recordIds = new Set<Id>();

        public String getHandlerName() {
            return this.handlerName;
        }

        public SObjectType getSObjectType() {
            return this.sObjectType;
        }

        public Exception getException() {
            return this.thrownException;
        }

        public System.TriggerOperation getOperation() {
            return this.triggerOperation;
        }

        public Set<Id> getRecordIds() {
            return this.recordIds;
        }

        public TriggerError withException(System.Exception thrownException) {
            this.thrownException = thrownException;
            return this;
        }

        public TriggerError withHandlerName(String handlerName) {
            this.handlerName = handlerName;
            return this;
        }

        public TriggerError withContext(TriggerContext context) {
            this.sObjectType = context.sObjectType;
            this.triggerOperation = context.triggerOperation;
            this.setRecordIds(context);
            return this;
        }

        private void setRecordIds(TriggerContext context) {
            for (TriggerTypes.TriggerRecord record : context.triggerRecords) {
                if (record.getId() != null) {
                    this.recordIds.add(record.getId());
                }
            }
        }
    }

    public abstract class Operation {
        public void execute(TriggerOrchestrator orchestrator) {
            List<HandlerExecutor> activeExecutors = this.getActiveExecutors(orchestrator);

            orchestrator.parentLoader.collectDeclarations(activeExecutors);

            for (HandlerExecutor executor : activeExecutors) {
                executor.execute(orchestrator.context.triggerRecords);
            }

            orchestrator.sharedUnitOfWork.commitWork();
        }

        private List<HandlerExecutor> getActiveExecutors(TriggerOrchestrator orchestrator) {
            List<HandlerExecutor> activeExecutors = new List<HandlerExecutor>();

            for (HandlerExecutor executor : this.buildExecutors(orchestrator)) {
                if (!executor.isBypassed()) {
                    activeExecutors.add(executor);
                }
            }

            return activeExecutors;
        }

        protected abstract List<HandlerExecutor> buildExecutors(TriggerOrchestrator orchestrator);
    }

    public abstract class HandlerExecutor {
        protected String handlerName;

        protected TriggerOrchestrator orchestrator;
        protected ParentDeclaration parentDeclaration;
        protected RelatedLoader relatedLoader;
        protected HandlerHooks handlerHooks;

        protected List<TriggerTypes.TriggerRecord> qualifiedRecords = new List<TriggerTypes.TriggerRecord>();

        public HandlerExecutor(Object handler, TriggerOrchestrator orchestrator) {
            this.handlerName = handler.toString().substringBefore(':');
            this.orchestrator = orchestrator;
        }

        public Boolean isBypassed() {
            return this.isBypassedByApexOrMetadata() || this.handlerHooks.isBypassedByAddOn();
        }

        private Boolean isBypassedByApexOrMetadata() {
            return TriggerOrchestrator.triggerBypass.isHandlerBypassed(this.handlerName) ||
                TriggerOrchestrator.metadataBypass.isHandlerBypassed(this.orchestrator.context, this.handlerName);
        }

        public abstract void execute(List<TriggerTypes.TriggerRecord> records);

        protected void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerTypes.TriggerLibException || !this.handlerHooks.continuesOnError()) {
                throw e;
            }
        }

        protected void logError(Exception e) {
            TriggerOrchestrator.triggerLogger.log(new TriggerError().withException(e).withHandlerName(this.handlerName).withContext(this.orchestrator.context));
        }
    }

    public abstract class ParentDeclaration {
        public virtual Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }

        public virtual Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class ParentLoader implements TriggerTypes.ParentLoader {
        private Set<SObjectField> lookupsForNewParents = new Set<SObjectField>();
        private Set<SObjectField> lookupsForOldParents = new Set<SObjectField>();
        private Set<SObjectField> loadedLookups = new Set<SObjectField>();

        private Map<String, SObjectField> lookupByRelationshipName = new Map<String, SObjectField>();
        private Map<SObjectField, Set<String>> fieldPathsByLookup = new Map<SObjectField, Set<String>>();
        private Map<SObjectField, Map<Id, SObject>> cachedParentsByLookup = new Map<SObjectField, Map<Id, SObject>>();

        private Boolean areSavedRecordsQueried = false;

        private TriggerContext context;

        public ParentLoader(TriggerContext context) {
            this.context = context;
        }

        public void collectDeclarations(List<HandlerExecutor> handlers) {
            for (HandlerExecutor handler : handlers) {
                this.declareNewParents(handler.parentDeclaration.getNewParentFields());
                this.declareOldParents(handler.parentDeclaration.getOldParentFields());
            }

            for (TriggerTypes.TriggerRecord record : this.context.triggerRecords) {
                record.setParentLoader(this);
            }
        }

        public void load(String relationshipName) {
            SObjectField lookupField = this.lookupByRelationshipName.get(relationshipName);

            if (lookupField == null || this.loadedLookups.contains(lookupField)) {
                return;
            }

            if (this.lookupsForNewParents.contains(lookupField)) {
                this.queryNewParentsFromSavedRecords();
            }

            this.queryAndAttachParents(lookupField);
            this.loadedLookups.add(lookupField);
        }

        public void refreshNewParents(List<TriggerTypes.TriggerRecord> records) {
            if (records.isEmpty()) {
                return;
            }

            for (SObjectField lookupField : this.loadedLookups) {
                this.queryParents(lookupField, this.notQueriedNewParentIds(lookupField, records));
                this.attachNewParents(lookupField, records);
            }
        }

        private void declareNewParents(Map<SObjectField, TriggerTypes.ParentFields> parentFieldsByLookup) {
            this.lookupsForNewParents.addAll(parentFieldsByLookup.keySet());
            this.declare(parentFieldsByLookup);
        }

        private void declareOldParents(Map<SObjectField, TriggerTypes.ParentFields> parentFieldsByLookup) {
            this.lookupsForOldParents.addAll(parentFieldsByLookup.keySet());
            this.declare(parentFieldsByLookup);
        }

        private void declare(Map<SObjectField, TriggerTypes.ParentFields> parentFieldsByLookup) {
            for (SObjectField lookupField : parentFieldsByLookup.keySet()) {
                if (!this.fieldPathsByLookup.containsKey(lookupField)) {
                    this.fieldPathsByLookup.put(lookupField, new Set<String>());
                }
                if (!this.cachedParentsByLookup.containsKey(lookupField)) {
                    this.cachedParentsByLookup.put(lookupField, new Map<Id, SObject>());
                }

                this.lookupByRelationshipName.put(lookupField.getDescribe().getRelationshipName(), lookupField);
                this.fieldPathsByLookup.get(lookupField).addAll(parentFieldsByLookup.get(lookupField).getFields());
            }
        }

        private void queryNewParentsFromSavedRecords() {
            if (this.areSavedRecordsQueried || !this.haveTriggeredRecordsIds()) {
                return;
            }

            Set<String> fieldsToQuery = new Set<String>();

            for (SObjectField lookupField : this.lookupsForNewParents) {
                fieldsToQuery.addAll(this.getFieldPathsForLookup(lookupField));
            }

            List<SObject> savedRecords = SOQL.of(this.context.sObjectType).with(fieldsToQuery).byIds(this.context.newRecords).systemMode().withoutSharing().toList();

            for (SObjectField lookupField : this.lookupsForNewParents) {
                Map<Id, SObject> cachedParentById = this.cachedParentsByLookup.get(lookupField);
                String relationshipName = lookupField.getDescribe().getRelationshipName();

                for (SObject savedRecord : savedRecords) {
                    SObject parent = savedRecord.getSObject(relationshipName);

                    if (parent != null) {
                        cachedParentById.put(parent.Id, parent);
                    }
                }
            }

            this.areSavedRecordsQueried = true;
        }

        private Boolean haveTriggeredRecordsIds() {
            return this.context.triggerOperation == System.TriggerOperation.AFTER_INSERT ||
                this.context.triggerOperation == System.TriggerOperation.AFTER_UPDATE ||
                this.context.triggerOperation == System.TriggerOperation.AFTER_UNDELETE;
        }

        private Set<String> getFieldPathsForLookup(SObjectField lookupField) {
            String relationshipName = lookupField.getDescribe().getRelationshipName();
            Set<String> fieldPaths = new Set<String>{ relationshipName + '.Id' };

            for (String field : this.fieldPathsByLookup.get(lookupField)) {
                fieldPaths.add(relationshipName + '.' + field);
            }

            return fieldPaths;
        }

        private void queryAndAttachParents(SObjectField lookupField) {
            Set<Id> parentIdsToQuery = new Set<Id>();

            parentIdsToQuery.addAll(this.notQueriedNewParentIds(lookupField, this.context.triggerRecords));
            parentIdsToQuery.addAll(this.notQueriedOldParentIds(lookupField, this.context.triggerRecords));

            this.queryParents(lookupField, parentIdsToQuery);

            this.attachNewParents(lookupField, this.context.triggerRecords);
            this.attachOldParents(lookupField, this.context.triggerRecords);
        }

        private Set<Id> notQueriedNewParentIds(SObjectField lookupField, List<TriggerTypes.TriggerRecord> records) {
            Set<Id> parentIds = new Set<Id>();

            if (!this.lookupsForNewParents.contains(lookupField)) {
                return parentIds;
            }

            Map<Id, SObject> cachedParentById = this.cachedParentsByLookup.get(lookupField);

            for (TriggerTypes.TriggerRecord record : records) {
                Id parentId = record.getNewParentId(lookupField);

                if (parentId != null && !cachedParentById.containsKey(parentId)) {
                    parentIds.add(parentId);
                }
            }

            return parentIds;
        }

        private Set<Id> notQueriedOldParentIds(SObjectField lookupField, List<TriggerTypes.TriggerRecord> records) {
            Set<Id> parentIds = new Set<Id>();

            if (!this.lookupsForOldParents.contains(lookupField)) {
                return parentIds;
            }

            Map<Id, SObject> cachedParentById = this.cachedParentsByLookup.get(lookupField);

            for (TriggerTypes.TriggerRecord record : records) {
                Id parentId = record.getOldParentId(lookupField);

                if (parentId != null && !cachedParentById.containsKey(parentId)) {
                    parentIds.add(parentId);
                }
            }

            return parentIds;
        }

        private void queryParents(SObjectField lookupField, Set<Id> parentIdsToQuery) {
            if (parentIdsToQuery.isEmpty()) {
                return;
            }

            Map<Id, SObject> queriedParentById = SOQL.of(lookupField.getDescribe().getReferenceTo()[0])
                .with(this.fieldPathsByLookup.get(lookupField))
                .byIds(parentIdsToQuery)
                .systemMode()
                .withoutSharing()
                .toMap();

            Map<Id, SObject> cachedParentById = this.cachedParentsByLookup.get(lookupField);

            for (Id parentId : parentIdsToQuery) {
                cachedParentById.put(parentId, queriedParentById.get(parentId));
            }
        }

        private void attachNewParents(SObjectField lookupField, List<TriggerTypes.TriggerRecord> records) {
            if (!this.lookupsForNewParents.contains(lookupField)) {
                return;
            }

            Map<Id, SObject> parentsById = this.cachedParentsByLookup.get(lookupField);
            String relationshipName = lookupField.getDescribe().getRelationshipName();

            for (TriggerTypes.TriggerRecord record : records) {
                record.setNewParent(relationshipName, parentsById.get(record.getNewParentId(lookupField)));
            }
        }

        private void attachOldParents(SObjectField lookupField, List<TriggerTypes.TriggerRecord> records) {
            if (!this.lookupsForOldParents.contains(lookupField)) {
                return;
            }

            Map<Id, SObject> parentsById = this.cachedParentsByLookup.get(lookupField);
            String relationshipName = lookupField.getDescribe().getRelationshipName();

            for (TriggerTypes.TriggerRecord record : records) {
                record.setOldParent(relationshipName, parentsById.get(record.getOldParentId(lookupField)));
            }
        }
    }

    public abstract class RelatedLoader implements TriggerTypes.RelatedLoader {
        protected List<TriggerTypes.TriggerRecord> records = new List<TriggerTypes.TriggerRecord>();

        private Map<String, TriggerTypes.RelatedRecords> relatedByProviderName = new Map<String, TriggerTypes.RelatedRecords>();

        public void attachTo(List<TriggerTypes.TriggerRecord> records) {
            this.records = records;

            for (TriggerTypes.TriggerRecord record : records) {
                record.setRelated(this.relatedByProviderName);
                record.setRelatedLoader(this);
            }
        }

        public void load(String providerName) {
            if (this.relatedByProviderName.containsKey(providerName)) {
                return;
            }

            TriggerTypes.RelatedRecords related = this.queryRelated(providerName);

            if (related != null) {
                this.relatedByProviderName.put(providerName, related);
            }
        }

        protected abstract TriggerTypes.RelatedRecords queryRelated(String providerName);
    }

    public abstract class UnitOfWorkResolver {
        public abstract UnitOfWork resolve(UnitOfWork sharedUnitOfWork);
    }

    public class UnitOfWork implements TriggerTypes.UnitOfWork {
        private DML.Committable dml;

        public UnitOfWork() {
            this(new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow'));
        }

        public UnitOfWork(DML.Committable dml) {
            this.dml = dml;
        }

        public TriggerTypes.UnitOfWork toInsert(SObject record) {
            this.dml.toInsert(record);
            return this;
        }

        public TriggerTypes.UnitOfWork toInsert(DML.Record record) {
            this.dml.toInsert(record);
            return this;
        }

        public TriggerTypes.UnitOfWork toUpdate(SObject record) {
            this.dml.toUpdate(record);
            return this;
        }

        public TriggerTypes.UnitOfWork toUpdate(DML.Record record) {
            this.dml.toUpdate(record);
            return this;
        }

        public TriggerTypes.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) {
            this.dml.toUpsert(record, externalIdField);
            return this;
        }

        public TriggerTypes.UnitOfWork toDelete(SObject record) {
            this.dml.toDelete(record);
            return this;
        }

        public TriggerTypes.UnitOfWork toPublish(SObject event) {
            this.dml.toPublish(event);
            return this;
        }

        public void commitWork() {
            this.dml.commitWork();
        }
    }

    public abstract class HandlerHooks {
        public abstract Boolean isBypassedByAddOn();
        public abstract void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords);
        public abstract Boolean continuesOnError();
    }

    public abstract class RecursionTracker {
        private Map<Id, Integer> runCountByRecordId;
        protected Integer maxRunsPerRecord = 3;

        public RecursionTracker(String recursionScope) {
            TriggerOrchestrator.runCounter.registerScope(recursionScope);
            this.runCountByRecordId = TriggerOrchestrator.runCounter.getForRecursionScope(recursionScope);
        }

        public Boolean isLimitReached(TriggerTypes.TriggerRecord record) {
            return (this.runCountByRecordId.get(record.getId()) ?? 0) >= this.maxRunsPerRecord;
        }

        public void countRun(TriggerTypes.TriggerRecord record) {
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RunCounter {
        private Map<String, Map<Id, Integer>> runCountByRecordIdByScope = new Map<String, Map<Id, Integer>>();

        public void registerScope(String recursionScope) {
            if (!this.runCountByRecordIdByScope.containsKey(recursionScope)) {
                this.runCountByRecordIdByScope.put(recursionScope, new Map<Id, Integer>());
            }
        }

        public Map<Id, Integer> getForRecursionScope(String recursionScope) {
            return this.runCountByRecordIdByScope.get(recursionScope);
        }
    }

    private class TriggerMock implements Mockable {
        private Map<String, List<MockedContext>> mockedContextsByClassName = new Map<String, List<MockedContext>>();

        public BeforeInsertMockable beforeInsertFor(System.Type handlerOrOrchestratorType) {
            BeforeInsert.MockedContext mockedContext = new BeforeInsert.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterInsertMockable afterInsertFor(System.Type handlerOrOrchestratorType) {
            AfterInsert.MockedContext mockedContext = new AfterInsert.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public BeforeUpdateMockable beforeUpdateFor(System.Type handlerOrOrchestratorType) {
            BeforeUpdate.MockedContext mockedContext = new BeforeUpdate.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterUpdateMockable afterUpdateFor(System.Type handlerOrOrchestratorType) {
            AfterUpdate.MockedContext mockedContext = new AfterUpdate.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public BeforeDeleteMockable beforeDeleteFor(System.Type handlerOrOrchestratorType) {
            BeforeDelete.MockedContext mockedContext = new BeforeDelete.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterDeleteMockable afterDeleteFor(System.Type handlerOrOrchestratorType) {
            AfterDelete.MockedContext mockedContext = new AfterDelete.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterUndeleteMockable afterUndeleteFor(System.Type handlerOrOrchestratorType) {
            AfterUndelete.MockedContext mockedContext = new AfterUndelete.MockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public MockedContext nextContextFor(Object handlerOrOrchestrator) {
            String className = String.valueOf(handlerOrOrchestrator).substringBefore(':');
            List<MockedContext> mockedContexts = this.mockedContextsByClassName.get(className);

            if (mockedContexts == null) {
                throw new TriggerTypes.TriggerLibException('No trigger context is mocked for ' + className + '.');
            }

            return mockedContexts.size() > 1 ? mockedContexts.remove(0) : mockedContexts[0];
        }

        private void addMockedContext(System.Type handlerOrOrchestratorType, MockedContext mockedContext) {
            String className = ('.' + handlerOrOrchestratorType.getName()).substringAfterLast('.');
            List<MockedContext> mockedContexts = this.mockedContextsByClassName.get(className) ?? new List<MockedContext>();

            mockedContexts.add(mockedContext);
            this.mockedContextsByClassName.put(className, mockedContexts);
        }
    }

    public abstract class MockedContext {
        protected System.TriggerOperation triggerOperation;

        protected List<SObject> newRecords = new List<SObject>();
        protected List<SObject> oldRecords = new List<SObject>();

        protected Map<SObjectType, List<SObject>> parentsByType = new Map<SObjectType, List<SObject>>();

        protected Object handlerOrOrchestrator;

        public MockedContext(System.TriggerOperation triggerOperation) {
            this.triggerOperation = triggerOperation;
        }

        public void run(Object handlerOrOrchestrator) {
            this.handlerOrOrchestrator = handlerOrOrchestrator;

            for (SObjectType parentType : this.parentsByType.keySet()) {
                SOQL.mock(parentType).thenReturn(this.typed(this.parentsByType.get(parentType)));
            }

            TriggerOrchestrator orchestrator = new TriggerOrchestrator(this);

            orchestrator.context.triggerOperation = this.triggerOperation;
            orchestrator.context.newRecords = this.typed(this.newRecords);
            orchestrator.context.oldRecords = this.typed(this.oldRecords);

            orchestrator.run();
        }

        protected void addParents(SObjectField lookupField, List<SObject> parents) {
            SObjectType parentType = lookupField.getDescribe().getReferenceTo()[0];
            List<SObject> parentsOfType = this.parentsByType.get(parentType) ?? new List<SObject>();

            parentsOfType.addAll(parents);
            this.parentsByType.put(parentType, parentsOfType);
        }

        protected List<SObject> assignIds(List<SObject> records) {
            for (SObject record : records) {
                record.put('Id', record.Id ?? new TriggerTypes.RandomIdGenerator().get(record.getSObjectType()));
            }

            return records;
        }

        protected void shareIds(List<SObject> newRecords, List<SObject> oldRecords) {
            for (Integer i = 0; i < newRecords.size(); i++) {
                Id recordId = newRecords[i].Id ?? oldRecords[i].Id ?? new TriggerTypes.RandomIdGenerator().get(newRecords[i].getSObjectType());

                newRecords[i].put('Id', recordId);
                oldRecords[i].put('Id', recordId);
            }
        }

        private List<SObject> typed(List<SObject> records) {
            if (records.isEmpty()) {
                return null;
            }

            List<SObject> typedRecords = (List<SObject>) Type.forName('List<Schema.' + String.valueOf(records[0].getSObjectType()) + '>').newInstance();
            typedRecords.addAll(records);

            return typedRecords;
        }
    }
}
