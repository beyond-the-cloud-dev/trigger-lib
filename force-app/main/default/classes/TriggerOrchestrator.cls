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
        void flush();
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

    @TestVisible
    private static Mockable mock() {
        return TriggerOrchestrator.triggerMock;
    }

    @TestVisible
    private static void runTestFor(Object handlerOrOrchestrator) {
        TriggerOrchestrator.triggerMock.nextContextFor(handlerOrOrchestrator).run(handlerOrOrchestrator);
    }

    @TestVisible
    private interface Mockable {
        BeforeInsertMockable beforeInsertFor(System.Type handlerOrOrchestratorType);
        AfterInsertMockable afterInsertFor(System.Type handlerOrOrchestratorType);
        BeforeUpdateMockable beforeUpdateFor(System.Type handlerOrOrchestratorType);
        AfterUpdateMockable afterUpdateFor(System.Type handlerOrOrchestratorType);
        BeforeDeleteMockable beforeDeleteFor(System.Type handlerOrOrchestratorType);
        AfterDeleteMockable afterDeleteFor(System.Type handlerOrOrchestratorType);
        AfterUndeleteMockable afterUndeleteFor(System.Type handlerOrOrchestratorType);
    }

    @TestVisible
    private interface BeforeInsertMockable {
        BeforeInsertMockable with(SObject row);
        BeforeInsertMockable with(List<SObject> rows);
        BeforeInsertMockable withParent(SObjectField lookupField, SObject parent);
        BeforeInsertMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    @TestVisible
    private interface AfterInsertMockable {
        AfterInsertMockable with(SObject row);
        AfterInsertMockable with(List<SObject> rows);
        AfterInsertMockable withParent(SObjectField lookupField, SObject parent);
        AfterInsertMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    @TestVisible
    private interface BeforeUpdateMockable {
        BeforeUpdateMockable with(SObject newRow, SObject oldRow);
        BeforeUpdateMockable with(List<SObject> newRows, List<SObject> oldRows);
        BeforeUpdateMockable withParent(SObjectField lookupField, SObject parent);
        BeforeUpdateMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    @TestVisible
    private interface AfterUpdateMockable {
        AfterUpdateMockable with(SObject newRow, SObject oldRow);
        AfterUpdateMockable with(List<SObject> newRows, List<SObject> oldRows);
        AfterUpdateMockable withParent(SObjectField lookupField, SObject parent);
        AfterUpdateMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    @TestVisible
    private interface BeforeDeleteMockable {
        BeforeDeleteMockable with(SObject row);
        BeforeDeleteMockable with(List<SObject> rows);
        BeforeDeleteMockable withParent(SObjectField lookupField, SObject parent);
        BeforeDeleteMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    @TestVisible
    private interface AfterDeleteMockable {
        AfterDeleteMockable with(SObject row);
        AfterDeleteMockable with(List<SObject> rows);
        AfterDeleteMockable withParent(SObjectField lookupField, SObject parent);
        AfterDeleteMockable withParent(SObjectField lookupField, List<SObject> parents);
    }

    @TestVisible
    private interface AfterUndeleteMockable {
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
    private Object orchestrator;
    private ParentLoader parentLoader;
    private UnitOfWork sharedUnitOfWork;

    @TestVisible
    private TriggerOrchestrator(Object orchestrator) {
        this.orchestrator = orchestrator;
        this.context = new TriggerContext();
        this.parentLoader = new ParentLoader(this.context);
        this.sharedUnitOfWork = new UnitOfWork();
    }

    @TestVisible
    private void run() {
        ExecutionStrategy executionStrategy;

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

    private abstract class ExecutionStrategy {
        public void execute(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> activeAdapters = this.getActiveAdapters(orchestrator);

            orchestrator.parentLoader.collectDeclarations(activeAdapters);

            for (HandlerAdapter adapter : activeAdapters) {
                adapter.execute(orchestrator.context.triggerRecords);
            }

            orchestrator.sharedUnitOfWork.commitWork();
        }

        private List<HandlerAdapter> getActiveAdapters(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> activeAdapters = new List<HandlerAdapter>();

            for (HandlerAdapter adapter : this.adaptHandlers(orchestrator)) {
                if (!adapter.isBypassed()) {
                    activeAdapters.add(adapter);
                }
            }

            return activeAdapters;
        }

        protected abstract List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator);
    }

    private class BeforeInsertExecutionStrategy extends ExecutionStrategy {
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

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
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

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
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

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
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

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
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) orchestrator.orchestrator).beforeDeleteHandlers()) {
                if (handler instanceof BeforeDelete.Validator) {
                    adapters.add(new BeforeDeleteValidatorAdapter((BeforeDelete.Validator) handler, orchestrator));
                } else if (handler instanceof BeforeDelete.Writer) {
                    adapters.add(new BeforeDeleteWriterAdapter((BeforeDelete.Writer) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    private class AfterDeleteExecutionStrategy extends ExecutionStrategy {
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

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
        public override List<HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<HandlerAdapter> adapters = new List<HandlerAdapter>();

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

    private abstract class HandlerAdapter {
        protected String handlerName;

        protected TriggerOrchestrator orchestrator;
        protected ParentDeclaration parentDeclaration;
        protected RelatedLoader relatedLoader;
        protected HandlerLifecycle handlerLifecycle;

        protected List<TriggerTypes.TriggerRecord> qualifiedRecords = new List<TriggerTypes.TriggerRecord>();

        public HandlerAdapter(Object handler, TriggerOrchestrator orchestrator) {
            this.handlerName = handler.toString().substringBefore(':');
            this.orchestrator = orchestrator;
        }

        public Boolean isBypassed() {
            return this.isBypassedByApexOrMetadata() || this.handlerLifecycle.isBypassedByAddOn();
        }

        private Boolean isBypassedByApexOrMetadata() {
            return TriggerOrchestrator.triggerBypass.isHandlerBypassed(this.handlerName) ||
                TriggerOrchestrator.metadataBypass.isHandlerBypassed(this.orchestrator.context, this.handlerName);
        }

        public abstract void execute(List<TriggerTypes.TriggerRecord> records);

        protected void handleException(Exception e) {
            this.logError(e);

            if (e instanceof TriggerTypes.TriggerLibException || !this.handlerLifecycle.continuesOnError()) {
                throw e;
            }
        }

        protected void logError(Exception e) {
            TriggerOrchestrator.triggerLogger.log(new TriggerError().withException(e).withHandlerName(this.handlerName).withContext(this.orchestrator.context));
        }
    }

    private class BeforeInsertPopulatorAdapter extends HandlerAdapter {
        private BeforeInsert.Populator populator;

        public BeforeInsertPopulatorAdapter(BeforeInsert.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);

            this.populator = populator;
            this.parentDeclaration = new BeforeInsertParentDeclaration(this.populator);
            this.relatedLoader = new BeforeInsertRelatedLoader(this.populator);
            this.handlerLifecycle = new BeforeInsertHandlerLifecycle(this.populator);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.populate(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerTypes.TriggerLibException guardException = new TriggerTypes.TriggerLibException(
                    this.handlerName + ' performed DML in before insert. Move that work to an after insert Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }

            this.orchestrator.parentLoader.refreshNewParents(this.qualifiedRecords);
        }

        private void populate(TriggerTypes.TriggerRecord record) {
            if (!this.populator.populateOnBeforeInsertWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
            this.populator.populateOnBeforeInsert(record);
        }
    }

    private class BeforeInsertValidatorAdapter extends HandlerAdapter {
        private BeforeInsert.Validator validator;

        public BeforeInsertValidatorAdapter(BeforeInsert.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);

            this.validator = validator;
            this.parentDeclaration = new BeforeInsertParentDeclaration(this.validator);
            this.relatedLoader = new BeforeInsertRelatedLoader(this.validator);
            this.handlerLifecycle = new BeforeInsertHandlerLifecycle(this.validator);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerTypes.TriggerLibException guardException = new TriggerTypes.TriggerLibException(
                    this.handlerName + ' performed DML in before insert. Move that work to an after insert Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }
        }

        private void validate(TriggerTypes.TriggerRecord record) {
            if (!this.validator.addErrorOnBeforeInsertWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);

            Integer errorsBefore = record.getNewSObject().getErrors().size();

            this.validator.addErrorOnBeforeInsert(record);

            if (record.getNewSObject().getErrors().size() == errorsBefore) {
                throw new TriggerTypes.TriggerLibException(this.handlerName + ' qualified a record in addErrorOnBeforeInsertWhen but attached no error in addErrorOnBeforeInsert.');
            }
        }
    }

    private class AfterInsertWriterAdapter extends HandlerAdapter {
        private AfterInsert.Writer writer;
        private UnitOfWork unitOfWork;

        public AfterInsertWriterAdapter(AfterInsert.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterInsertParentDeclaration(this.writer);
            this.relatedLoader = new AfterInsertRelatedLoader(this.writer);
            this.unitOfWork = new AfterInsertUnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new AfterInsertHandlerLifecycle(this.writer);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.write(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerTypes.TriggerRecord record) {
            if (!this.writer.writeOnAfterInsertWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
            this.writer.writeOnAfterInsert(record, this.unitOfWork);
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    private class AfterInsertDispatcherAdapter extends HandlerAdapter {
        private AfterInsert.Dispatcher dispatcher;

        public AfterInsertDispatcherAdapter(AfterInsert.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterInsertParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterInsertRelatedLoader(this.dispatcher);
            this.handlerLifecycle = new AfterInsertHandlerLifecycle(this.dispatcher);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerTypes.TriggerRecord record) {
            if (!this.dispatcher.dispatchOnAfterInsertWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
        }

        private void dispatch() {
            if (this.qualifiedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterInsert(new TriggerTypes.InsertTriggerRecords(this.qualifiedRecords));
        }
    }

    private class BeforeUpdatePopulatorAdapter extends HandlerAdapter {
        private BeforeUpdate.Populator populator;
        private RecursionTracker recursionTracker;

        public BeforeUpdatePopulatorAdapter(BeforeUpdate.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);

            this.populator = populator;
            this.parentDeclaration = new BeforeUpdateParentDeclaration(this.populator);
            this.relatedLoader = new BeforeUpdateRelatedLoader(this.populator);
            this.handlerLifecycle = new BeforeUpdateHandlerLifecycle(this.populator);
            this.recursionTracker = new BeforeUpdateRecursionTracker(this.populator, this.handlerName);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.populate(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerTypes.TriggerLibException guardException = new TriggerTypes.TriggerLibException(
                    this.handlerName + ' performed DML in before update. Move that work to an after update Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }

            this.orchestrator.parentLoader.refreshNewParents(this.qualifiedRecords);
        }

        private void populate(TriggerTypes.TriggerRecord record) {
            if (this.recursionTracker.isLimitReached(record) || !this.populator.populateOnBeforeUpdateWhen(record)) {
                return;
            }

            this.recursionTracker.countRun(record);
            this.qualifiedRecords.add(record);
            this.populator.populateOnBeforeUpdate(record);
        }
    }

    private class BeforeUpdateValidatorAdapter extends HandlerAdapter {
        private BeforeUpdate.Validator validator;

        public BeforeUpdateValidatorAdapter(BeforeUpdate.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);

            this.validator = validator;
            this.parentDeclaration = new BeforeUpdateParentDeclaration(this.validator);
            this.relatedLoader = new BeforeUpdateRelatedLoader(this.validator);
            this.handlerLifecycle = new BeforeUpdateHandlerLifecycle(this.validator);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerTypes.TriggerLibException guardException = new TriggerTypes.TriggerLibException(
                    this.handlerName + ' performed DML in before update. Move that work to an after update Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }
        }

        private void validate(TriggerTypes.TriggerRecord record) {
            if (!this.validator.addErrorOnBeforeUpdateWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);

            Integer errorsBefore = record.getNewSObject().getErrors().size();

            this.validator.addErrorOnBeforeUpdate(record);

            if (record.getNewSObject().getErrors().size() == errorsBefore) {
                throw new TriggerTypes.TriggerLibException(this.handlerName + ' qualified a record in addErrorOnBeforeUpdateWhen but attached no error in addErrorOnBeforeUpdate.');
            }
        }
    }

    private class AfterUpdateWriterAdapter extends HandlerAdapter {
        private AfterUpdate.Writer writer;
        private UnitOfWork unitOfWork;
        private RecursionTracker recursionTracker;

        public AfterUpdateWriterAdapter(AfterUpdate.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterUpdateParentDeclaration(this.writer);
            this.relatedLoader = new AfterUpdateRelatedLoader(this.writer);
            this.unitOfWork = new AfterUpdateUnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new AfterUpdateHandlerLifecycle(this.writer);
            this.recursionTracker = new AfterUpdateRecursionTracker(this.writer, this.handlerName);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.write(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerTypes.TriggerRecord record) {
            if (this.recursionTracker.isLimitReached(record) || !this.writer.writeOnAfterUpdateWhen(record)) {
                return;
            }

            this.recursionTracker.countRun(record);
            this.qualifiedRecords.add(record);
            this.writer.writeOnAfterUpdate(record, this.unitOfWork);
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    private class AfterUpdateDispatcherAdapter extends HandlerAdapter {
        private AfterUpdate.Dispatcher dispatcher;
        private RecursionTracker recursionTracker;

        public AfterUpdateDispatcherAdapter(AfterUpdate.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterUpdateParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterUpdateRelatedLoader(this.dispatcher);
            this.handlerLifecycle = new AfterUpdateHandlerLifecycle(this.dispatcher);
            this.recursionTracker = new AfterUpdateRecursionTracker(this.dispatcher, this.handlerName);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerTypes.TriggerRecord record) {
            if (this.recursionTracker.isLimitReached(record) || !this.dispatcher.dispatchOnAfterUpdateWhen(record)) {
                return;
            }

            this.recursionTracker.countRun(record);
            this.qualifiedRecords.add(record);
        }

        private void dispatch() {
            if (this.qualifiedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterUpdate(new TriggerTypes.UpdateTriggerRecords(this.qualifiedRecords));
        }
    }

    private class BeforeDeleteValidatorAdapter extends HandlerAdapter {
        private BeforeDelete.Validator validator;

        public BeforeDeleteValidatorAdapter(BeforeDelete.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);

            this.validator = validator;
            this.parentDeclaration = new BeforeDeleteParentDeclaration(this.validator);
            this.relatedLoader = new BeforeDeleteRelatedLoader(this.validator);
            this.handlerLifecycle = new BeforeDeleteHandlerLifecycle(this.validator);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void validate(TriggerTypes.TriggerRecord record) {
            if (!this.validator.addErrorOnBeforeDeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);

            Integer errorsBefore = record.getOldSObject().getErrors().size();

            this.validator.addErrorOnBeforeDelete(record);

            if (record.getOldSObject().getErrors().size() == errorsBefore) {
                throw new TriggerTypes.TriggerLibException(this.handlerName + ' qualified a record in addErrorOnBeforeDeleteWhen but attached no error in addErrorOnBeforeDelete.');
            }
        }
    }

    private class BeforeDeleteWriterAdapter extends HandlerAdapter {
        private BeforeDelete.Writer writer;
        private UnitOfWork unitOfWork;

        public BeforeDeleteWriterAdapter(BeforeDelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new BeforeDeleteParentDeclaration(this.writer);
            this.relatedLoader = new BeforeDeleteRelatedLoader(this.writer);
            this.unitOfWork = new BeforeDeleteUnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new BeforeDeleteHandlerLifecycle(this.writer);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.write(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerTypes.TriggerRecord record) {
            if (!this.writer.writeOnBeforeDeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
            this.writer.writeOnBeforeDelete(record, this.unitOfWork);
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    private class AfterDeleteWriterAdapter extends HandlerAdapter {
        private AfterDelete.Writer writer;
        private UnitOfWork unitOfWork;

        public AfterDeleteWriterAdapter(AfterDelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterDeleteParentDeclaration(this.writer);
            this.relatedLoader = new AfterDeleteRelatedLoader(this.writer);
            this.unitOfWork = new AfterDeleteUnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new AfterDeleteHandlerLifecycle(this.writer);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.write(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerTypes.TriggerRecord record) {
            if (!this.writer.writeOnAfterDeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
            this.writer.writeOnAfterDelete(record, this.unitOfWork);
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    private class AfterDeleteDispatcherAdapter extends HandlerAdapter {
        private AfterDelete.Dispatcher dispatcher;

        public AfterDeleteDispatcherAdapter(AfterDelete.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterDeleteParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterDeleteRelatedLoader(this.dispatcher);
            this.handlerLifecycle = new AfterDeleteHandlerLifecycle(this.dispatcher);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerTypes.TriggerRecord record) {
            if (!this.dispatcher.dispatchOnAfterDeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
        }

        private void dispatch() {
            if (this.qualifiedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterDelete(new TriggerTypes.DeleteTriggerRecords(this.qualifiedRecords));
        }
    }

    private class AfterUndeleteWriterAdapter extends HandlerAdapter {
        private AfterUndelete.Writer writer;
        private UnitOfWork unitOfWork;

        public AfterUndeleteWriterAdapter(AfterUndelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterUndeleteParentDeclaration(this.writer);
            this.relatedLoader = new AfterUndeleteRelatedLoader(this.writer);
            this.unitOfWork = new AfterUndeleteUnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new AfterUndeleteHandlerLifecycle(this.writer);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.write(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerTypes.TriggerRecord record) {
            if (!this.writer.writeOnAfterUndeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
            this.writer.writeOnAfterUndelete(record, this.unitOfWork);
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    private class AfterUndeleteDispatcherAdapter extends HandlerAdapter {
        private AfterUndelete.Dispatcher dispatcher;

        public AfterUndeleteDispatcherAdapter(AfterUndelete.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterUndeleteParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterUndeleteRelatedLoader(this.dispatcher);
            this.handlerLifecycle = new AfterUndeleteHandlerLifecycle(this.dispatcher);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerTypes.TriggerRecord record) {
            if (!this.dispatcher.dispatchOnAfterUndeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
        }

        private void dispatch() {
            if (this.qualifiedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterUndelete(new TriggerTypes.UndeleteTriggerRecords(this.qualifiedRecords));
        }
    }

    private abstract class ParentDeclaration {
        public virtual Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }

        public virtual Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class BeforeInsertParentDeclaration extends ParentDeclaration {
        private BeforeInsert.Handler handler;

        public BeforeInsertParentDeclaration(BeforeInsert.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof BeforeInsert.ParentQuery) {
                return ((BeforeInsert.ParentQuery) this.handler).queryParentsOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class AfterInsertParentDeclaration extends ParentDeclaration {
        private AfterInsert.Handler handler;

        public AfterInsertParentDeclaration(AfterInsert.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof AfterInsert.ParentQuery) {
                return ((AfterInsert.ParentQuery) this.handler).queryParentsOnAfterInsert();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class BeforeUpdateParentDeclaration extends ParentDeclaration {
        private BeforeUpdate.Handler handler;

        public BeforeUpdateParentDeclaration(BeforeUpdate.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof BeforeUpdate.ParentQuery) {
                return ((BeforeUpdate.ParentQuery) this.handler).queryParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof BeforeUpdate.PriorParentQuery) {
                return ((BeforeUpdate.PriorParentQuery) this.handler).queryPriorParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class AfterUpdateParentDeclaration extends ParentDeclaration {
        private AfterUpdate.Handler handler;

        public AfterUpdateParentDeclaration(AfterUpdate.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof AfterUpdate.ParentQuery) {
                return ((AfterUpdate.ParentQuery) this.handler).queryParentsOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof AfterUpdate.PriorParentQuery) {
                return ((AfterUpdate.PriorParentQuery) this.handler).queryPriorParentsOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class BeforeDeleteParentDeclaration extends ParentDeclaration {
        private BeforeDelete.Handler handler;

        public BeforeDeleteParentDeclaration(BeforeDelete.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof BeforeDelete.PriorParentQuery) {
                return ((BeforeDelete.PriorParentQuery) this.handler).queryPriorParentsOnBeforeDelete();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class AfterDeleteParentDeclaration extends ParentDeclaration {
        private AfterDelete.Handler handler;

        public AfterDeleteParentDeclaration(AfterDelete.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof AfterDelete.PriorParentQuery) {
                return ((AfterDelete.PriorParentQuery) this.handler).queryPriorParentsOnAfterDelete();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class AfterUndeleteParentDeclaration extends ParentDeclaration {
        private AfterUndelete.Handler handler;

        public AfterUndeleteParentDeclaration(AfterUndelete.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof AfterUndelete.ParentQuery) {
                return ((AfterUndelete.ParentQuery) this.handler).queryParentsOnAfterUndelete();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    private class ParentLoader implements TriggerTypes.ParentLoader {
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

        public void collectDeclarations(List<HandlerAdapter> handlers) {
            for (HandlerAdapter handler : handlers) {
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

    private abstract class RelatedLoader implements TriggerTypes.RelatedLoader {
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

    private class BeforeInsertRelatedLoader extends RelatedLoader {
        private BeforeInsert.Handler handler;
        private Map<String, BeforeInsert.RecordsProvider> providers;

        public BeforeInsertRelatedLoader(BeforeInsert.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof BeforeInsert.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((BeforeInsert.RelatedQuery) this.handler).queryRelatedOnBeforeInsert() ?? new Map<String, BeforeInsert.RecordsProvider>();
            }

            BeforeInsert.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.InsertRecords insertRecords = new TriggerTypes.InsertTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(insertRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private class AfterInsertRelatedLoader extends RelatedLoader {
        private AfterInsert.Handler handler;
        private Map<String, AfterInsert.RecordsProvider> providers;

        public AfterInsertRelatedLoader(AfterInsert.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof AfterInsert.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((AfterInsert.RelatedQuery) this.handler).queryRelatedOnAfterInsert() ?? new Map<String, AfterInsert.RecordsProvider>();
            }

            AfterInsert.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.InsertRecords insertRecords = new TriggerTypes.InsertTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(insertRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private class BeforeUpdateRelatedLoader extends RelatedLoader {
        private BeforeUpdate.Handler handler;
        private Map<String, BeforeUpdate.RecordsProvider> providers;

        public BeforeUpdateRelatedLoader(BeforeUpdate.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof BeforeUpdate.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((BeforeUpdate.RelatedQuery) this.handler).queryRelatedOnBeforeUpdate() ?? new Map<String, BeforeUpdate.RecordsProvider>();
            }

            BeforeUpdate.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.UpdateRecords updateRecords = new TriggerTypes.UpdateTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(updateRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private class AfterUpdateRelatedLoader extends RelatedLoader {
        private AfterUpdate.Handler handler;
        private Map<String, AfterUpdate.RecordsProvider> providers;

        public AfterUpdateRelatedLoader(AfterUpdate.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof AfterUpdate.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((AfterUpdate.RelatedQuery) this.handler).queryRelatedOnAfterUpdate() ?? new Map<String, AfterUpdate.RecordsProvider>();
            }

            AfterUpdate.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.UpdateRecords updateRecords = new TriggerTypes.UpdateTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(updateRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private class BeforeDeleteRelatedLoader extends RelatedLoader {
        private BeforeDelete.Handler handler;
        private Map<String, BeforeDelete.RecordsProvider> providers;

        public BeforeDeleteRelatedLoader(BeforeDelete.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof BeforeDelete.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((BeforeDelete.RelatedQuery) this.handler).queryRelatedOnBeforeDelete() ?? new Map<String, BeforeDelete.RecordsProvider>();
            }

            BeforeDelete.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.DeleteRecords deleteRecords = new TriggerTypes.DeleteTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(deleteRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private class AfterDeleteRelatedLoader extends RelatedLoader {
        private AfterDelete.Handler handler;
        private Map<String, AfterDelete.RecordsProvider> providers;

        public AfterDeleteRelatedLoader(AfterDelete.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof AfterDelete.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((AfterDelete.RelatedQuery) this.handler).queryRelatedOnAfterDelete() ?? new Map<String, AfterDelete.RecordsProvider>();
            }

            AfterDelete.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.DeleteRecords deleteRecords = new TriggerTypes.DeleteTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(deleteRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private class AfterUndeleteRelatedLoader extends RelatedLoader {
        private AfterUndelete.Handler handler;
        private Map<String, AfterUndelete.RecordsProvider> providers;

        public AfterUndeleteRelatedLoader(AfterUndelete.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof AfterUndelete.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((AfterUndelete.RelatedQuery) this.handler).queryRelatedOnAfterUndelete() ?? new Map<String, AfterUndelete.RecordsProvider>();
            }

            AfterUndelete.RecordsProvider provider = this.providers.get(providerName);

            if (provider == null) {
                return null;
            }

            TriggerTypes.UndeleteRecords undeleteRecords = new TriggerTypes.UndeleteTriggerRecords(this.records);
            TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(provider.query(undeleteRecords));

            for (SObject row : related.getRecords()) {
                related.groupUnderKey(provider.keyOf(row), row);
            }

            return related;
        }
    }

    private abstract class UnitOfWorkResolver {
        public abstract UnitOfWork resolve(UnitOfWork sharedUnitOfWork);
    }

    private class AfterInsertUnitOfWorkResolver extends UnitOfWorkResolver {
        private AfterInsert.Writer writer;

        public AfterInsertUnitOfWorkResolver(AfterInsert.Writer writer) {
            this.writer = writer;
        }

        public override UnitOfWork resolve(UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof AfterInsert.OwnUnitOfWork
                ? new UnitOfWork(((AfterInsert.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterInsert())
                : this.writer instanceof AfterInsert.ContinueOnError ? new UnitOfWork() : sharedUnitOfWork;
        }
    }

    private class AfterUpdateUnitOfWorkResolver extends UnitOfWorkResolver {
        private AfterUpdate.Writer writer;

        public AfterUpdateUnitOfWorkResolver(AfterUpdate.Writer writer) {
            this.writer = writer;
        }

        public override UnitOfWork resolve(UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof AfterUpdate.OwnUnitOfWork
                ? new UnitOfWork(((AfterUpdate.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterUpdate())
                : this.writer instanceof AfterUpdate.ContinueOnError ? new UnitOfWork() : sharedUnitOfWork;
        }
    }

    private class BeforeDeleteUnitOfWorkResolver extends UnitOfWorkResolver {
        private BeforeDelete.Writer writer;

        public BeforeDeleteUnitOfWorkResolver(BeforeDelete.Writer writer) {
            this.writer = writer;
        }

        public override UnitOfWork resolve(UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof BeforeDelete.OwnUnitOfWork
                ? new UnitOfWork(((BeforeDelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnBeforeDelete())
                : this.writer instanceof BeforeDelete.ContinueOnError ? new UnitOfWork() : sharedUnitOfWork;
        }
    }

    private class AfterDeleteUnitOfWorkResolver extends UnitOfWorkResolver {
        private AfterDelete.Writer writer;

        public AfterDeleteUnitOfWorkResolver(AfterDelete.Writer writer) {
            this.writer = writer;
        }

        public override UnitOfWork resolve(UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof AfterDelete.OwnUnitOfWork
                ? new UnitOfWork(((AfterDelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterDelete())
                : this.writer instanceof AfterDelete.ContinueOnError ? new UnitOfWork() : sharedUnitOfWork;
        }
    }

    private class AfterUndeleteUnitOfWorkResolver extends UnitOfWorkResolver {
        private AfterUndelete.Writer writer;

        public AfterUndeleteUnitOfWorkResolver(AfterUndelete.Writer writer) {
            this.writer = writer;
        }

        public override UnitOfWork resolve(UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof AfterUndelete.OwnUnitOfWork
                ? new UnitOfWork(((AfterUndelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterUndelete())
                : this.writer instanceof AfterUndelete.ContinueOnError ? new UnitOfWork() : sharedUnitOfWork;
        }
    }

    private class UnitOfWork implements TriggerTypes.UnitOfWork {
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

    private abstract class HandlerLifecycle {
        public abstract Boolean isBypassedByAddOn();
        public abstract void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords);
        public abstract Boolean continuesOnError();
    }

    private class BeforeInsertHandlerLifecycle extends HandlerLifecycle {
        private BeforeInsert.Handler handler;

        public BeforeInsertHandlerLifecycle(BeforeInsert.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof BeforeInsert.Bypassable && ((BeforeInsert.Bypassable) this.handler).bypassOnBeforeInsertWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof BeforeInsert.Finalizer)) {
                return;
            }

            ((BeforeInsert.Finalizer) this.handler).finalizeOnBeforeInsert(new TriggerTypes.InsertTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }
    }

    private class AfterInsertHandlerLifecycle extends HandlerLifecycle {
        private AfterInsert.Handler handler;

        public AfterInsertHandlerLifecycle(AfterInsert.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof AfterInsert.Bypassable && ((AfterInsert.Bypassable) this.handler).bypassOnAfterInsertWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof AfterInsert.Finalizer)) {
                return;
            }

            ((AfterInsert.Finalizer) this.handler).finalizeOnAfterInsert(new TriggerTypes.InsertTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterInsert.ContinueOnError;
        }
    }

    private class BeforeUpdateHandlerLifecycle extends HandlerLifecycle {
        private BeforeUpdate.Handler handler;

        public BeforeUpdateHandlerLifecycle(BeforeUpdate.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof BeforeUpdate.Bypassable && ((BeforeUpdate.Bypassable) this.handler).bypassOnBeforeUpdateWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof BeforeUpdate.Finalizer)) {
                return;
            }

            ((BeforeUpdate.Finalizer) this.handler).finalizeOnBeforeUpdate(new TriggerTypes.UpdateTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }
    }

    private class AfterUpdateHandlerLifecycle extends HandlerLifecycle {
        private AfterUpdate.Handler handler;

        public AfterUpdateHandlerLifecycle(AfterUpdate.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof AfterUpdate.Bypassable && ((AfterUpdate.Bypassable) this.handler).bypassOnAfterUpdateWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof AfterUpdate.Finalizer)) {
                return;
            }

            ((AfterUpdate.Finalizer) this.handler).finalizeOnAfterUpdate(new TriggerTypes.UpdateTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterUpdate.ContinueOnError;
        }
    }

    private class BeforeDeleteHandlerLifecycle extends HandlerLifecycle {
        private BeforeDelete.Handler handler;

        public BeforeDeleteHandlerLifecycle(BeforeDelete.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof BeforeDelete.Bypassable && ((BeforeDelete.Bypassable) this.handler).bypassOnBeforeDeleteWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof BeforeDelete.Finalizer)) {
                return;
            }

            ((BeforeDelete.Finalizer) this.handler).finalizeOnBeforeDelete(new TriggerTypes.DeleteTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeDelete.ContinueOnError;
        }
    }

    private class AfterDeleteHandlerLifecycle extends HandlerLifecycle {
        private AfterDelete.Handler handler;

        public AfterDeleteHandlerLifecycle(AfterDelete.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof AfterDelete.Bypassable && ((AfterDelete.Bypassable) this.handler).bypassOnAfterDeleteWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof AfterDelete.Finalizer)) {
                return;
            }

            ((AfterDelete.Finalizer) this.handler).finalizeOnAfterDelete(new TriggerTypes.DeleteTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterDelete.ContinueOnError;
        }
    }

    private class AfterUndeleteHandlerLifecycle extends HandlerLifecycle {
        private AfterUndelete.Handler handler;

        public AfterUndeleteHandlerLifecycle(AfterUndelete.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof AfterUndelete.Bypassable && ((AfterUndelete.Bypassable) this.handler).bypassOnAfterUndeleteWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof AfterUndelete.Finalizer)) {
                return;
            }

            ((AfterUndelete.Finalizer) this.handler).finalizeOnAfterUndelete(new TriggerTypes.UndeleteTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof AfterUndelete.ContinueOnError;
        }
    }

    private abstract class RecursionTracker {
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

    private class BeforeUpdateRecursionTracker extends RecursionTracker {
        public BeforeUpdateRecursionTracker(BeforeUpdate.Handler handler, String handlerName) {
            super(handlerName + ':BEFORE_UPDATE');

            if (handler instanceof BeforeUpdate.RecursionGuard) {
                this.maxRunsPerRecord = ((BeforeUpdate.RecursionGuard) handler).maxRunsPerRecordOnBeforeUpdate();
            }
        }
    }

    private class AfterUpdateRecursionTracker extends RecursionTracker {
        public AfterUpdateRecursionTracker(AfterUpdate.Handler handler, String handlerName) {
            super(handlerName + ':AFTER_UPDATE');

            if (handler instanceof AfterUpdate.RecursionGuard) {
                this.maxRunsPerRecord = ((AfterUpdate.RecursionGuard) handler).maxRunsPerRecordOnAfterUpdate();
            }
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
            BeforeInsertMockedContext mockedContext = new BeforeInsertMockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterInsertMockable afterInsertFor(System.Type handlerOrOrchestratorType) {
            AfterInsertMockedContext mockedContext = new AfterInsertMockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public BeforeUpdateMockable beforeUpdateFor(System.Type handlerOrOrchestratorType) {
            BeforeUpdateMockedContext mockedContext = new BeforeUpdateMockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterUpdateMockable afterUpdateFor(System.Type handlerOrOrchestratorType) {
            AfterUpdateMockedContext mockedContext = new AfterUpdateMockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public BeforeDeleteMockable beforeDeleteFor(System.Type handlerOrOrchestratorType) {
            BeforeDeleteMockedContext mockedContext = new BeforeDeleteMockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterDeleteMockable afterDeleteFor(System.Type handlerOrOrchestratorType) {
            AfterDeleteMockedContext mockedContext = new AfterDeleteMockedContext();
            this.addMockedContext(handlerOrOrchestratorType, mockedContext);
            return mockedContext;
        }

        public AfterUndeleteMockable afterUndeleteFor(System.Type handlerOrOrchestratorType) {
            AfterUndeleteMockedContext mockedContext = new AfterUndeleteMockedContext();
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

    private abstract class MockedContext {
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

    private class BeforeInsertMockedContext extends MockedContext implements BeforeInsertMockable, TriggerOrchestrator.BeforeInsert {
        public BeforeInsertMockedContext() {
            super(System.TriggerOperation.BEFORE_INSERT);
        }

        public BeforeInsertMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public BeforeInsertMockable with(List<SObject> rows) {
            this.newRecords.addAll(rows);
            return this;
        }

        public BeforeInsertMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public BeforeInsertMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.BeforeInsert
                ? ((TriggerOrchestrator.BeforeInsert) this.handlerOrOrchestrator).beforeInsertHandlers()
                : new List<BeforeInsert.Handler>{ (BeforeInsert.Handler) this.handlerOrOrchestrator };
        }
    }

    private class AfterInsertMockedContext extends MockedContext implements AfterInsertMockable, TriggerOrchestrator.AfterInsert {
        public AfterInsertMockedContext() {
            super(System.TriggerOperation.AFTER_INSERT);
        }

        public AfterInsertMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public AfterInsertMockable with(List<SObject> rows) {
            this.newRecords.addAll(this.assignIds(rows));
            return this;
        }

        public AfterInsertMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public AfterInsertMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterInsert
                ? ((TriggerOrchestrator.AfterInsert) this.handlerOrOrchestrator).afterInsertHandlers()
                : new List<AfterInsert.Handler>{ (AfterInsert.Handler) this.handlerOrOrchestrator };
        }
    }

    private class BeforeUpdateMockedContext extends MockedContext implements BeforeUpdateMockable, TriggerOrchestrator.BeforeUpdate {
        public BeforeUpdateMockedContext() {
            super(System.TriggerOperation.BEFORE_UPDATE);
        }

        public BeforeUpdateMockable with(SObject newRow, SObject oldRow) {
            return this.with(new List<SObject>{ newRow }, new List<SObject>{ oldRow });
        }

        public BeforeUpdateMockable with(List<SObject> newRows, List<SObject> oldRows) {
            this.shareIds(newRows, oldRows);
            this.newRecords.addAll(newRows);
            this.oldRecords.addAll(oldRows);
            return this;
        }

        public BeforeUpdateMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public BeforeUpdateMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.BeforeUpdate
                ? ((TriggerOrchestrator.BeforeUpdate) this.handlerOrOrchestrator).beforeUpdateHandlers()
                : new List<BeforeUpdate.Handler>{ (BeforeUpdate.Handler) this.handlerOrOrchestrator };
        }
    }

    private class AfterUpdateMockedContext extends MockedContext implements AfterUpdateMockable, TriggerOrchestrator.AfterUpdate {
        public AfterUpdateMockedContext() {
            super(System.TriggerOperation.AFTER_UPDATE);
        }

        public AfterUpdateMockable with(SObject newRow, SObject oldRow) {
            return this.with(new List<SObject>{ newRow }, new List<SObject>{ oldRow });
        }

        public AfterUpdateMockable with(List<SObject> newRows, List<SObject> oldRows) {
            this.shareIds(newRows, oldRows);
            this.newRecords.addAll(newRows);
            this.oldRecords.addAll(oldRows);
            return this;
        }

        public AfterUpdateMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public AfterUpdateMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterUpdate
                ? ((TriggerOrchestrator.AfterUpdate) this.handlerOrOrchestrator).afterUpdateHandlers()
                : new List<AfterUpdate.Handler>{ (AfterUpdate.Handler) this.handlerOrOrchestrator };
        }
    }

    private class BeforeDeleteMockedContext extends MockedContext implements BeforeDeleteMockable, TriggerOrchestrator.BeforeDelete {
        public BeforeDeleteMockedContext() {
            super(System.TriggerOperation.BEFORE_DELETE);
        }

        public BeforeDeleteMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public BeforeDeleteMockable with(List<SObject> rows) {
            this.oldRecords.addAll(this.assignIds(rows));
            return this;
        }

        public BeforeDeleteMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public BeforeDeleteMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.BeforeDelete
                ? ((TriggerOrchestrator.BeforeDelete) this.handlerOrOrchestrator).beforeDeleteHandlers()
                : new List<BeforeDelete.Handler>{ (BeforeDelete.Handler) this.handlerOrOrchestrator };
        }
    }

    private class AfterDeleteMockedContext extends MockedContext implements AfterDeleteMockable, TriggerOrchestrator.AfterDelete {
        public AfterDeleteMockedContext() {
            super(System.TriggerOperation.AFTER_DELETE);
        }

        public AfterDeleteMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public AfterDeleteMockable with(List<SObject> rows) {
            this.oldRecords.addAll(this.assignIds(rows));
            return this;
        }

        public AfterDeleteMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public AfterDeleteMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterDelete
                ? ((TriggerOrchestrator.AfterDelete) this.handlerOrOrchestrator).afterDeleteHandlers()
                : new List<AfterDelete.Handler>{ (AfterDelete.Handler) this.handlerOrOrchestrator };
        }
    }

    private class AfterUndeleteMockedContext extends MockedContext implements AfterUndeleteMockable, TriggerOrchestrator.AfterUndelete {
        public AfterUndeleteMockedContext() {
            super(System.TriggerOperation.AFTER_UNDELETE);
        }

        public AfterUndeleteMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public AfterUndeleteMockable with(List<SObject> rows) {
            this.newRecords.addAll(this.assignIds(rows));
            return this;
        }

        public AfterUndeleteMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public AfterUndeleteMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterUndelete
                ? ((TriggerOrchestrator.AfterUndelete) this.handlerOrOrchestrator).afterUndeleteHandlers()
                : new List<AfterUndelete.Handler>{ (AfterUndelete.Handler) this.handlerOrOrchestrator };
        }
    }
}
