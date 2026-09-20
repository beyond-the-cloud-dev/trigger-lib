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

    public static Bypassable bypass() {
        return TriggerOrchestrator.triggerBypass;
    }

    public interface Bypassable {
        Bypassable sObject(SObjectType sObjectType);
        Bypassable orchestrator(System.Type orchestrator);
        Bypassable handler(System.Type handler);
        void all();
        void clear();
    }

    // Implementations

    private static TriggerSettings triggerSettings = new TriggerSettings();
    private static TriggerLogger triggerLogger = new TriggerLogger();
    private static TriggerBypass triggerBypass = new TriggerBypass();
    private static TriggerStack triggerStack = new TriggerStack();
    private static TriggerDepth triggerDepth = new TriggerDepth();

    @TestVisible
    private TriggerContext context;
    private Object orchestrator;
    private LookupEnrichment lookupEnrichment;

    @TestVisible
    private TriggerOrchestrator(Object orchestrator) {
        this.orchestrator = orchestrator;
        this.context = new TriggerContext();
        this.lookupEnrichment = new LookupEnrichment(this.context.triggerRecords);
    }

    @TestVisible
    private void run() {
        ExecutionStrategy executionStrategy;

        try {
            if (this.context.triggerOperation == null) {
                throw new TriggerOrchestratorException('Called outside of a trigger context, or the trigger operation is not supported.');
            }

            if (TriggerOrchestrator.triggerBypass.isRunBypassed(this)) {
                return;
            }

            if (TriggerOrchestrator.triggerSettings.isSObjectTriggerBypassed(this.context)) {
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

            TriggerOrchestrator.triggerStack.push(executionStrategy);

            executionStrategy.execute(this);
        } finally {
            this.finalizeTransactionChunk(executionStrategy);
        }
    }

    private void finalizeTransactionChunk(ExecutionStrategy executionStrategy) {
        if (executionStrategy == null) {
            return;
        }

        TriggerOrchestrator.triggerStack.popLast();

        if (TriggerOrchestrator.triggerStack.isMainTransactionChunkCompleted()) {
            TriggerOrchestrator.triggerLogger.finalizeLogger();
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

        public List<TriggerHandler.TriggerRecord> triggerRecords {
            get {
                if (this.triggerRecords == null) {
                    this.triggerRecords = TriggerHandler.getTriggerRecordsFrom(this.newRecords, this.oldRecords);
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

    private class TriggerStack {
        private List<ExecutionStrategy> executionStack = new List<ExecutionStrategy>();

        public void push(ExecutionStrategy executionStrategy) {
            this.executionStack.add(executionStrategy);
        }

        public void popLast() {
            this.executionStack.remove(this.executionStack.size() - 1);
        }

        public Boolean isMainTransactionChunkCompleted() {
            return this.executionStack.isEmpty();
        }
    }

    private class TriggerDepth {
        private Map<String, Map<Id, Integer>> recursionDepthByRecordByHandler = new Map<String, Map<Id, Integer>>();

        public void registerScope(String recursionScope) {
            if (!this.recursionDepthByRecordByHandler.containsKey(recursionScope)) {
                this.recursionDepthByRecordByHandler.put(recursionScope, new Map<Id, Integer>());
            }
        }

        public Map<Id, Integer> getForRecursionScope(String recursionScope) {
            return this.recursionDepthByRecordByHandler.get(recursionScope);
        }
    }

    @TestVisible
    private class TriggerLogger {
        @TestVisible
        private Logger logger = this.resolveLogger();

        public void log(Error error) {
            this.logger?.log(error);
        }

        public void finalizeLogger() {
            this.logger?.finalize();
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
                throw new TriggerOrchestratorException('Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.');
            }

            if (implementors.isEmpty()) {
                return null;
            }

            return (Logger) Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();
        }
    }

    @TestVisible
    private class TriggerSettings {
        private Map<String, MetadataSettings> settingsByObjectName = this.resolveMetadataSettings();

        public Boolean isSObjectTriggerBypassed(TriggerContext context) {
            return this.settingsByObjectName.get(context.sObjectType.toString().toLowerCase())?.sObjectSetting.Bypass__c == true;
        }

        public Boolean isHandlerBypassed(TriggerContext context, String handlerName) {
            return this.settingsByObjectName.get(context.sObjectType.toString().toLowerCase())?.settingByHandlerName.get(handlerName.toLowerCase())?.Bypass__c == true;
        }

        private Map<String, MetadataSettings> resolveMetadataSettings() {
            Map<String, MetadataSettings> settingsByObjectName = new Map<String, MetadataSettings>();

            for (
                TriggerObject__mdt triggerObject : (List<TriggerObject__mdt>) SOQL.of(TriggerObject__mdt.SObjectType)
                    .with(TriggerObject__mdt.ObjectAPIName__c, TriggerObject__mdt.Bypass__c)
                    .with(SOQL.SubQuery.of('TriggerHandlers__r').with(TriggerHandler__mdt.ApexClassName__c, TriggerHandler__mdt.Bypass__c))
                    .systemMode()
                    .mockId('TriggerObject__mdt')
                    .toList()
            ) {
                settingsByObjectName.put(triggerObject.ObjectAPIName__c.trim().toLowerCase(), new MetadataSettings(triggerObject));
            }

            return settingsByObjectName;
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

    private abstract class ExecutionStrategy {
        public void execute(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> activeHandlers = this.getActiveHandlers(orchestrator);

            orchestrator.lookupEnrichment.queryParentRelationships(activeHandlers);

            for (TriggerHandlerAdapter adapter : activeHandlers) {
                try {
                    adapter.execute(orchestrator.context.triggerRecords);
                } catch (Exception e) {
                    adapter.handleException(e);
                }

                orchestrator.lookupEnrichment.requeryWhenParentLookupChanged(adapter.getProcessedRecords());
            }
        }

        private List<TriggerHandlerAdapter> getActiveHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> activeHandlers = new List<TriggerHandlerAdapter>();

            for (TriggerHandlerAdapter adapter : this.adaptHandlers(orchestrator)) {
                if (!adapter.isBypassed()) {
                    activeHandlers.add(adapter);
                }
            }

            return activeHandlers;
        }

        protected abstract List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator);
    }

    private class BeforeInsertExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) orchestrator.orchestrator).beforeInsertHandlers()) {
                if (handler instanceof BeforeInsert.Populator) {
                    handlerAdapters.add(new BeforeInsertPopulatorHandlerAdapter((BeforeInsert.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeInsert.Validator) {
                    handlerAdapters.add(new BeforeInsertValidatorHandlerAdapter((BeforeInsert.Validator) handler, orchestrator));
                }
            }

            return handlerAdapters;
        }
    }

    private class AfterInsertExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) orchestrator.orchestrator).afterInsertHandlers()) {
                handlerAdapters.add(new AfterInsertHandlerAdapter(handler, orchestrator));
            }

            return handlerAdapters;
        }
    }

    private class BeforeUpdateExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator.orchestrator).beforeUpdateHandlers()) {
                if (handler instanceof BeforeUpdate.Populator) {
                    handlerAdapters.add(new BeforeUpdatePopulatorHandlerAdapter((BeforeUpdate.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeUpdate.Validator) {
                    handlerAdapters.add(new BeforeUpdateValidatorHandlerAdapter((BeforeUpdate.Validator) handler, orchestrator));
                }
            }

            return handlerAdapters;
        }
    }

    private class AfterUpdateExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) orchestrator.orchestrator).afterUpdateHandlers()) {
                handlerAdapters.add(new AfterUpdateHandlerAdapter(handler, orchestrator));
            }

            return handlerAdapters;
        }
    }

    private class BeforeDeleteExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) orchestrator.orchestrator).beforeDeleteHandlers()) {
                handlerAdapters.add(new BeforeDeleteHandlerAdapter(handler, orchestrator));
            }

            return handlerAdapters;
        }
    }

    private class AfterDeleteExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) orchestrator.orchestrator).afterDeleteHandlers()) {
                handlerAdapters.add(new AfterDeleteHandlerAdapter(handler, orchestrator));
            }

            return handlerAdapters;
        }
    }

    private class AfterUndeleteExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();

            for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) orchestrator.orchestrator).afterUndeleteHandlers()) {
                handlerAdapters.add(new AfterUndeleteHandlerAdapter(handler, orchestrator));
            }

            return handlerAdapters;
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
            for (TriggerHandler.TriggerRecord record : context.triggerRecords) {
                if (record.getId() != null) {
                    this.recordIds.add(record.getId());
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

        public void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !this.continuesOnError()) {
                throw e;
            }
        }

        private void logError(Exception e) {
            TriggerOrchestrator.triggerLogger.log(new TriggerError().withException(e).withHandlerName(this.handlerName).withContext(this.orchestrator.context));
        }

        public Boolean isBypassed() {
            return this.isBypassedBySettings() || this.isBypassedByHandler();
        }

        private Boolean isBypassedBySettings() {
            return TriggerOrchestrator.triggerBypass.isHandlerBypassed(this.handlerName) ||
                TriggerOrchestrator.triggerSettings.isHandlerBypassed(this.orchestrator.context, this.handlerName);
        }

        protected virtual Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            return false;
        }

        protected virtual void registerRecord(TriggerHandler.TriggerRecord record) {
        }

        public abstract Boolean isBypassedByHandler();
        public abstract Boolean continuesOnError();
        public abstract Boolean isQualified(TriggerHandler.TriggerRecord record);
        public abstract void finalizeHandler();
        public abstract void executeOn(TriggerHandler.TriggerRecord record);
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

            TriggerOrchestrator.triggerDepth.registerScope(recursionScope);

            this.recursionDepthByRecord = TriggerOrchestrator.triggerDepth.getForRecursionScope(recursionScope);
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

            TriggerOrchestrator.triggerDepth.registerScope(recursionScope);

            this.recursionDepthByRecord = TriggerOrchestrator.triggerDepth.getForRecursionScope(recursionScope);
        }

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
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

        public override Boolean isBypassedByHandler() {
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

        public override void executeOn(TriggerHandler.TriggerRecord record) {
            ((AfterUndelete.Handler) this.handler).onAfterUndelete(record);
        }

        public override void finalizeHandler() {
            if (this.handler instanceof AfterUndelete.Finalizer) {
                ((AfterUndelete.Finalizer) this.handler).finalizeAfterUndelete();
            }
        }
    }

    private class LookupEnrichment {
        private Set<SObjectField> newParentLookupsToEnrich = new Set<SObjectField>();
        private Set<SObjectField> oldParentLookupsToEnrich = new Set<SObjectField>();

        private Map<SObjectField, Set<String>> fieldsToQueryByParentLookup = new Map<SObjectField, Set<String>>();
        private Map<SObjectField, Map<Id, SObject>> cachedParentByParentLookup = new Map<SObjectField, Map<Id, SObject>>();

        private List<TriggerHandler.TriggerRecord> triggerRecords;

        public LookupEnrichment(List<TriggerHandler.TriggerRecord> triggerRecords) {
            this.triggerRecords = triggerRecords;
        }

        public void queryParentRelationships(List<TriggerHandlerAdapter> handlers) {
            this.extractFieldsToEnrichList(handlers);
            this.enrichRecordsLookups();
        }

        private void extractFieldsToEnrichList(List<TriggerHandlerAdapter> handlers) {
            for (TriggerHandlerAdapter handler : handlers) {
                if (handler instanceof NewRecordEnricher) {
                    this.declareNewFieldsToEnrich(((NewRecordEnricher) handler).getNewFieldsToEnrich());
                }
                if (handler instanceof OldRecordEnricher) {
                    this.declareOldFieldsToEnrich(((OldRecordEnricher) handler).getOldFieldsToEnrich());
                }
            }
        }

        private void enrichRecordsLookups() {
            for (SObjectField parentField : this.fieldsToQueryByParentLookup.keySet()) {
                Set<Id> parentIdsToQuery = new Set<Id>();

                parentIdsToQuery.addAll(this.notQueriedNewParentIds(parentField, this.triggerRecords));
                parentIdsToQuery.addAll(this.notQueriedOldParentIds(parentField, this.triggerRecords));

                this.queryParentsRelationships(parentField, parentIdsToQuery);

                this.attachNewToTriggerRecords(parentField, this.triggerRecords);
                this.attachOldToTriggerRecords(parentField, this.triggerRecords);
            }
        }

        public void requeryWhenParentLookupChanged(List<TriggerHandler.TriggerRecord> records) {
            if (records.isEmpty()) {
                return;
            }

            for (SObjectField parentField : this.fieldsToQueryByParentLookup.keySet()) {
                this.queryParentsRelationships(parentField, this.notQueriedNewParentIds(parentField, records));

                this.attachNewToTriggerRecords(parentField, records);
            }
        }

        private Set<Id> notQueriedNewParentIds(SObjectField parentField, List<TriggerHandler.TriggerRecord> records) {
            Set<Id> parentIds = new Set<Id>();

            if (!this.newParentLookupsToEnrich.contains(parentField)) {
                return parentIds;
            }

            Map<Id, SObject> cachedParentById = this.cachedParentByParentLookup.get(parentField);

            for (TriggerHandler.TriggerRecord record : records) {
                Id parentId = record.getNewParentId(parentField);

                if (parentId != null && !cachedParentById.containsKey(parentId)) {
                    parentIds.add(parentId);
                }
            }

            return parentIds;
        }

        private Set<Id> notQueriedOldParentIds(SObjectField parentField, List<TriggerHandler.TriggerRecord> records) {
            Set<Id> parentIds = new Set<Id>();

            if (!this.oldParentLookupsToEnrich.contains(parentField)) {
                return parentIds;
            }

            Map<Id, SObject> cachedParentById = this.cachedParentByParentLookup.get(parentField);

            for (TriggerHandler.TriggerRecord record : records) {
                Id parentId = record.getOldParentId(parentField);

                if (parentId != null && !cachedParentById.containsKey(parentId)) {
                    parentIds.add(parentId);
                }
            }

            return parentIds;
        }

        private void queryParentsRelationships(SObjectField parentField, Set<Id> parentIdsToQuery) {
            if (parentIdsToQuery.isEmpty()) {
                return;
            }

            Map<Id, SObject> queriedParentById = SOQL.of(parentField.getDescribe().getReferenceTo()[0])
                .with(this.fieldsToQueryByParentLookup.get(parentField))
                .byIds(parentIdsToQuery)
                .systemMode()
                .withoutSharing()
                .toMap();

            Map<Id, SObject> cachedParentById = this.cachedParentByParentLookup.get(parentField);

            for (Id parentId : parentIdsToQuery) {
                cachedParentById.put(parentId, queriedParentById.get(parentId));
            }
        }

        private void attachNewToTriggerRecords(SObjectField parentField, List<TriggerHandler.TriggerRecord> records) {
            if (!this.newParentLookupsToEnrich.contains(parentField)) {
                return;
            }

            Map<Id, SObject> parentsById = this.cachedParentByParentLookup.get(parentField);
            String relationshipName = parentField.getDescribe().getRelationshipName();

            for (TriggerHandler.TriggerRecord record : records) {
                record.enrichNew(relationshipName, parentsById.get(record.getNewParentId(parentField)));
            }
        }

        private void attachOldToTriggerRecords(SObjectField parentField, List<TriggerHandler.TriggerRecord> records) {
            if (!this.oldParentLookupsToEnrich.contains(parentField)) {
                return;
            }

            Map<Id, SObject> parentsById = this.cachedParentByParentLookup.get(parentField);
            String relationshipName = parentField.getDescribe().getRelationshipName();

            for (TriggerHandler.TriggerRecord record : records) {
                record.enrichOld(relationshipName, parentsById.get(record.getOldParentId(parentField)));
            }
        }

        private void declareNewFieldsToEnrich(Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich) {
            this.newParentLookupsToEnrich.addAll(fieldsToEnrich.keySet());
            this.declare(fieldsToEnrich);
        }

        private void declareOldFieldsToEnrich(Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich) {
            this.oldParentLookupsToEnrich.addAll(fieldsToEnrich.keySet());
            this.declare(fieldsToEnrich);
        }

        private void declare(Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich) {
            for (SObjectField parentField : fieldsToEnrich.keySet()) {
                if (!this.fieldsToQueryByParentLookup.containsKey(parentField)) {
                    this.fieldsToQueryByParentLookup.put(parentField, new Set<String>());
                }
                if (!this.cachedParentByParentLookup.containsKey(parentField)) {
                    this.cachedParentByParentLookup.put(parentField, new Map<Id, SObject>());
                }

                this.fieldsToQueryByParentLookup.get(parentField).addAll(fieldsToEnrich.get(parentField).getFields());
            }
        }
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
