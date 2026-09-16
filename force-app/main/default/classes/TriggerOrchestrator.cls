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
    private static TriggerSettings TriggerSettings = new TriggerSettings();
    private static TransactionState TransactionState = new TransactionState();

    @TestVisible
    private TriggerContext context;
    private Object orchestrator;

    private TriggerOrchestrator(Object orchestrator) {
        this.orchestrator = orchestrator;
        this.context = new TriggerContext();
    }

    @TestVisible
    private void run() {
        ExecutionStrategy executionStrategy;

        try {
            if (this.context.triggerOperation == null) {
                throw new TriggerOrchestratorException('Called outside of a trigger context, or the trigger operation is not supported.');
            }

            if (TriggerOrchestrator.TriggerSettings.isSObjectTriggerBypassedInMetadata(this.context)) {
                return;
            }

            if (this.context.triggerOperation == System.TriggerOperation.BEFORE_INSERT && this.orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                executionStrategy = new BeforeInsertExecutionStrategy();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_INSERT && this.orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                executionStrategy = new AfterInsertExecutionStrategy();
            } else if (this.context.triggerOperation == System.TriggerOperation.BEFORE_UPDATE && this.orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                executionStrategy = new BeforeUpdateExecutionStrategy();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_UPDATE && this.orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                executionStrategy = new AfterUpdateExecutionStrategy();
            } else if (this.context.triggerOperation == System.TriggerOperation.BEFORE_DELETE && this.orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                executionStrategy = new BeforeDeleteExecutionStrategy();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_DELETE && this.orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                executionStrategy = new AfterDeleteExecutionStrategy();
            } else if (this.context.triggerOperation == System.TriggerOperation.AFTER_UNDELETE && this.orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                executionStrategy = new AfterUndeleteExecutionStrategy();
            } else {
                return;
            }

            TriggerOrchestrator.TransactionState.executionStack.add(executionStrategy);

            executionStrategy.execute(this);
        } finally {
            this.finalizeTransactionChunk(executionStrategy);
        }
    }

    private void finalizeTransactionChunk(ExecutionStrategy executionStrategy) {
        if (executionStrategy == null) {
            return;
        }

        TriggerOrchestrator.TransactionState.executionStack.remove(TriggerOrchestrator.TransactionState.executionStack.size() - 1);

        if (TriggerOrchestrator.TransactionState.executionStack.isEmpty()) {
            TriggerOrchestrator.TriggerSettings.logger?.finalize();
        }
    }

    private class TriggerContext {
        public System.TriggerOperation triggerOperation = Trigger.operationType;
        public List<SObject> triggerNewRecords = Trigger.new;
        public List<SObject> triggerOldRecords = Trigger.old;
        public SObjectType sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
        public Integer recordsCount = (Trigger.new ?? Trigger.old).size();
        public String sObjectTypeName = (Trigger.new ?? Trigger.old)?.getSObjectType().toString().toLowerCase();
    }

    private class TransactionState {
        public Map<String, Map<Id, Integer>> recursionDepthByRecordByHandler = new Map<String, Map<Id, Integer>>();
        public List<ExecutionStrategy> executionStack = new List<ExecutionStrategy>();
    }

    private class TriggerSettings {
        public Logger logger = this.resolveLogger();
        public Map<String, MetadataSettings> metadataSettingsByObjectName = this.resolveMetadataSettings();

        public Boolean isSObjectTriggerBypassedInMetadata(TriggerContext context) {
            return this.metadataSettingsByObjectName.get(context.sObjectTypeName)?.sObjectSetting.Bypass__c == true;
        }

        public Boolean isHandlerBypassedInMetadata(TriggerContext context, Object handler) {
            String handlerClassName = handler.toString().substringBefore(':').toLowerCase();
            return this.metadataSettingsByObjectName.get(context.sObjectTypeName)?.settingByHandlerName.get(handlerClassName)?.Bypass__c == true;
        }

        private Logger resolveLogger() {
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

        private Map<String, MetadataSettings> resolveMetadataSettings() {
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
    }

    private abstract class ExecutionStrategy {
        protected List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();
        protected List<TriggerHandlerAdapter> activeHandlers = new List<TriggerHandlerAdapter>();
        protected List<TriggerHandler.TriggerRecord> triggerRecords = new List<TriggerHandler.TriggerRecord>();
        protected ParentRelationshipEnrichment parentRelationshipEnrichment;

        private TriggerContext context;

        public void execute(TriggerOrchestrator orchestrator) {
            this.context = orchestrator.context;

            this.enhanceRecords();
            this.adaptHandlers(orchestrator);
            this.getActiveHandlers();
            this.declareParentRelationships();
            this.runHandlers();
        }

        protected abstract void adaptHandlers(TriggerOrchestrator orchestrator);

        private void enhanceRecords() {
            for (Integer i = 0; i < this.context.recordsCount; i++) {
                this.triggerRecords.add(new TriggerHandler.TriggerRecord(this.context.triggerNewRecords?.get(i), this.context.triggerOldRecords?.get(i)));
            }
        }

        private void getActiveHandlers() {
            for (TriggerHandlerAdapter adapter : this.handlerAdapters) {
                if (!adapter.isBypassed()) {
                    this.activeHandlers.add(adapter);
                }
            }
        }

        private void declareParentRelationships() {
            this.parentRelationshipEnrichment = new ParentRelationshipEnrichment(this.context.triggerOperation);
            this.parentRelationshipEnrichment.declareParentFields(this.activeHandlers);
        }

        private void runHandlers() {
            List<TriggerHandler.TriggerRecord> recordsToEnrich = this.triggerRecords;

            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                this.parentRelationshipEnrichment.enrich(recordsToEnrich);

                try {
                    adapter.execute(this.triggerRecords);
                } catch (TriggerOrchestratorException e) {
                    adapter.logError(e);
                    throw e;
                } catch (TriggerHandler.TriggerHandlerException e) {
                    adapter.logError(e);
                    throw e;
                } catch (Exception e) {
                    adapter.logError(e);

                    if (!adapter.continuesOnError()) {
                        throw e;
                    }
                }

                recordsToEnrich = adapter.getProcessedRecords();
            }
        }
    }

    private class BeforeInsertExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) orchestrator.orchestrator).beforeInsertHandlers()) {
                if (handler instanceof BeforeInsert.Populator) {
                    this.handlerAdapters.add(new BeforeInsertPopulatorHandlerAdapter((BeforeInsert.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeInsert.Validator) {
                    this.handlerAdapters.add(new BeforeInsertValidatorHandlerAdapter((BeforeInsert.Validator) handler, orchestrator));
                }
            }
        }
    }

    private class AfterInsertExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) orchestrator.orchestrator).afterInsertHandlers()) {
                this.handlerAdapters.add(new AfterInsertHandlerAdapter(handler, orchestrator));
            }
        }
    }

    private class BeforeUpdateExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator.orchestrator).beforeUpdateHandlers()) {
                if (handler instanceof BeforeUpdate.Populator) {
                    this.handlerAdapters.add(new BeforeUpdatePopulatorHandlerAdapter((BeforeUpdate.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeUpdate.Validator) {
                    this.handlerAdapters.add(new BeforeUpdateValidatorHandlerAdapter((BeforeUpdate.Validator) handler, orchestrator));
                }
            }
        }
    }

    private class AfterUpdateExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) orchestrator.orchestrator).afterUpdateHandlers()) {
                this.handlerAdapters.add(new AfterUpdateHandlerAdapter(handler, orchestrator));
            }
        }
    }

    private class BeforeDeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) orchestrator.orchestrator).beforeDeleteHandlers()) {
                this.handlerAdapters.add(new BeforeDeleteHandlerAdapter(handler, orchestrator));
            }
        }
    }

    private class AfterDeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) orchestrator.orchestrator).afterDeleteHandlers()) {
                this.handlerAdapters.add(new AfterDeleteHandlerAdapter(handler, orchestrator));
            }
        }
    }

    private class AfterUndeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers(TriggerOrchestrator orchestrator) {
            for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) orchestrator.orchestrator).afterUndeleteHandlers()) {
                this.handlerAdapters.add(new AfterUndeleteHandlerAdapter(handler, orchestrator));
            }
        }
    }

    @TestVisible
    private class MetadataSettings {
        public TriggerObject__mdt sObjectSetting = new TriggerObject__mdt();
        public Map<String, TriggerHandler__mdt> settingByHandlerName = new Map<String, TriggerHandler__mdt>();

        public MetadataSettings(TriggerObject__mdt triggerObject) {
            this.sObjectSetting = triggerObject;
            this.addHandlerSettings();
        }

        private void addHandlerSettings() {
            for (TriggerHandler__mdt triggerHandler : this.sObjectSetting.TriggerHandlers__r ?? new List<TriggerHandler__mdt>()) {
                this.addHandlerSetting(triggerHandler);
            }
        }

        private void addHandlerSetting(TriggerHandler__mdt triggerHandler) {
            String handlerName = triggerHandler.ApexClassName__c.trim().toLowerCase();

            this.settingByHandlerName.put(handlerName, triggerHandler);

            if (handlerName.contains('.')) {
                this.settingByHandlerName.put(handlerName.substringAfterLast('.'), triggerHandler);
            }
        }
    }

    private class TriggerError implements Error {
        public String handlerName;
        public SObjectType sObjectType;
        public System.Exception triggerException;
        public System.TriggerOperation operation;
        public Set<Id> recordIds = new Set<Id>();

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

        public TriggerError withException(System.Exception error) {
            this.triggerException = error;
            return this;
        }

        public TriggerError withHandlerName(String handlerName) {
            this.handlerName = handlerName;
            return this;
        }

        public TriggerError withContext(TriggerContext context) {
            this.sObjectType = context.sObjectType;
            this.operation = context.triggerOperation;
            this.setRecordIds(context);
            return this;
        }

        private void setRecordIds(TriggerContext context) {
            for (SObject record : context.triggerNewRecords ?? context.triggerOldRecords) {
                if (record.Id != null) {
                    this.recordIds.add(record.Id);
                }
            }
        }
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

        public TriggerHandlerAdapter(Object handler, TriggerOrchestrator orchestrator) {
            this.handler = handler;
            this.orchestrator = orchestrator;
            this.handlerName = handler.toString().substringBefore(':');
        }

        public virtual void execute(List<TriggerHandler.TriggerRecord> records) {
            for (TriggerHandler.TriggerRecord record : records) {
                if (this.isRecursionDepthExceeded(record)) {
                    continue;
                }

                if (!this.isQualified(record)) {
                    continue;
                }

                this.registerRecord(record);

                this.processedRecords.add(record);

                this.executeOn(record);
            }

            if (!this.processedRecords.isEmpty()) {
                this.finalizeHandler();
            }
        }

        public List<TriggerHandler.TriggerRecord> getProcessedRecords() {
            return this.processedRecords;
        }

        public void logError(Exception e) {
            TriggerOrchestrator.TriggerSettings.logger?.log(new TriggerError().withException(e).withHandlerName(this.handlerName).withContext(this.orchestrator.context));
        }

        protected virtual Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            return false;
        }

        protected virtual void registerRecord(TriggerHandler.TriggerRecord record) {
        }

        public abstract Boolean isBypassed();
        public abstract Boolean continuesOnError();

        protected abstract void finalizeHandler();
        protected abstract Boolean isQualified(TriggerHandler.TriggerRecord record);
        protected abstract void executeOn(TriggerHandler.TriggerRecord record);
    }

    private class BeforeInsertPopulatorHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        public BeforeInsertPopulatorHandlerAdapter(BeforeInsert.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);
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

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeInsert.Populator) this.handler).populateOnBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeInsert.Populator) this.handler).populateOnBeforeInsert(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof BeforeInsert.Finalizer) {
                ((BeforeInsert.Finalizer) this.handler).finalizeBeforeInsert();
            }
        }
    }

    private class BeforeInsertValidatorHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        public BeforeInsertValidatorHandlerAdapter(BeforeInsert.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);
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

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeInsert.Validator) this.handler).errorShouldBeAttachedOnBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            record.getNewSObject().addError(((BeforeInsert.Validator) this.handler).beforeInsertValidationMessage(record));
        }

        public override void finalizeHandler() {
            if (this.handler instanceof BeforeInsert.Finalizer) {
                ((BeforeInsert.Finalizer) this.handler).finalizeBeforeInsert();
            }
        }
    }

    private class AfterInsertHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        public AfterInsertHandlerAdapter(AfterInsert.Handler handler, TriggerOrchestrator orchestrator) {
            super(handler, orchestrator);
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterInsert.Handler) this.handler).qualifiesForAfterInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterInsert.Handler) this.handler).onAfterInsert(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof AfterInsert.Finalizer) {
                ((AfterInsert.Finalizer) this.handler).finalizeAfterInsert();
            }
        }
    }

    private class BeforeUpdatePopulatorHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth;

        public BeforeUpdatePopulatorHandlerAdapter(BeforeUpdate.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);
            String recursionScope = this.handlerName + ':BEFORE_UPDATE';

            if (!TriggerOrchestrator.TransactionState.recursionDepthByRecordByHandler.containsKey(recursionScope)) {
                TriggerOrchestrator.TransactionState.recursionDepthByRecordByHandler.put(recursionScope, new Map<Id, Integer>());
            }

            this.recursionDepthByRecord = TriggerOrchestrator.TransactionState.recursionDepthByRecordByHandler.get(recursionScope);
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

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }

        public override Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
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

        public override void registerRecord(TriggerHandler.TriggerRecord record) {
            this.recursionDepthByRecord.put(record.getId(), (this.recursionDepthByRecord.get(record.getId()) ?? 0) + 1);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeUpdate.Populator) this.handler).populateOnBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeUpdate.Populator) this.handler).populateOnBeforeUpdate(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof BeforeUpdate.Finalizer) {
                ((BeforeUpdate.Finalizer) this.handler).finalizeBeforeUpdate();
            }
        }
    }

    private class BeforeUpdateValidatorHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        public BeforeUpdateValidatorHandlerAdapter(BeforeUpdate.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);
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

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeUpdate.Validator) this.handler).errorShouldBeAttachedOnBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            record.getNewSObject().addError(((BeforeUpdate.Validator) this.handler).beforeUpdateValidationMessage(record));
        }

        public override void finalizeHandler() {
            if (this.handler instanceof BeforeUpdate.Finalizer) {
                ((BeforeUpdate.Finalizer) this.handler).finalizeBeforeUpdate();
            }
        }
    }

    private class AfterUpdateHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth;

        public AfterUpdateHandlerAdapter(AfterUpdate.Handler handler, TriggerOrchestrator orchestrator) {
            super(handler, orchestrator);
            String recursionScope = this.handlerName + ':AFTER_UPDATE';

            if (!TriggerOrchestrator.TransactionState.recursionDepthByRecordByHandler.containsKey(recursionScope)) {
                TriggerOrchestrator.TransactionState.recursionDepthByRecordByHandler.put(recursionScope, new Map<Id, Integer>());
            }

            this.recursionDepthByRecord = TriggerOrchestrator.TransactionState.recursionDepthByRecordByHandler.get(recursionScope);
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
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

        public override void registerRecord(TriggerHandler.TriggerRecord record) {
            this.recursionDepthByRecord.put(record.getId(), (this.recursionDepthByRecord.get(record.getId()) ?? 0) + 1);
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterUpdate.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterUpdate.Handler) this.handler).qualifiesForAfterUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterUpdate.Handler) this.handler).onAfterUpdate(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof AfterUpdate.Finalizer) {
                ((AfterUpdate.Finalizer) this.handler).finalizeAfterUpdate();
            }
        }
    }

    private class BeforeDeleteHandlerAdapter extends TriggerHandlerAdapter implements OldRecordEnricher {
        public BeforeDeleteHandlerAdapter(BeforeDelete.Handler handler, TriggerOrchestrator orchestrator) {
            super(handler, orchestrator);
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeDelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeDelete.Handler) this.handler).qualifiesForBeforeDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeDelete.Handler) this.handler).onBeforeDelete(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof BeforeDelete.Finalizer) {
                ((BeforeDelete.Finalizer) this.handler).finalizeBeforeDelete();
            }
        }
    }

    private class AfterDeleteHandlerAdapter extends TriggerHandlerAdapter implements OldRecordEnricher {
        public AfterDeleteHandlerAdapter(AfterDelete.Handler handler, TriggerOrchestrator orchestrator) {
            super(handler, orchestrator);
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterDelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterDelete.Handler) this.handler).qualifiesForAfterDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterDelete.Handler) this.handler).onAfterDelete(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof AfterDelete.Finalizer) {
                ((AfterDelete.Finalizer) this.handler).finalizeAfterDelete();
            }
        }
    }

    private class AfterUndeleteHandlerAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        public AfterUndeleteHandlerAdapter(AfterUndelete.Handler handler, TriggerOrchestrator orchestrator) {
            super(handler, orchestrator);
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.TriggerSettings.isHandlerBypassedInMetadata(this.orchestrator.context, this.handler)) {
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

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterUndelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((AfterUndelete.Handler) this.handler).qualifiesForAfterUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterUndelete.Handler) this.handler).onAfterUndelete(record);
        }

        public override void finalizeHandler() {
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
        private Boolean canBeParentRelatioshipsChanged;

        public ParentRelationshipEnrichment(System.TriggerOperation triggerOperation) {
            this.canBeParentRelatioshipsChanged = triggerOperation == System.TriggerOperation.BEFORE_INSERT || triggerOperation == System.TriggerOperation.BEFORE_UPDATE;
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
            if (this.isResolved && (!this.canBeParentRelatioshipsChanged || recordsToEnrich.isEmpty())) {
                return;
            }

            for (SObjectField parentField : this.selectedFieldsByParentField.keySet()) {
                this.enrichParentField(parentField, recordsToEnrich);
            }

            this.isResolved = true;
        }

        private void enrichParentField(SObjectField parentField, List<TriggerHandler.TriggerRecord> recordsToScan) {
            Map<String, Id> staleNewIdByRecord = this.findStaleNewParentIds(parentField, recordsToScan);

            if (staleNewIdByRecord.isEmpty() && !this.isOldSideEnriched(parentField)) {
                return;
            }

            this.cacheParents(parentField, recordsToScan, staleNewIdByRecord);
            this.attachParents(parentField, recordsToScan, staleNewIdByRecord);
        }

        private Map<String, Id> findStaleNewParentIds(SObjectField parentField, List<TriggerHandler.TriggerRecord> recordsToScan) {
            Map<String, Id> staleNewIdByRecord = new Map<String, Id>();

            if (!this.newRecordFieldsToEnrich.contains(parentField)) {
                return staleNewIdByRecord;
            }

            Map<String, Id> enrichedNewIdByRecord = this.enrichedNewIdByRecordByParentField.get(parentField);

            for (TriggerHandler.TriggerRecord record : recordsToScan) {
                Id parentId = this.getNewParentId(record, parentField);

                if (enrichedNewIdByRecord.get(record.getIdentifier()) == parentId) {
                    continue;
                }

                staleNewIdByRecord.put(record.getIdentifier(), parentId);
            }

            return staleNewIdByRecord;
        }

        private void cacheParents(SObjectField parentField, List<TriggerHandler.TriggerRecord> recordsToScan, Map<String, Id> staleNewIdByRecord) {
            Map<Id, SObject> cachedParentById = this.cachedParentByIdByParentField.get(parentField);
            Set<Id> parentIdsToQuery = new Set<Id>();

            for (Id parentId : staleNewIdByRecord.values()) {
                if (parentId != null && !cachedParentById.containsKey(parentId)) {
                    parentIdsToQuery.add(parentId);
                }
            }

            if (this.isOldSideEnriched(parentField)) {
                for (TriggerHandler.TriggerRecord record : recordsToScan) {
                    Id parentId = this.getOldParentId(record, parentField);

                    if (parentId != null && !cachedParentById.containsKey(parentId)) {
                        parentIdsToQuery.add(parentId);
                    }
                }
            }

            if (parentIdsToQuery.isEmpty()) {
                return;
            }

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

        private void attachParents(SObjectField parentField, List<TriggerHandler.TriggerRecord> recordsToScan, Map<String, Id> staleNewIdByRecord) {
            Map<Id, SObject> cachedParentById = this.cachedParentByIdByParentField.get(parentField);
            Map<String, Id> enrichedNewIdByRecord = this.enrichedNewIdByRecordByParentField.get(parentField);

            Boolean enrichOldSide = this.isOldSideEnriched(parentField);
            String relationshipName = parentField.getDescribe().getRelationshipName();

            for (TriggerHandler.TriggerRecord record : recordsToScan) {
                if (staleNewIdByRecord.containsKey(record.getIdentifier())) {
                    record.enrichNew(relationshipName, cachedParentById.get(staleNewIdByRecord.get(record.getIdentifier())));
                    enrichedNewIdByRecord.put(record.getIdentifier(), staleNewIdByRecord.get(record.getIdentifier()));
                }

                if (enrichOldSide) {
                    record.enrichOld(relationshipName, cachedParentById.get(this.getOldParentId(record, parentField)));
                }
            }
        }

        private Boolean isOldSideEnriched(SObjectField parentField) {
            return !this.isResolved && this.oldRecordFieldsToEnrich.contains(parentField);
        }

        private Id getNewParentId(TriggerHandler.TriggerRecord record, SObjectField parentField) {
            return record.getNewSObject()?.isSet(parentField) == true ? (Id) record.getNewSObject().get(parentField) : null;
        }

        private Id getOldParentId(TriggerHandler.TriggerRecord record, SObjectField parentField) {
            return record.getOldSObject()?.isSet(parentField) == true ? (Id) record.getOldSObject().get(parentField) : null;
        }
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
