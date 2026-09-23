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
 * - FieldDeclarationsShouldBeAtStart: Developer who uses lib should see what's important at start
 **/
@SuppressWarnings(
    'PMD.ExcessiveClassLength,PMD.NcssTypeCount,PMD.NcssMethodCount,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.AvoidNonRestrictiveQueries,PMD.FieldDeclarationsShouldBeAtStart'
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

    @TestVisible
    private static TriggerLogger triggerLogger = new TriggerLogger();
    private static TriggerSettings triggerSettings = new TriggerSettings();
    private static TriggerBypass triggerBypass = new TriggerBypass();
    private static TriggerStack triggerStack = new TriggerStack();
    private static TriggerDepth triggerDepth = new TriggerDepth();

    @TestVisible
    private TriggerContext context;
    private Object orchestrator;
    private LookupEnrichment lookupEnrichment;
    private TriggerUnitOfWork sharedUnitOfWork;

    @TestVisible
    private TriggerOrchestrator(Object orchestrator) {
        this.orchestrator = orchestrator;
        this.context = new TriggerContext();
        this.lookupEnrichment = new LookupEnrichment(this.context);
        this.sharedUnitOfWork = new TriggerUnitOfWork();
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
            List<TriggerHandlerAdapter> activeAdapters = this.getActiveAdapters(orchestrator);

            orchestrator.lookupEnrichment.queryParentRelationships(activeAdapters);

            for (TriggerHandlerAdapter adapter : activeAdapters) {
                adapter.execute(orchestrator.context.triggerRecords);
            }

            orchestrator.sharedUnitOfWork.commitWork();
        }

        private List<TriggerHandlerAdapter> getActiveAdapters(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> activeAdapters = new List<TriggerHandlerAdapter>();

            for (TriggerHandlerAdapter adapter : this.adaptHandlers(orchestrator)) {
                if (!adapter.isBypassed()) {
                    activeAdapters.add(adapter);
                }
            }

            return activeAdapters;
        }

        protected abstract List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator);
    }

    private class BeforeInsertExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) orchestrator.orchestrator).beforeInsertHandlers()) {
                if (handler instanceof BeforeInsert.Populator) {
                    adapters.add(new BeforeInsertPopulatorAdapter((BeforeInsert.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeInsert.Validator) {
                    adapters.add(new BeforeInsertValidatorAdapter((BeforeInsert.Validator) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    private class AfterInsertExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) orchestrator.orchestrator).afterInsertHandlers()) {
                if (handler instanceof AfterInsert.Writer) {
                    adapters.add(new AfterInsertWriterAdapter((AfterInsert.Writer) handler, orchestrator));
                } else if (handler instanceof AfterInsert.Dispatcher) {
                    adapters.add(new AfterInsertDispatcherAdapter((AfterInsert.Dispatcher) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    private class BeforeUpdateExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator.orchestrator).beforeUpdateHandlers()) {
                if (handler instanceof BeforeUpdate.Populator) {
                    adapters.add(new BeforeUpdatePopulatorAdapter((BeforeUpdate.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeUpdate.Validator) {
                    adapters.add(new BeforeUpdateValidatorAdapter((BeforeUpdate.Validator) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    private class AfterUpdateExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) orchestrator.orchestrator).afterUpdateHandlers()) {
                if (handler instanceof AfterUpdate.Writer) {
                    adapters.add(new AfterUpdateWriterAdapter((AfterUpdate.Writer) handler, orchestrator));
                } else if (handler instanceof AfterUpdate.Dispatcher) {
                    adapters.add(new AfterUpdateDispatcherAdapter((AfterUpdate.Dispatcher) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    private class BeforeDeleteExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) orchestrator.orchestrator).beforeDeleteHandlers()) {
                adapters.add(new BeforeDeleteHandlerAdapter(handler, orchestrator));
            }

            return adapters;
        }
    }

    private class AfterDeleteExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) orchestrator.orchestrator).afterDeleteHandlers()) {
                if (handler instanceof AfterDelete.Writer) {
                    adapters.add(new AfterDeleteWriterAdapter((AfterDelete.Writer) handler, orchestrator));
                } else if (handler instanceof AfterDelete.Dispatcher) {
                    adapters.add(new AfterDeleteDispatcherAdapter((AfterDelete.Dispatcher) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    private class AfterUndeleteExecutionStrategy extends ExecutionStrategy {
        public override List<TriggerHandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();

            for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) orchestrator.orchestrator).afterUndeleteHandlers()) {
                if (handler instanceof AfterUndelete.Writer) {
                    adapters.add(new AfterUndeleteWriterAdapter((AfterUndelete.Writer) handler, orchestrator));
                } else if (handler instanceof AfterUndelete.Dispatcher) {
                    adapters.add(new AfterUndeleteDispatcherAdapter((AfterUndelete.Dispatcher) handler, orchestrator));
                }
            }

            return adapters;
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
        Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich();
    }

    private interface OldRecordEnricher {
        Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich();
    }

    private abstract class TriggerHandlerAdapter {
        protected String handlerName;
        protected TriggerOrchestrator orchestrator;
        protected List<TriggerHandler.TriggerRecord> processedRecords = new List<TriggerHandler.TriggerRecord>();

        public TriggerHandlerAdapter(Object handler, TriggerOrchestrator orchestrator) {
            this.handlerName = handler.toString().substringBefore(':');
            this.orchestrator = orchestrator;
        }

        public abstract void execute(List<TriggerHandler.TriggerRecord> records);
        public abstract Boolean isBypassedByInterface();
        public abstract Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records);

        public Boolean isBypassed() {
            return this.isBypassedBySettings() || this.isBypassedByInterface();
        }

        private Boolean isBypassedBySettings() {
            return TriggerOrchestrator.triggerBypass.isHandlerBypassed(this.handlerName) ||
                TriggerOrchestrator.triggerSettings.isHandlerBypassed(this.orchestrator.context, this.handlerName);
        }

        protected void logError(Exception e) {
            TriggerOrchestrator.triggerLogger.log(new TriggerError().withException(e).withHandlerName(this.handlerName).withContext(this.orchestrator.context));
        }

        protected void loadRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            for (TriggerHandler.TriggerRecord record : records) {
                record.setProvidedRecords(relatedRecords);
            }

            relatedRecords.putAll(this.queryRelated(records));
        }
    }

    private class BeforeInsertPopulatorAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        private BeforeInsert.Populator populator;

        public BeforeInsertPopulatorAdapter(BeforeInsert.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);
            this.populator = populator;
        }

        public override Boolean isBypassedByInterface() {
            return (this.populator instanceof BeforeInsert.Bypassable && ((BeforeInsert.Bypassable) this.populator).bypassOnBeforeInsertWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.populator instanceof BeforeInsert.ParentQuery) {
                return ((BeforeInsert.ParentQuery) this.populator).queryParentsOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.populate(record);
                }

                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerOrchestratorException guardException = new TriggerOrchestratorException(
                    this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                );

                this.logError(guardException);

                throw guardException;
            }

            this.orchestrator.lookupEnrichment.requeryWhenParentLookupChanged(this.processedRecords);
        }

        private void populate(TriggerHandler.TriggerRecord record) {
            if (!this.populator.populateOnBeforeInsertWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            this.populator.populateOnBeforeInsert(record);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.populator instanceof BeforeInsert.Finalizer)) {
                return;
            }

            ((BeforeInsert.Finalizer) this.populator).finalizeBeforeInsert();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.populator instanceof BeforeInsert.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, BeforeInsert.RecordsProvider> providers = ((BeforeInsert.RelatedQuery) this.populator).queryRelatedOnBeforeInsert() ??
                new Map<String, BeforeInsert.RecordsProvider>();
            TriggerHandler.InsertRecords providedTo = new TriggerHandler.InsertTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.populator instanceof BeforeInsert.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class BeforeInsertValidatorAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        private BeforeInsert.Validator validator;

        public BeforeInsertValidatorAdapter(BeforeInsert.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);
            this.validator = validator;
        }

        public override Boolean isBypassedByInterface() {
            return (this.validator instanceof BeforeInsert.Bypassable && ((BeforeInsert.Bypassable) this.validator).bypassOnBeforeInsertWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.validator instanceof BeforeInsert.ParentQuery) {
                return ((BeforeInsert.ParentQuery) this.validator).queryParentsOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerOrchestratorException guardException = new TriggerOrchestratorException(
                    this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                );

                this.logError(guardException);

                throw guardException;
            }
        }

        private void validate(TriggerHandler.TriggerRecord record) {
            if (!this.validator.errorShouldBeAttachedOnBeforeInsertWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            record.getNewSObject().addError(this.validator.beforeInsertValidationMessage(record));
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.validator instanceof BeforeInsert.Finalizer)) {
                return;
            }

            ((BeforeInsert.Finalizer) this.validator).finalizeBeforeInsert();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.validator instanceof BeforeInsert.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, BeforeInsert.RecordsProvider> providers = ((BeforeInsert.RelatedQuery) this.validator).queryRelatedOnBeforeInsert() ??
                new Map<String, BeforeInsert.RecordsProvider>();
            TriggerHandler.InsertRecords providedTo = new TriggerHandler.InsertTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.validator instanceof BeforeInsert.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterInsertWriterAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        private AfterInsert.Writer writer;
        private TriggerUnitOfWork unitOfWork;

        public AfterInsertWriterAdapter(AfterInsert.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);
            this.writer = writer;
            this.unitOfWork = this.writer instanceof AfterInsert.OwnUnitOfWork
                ? new TriggerUnitOfWork(((AfterInsert.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterInsert())
                : this.writer instanceof AfterInsert.ContinueOnError ? new TriggerUnitOfWork() : this.orchestrator.sharedUnitOfWork;
        }

        public override Boolean isBypassedByInterface() {
            return (this.writer instanceof AfterInsert.Bypassable && ((AfterInsert.Bypassable) this.writer).bypassOnAfterInsertWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.writer instanceof AfterInsert.ParentQuery) {
                return ((AfterInsert.ParentQuery) this.writer).queryParentsOnAfterInsert();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.write(record);
                }

                this.finalize();
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerHandler.TriggerRecord record) {
            if (!this.writer.writeOnAfterInsertWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            this.writer.writeOnAfterInsert(record, this.unitOfWork);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.writer instanceof AfterInsert.Finalizer)) {
                return;
            }

            ((AfterInsert.Finalizer) this.writer).finalizeAfterInsert();
        }

        private void commitOwnUnitOfWork() {
            if (this.processedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.writer instanceof AfterInsert.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterInsert.RecordsProvider> providers = ((AfterInsert.RelatedQuery) this.writer).queryRelatedOnAfterInsert() ??
                new Map<String, AfterInsert.RecordsProvider>();
            TriggerHandler.InsertRecords providedTo = new TriggerHandler.InsertTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.writer instanceof AfterInsert.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterInsertDispatcherAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        private AfterInsert.Dispatcher dispatcher;

        public AfterInsertDispatcherAdapter(AfterInsert.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);
            this.dispatcher = dispatcher;
        }

        public override Boolean isBypassedByInterface() {
            return (this.dispatcher instanceof AfterInsert.Bypassable && ((AfterInsert.Bypassable) this.dispatcher).bypassOnAfterInsertWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.dispatcher instanceof AfterInsert.ParentQuery) {
                return ((AfterInsert.ParentQuery) this.dispatcher).queryParentsOnAfterInsert();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerHandler.TriggerRecord record) {
            if (!this.dispatcher.dispatchOnAfterInsertWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
        }

        private void dispatch() {
            if (this.processedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterInsert(new TriggerHandler.InsertTriggerRecords(this.processedRecords));
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.dispatcher instanceof AfterInsert.Finalizer)) {
                return;
            }

            ((AfterInsert.Finalizer) this.dispatcher).finalizeAfterInsert();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.dispatcher instanceof AfterInsert.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterInsert.RecordsProvider> providers = ((AfterInsert.RelatedQuery) this.dispatcher).queryRelatedOnAfterInsert() ??
                new Map<String, AfterInsert.RecordsProvider>();
            TriggerHandler.InsertRecords providedTo = new TriggerHandler.InsertTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.dispatcher instanceof AfterInsert.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class BeforeUpdatePopulatorAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        private BeforeUpdate.Populator populator;
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth = 3;

        public BeforeUpdatePopulatorAdapter(BeforeUpdate.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);
            this.populator = populator;

            TriggerOrchestrator.triggerDepth.registerScope(this.handlerName + ':BEFORE_UPDATE');
            this.recursionDepthByRecord = TriggerOrchestrator.triggerDepth.getForRecursionScope(this.handlerName + ':BEFORE_UPDATE');

            if (populator instanceof BeforeUpdate.RecursionGuard) {
                this.maxRecursionDepth = ((BeforeUpdate.RecursionGuard) populator).maxRecursionDepthOnBeforeUpdate();
            }
        }

        public override Boolean isBypassedByInterface() {
            return (this.populator instanceof BeforeUpdate.Bypassable && ((BeforeUpdate.Bypassable) this.populator).bypassOnBeforeUpdateWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.populator instanceof BeforeUpdate.ParentQuery) {
                return ((BeforeUpdate.ParentQuery) this.populator).queryParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.populator instanceof BeforeUpdate.PriorParentQuery) {
                return ((BeforeUpdate.PriorParentQuery) this.populator).queryPriorParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.populate(record);
                }

                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerOrchestratorException guardException = new TriggerOrchestratorException(
                    this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                );

                this.logError(guardException);

                throw guardException;
            }

            this.orchestrator.lookupEnrichment.requeryWhenParentLookupChanged(this.processedRecords);
        }

        private void populate(TriggerHandler.TriggerRecord record) {
            Integer recursionDepth = this.recursionDepthByRecord.get(record.getId()) ?? 0;

            if (recursionDepth >= this.maxRecursionDepth || !this.populator.populateOnBeforeUpdateWhen(record)) {
                return;
            }

            this.recursionDepthByRecord.put(record.getId(), recursionDepth + 1);
            this.processedRecords.add(record);
            this.populator.populateOnBeforeUpdate(record);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.populator instanceof BeforeUpdate.Finalizer)) {
                return;
            }

            ((BeforeUpdate.Finalizer) this.populator).finalizeBeforeUpdate();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.populator instanceof BeforeUpdate.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, BeforeUpdate.RecordsProvider> providers = ((BeforeUpdate.RelatedQuery) this.populator).queryRelatedOnBeforeUpdate() ??
                new Map<String, BeforeUpdate.RecordsProvider>();
            TriggerHandler.UpdateRecords providedTo = new TriggerHandler.UpdateTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.populator instanceof BeforeUpdate.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class BeforeUpdateValidatorAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        private BeforeUpdate.Validator validator;

        public BeforeUpdateValidatorAdapter(BeforeUpdate.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);
            this.validator = validator;
        }

        public override Boolean isBypassedByInterface() {
            return (this.validator instanceof BeforeUpdate.Bypassable && ((BeforeUpdate.Bypassable) this.validator).bypassOnBeforeUpdateWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.validator instanceof BeforeUpdate.ParentQuery) {
                return ((BeforeUpdate.ParentQuery) this.validator).queryParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.validator instanceof BeforeUpdate.PriorParentQuery) {
                return ((BeforeUpdate.PriorParentQuery) this.validator).queryPriorParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerOrchestratorException guardException = new TriggerOrchestratorException(
                    this.handlerName + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                );

                this.logError(guardException);

                throw guardException;
            }
        }

        private void validate(TriggerHandler.TriggerRecord record) {
            if (!this.validator.errorShouldBeAttachedOnBeforeUpdateWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            record.getNewSObject().addError(this.validator.beforeUpdateValidationMessage(record));
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.validator instanceof BeforeUpdate.Finalizer)) {
                return;
            }

            ((BeforeUpdate.Finalizer) this.validator).finalizeBeforeUpdate();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.validator instanceof BeforeUpdate.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, BeforeUpdate.RecordsProvider> providers = ((BeforeUpdate.RelatedQuery) this.validator).queryRelatedOnBeforeUpdate() ??
                new Map<String, BeforeUpdate.RecordsProvider>();
            TriggerHandler.UpdateRecords providedTo = new TriggerHandler.UpdateTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.validator instanceof BeforeUpdate.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterUpdateWriterAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        private AfterUpdate.Writer writer;
        private TriggerUnitOfWork unitOfWork;
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth = 3;

        public AfterUpdateWriterAdapter(AfterUpdate.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);
            this.writer = writer;
            this.unitOfWork = this.writer instanceof AfterUpdate.OwnUnitOfWork
                ? new TriggerUnitOfWork(((AfterUpdate.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterUpdate())
                : this.writer instanceof AfterUpdate.ContinueOnError ? new TriggerUnitOfWork() : this.orchestrator.sharedUnitOfWork;

            TriggerOrchestrator.triggerDepth.registerScope(this.handlerName + ':AFTER_UPDATE');
            this.recursionDepthByRecord = TriggerOrchestrator.triggerDepth.getForRecursionScope(this.handlerName + ':AFTER_UPDATE');

            if (writer instanceof AfterUpdate.RecursionGuard) {
                this.maxRecursionDepth = ((AfterUpdate.RecursionGuard) writer).maxRecursionDepthOnAfterUpdate();
            }
        }

        public override Boolean isBypassedByInterface() {
            return (this.writer instanceof AfterUpdate.Bypassable && ((AfterUpdate.Bypassable) this.writer).bypassOnAfterUpdateWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.writer instanceof AfterUpdate.ParentQuery) {
                return ((AfterUpdate.ParentQuery) this.writer).queryParentsOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.writer instanceof AfterUpdate.PriorParentQuery) {
                return ((AfterUpdate.PriorParentQuery) this.writer).queryPriorParentsOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.write(record);
                }

                this.finalize();
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerHandler.TriggerRecord record) {
            Integer recursionDepth = this.recursionDepthByRecord.get(record.getId()) ?? 0;

            if (recursionDepth >= this.maxRecursionDepth || !this.writer.writeOnAfterUpdateWhen(record)) {
                return;
            }

            this.recursionDepthByRecord.put(record.getId(), recursionDepth + 1);
            this.processedRecords.add(record);
            this.writer.writeOnAfterUpdate(record, this.unitOfWork);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.writer instanceof AfterUpdate.Finalizer)) {
                return;
            }

            ((AfterUpdate.Finalizer) this.writer).finalizeAfterUpdate();
        }

        private void commitOwnUnitOfWork() {
            if (this.processedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.writer instanceof AfterUpdate.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterUpdate.RecordsProvider> providers = ((AfterUpdate.RelatedQuery) this.writer).queryRelatedOnAfterUpdate() ??
                new Map<String, AfterUpdate.RecordsProvider>();
            TriggerHandler.UpdateRecords providedTo = new TriggerHandler.UpdateTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.writer instanceof AfterUpdate.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterUpdateDispatcherAdapter extends TriggerHandlerAdapter implements NewRecordEnricher, OldRecordEnricher {
        private AfterUpdate.Dispatcher dispatcher;
        private Map<Id, Integer> recursionDepthByRecord;
        private Integer maxRecursionDepth = 3;

        public AfterUpdateDispatcherAdapter(AfterUpdate.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);
            this.dispatcher = dispatcher;

            TriggerOrchestrator.triggerDepth.registerScope(this.handlerName + ':AFTER_UPDATE');
            this.recursionDepthByRecord = TriggerOrchestrator.triggerDepth.getForRecursionScope(this.handlerName + ':AFTER_UPDATE');

            if (dispatcher instanceof AfterUpdate.RecursionGuard) {
                this.maxRecursionDepth = ((AfterUpdate.RecursionGuard) dispatcher).maxRecursionDepthOnAfterUpdate();
            }
        }

        public override Boolean isBypassedByInterface() {
            return (this.dispatcher instanceof AfterUpdate.Bypassable && ((AfterUpdate.Bypassable) this.dispatcher).bypassOnAfterUpdateWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.dispatcher instanceof AfterUpdate.ParentQuery) {
                return ((AfterUpdate.ParentQuery) this.dispatcher).queryParentsOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.dispatcher instanceof AfterUpdate.PriorParentQuery) {
                return ((AfterUpdate.PriorParentQuery) this.dispatcher).queryPriorParentsOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerHandler.TriggerRecord record) {
            Integer recursionDepth = this.recursionDepthByRecord.get(record.getId()) ?? 0;

            if (recursionDepth >= this.maxRecursionDepth || !this.dispatcher.dispatchOnAfterUpdateWhen(record)) {
                return;
            }

            this.recursionDepthByRecord.put(record.getId(), recursionDepth + 1);
            this.processedRecords.add(record);
        }

        private void dispatch() {
            if (this.processedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterUpdate(new TriggerHandler.UpdateTriggerRecords(this.processedRecords));
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.dispatcher instanceof AfterUpdate.Finalizer)) {
                return;
            }

            ((AfterUpdate.Finalizer) this.dispatcher).finalizeAfterUpdate();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.dispatcher instanceof AfterUpdate.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterUpdate.RecordsProvider> providers = ((AfterUpdate.RelatedQuery) this.dispatcher).queryRelatedOnAfterUpdate() ??
                new Map<String, AfterUpdate.RecordsProvider>();
            TriggerHandler.UpdateRecords providedTo = new TriggerHandler.UpdateTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.dispatcher instanceof AfterUpdate.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class BeforeDeleteHandlerAdapter extends TriggerHandlerAdapter implements OldRecordEnricher {
        private BeforeDelete.Handler handler;

        public BeforeDeleteHandlerAdapter(BeforeDelete.Handler handler, TriggerOrchestrator orchestrator) {
            super(handler, orchestrator);
            this.handler = handler;
        }

        public override Boolean isBypassedByInterface() {
            return (this.handler instanceof BeforeDelete.Bypassable && ((BeforeDelete.Bypassable) this.handler).bypassOnBeforeDeleteWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.handler instanceof BeforeDelete.PriorParentQuery) {
                return ((BeforeDelete.PriorParentQuery) this.handler).queryParentsOnBeforeDelete();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.handle(record);
                }

                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void handle(TriggerHandler.TriggerRecord record) {
            if (!this.handler.qualifiesForBeforeDeleteWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            this.handler.onBeforeDelete(record);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.handler instanceof BeforeDelete.Finalizer)) {
                return;
            }

            ((BeforeDelete.Finalizer) this.handler).finalizeBeforeDelete();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.handler instanceof BeforeDelete.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, BeforeDelete.RecordsProvider> providers = ((BeforeDelete.RelatedQuery) this.handler).queryRelatedOnBeforeDelete() ??
                new Map<String, BeforeDelete.RecordsProvider>();
            TriggerHandler.DeleteRecords providedTo = new TriggerHandler.DeleteTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.handler instanceof BeforeDelete.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterDeleteWriterAdapter extends TriggerHandlerAdapter implements OldRecordEnricher {
        private AfterDelete.Writer writer;
        private TriggerUnitOfWork unitOfWork;

        public AfterDeleteWriterAdapter(AfterDelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);
            this.writer = writer;
            this.unitOfWork = this.writer instanceof AfterDelete.OwnUnitOfWork
                ? new TriggerUnitOfWork(((AfterDelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterDelete())
                : this.writer instanceof AfterDelete.ContinueOnError ? new TriggerUnitOfWork() : this.orchestrator.sharedUnitOfWork;
        }

        public override Boolean isBypassedByInterface() {
            return (this.writer instanceof AfterDelete.Bypassable && ((AfterDelete.Bypassable) this.writer).bypassOnAfterDeleteWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.writer instanceof AfterDelete.PriorParentQuery) {
                return ((AfterDelete.PriorParentQuery) this.writer).queryParentsOnAfterDelete();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.write(record);
                }

                this.finalize();
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerHandler.TriggerRecord record) {
            if (!this.writer.writeOnAfterDeleteWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            this.writer.writeOnAfterDelete(record, this.unitOfWork);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.writer instanceof AfterDelete.Finalizer)) {
                return;
            }

            ((AfterDelete.Finalizer) this.writer).finalizeAfterDelete();
        }

        private void commitOwnUnitOfWork() {
            if (this.processedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.writer instanceof AfterDelete.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterDelete.RecordsProvider> providers = ((AfterDelete.RelatedQuery) this.writer).queryRelatedOnAfterDelete() ??
                new Map<String, AfterDelete.RecordsProvider>();
            TriggerHandler.DeleteRecords providedTo = new TriggerHandler.DeleteTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.writer instanceof AfterDelete.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterDeleteDispatcherAdapter extends TriggerHandlerAdapter implements OldRecordEnricher {
        private AfterDelete.Dispatcher dispatcher;

        public AfterDeleteDispatcherAdapter(AfterDelete.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);
            this.dispatcher = dispatcher;
        }

        public override Boolean isBypassedByInterface() {
            return (this.dispatcher instanceof AfterDelete.Bypassable && ((AfterDelete.Bypassable) this.dispatcher).bypassOnAfterDeleteWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getOldFieldsToEnrich() {
            if (this.dispatcher instanceof AfterDelete.PriorParentQuery) {
                return ((AfterDelete.PriorParentQuery) this.dispatcher).queryParentsOnAfterDelete();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerHandler.TriggerRecord record) {
            if (!this.dispatcher.dispatchOnAfterDeleteWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
        }

        private void dispatch() {
            if (this.processedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterDelete(new TriggerHandler.DeleteTriggerRecords(this.processedRecords));
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.dispatcher instanceof AfterDelete.Finalizer)) {
                return;
            }

            ((AfterDelete.Finalizer) this.dispatcher).finalizeAfterDelete();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.dispatcher instanceof AfterDelete.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterDelete.RecordsProvider> providers = ((AfterDelete.RelatedQuery) this.dispatcher).queryRelatedOnAfterDelete() ??
                new Map<String, AfterDelete.RecordsProvider>();
            TriggerHandler.DeleteRecords providedTo = new TriggerHandler.DeleteTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.dispatcher instanceof AfterDelete.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterUndeleteWriterAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        private AfterUndelete.Writer writer;
        private TriggerUnitOfWork unitOfWork;

        public AfterUndeleteWriterAdapter(AfterUndelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);
            this.writer = writer;
            this.unitOfWork = this.writer instanceof AfterUndelete.OwnUnitOfWork
                ? new TriggerUnitOfWork(((AfterUndelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterUndelete())
                : this.writer instanceof AfterUndelete.ContinueOnError ? new TriggerUnitOfWork() : this.orchestrator.sharedUnitOfWork;
        }

        public override Boolean isBypassedByInterface() {
            return (this.writer instanceof AfterUndelete.Bypassable && ((AfterUndelete.Bypassable) this.writer).bypassOnAfterUndeleteWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.writer instanceof AfterUndelete.ParentQuery) {
                return ((AfterUndelete.ParentQuery) this.writer).queryParentsOnAfterUndelete();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.write(record);
                }

                this.finalize();
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerHandler.TriggerRecord record) {
            if (!this.writer.writeOnAfterUndeleteWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
            this.writer.writeOnAfterUndelete(record, this.unitOfWork);
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.writer instanceof AfterUndelete.Finalizer)) {
                return;
            }

            ((AfterUndelete.Finalizer) this.writer).finalizeAfterUndelete();
        }

        private void commitOwnUnitOfWork() {
            if (this.processedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.writer instanceof AfterUndelete.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterUndelete.RecordsProvider> providers = ((AfterUndelete.RelatedQuery) this.writer).queryRelatedOnAfterUndelete() ??
                new Map<String, AfterUndelete.RecordsProvider>();
            TriggerHandler.UndeleteRecords providedTo = new TriggerHandler.UndeleteTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.writer instanceof AfterUndelete.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class AfterUndeleteDispatcherAdapter extends TriggerHandlerAdapter implements NewRecordEnricher {
        private AfterUndelete.Dispatcher dispatcher;

        public AfterUndeleteDispatcherAdapter(AfterUndelete.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);
            this.dispatcher = dispatcher;
        }

        public override Boolean isBypassedByInterface() {
            return (this.dispatcher instanceof AfterUndelete.Bypassable && ((AfterUndelete.Bypassable) this.dispatcher).bypassOnAfterUndeleteWhen());
        }

        public Map<SObjectField, TriggerHandler.ParentFields> getNewFieldsToEnrich() {
            if (this.dispatcher instanceof AfterUndelete.ParentQuery) {
                return ((AfterUndelete.ParentQuery) this.dispatcher).queryParentsOnAfterUndelete();
            }

            return new Map<SObjectField, TriggerHandler.ParentFields>();
        }

        public override void execute(List<TriggerHandler.TriggerRecord> records) {
            try {
                this.loadRelated(records);

                for (TriggerHandler.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.finalize();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerHandler.TriggerRecord record) {
            if (!this.dispatcher.dispatchOnAfterUndeleteWhen(record)) {
                return;
            }

            this.processedRecords.add(record);
        }

        private void dispatch() {
            if (this.processedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterUndelete(new TriggerHandler.UndeleteTriggerRecords(this.processedRecords));
        }

        private void finalize() {
            if (this.processedRecords.isEmpty() || !(this.dispatcher instanceof AfterUndelete.Finalizer)) {
                return;
            }

            ((AfterUndelete.Finalizer) this.dispatcher).finalizeAfterUndelete();
        }

        public override Map<String, TriggerHandler.RelatedRecords> queryRelated(List<TriggerHandler.TriggerRecord> records) {
            Map<String, TriggerHandler.RelatedRecords> relatedRecords = new Map<String, TriggerHandler.RelatedRecords>();

            if (!(this.dispatcher instanceof AfterUndelete.RelatedQuery)) {
                return relatedRecords;
            }

            Map<String, AfterUndelete.RecordsProvider> providers = ((AfterUndelete.RelatedQuery) this.dispatcher).queryRelatedOnAfterUndelete() ??
                new Map<String, AfterUndelete.RecordsProvider>();
            TriggerHandler.UndeleteRecords providedTo = new TriggerHandler.UndeleteTriggerRecords(records);

            for (String providerName : providers.keySet()) {
                relatedRecords.put(providerName, new TriggerHandler.ProvidedRecords(providers.get(providerName), providedTo));
            }

            return relatedRecords;
        }

        private void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerOrchestratorException || e instanceof TriggerHandler.TriggerHandlerException || !(this.dispatcher instanceof AfterUndelete.ContinueOnError)) {
                throw e;
            }
        }
    }

    private class TriggerUnitOfWork implements TriggerHandler.UnitOfWork {
        private DML.Committable dml;

        public TriggerUnitOfWork() {
            this(new DML().combineOnDuplicate().systemMode().withoutSharing());
        }

        public TriggerUnitOfWork(DML.Committable dml) {
            this.dml = dml;
        }

        public TriggerHandler.UnitOfWork toInsert(SObject record) {
            this.dml.toInsert(record);
            return this;
        }

        public TriggerHandler.UnitOfWork toInsert(DML.Record record) {
            this.dml.toInsert(record);
            return this;
        }

        public TriggerHandler.UnitOfWork toUpdate(SObject record) {
            this.dml.toUpdate(record);
            return this;
        }

        public TriggerHandler.UnitOfWork toUpdate(DML.Record record) {
            this.dml.toUpdate(record);
            return this;
        }

        public TriggerHandler.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) {
            this.dml.toUpsert(record, externalIdField);
            return this;
        }

        public TriggerHandler.UnitOfWork toDelete(SObject record) {
            this.dml.toDelete(record);
            return this;
        }

        public TriggerHandler.UnitOfWork toPublish(SObject event) {
            this.dml.toPublish(event);
            return this;
        }

        public void commitWork() {
            this.dml.commitWork();
        }
    }

    private class LookupEnrichment {
        private Set<SObjectField> newParentLookupsToEnrich = new Set<SObjectField>();
        private Set<SObjectField> oldParentLookupsToEnrich = new Set<SObjectField>();

        private Map<SObjectField, Set<String>> fieldsToQueryByParentLookup = new Map<SObjectField, Set<String>>();
        private Map<SObjectField, Map<Id, SObject>> cachedParentByParentLookup = new Map<SObjectField, Map<Id, SObject>>();

        private TriggerContext context;

        public LookupEnrichment(TriggerContext context) {
            this.context = context;
        }

        public void queryParentRelationships(List<TriggerHandlerAdapter> handlers) {
            this.extractFieldsToEnrichList(handlers);
            this.cacheNewParentsFromSavedRecords();
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

        private void cacheNewParentsFromSavedRecords() {
            if (this.newParentLookupsToEnrich.isEmpty() || !this.areNewRecordsSaved()) {
                return;
            }

            Set<String> fieldsToQuery = new Set<String>();

            for (SObjectField parentField : this.newParentLookupsToEnrich) {
                String relationshipName = parentField.getDescribe().getRelationshipName();

                fieldsToQuery.add(relationshipName + '.Id');

                for (String field : this.fieldsToQueryByParentLookup.get(parentField)) {
                    fieldsToQuery.add(relationshipName + '.' + field);
                }
            }

            List<SObject> savedRecords = SOQL.of(this.context.sObjectType).with(fieldsToQuery).byIds(this.context.newRecords).systemMode().withoutSharing().toList();

            for (SObjectField parentField : this.newParentLookupsToEnrich) {
                Map<Id, SObject> cachedParentById = this.cachedParentByParentLookup.get(parentField);
                String relationshipName = parentField.getDescribe().getRelationshipName();

                for (SObject savedRecord : savedRecords) {
                    SObject parent = savedRecord.getSObject(relationshipName);

                    if (parent != null) {
                        cachedParentById.put(parent.Id, parent);
                    }
                }
            }
        }

        private Boolean areNewRecordsSaved() {
            return this.context.triggerOperation == System.TriggerOperation.AFTER_INSERT ||
                this.context.triggerOperation == System.TriggerOperation.AFTER_UPDATE ||
                this.context.triggerOperation == System.TriggerOperation.AFTER_UNDELETE;
        }

        private void enrichRecordsLookups() {
            for (SObjectField parentField : this.fieldsToQueryByParentLookup.keySet()) {
                Set<Id> parentIdsToQuery = new Set<Id>();

                parentIdsToQuery.addAll(this.notQueriedNewParentIds(parentField, this.context.triggerRecords));
                parentIdsToQuery.addAll(this.notQueriedOldParentIds(parentField, this.context.triggerRecords));

                this.queryParentsRelationships(parentField, parentIdsToQuery);

                this.attachNewToTriggerRecords(parentField, this.context.triggerRecords);
                this.attachOldToTriggerRecords(parentField, this.context.triggerRecords);
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

        private void declareNewFieldsToEnrich(Map<SObjectField, TriggerHandler.ParentFields> fieldsToEnrich) {
            this.newParentLookupsToEnrich.addAll(fieldsToEnrich.keySet());
            this.declare(fieldsToEnrich);
        }

        private void declareOldFieldsToEnrich(Map<SObjectField, TriggerHandler.ParentFields> fieldsToEnrich) {
            this.oldParentLookupsToEnrich.addAll(fieldsToEnrich.keySet());
            this.declare(fieldsToEnrich);
        }

        private void declare(Map<SObjectField, TriggerHandler.ParentFields> fieldsToEnrich) {
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
