/**
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.1
 *
 * PMD False Positives:
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE class
 * - NcssMethodCount: Parent enrichment resolves the new and the old side in one pass to keep it to a single query
 * - CyclomaticComplexity: Dispatch has to branch over all seven trigger contexts
 * - StdCyclomaticComplexity: Dispatch has to branch over all seven trigger contexts
 * - CognitiveComplexity: Dispatch has to branch over all seven trigger contexts
 * - AvoidNonRestrictiveQueries: The bypass configuration is custom metadata, it is read once and does not count against SOQL limits
 **/
@SuppressWarnings(
    'PMD.ExcessiveClassLength,PMD.NcssTypeCount,PMD.NcssMethodCount,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.AvoidNonRestrictiveQueries'
)
public with sharing class TriggerOrchestrator {
    public interface BeforeInsert {
        List<BeforeInsert.Handler> beforeInsertHandlers();
    }

    public interface AfterInsert {
        List<AfterInsert.Handler> afterInsertHandlers();
    }

    public interface BeforeUpdate {
        List<BeforeUpdate.Handler> beforeUpdateHandlers();
    }

    public interface AfterUpdate {
        List<AfterUpdate.Handler> afterUpdateHandlers();
    }

    public interface BeforeDelete {
        List<BeforeDelete.Handler> beforeDeleteHandlers();
    }

    public interface AfterDelete {
        List<AfterDelete.Handler> afterDeleteHandlers();
    }

    public interface AfterUndelete {
        List<AfterUndelete.Handler> afterUndeleteHandlers();
    }

    public interface RecursionGuard {
        Integer maxRecursionDepth();
    }

    public interface Logger {
        void log(TriggerOrchestrator.Error error);
        void finalize();
    }

    public interface Error {
        String getHandlerName();
        SObjectType getSObjectType();
        System.Exception getException();
        System.TriggerOperation getOperation();
        Set<Id> getRecordIds();
    }

    public static void run(Object orchestrator) {
        new TriggerOrchestrator(orchestrator).run();
    }

    // Implementations

    @TestVisible
    private static Logger logger = TriggerOrchestrator.resolveLogger();
    @TestVisible
    private static Map<String, MetadataSettings> metadataSettingsByObjectName = TriggerOrchestrator.resolveMetadataSettings();
    private static Map<String, Map<Id, Integer>> recursionDepthByRecordByHandler = new Map<String, Map<Id, Integer>>();
    private static List<ExecutionStrategy> executionStack = new List<ExecutionStrategy>();

    private Object orchestrator;

    @TestVisible
    private System.TriggerOperation triggerOperation = Trigger.operationType;
    @TestVisible
    private List<SObject> triggerNewRecords = Trigger.new;
    @TestVisible
    private List<SObject> triggerOldRecords = Trigger.old;
    @TestVisible
    private SObjectType sObjectType;

    @TestVisible
    private TriggerOrchestrator(Object orchestrator) {
        this.orchestrator = orchestrator;
    }

    @TestVisible
    private void run() {
        ExecutionStrategy executionStrategy;

        try {
            if (this.triggerOperation == null) {
                throw new TriggerOrchestratorException('Called outside of a trigger context, or the trigger operation is not supported.');
            }

            this.sObjectType = (this.triggerNewRecords ?? this.triggerOldRecords)?.getSObjectType();

            if (TriggerOrchestrator.metadataSettingsByObjectName.get(this.sObjectType?.toString()?.toLowerCase())?.sObjectSetting.Bypass__c == true) {
                return;
            }

            if (this.triggerOperation == System.TriggerOperation.BEFORE_INSERT && this.orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                executionStrategy = new BeforeInsertExecutionStrategy();
            } else if (this.triggerOperation == System.TriggerOperation.AFTER_INSERT && this.orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                executionStrategy = new AfterInsertExecutionStrategy();
            } else if (this.triggerOperation == System.TriggerOperation.BEFORE_UPDATE && this.orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                executionStrategy = new BeforeUpdateExecutionStrategy();
            } else if (this.triggerOperation == System.TriggerOperation.AFTER_UPDATE && this.orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                executionStrategy = new AfterUpdateExecutionStrategy();
            } else if (this.triggerOperation == System.TriggerOperation.BEFORE_DELETE && this.orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                executionStrategy = new BeforeDeleteExecutionStrategy();
            } else if (this.triggerOperation == System.TriggerOperation.AFTER_DELETE && this.orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                executionStrategy = new AfterDeleteExecutionStrategy();
            } else if (this.triggerOperation == System.TriggerOperation.AFTER_UNDELETE && this.orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                executionStrategy = new AfterUndeleteExecutionStrategy();
            } else {
                return;
            }

            TriggerOrchestrator.executionStack.add(executionStrategy);

            executionStrategy.execute(this);
        } finally {
            this.finalizeTransactionChunk(executionStrategy);
        }
    }

    private void finalizeTransactionChunk(ExecutionStrategy executionStrategy) {
        if (executionStrategy == null) {
            return;
        }

        TriggerOrchestrator.executionStack.remove(TriggerOrchestrator.executionStack.size() - 1);

        if (TriggerOrchestrator.executionStack.isEmpty()) {
            TriggerOrchestrator.logger?.finalize();
        }
    }

    private static Logger resolveLogger() {
        List<ApexTypeImplementor> implementors = SOQL.of('ApexTypeImplementor')
            .with(ApexTypeImplementor.ClassName, ApexTypeImplementor.ClassNamespacePrefix)
            .whereAre(SOQL.Filter.with(ApexTypeImplementor.InterfaceName).equal('TriggerOrchestrator.Logger'))
            .whereAre(SOQL.Filter.with(ApexTypeImplementor.InterfaceNamespacePrefix).equal(TriggerOrchestrator.class.getName().substringBetween('', '.')))
            .whereAre(SOQL.Filter.with(ApexTypeImplementor.IsConcrete).isTrue())
            .systemMode()
            .setLimit(2)
            .toList();

        if (implementors.size() > 1) {
            throw new TriggerOrchestratorException('Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.');
        }

        if (implementors.isEmpty()) {
            return null;
        }

        return (Logger) Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();
    }

    private static Boolean isHandlerBypassedInMetadata(Object handler, SObjectType sObjectType) {
        return TriggerOrchestrator.metadataSettingsByObjectName.get(sObjectType?.toString()?.toLowerCase())?.isHandlerBypassed(handler) == true;
    }

    private static Map<String, MetadataSettings> resolveMetadataSettings() {
        Map<String, MetadataSettings> metadataSettingsByObjectName = new Map<String, MetadataSettings>();

        for (
            TriggerObject__mdt triggerObject : (List<TriggerObject__mdt>) SOQL.of(TriggerObject__mdt.SObjectType)
                .with(TriggerObject__mdt.ObjectAPIName__c, TriggerObject__mdt.Bypass__c)
                .with(SOQL.SubQuery.of('TriggerHandlers__r').with(TriggerHandler__mdt.ApexClassName__c, TriggerHandler__mdt.Bypass__c))
                .systemMode()
                .toList()
        ) {
            metadataSettingsByObjectName.put(triggerObject.ObjectAPIName__c.trim().toLowerCase(), new MetadataSettings(triggerObject));
        }

        return metadataSettingsByObjectName;
    }

    private abstract class ExecutionStrategy {
        protected TriggerOrchestrator orchestrator;

        protected List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();
        protected List<TriggerHandlerAdapter> activeHandlers = new List<TriggerHandlerAdapter>();
        protected List<TriggerHandler.TriggerRecord> triggerRecords = new List<TriggerHandler.TriggerRecord>();
        protected ParentRelationshipEnrichment parentRelationshipEnrichment;

        public void execute(TriggerOrchestrator orchestrator) {
            this.orchestrator = orchestrator;

            this.registerRecords();
            this.adaptHandlers();
            this.registerOrchestratorOnHandlerAdapters();

            this.filterBypassedHandlers();
            this.declareParentRelationships();

            this.runHandlers();
        }

        protected abstract void adaptHandlers();

        private void registerRecords() {
            List<SObject> newRecords = this.orchestrator.triggerNewRecords;
            List<SObject> oldRecords = this.orchestrator.triggerOldRecords;

            Integer recordCount = (newRecords ?? oldRecords).size();

            for (Integer i = 0; i < recordCount; i++) {
                this.triggerRecords.add(new TriggerHandler.TriggerRecord(newRecords?.get(i), oldRecords?.get(i)));
            }
        }

        private void registerOrchestratorOnHandlerAdapters() {
            for (TriggerHandlerAdapter adapter : this.handlerAdapters) {
                adapter.registerContext(this.orchestrator);
            }
        }

        private void filterBypassedHandlers() {
            for (TriggerHandlerAdapter adapter : this.handlerAdapters) {
                if (adapter instanceof Bypassable && ((Bypassable) adapter).isBypassed()) {
                    continue;
                }

                this.activeHandlers.add(adapter);
            }
        }

        private void declareParentRelationships() {
            this.parentRelationshipEnrichment = new ParentRelationshipEnrichment(this.orchestrator.triggerOperation);
            this.parentRelationshipEnrichment.declareParentFields(this.activeHandlers);
        }

        private void logError(Exception e, TriggerHandlerAdapter adapter) {
            if (TriggerOrchestrator.logger == null) {
                return;
            }

            Set<Id> recordIds = new Set<Id>();

            for (SObject record : this.orchestrator.triggerNewRecords ?? this.orchestrator.triggerOldRecords) {
                if (record.Id != null) {
                    recordIds.add(record.Id);
                }
            }

            TriggerError error = new TriggerError();

            error.triggerException = e;
            error.handlerName = adapter.handlerName;
            error.operation = this.orchestrator.triggerOperation;
            error.sObjectType = this.orchestrator.sObjectType;
            error.recordIds = recordIds;

            TriggerOrchestrator.logger.log(error);
        }

        private void runHandlers() {
            List<TriggerHandler.TriggerRecord> recordsToEnrich = this.triggerRecords;

            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                this.parentRelationshipEnrichment.enrich(recordsToEnrich);

                try {
                    adapter.execute(this.triggerRecords);
                } catch (Exception e) {
                    this.logError(e, adapter);

                    if (
                        e instanceof TriggerOrchestratorException ||
                        e instanceof TriggerHandler.TriggerHandlerException ||
                        !(adapter instanceof ContinueOnError) ||
                        !((ContinueOnError) adapter).continuesOnError()
                    ) {
                        throw e;
                    }
                }

                recordsToEnrich = adapter.getProcessedRecords();
            }
        }
    }

    private class BeforeInsertExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) this.orchestrator.orchestrator).beforeInsertHandlers()) {
                if (handler instanceof BeforeInsert.Populator && handler instanceof BeforeInsert.Validator) {
                    throw new TriggerOrchestratorException(
                        handler.toString().substringBefore(':') +
                        ' implements both BeforeInsert.Populator and BeforeInsert.Validator. A class can implement only one main interface per context.'
                    );
                }

                if (handler instanceof BeforeInsert.Populator) {
                    this.handlerAdapters.add(new BeforeInsertPopulatorHandlerAdapter((BeforeInsert.Populator) handler));
                }

                if (handler instanceof BeforeInsert.Validator) {
                    this.handlerAdapters.add(new BeforeInsertValidatorHandlerAdapter((BeforeInsert.Validator) handler));
                }

                if (!(handler instanceof BeforeInsert.Populator) && !(handler instanceof BeforeInsert.Validator)) {
                    throw new TriggerOrchestratorException(
                        handler.toString().substringBefore(':') +
                        ' implements neither BeforeInsert.Populator nor BeforeInsert.Validator. A class must implement one main interface per context.'
                    );
                }
            }
        }
    }

    private class AfterInsertExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) this.orchestrator.orchestrator).afterInsertHandlers()) {
                this.handlerAdapters.add(new AfterInsertHandlerAdapter(handler));
            }
        }
    }

    private class BeforeUpdateExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) this.orchestrator.orchestrator).beforeUpdateHandlers()) {
                if (handler instanceof BeforeUpdate.Populator && handler instanceof BeforeUpdate.Validator) {
                    throw new TriggerOrchestratorException(
                        handler.toString().substringBefore(':') +
                        ' implements both BeforeUpdate.Populator and BeforeUpdate.Validator. A class can implement only one main interface per context.'
                    );
                }

                if (handler instanceof BeforeUpdate.Populator) {
                    this.handlerAdapters.add(new BeforeUpdatePopulatorHandlerAdapter((BeforeUpdate.Populator) handler));
                }

                if (handler instanceof BeforeUpdate.Validator) {
                    this.handlerAdapters.add(new BeforeUpdateValidatorHandlerAdapter((BeforeUpdate.Validator) handler));
                }

                if (!(handler instanceof BeforeUpdate.Populator) && !(handler instanceof BeforeUpdate.Validator)) {
                    throw new TriggerOrchestratorException(
                        handler.toString().substringBefore(':') +
                        ' implements neither BeforeUpdate.Populator nor BeforeUpdate.Validator. A class must implement one main interface per context.'
                    );
                }
            }
        }
    }

    private class AfterUpdateExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) this.orchestrator.orchestrator).afterUpdateHandlers()) {
                this.handlerAdapters.add(new AfterUpdateHandlerAdapter(handler));
            }
        }
    }

    private class BeforeDeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) this.orchestrator.orchestrator).beforeDeleteHandlers()) {
                this.handlerAdapters.add(new BeforeDeleteHandlerAdapter(handler));
            }
        }
    }

    private class AfterDeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) this.orchestrator.orchestrator).afterDeleteHandlers()) {
                this.handlerAdapters.add(new AfterDeleteHandlerAdapter(handler));
            }
        }
    }

    private class AfterUndeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) this.orchestrator.orchestrator).afterUndeleteHandlers()) {
                this.handlerAdapters.add(new AfterUndeleteHandlerAdapter(handler));
            }
        }
    }

    @TestVisible
    private class MetadataSettings {
        public TriggerObject__mdt sObjectSetting = new TriggerObject__mdt();
        public Map<String, TriggerHandler__mdt> settingByHandlerName = new Map<String, TriggerHandler__mdt>();

        public MetadataSettings(TriggerObject__mdt triggerObject) {
            this.sObjectSetting = triggerObject;

            for (TriggerHandler__mdt triggerHandler : triggerObject.TriggerHandlers__r ?? new List<TriggerHandler__mdt>()) {
                String handlerName = triggerHandler.ApexClassName__c.trim().toLowerCase();

                this.settingByHandlerName.put(handlerName, triggerHandler);

                if (handlerName.contains('.')) {
                    this.settingByHandlerName.put(handlerName.substringAfterLast('.'), triggerHandler);
                }
            }
        }

        public Boolean isHandlerBypassed(Object handler) {
            return this.settingByHandlerName.get(handler.toString().substringBefore(':').toLowerCase())?.Bypass__c == true;
        }
    }

    private class TriggerError implements Error {
        public String handlerName;
        public SObjectType sObjectType;
        public System.Exception triggerException;
        public System.TriggerOperation operation;
        public Set<Id> recordIds;

        public Exception getException() {
            return this.triggerException;
        }

        public String getHandlerName() {
            return this.handlerName;
        }

        public System.TriggerOperation getOperation() {
            return this.operation;
        }

        public SObjectType getSObjectType() {
            return this.sObjectType;
        }

        public Set<Id> getRecordIds() {
            return this.recordIds;
        }
    }

    private interface Bypassable {
        Boolean isBypassed();
    }

    private interface ContinueOnError {
        Boolean continuesOnError();
    }

    private interface Finalizer {
        void finalizeHandler();
    }

    private interface RecursionGuarded {
        Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record);
        void registerRecord(TriggerHandler.TriggerRecord record);
    }

    private interface NewRecordEnricher {
        Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich();
    }

    private interface OldRecordEnricher {
        Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich();
    }

    private abstract class TriggerHandlerAdapter {
        public String handlerName;

        protected Object handler;
        protected TriggerOrchestrator orchestrator;
        protected List<TriggerHandler.TriggerRecord> processedRecords = new List<TriggerHandler.TriggerRecord>();

        public TriggerHandlerAdapter(Object handler) {
            this.handler = handler;
            this.handlerName = handler.toString().substringBefore(':');
        }

        public void registerContext(TriggerOrchestrator orchestrator) {
            this.orchestrator = orchestrator;
        }

        public virtual void execute(List<TriggerHandler.TriggerRecord> records) {
            for (TriggerHandler.TriggerRecord record : records) {
                if (this.isRecursionGuarded() && ((RecursionGuarded) this).isRecursionDepthExceeded(record)) {
                    continue;
                }

                if (!this.isQualified(record)) {
                    continue;
                }

                if (this.isRecursionGuarded()) {
                    ((RecursionGuarded) this).registerRecord(record);
                }

                this.processedRecords.add(record);

                this.executeOn(record);
            }

            if (!this.processedRecords.isEmpty() && this.isFinalizer()) {
                ((Finalizer) this).finalizeHandler();
            }
        }

        private Boolean isRecursionGuarded() {
            return this instanceof RecursionGuarded;
        }

        private Boolean isFinalizer() {
            return this instanceof Finalizer;
        }

        public List<TriggerHandler.TriggerRecord> getProcessedRecords() {
            return this.processedRecords;
        }

        protected abstract Boolean isQualified(TriggerHandler.TriggerRecord record);
        protected abstract void executeOn(TriggerHandler.TriggerRecord record);
    }

    private class BeforeInsertPopulatorHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher {
        public BeforeInsertPopulatorHandlerAdapter(BeforeInsert.Populator populator) {
            super(populator);
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                super.execute(records);
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof BeforeInsert.Bypassable) {
                return ((BeforeInsert.Bypassable) this.handler).bypassOnBeforeInsertWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeInsert.NewRecordEnrichment) {
                return ((BeforeInsert.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeInsert.Populator) this.handler).populateOnBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeInsert.Populator) this.handler).populateOnBeforeInsert(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof BeforeInsert.Finalizer) {
                ((BeforeInsert.Finalizer) this.handler).finalizeBeforeInsert();
            }
        }
    }

    private class BeforeInsertValidatorHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher {
        public BeforeInsertValidatorHandlerAdapter(BeforeInsert.Validator validator) {
            super(validator);
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                super.execute(records);
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof BeforeInsert.Bypassable) {
                return ((BeforeInsert.Bypassable) this.handler).bypassOnBeforeInsertWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeInsert.NewRecordEnrichment) {
                return ((BeforeInsert.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeInsert.Validator) this.handler).errorShouldBeAttachedOnBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            record.getNewSObject().addError(((BeforeInsert.Validator) this.handler).beforeInsertValidationMessage(record));
        }

        public void finalizeHandler() {
            if (this.handler instanceof BeforeInsert.Finalizer) {
                ((BeforeInsert.Finalizer) this.handler).finalizeBeforeInsert();
            }
        }
    }

    private class AfterInsertHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher {
        public AfterInsertHandlerAdapter(AfterInsert.Handler handler) {
            super(handler);
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof AfterInsert.Bypassable) {
                return ((AfterInsert.Bypassable) this.handler).bypassOnAfterInsertWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof AfterInsert.NewRecordEnrichment) {
                return ((AfterInsert.NewRecordEnrichment) this.handler).newFieldsToEnrichOnAfterInsert();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof AfterInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterInsert.Handler) this.handler).qualifiesForAfterInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterInsert.Handler) this.handler).onAfterInsert(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof AfterInsert.Finalizer) {
                ((AfterInsert.Finalizer) this.handler).finalizeAfterInsert();
            }
        }
    }

    private class BeforeUpdatePopulatorHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher, OldRecordEnricher, RecursionGuarded {
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth;

        public BeforeUpdatePopulatorHandlerAdapter(BeforeUpdate.Populator populator) {
            super(populator);
            String recursionScope = this.handlerName + ':BEFORE_UPDATE';

            if (!TriggerOrchestrator.recursionDepthByRecordByHandler.containsKey(recursionScope)) {
                TriggerOrchestrator.recursionDepthByRecordByHandler.put(recursionScope, new Map<Id, Integer>());
            }

            this.recursionDepthByRecord = TriggerOrchestrator.recursionDepthByRecordByHandler.get(recursionScope);
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                super.execute(records);
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof BeforeUpdate.Bypassable) {
                return ((BeforeUpdate.Bypassable) this.handler).bypassOnBeforeUpdateWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeUpdate.NewRecordEnrichment) {
                return ((BeforeUpdate.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof BeforeUpdate.OldRecordEnrichment) {
                return ((BeforeUpdate.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }

        public Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            if (this.maxRecursionDepth == null) {
                this.maxRecursionDepth = 3;

                if (this.orchestrator.orchestrator instanceof TriggerOrchestrator.RecursionGuard) {
                    this.maxRecursionDepth = ((TriggerOrchestrator.RecursionGuard) this.orchestrator.orchestrator).maxRecursionDepth();

                    if (this.maxRecursionDepth == null || this.maxRecursionDepth < 1) {
                        throw new TriggerOrchestratorException(
                            this.orchestrator.toString().substringBefore(':') +
                                ' returned a recursion depth of ' +
                                this.maxRecursionDepth +
                                ' from maxRecursionDepth(). The minimum is 1, meaning the handler runs once per record.'
                        );
                    }
                }

                if (this.handler instanceof BeforeUpdate.RecursionGuard) {
                    this.maxRecursionDepth = ((BeforeUpdate.RecursionGuard) this.handler).maxRecursionDepthOnBeforeUpdate();

                    if (this.maxRecursionDepth == null || this.maxRecursionDepth < 1) {
                        throw new TriggerOrchestratorException(
                            this.handlerName +
                                ' returned a recursion depth of ' +
                                this.maxRecursionDepth +
                                ' from maxRecursionDepthOnBeforeUpdate(). The minimum is 1, meaning the handler runs once per record.'
                        );
                    }
                }
            }

            return (this.recursionDepthByRecord.get(record.getId()) ?? 0) >= this.maxRecursionDepth;
        }

        public void registerRecord(TriggerHandler.TriggerRecord record) {
            this.recursionDepthByRecord.put(record.getId(), (this.recursionDepthByRecord.get(record.getId()) ?? 0) + 1);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeUpdate.Populator) this.handler).populateOnBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeUpdate.Populator) this.handler).populateOnBeforeUpdate(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof BeforeUpdate.Finalizer) {
                ((BeforeUpdate.Finalizer) this.handler).finalizeBeforeUpdate();
            }
        }
    }

    private class BeforeUpdateValidatorHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher, OldRecordEnricher {
        public BeforeUpdateValidatorHandlerAdapter(BeforeUpdate.Validator validator) {
            super(validator);
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                super.execute(records);
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof BeforeUpdate.Bypassable) {
                return ((BeforeUpdate.Bypassable) this.handler).bypassOnBeforeUpdateWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeUpdate.NewRecordEnrichment) {
                return ((BeforeUpdate.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof BeforeUpdate.OldRecordEnrichment) {
                return ((BeforeUpdate.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeUpdate.Validator) this.handler).errorShouldBeAttachedOnBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            record.getNewSObject().addError(((BeforeUpdate.Validator) this.handler).beforeUpdateValidationMessage(record));
        }

        public void finalizeHandler() {
            if (this.handler instanceof BeforeUpdate.Finalizer) {
                ((BeforeUpdate.Finalizer) this.handler).finalizeBeforeUpdate();
            }
        }
    }

    private class AfterUpdateHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher, OldRecordEnricher, RecursionGuarded {
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth;

        public AfterUpdateHandlerAdapter(AfterUpdate.Handler handler) {
            super(handler);
            String recursionScope = this.handlerName + ':AFTER_UPDATE';

            if (!TriggerOrchestrator.recursionDepthByRecordByHandler.containsKey(recursionScope)) {
                TriggerOrchestrator.recursionDepthByRecordByHandler.put(recursionScope, new Map<Id, Integer>());
            }

            this.recursionDepthByRecord = TriggerOrchestrator.recursionDepthByRecordByHandler.get(recursionScope);
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof AfterUpdate.Bypassable) {
                return ((AfterUpdate.Bypassable) this.handler).bypassOnAfterUpdateWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof AfterUpdate.NewRecordEnrichment) {
                return ((AfterUpdate.NewRecordEnrichment) this.handler).newFieldsToEnrichOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof AfterUpdate.OldRecordEnrichment) {
                return ((AfterUpdate.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            if (this.maxRecursionDepth == null) {
                this.maxRecursionDepth = 3;

                if (this.orchestrator.orchestrator instanceof TriggerOrchestrator.RecursionGuard) {
                    this.maxRecursionDepth = ((TriggerOrchestrator.RecursionGuard) this.orchestrator.orchestrator).maxRecursionDepth();

                    if (this.maxRecursionDepth == null || this.maxRecursionDepth < 1) {
                        throw new TriggerOrchestratorException(
                            this.orchestrator.toString().substringBefore(':') +
                                ' returned a recursion depth of ' +
                                this.maxRecursionDepth +
                                ' from maxRecursionDepth(). The minimum is 1, meaning the handler runs once per record.'
                        );
                    }
                }

                if (this.handler instanceof AfterUpdate.RecursionGuard) {
                    this.maxRecursionDepth = ((AfterUpdate.RecursionGuard) this.handler).maxRecursionDepthOnAfterUpdate();

                    if (this.maxRecursionDepth == null || this.maxRecursionDepth < 1) {
                        throw new TriggerOrchestratorException(
                            this.handlerName +
                                ' returned a recursion depth of ' +
                                this.maxRecursionDepth +
                                ' from maxRecursionDepthOnAfterUpdate(). The minimum is 1, meaning the handler runs once per record.'
                        );
                    }
                }
            }

            return (this.recursionDepthByRecord.get(record.getId()) ?? 0) >= this.maxRecursionDepth;
        }

        public void registerRecord(TriggerHandler.TriggerRecord record) {
            this.recursionDepthByRecord.put(record.getId(), (this.recursionDepthByRecord.get(record.getId()) ?? 0) + 1);
        }

        public Boolean continuesOnError() {
            return this.handler instanceof AfterUpdate.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterUpdate.Handler) this.handler).qualifiesForAfterUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterUpdate.Handler) this.handler).onAfterUpdate(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof AfterUpdate.Finalizer) {
                ((AfterUpdate.Finalizer) this.handler).finalizeAfterUpdate();
            }
        }
    }

    private class BeforeDeleteHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, OldRecordEnricher {
        public BeforeDeleteHandlerAdapter(BeforeDelete.Handler handler) {
            super(handler);
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof BeforeDelete.Bypassable) {
                return ((BeforeDelete.Bypassable) this.handler).bypassOnBeforeDeleteWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof BeforeDelete.OldRecordEnrichment) {
                return ((BeforeDelete.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnBeforeDelete();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof BeforeDelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeDelete.Handler) this.handler).qualifiesForBeforeDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeDelete.Handler) this.handler).onBeforeDelete(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof BeforeDelete.Finalizer) {
                ((BeforeDelete.Finalizer) this.handler).finalizeBeforeDelete();
            }
        }
    }

    private class AfterDeleteHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, OldRecordEnricher {
        public AfterDeleteHandlerAdapter(AfterDelete.Handler handler) {
            super(handler);
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof AfterDelete.Bypassable) {
                return ((AfterDelete.Bypassable) this.handler).bypassOnAfterDeleteWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof AfterDelete.OldRecordEnrichment) {
                return ((AfterDelete.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnAfterDelete();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof AfterDelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterDelete.Handler) this.handler).qualifiesForAfterDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterDelete.Handler) this.handler).onAfterDelete(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof AfterDelete.Finalizer) {
                ((AfterDelete.Finalizer) this.handler).finalizeAfterDelete();
            }
        }
    }

    private class AfterUndeleteHandlerAdapter extends TriggerHandlerAdapter implements Bypassable, ContinueOnError, Finalizer, NewRecordEnricher {
        public AfterUndeleteHandlerAdapter(AfterUndelete.Handler handler) {
            super(handler);
        }

        public Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler, this.orchestrator.sObjectType)) {
                return true;
            }

            if (this.handler instanceof AfterUndelete.Bypassable) {
                return ((AfterUndelete.Bypassable) this.handler).bypassOnAfterUndeleteWhen();
            }

            return false;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof AfterUndelete.NewRecordEnrichment) {
                return ((AfterUndelete.NewRecordEnrichment) this.handler).newFieldsToEnrichOnAfterUndelete();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public Boolean continuesOnError() {
            return this.handler instanceof AfterUndelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterUndelete.Handler) this.handler).qualifiesForAfterUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterUndelete.Handler) this.handler).onAfterUndelete(record);
        }

        public void finalizeHandler() {
            if (this.handler instanceof AfterUndelete.Finalizer) {
                ((AfterUndelete.Finalizer) this.handler).finalizeAfterUndelete();
            }
        }
    }

    private class ParentRelationshipEnrichment {
        private Set<SObjectField> newRecordFieldsToEnrich = new Set<SObjectField>();
        private Set<SObjectField> oldRecordFieldsToEnrich = new Set<SObjectField>();
        private Map<SObjectField, Set<String>> selectedFieldsByParentField = new Map<SObjectField, Set<String>>();

        private Map<SObjectField, Map<Id, SObject>> cachedParentByIdByParentField = new Map<SObjectField, Map<Id, SObject>>();
        private Map<SObjectField, Map<String, Id>> enrichedNewIdByRecordByParentField = new Map<SObjectField, Map<String, Id>>();

        private Boolean isResolved = false;
        private Boolean isRecordMutable;

        public ParentRelationshipEnrichment(System.TriggerOperation triggerOperation) {
            this.isRecordMutable = triggerOperation == System.TriggerOperation.BEFORE_INSERT || triggerOperation == System.TriggerOperation.BEFORE_UPDATE;
        }

        public void declareParentFields(List<TriggerHandlerAdapter> adapters) {
            for (TriggerHandlerAdapter adapter : adapters) {
                if (adapter instanceof NewRecordEnricher) {
                    this.declare(((NewRecordEnricher) adapter).getNewFieldsToEnrich(), this.newRecordFieldsToEnrich);
                }

                if (adapter instanceof OldRecordEnricher) {
                    this.declare(((OldRecordEnricher) adapter).getOldFieldsToEnrich(), this.oldRecordFieldsToEnrich);
                }
            }
        }

        private void declare(Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich, Set<SObjectField> recordFieldsToEnrich) {
            for (SObjectField parentField : fieldsToEnrich.keySet()) {
                recordFieldsToEnrich.add(parentField);

                if (!this.selectedFieldsByParentField.containsKey(parentField)) {
                    this.selectedFieldsByParentField.put(parentField, new Set<String>());
                    this.cachedParentByIdByParentField.put(parentField, new Map<Id, SObject>());
                    this.enrichedNewIdByRecordByParentField.put(parentField, new Map<String, Id>());
                }

                this.selectedFieldsByParentField.get(parentField).addAll(fieldsToEnrich.get(parentField).getFields());
            }
        }

        public void enrich(List<TriggerHandler.TriggerRecord> recordsToEnrich) {
            if (this.isResolved && (!this.isRecordMutable || recordsToEnrich.isEmpty())) {
                return;
            }

            for (SObjectField parentField : this.selectedFieldsByParentField.keySet()) {
                this.enrichParentField(parentField, recordsToEnrich);
            }

            this.isResolved = true;
        }

        private void enrichParentField(SObjectField parentField, List<TriggerHandler.TriggerRecord> recordsToScan) {
            Map<Id, SObject> cachedParentById = this.cachedParentByIdByParentField.get(parentField);
            Map<String, Id> enrichedNewIdByRecord = this.enrichedNewIdByRecordByParentField.get(parentField);

            Boolean enrichNewSide = this.newRecordFieldsToEnrich.contains(parentField);
            Boolean enrichOldSide = !this.isResolved && this.oldRecordFieldsToEnrich.contains(parentField);

            Map<String, Id> staleNewIdByRecord = new Map<String, Id>();
            Set<Id> parentIdsToQuery = new Set<Id>();

            if (enrichNewSide) {
                for (TriggerHandler.TriggerRecord record : recordsToScan) {
                    Id parentId = record.getNewSObject()?.isSet(parentField) == true ? (Id) record.getNewSObject().get(parentField) : null;

                    if (enrichedNewIdByRecord.get(record.getIdentifier()) == parentId) {
                        continue;
                    }

                    staleNewIdByRecord.put(record.getIdentifier(), parentId);

                    if (parentId != null && !cachedParentById.containsKey(parentId)) {
                        parentIdsToQuery.add(parentId);
                    }
                }
            }

            if (enrichOldSide) {
                for (TriggerHandler.TriggerRecord record : recordsToScan) {
                    Id parentId = record.getOldSObject()?.isSet(parentField) == true ? (Id) record.getOldSObject().get(parentField) : null;

                    if (parentId != null && !cachedParentById.containsKey(parentId)) {
                        parentIdsToQuery.add(parentId);
                    }
                }
            }

            if (staleNewIdByRecord.isEmpty() && !enrichOldSide) {
                return;
            }

            if (!parentIdsToQuery.isEmpty()) {
                Map<Id, SObject> queriedParentById = SOQL.of(parentField.getDescribe().getReferenceTo()[0])
                    .with(new List<String>(this.selectedFieldsByParentField.get(parentField)))
                    .byIds(parentIdsToQuery)
                    .systemMode()
                    .withoutSharing()
                    .toMap();

                for (Id parentId : parentIdsToQuery) {
                    cachedParentById.put(parentId, queriedParentById.get(parentId));
                }
            }

            String relationshipName = parentField.getDescribe().getRelationshipName();

            for (TriggerHandler.TriggerRecord record : recordsToScan) {
                if (staleNewIdByRecord.containsKey(record.getIdentifier())) {
                    record.enrichNew(relationshipName, cachedParentById.get(staleNewIdByRecord.get(record.getIdentifier())));
                    enrichedNewIdByRecord.put(record.getIdentifier(), staleNewIdByRecord.get(record.getIdentifier()));
                }

                if (enrichOldSide) {
                    record.enrichOld(
                        relationshipName,
                        cachedParentById.get(record.getOldSObject()?.isSet(parentField) == true ? (Id) record.getOldSObject().get(parentField) : null)
                    );
                }
            }
        }
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
