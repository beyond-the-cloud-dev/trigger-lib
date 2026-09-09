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
        void log(Error error);
        void finalize();
    }

    public interface Error {
        Exception getException();
        String getHandlerName();
        System.TriggerOperation getOperation();
        SObjectType getSObjectType();
        Set<Id> getRecordIds();
    }

    // Implementations

    private static List<Invocation> invocationStack = new List<Invocation>();
    private static Map<String, Integer> recursionDepthByHandlerRecord = new Map<String, Integer>();
    private static Boolean isLoggerResolved = false;

    @TestVisible
    private static Logger logger {
        get {
            if (!isLoggerResolved) {
                logger = resolveLogger();
                isLoggerResolved = true;
            }
            return logger;
        }
        private set;
    }

    public static void run(Object orchestrator) {
        HandlerExecutor executor;

        try {
            if (Trigger.operationType == null) {
                throw new TriggerOrchestratorException('Called outside of trigger context, or not supported operation type');
            }

            Invocation invocation = new Invocation();

            TriggerOrchestrator.invocationStack.add(invocation);

            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();
            List<TriggerHandler.TriggerRecord> triggerRecords = new List<TriggerHandler.TriggerRecord>();

            if (Trigger.operationType == System.TriggerOperation.BEFORE_INSERT && orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) orchestrator).beforeInsertHandlers()) {
                    handlerAdapters.add(new BeforeInsertHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_INSERT && orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) orchestrator).afterInsertHandlers()) {
                    handlerAdapters.add(new AfterInsertHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE && orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator).beforeUpdateHandlers()) {
                    handlerAdapters.add(new BeforeUpdateHandlerAdapter(handler));
                }

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UPDATE && orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) orchestrator).afterUpdateHandlers()) {
                    handlerAdapters.add(new AfterUpdateHandlerAdapter(handler));
                }

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
                }
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_DELETE && orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) orchestrator).beforeDeleteHandlers()) {
                    handlerAdapters.add(new BeforeDeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.old) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_DELETE && orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) orchestrator).afterDeleteHandlers()) {
                    handlerAdapters.add(new AfterDeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.old) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UNDELETE && orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) orchestrator).afterUndeleteHandlers()) {
                    handlerAdapters.add(new AfterUndeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            }

            executor = new HandlerExecutor(handlerAdapters, triggerRecords);
            executor.run();
        } catch (Exception e) {
            logError(e, executor?.getCurrentHandler());

            throw e;
        } finally {
            TriggerOrchestrator.invocationStack.remove(TriggerOrchestrator.invocationStack.size() - 1);

            if (TriggerOrchestrator.invocationStack.isEmpty()) {
                TriggerOrchestrator.logger?.finalize();
            }
        }
    }

    private static Logger resolveLogger() {
        String namespacedClassName = TriggerOrchestrator.class.getName();
        String namespacePrefix = namespacedClassName.contains('.') ? namespacedClassName.substringBefore('.') : null;

        List<ApexTypeImplementor> implementors = [
            SELECT ClassName, ClassNamespacePrefix
            FROM ApexTypeImplementor
            WHERE InterfaceName = 'TriggerOrchestrator.Logger' AND InterfaceNamespacePrefix = :namespacePrefix AND IsConcrete = TRUE
            WITH SYSTEM_MODE
            LIMIT 2
        ];

        if (implementors.size() > 1) {
            throw new TriggerOrchestratorException('Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.');
        }

        if (implementors.isEmpty()) {
            return null;
        }

        Object instance = Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();

        return instance instanceof Logger ? (Logger) instance : null;
    }

    private static void logError(Exception e, Object handler) {
        if (TriggerOrchestrator.logger == null) {
            return;
        }

        TriggerError error = new TriggerError();

        error.triggerException = e;
        error.handlerName = handler == null ? null : String.valueOf(handler).substringBefore(':');
        error.operation = Trigger.operationType;
        error.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
        error.recordIds = (Trigger.newMap ?? Trigger.oldMap)?.keySet();

        TriggerOrchestrator.logger.log(error);
    }

    private class Invocation {
        private System.TriggerOperation operationType;
        private SObjectType sObjectType;
        private Integer recordCount;
        private Integer nestingLevel;

        private Invocation() {
            this.operationType = Trigger.operationType;
            this.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
            this.recordCount = (Trigger.new ?? Trigger.old)?.size() ?? 0;
            this.nestingLevel = TriggerOrchestrator.invocationStack.size();
        }
    }

    private class TriggerError implements Error {
        public Exception triggerException;
        public String handlerName;
        public System.TriggerOperation operation;
        public SObjectType sObjectType;
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

    private class HandlerExecutor {
        private List<TriggerHandlerAdapter> candidateAdapters;
        private List<TriggerHandlerAdapter> activeHandlers;
        private List<TriggerHandler.TriggerRecord> records;
        private Object currentHandler;

        private HandlerExecutor(List<TriggerHandlerAdapter> candidateAdapters, List<TriggerHandler.TriggerRecord> records) {
            this.candidateAdapters = candidateAdapters;
            this.records = records;
            this.activeHandlers = new List<TriggerHandlerAdapter>();
        }

        public void run() {
            this.gatherActiveHandlers();
            this.enrichRecords();
            this.qualifyRecords();
            this.executeHandlers();
        }

        public Object getCurrentHandler() {
            return this.currentHandler;
        }

        private void gatherActiveHandlers() {
            for (TriggerHandlerAdapter adapter : this.candidateAdapters) {
                this.currentHandler = adapter.getHandler();

                if (!adapter.isBypassed()) {
                    this.activeHandlers.add(adapter);
                }
            }
        }

        private void enrichRecords() {
            new ParentRelationshipEnrichment(this.activeHandlers, this.records).enrich();
        }

        private void qualifyRecords() {
            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                this.currentHandler = adapter.getHandler();

                for (TriggerHandler.TriggerRecord record : records) {
                    if (adapter.isRecursionDepthExceeded(record)) {
                        continue;
                    }

                    if (adapter.isQualified(record)) {
                        adapter.registerRecord(record);
                    }
                }
            }
        }

        private void executeHandlers() {
            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                this.currentHandler = adapter.getHandler();

                if (adapter.getQualifiedRecords().isEmpty()) {
                    continue;
                }

                try {
                    adapter.execute();
                } catch (Exception e) {
                    if (e instanceof TriggerOrchestratorException || !adapter.continuesOnError()) {
                        throw e;
                    }

                    logError(e, adapter.getHandler());
                }
            }
        }
    }

    private abstract class TriggerHandlerAdapter {
        protected Object handler;

        private Map<String, TriggerHandler.TriggerRecord> qualifiedRecordByIdentifier;

        public TriggerHandlerAdapter(Object handler) {
            this.handler = handler;
            this.qualifiedRecordByIdentifier = new Map<String, TriggerHandler.TriggerRecord>();
        }

        public Object getHandler() {
            return this.handler;
        }

        public virtual void registerRecord(TriggerHandler.TriggerRecord record) {
            this.qualifiedRecordByIdentifier.put(record.getIdentifier(), record);
        }

        public Boolean isRecordRegistered(TriggerHandler.TriggerRecord record) {
            return this.qualifiedRecordByIdentifier.containsKey(record.getIdentifier());
        }

        public List<TriggerHandler.TriggerRecord> getQualifiedRecords() {
            return new List<TriggerHandler.TriggerRecord>(this.qualifiedRecordByIdentifier.values());
        }

        public virtual void execute() {
            for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                this.executeOn(record);
            }

            this.finalizeHandler();
        }

        public virtual Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public virtual Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public virtual Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            return false;
        }

        public abstract Boolean isBypassed();

        public abstract Boolean continuesOnError();

        public abstract Boolean isQualified(TriggerHandler.TriggerRecord record);

        protected abstract void executeOn(TriggerHandler.TriggerRecord record);

        protected abstract void finalizeHandler();
    }

    private class BeforeInsertHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeInsertHandlerAdapter(BeforeInsert.Handler handler) {
            super(handler);
        }

        public override void execute() {
            if (this.handler instanceof BeforeInsert.AllowDmls) {
                super.execute();
                return;
            }

            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                this.executeOn(record);
            }

            this.finalizeHandler();

            if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                throw new TriggerOrchestratorException(String.valueOf(this.handler).substringBefore(':') + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.');
            }
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof BeforeInsert.Bypassable) {
                return ((BeforeInsert.Bypassable) this.handler).bypassOnBeforeInsertWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeInsert.NewRecordEnrichment) {
                return ((BeforeInsert.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeInsert.Handler) this.handler).qualifiesForBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeInsert.Handler) this.handler).onBeforeInsert(record);
        }

        protected override void finalizeHandler() {
            if (this.handler instanceof BeforeInsert.Finalizer) {
                ((BeforeInsert.Finalizer) this.handler).finalizeBeforeInsert();
            }
        }
    }

    private class AfterInsertHandlerAdapter extends TriggerHandlerAdapter {
        public AfterInsertHandlerAdapter(AfterInsert.Handler handler) {
            super(handler);
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof AfterInsert.Bypassable) {
                return ((AfterInsert.Bypassable) this.handler).bypassOnAfterInsertWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
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

        protected override void finalizeHandler() {
            if (this.handler instanceof AfterInsert.Finalizer) {
                ((AfterInsert.Finalizer) this.handler).finalizeAfterInsert();
            }
        }
    }

    private class BeforeUpdateHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeUpdateHandlerAdapter(BeforeUpdate.Handler handler) {
            super(handler);
        }

        public override void execute() {
            if (this.handler instanceof BeforeUpdate.AllowDmls) {
                super.execute();
                return;
            }

            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                this.executeOn(record);
            }

            this.finalizeHandler();

            if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                throw new TriggerOrchestratorException(String.valueOf(this.handler).substringBefore(':') + ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.');
            }
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof BeforeUpdate.Bypassable) {
                return ((BeforeUpdate.Bypassable) this.handler).bypassOnBeforeUpdateWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeUpdate.NewRecordEnrichment) {
                return ((BeforeUpdate.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof BeforeUpdate.OldRecordEnrichment) {
                return ((BeforeUpdate.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public override Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            Integer maxRecursionDepth = 3;

            if (this.handler instanceof BeforeUpdate.RecursionGuard) {
                maxRecursionDepth = ((BeforeUpdate.RecursionGuard) this.handler).maxRecursionDepthOnBeforeUpdate();
            }

            String recursionKey = String.valueOf(this.handler).substringBefore(':') + ':BEFORE_UPDATE:' + record.getId();

            return (TriggerOrchestrator.recursionDepthByHandlerRecord.get(recursionKey) ?? 0) >= maxRecursionDepth;
        }

        public override void registerRecord(TriggerHandler.TriggerRecord record) {
            super.registerRecord(record);

            String recursionKey = String.valueOf(this.handler).substringBefore(':') + ':BEFORE_UPDATE:' + record.getId();

            TriggerOrchestrator.recursionDepthByHandlerRecord.put(recursionKey, (TriggerOrchestrator.recursionDepthByHandlerRecord.get(recursionKey) ?? 0) + 1);
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeUpdate.Handler) this.handler).qualifiesForBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeUpdate.Handler) this.handler).onBeforeUpdate(record);
        }

        protected override void finalizeHandler() {
            if (this.handler instanceof BeforeUpdate.Finalizer) {
                ((BeforeUpdate.Finalizer) this.handler).finalizeBeforeUpdate();
            }
        }
    }

    private class AfterUpdateHandlerAdapter extends TriggerHandlerAdapter {
        public AfterUpdateHandlerAdapter(AfterUpdate.Handler handler) {
            super(handler);
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof AfterUpdate.Bypassable) {
                return ((AfterUpdate.Bypassable) this.handler).bypassOnAfterUpdateWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof AfterUpdate.NewRecordEnrichment) {
                return ((AfterUpdate.NewRecordEnrichment) this.handler).newFieldsToEnrichOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
            if (this.handler instanceof AfterUpdate.OldRecordEnrichment) {
                return ((AfterUpdate.OldRecordEnrichment) this.handler).oldFieldsToEnrichOnAfterUpdate();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public override Boolean isRecursionDepthExceeded(TriggerHandler.TriggerRecord record) {
            Integer maxRecursionDepth = 3;

            if (this.handler instanceof AfterUpdate.RecursionGuard) {
                maxRecursionDepth = ((AfterUpdate.RecursionGuard) this.handler).maxRecursionDepthOnAfterUpdate();
            }

            String recursionKey = String.valueOf(this.handler).substringBefore(':') + ':AFTER_UPDATE:' + record.getId();

            return (TriggerOrchestrator.recursionDepthByHandlerRecord.get(recursionKey) ?? 0) >= maxRecursionDepth;
        }

        public override void registerRecord(TriggerHandler.TriggerRecord record) {
            super.registerRecord(record);

            String recursionKey = String.valueOf(this.handler).substringBefore(':') + ':AFTER_UPDATE:' + record.getId();

            TriggerOrchestrator.recursionDepthByHandlerRecord.put(recursionKey, (TriggerOrchestrator.recursionDepthByHandlerRecord.get(recursionKey) ?? 0) + 1);
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

        protected override void finalizeHandler() {
            if (this.handler instanceof AfterUpdate.Finalizer) {
                ((AfterUpdate.Finalizer) this.handler).finalizeAfterUpdate();
            }
        }
    }

    private class BeforeDeleteHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeDeleteHandlerAdapter(BeforeDelete.Handler handler) {
            super(handler);
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof BeforeDelete.Bypassable) {
                return ((BeforeDelete.Bypassable) this.handler).bypassOnBeforeDeleteWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
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

        protected override void finalizeHandler() {
            if (this.handler instanceof BeforeDelete.Finalizer) {
                ((BeforeDelete.Finalizer) this.handler).finalizeBeforeDelete();
            }
        }
    }

    private class AfterDeleteHandlerAdapter extends TriggerHandlerAdapter {
        public AfterDeleteHandlerAdapter(AfterDelete.Handler handler) {
            super(handler);
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof AfterDelete.Bypassable) {
                return ((AfterDelete.Bypassable) this.handler).bypassOnAfterDeleteWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getOldFieldsToEnrich() {
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

        protected override void finalizeHandler() {
            if (this.handler instanceof AfterDelete.Finalizer) {
                ((AfterDelete.Finalizer) this.handler).finalizeAfterDelete();
            }
        }
    }

    private class BeforeUndeleteHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeUndeleteHandlerAdapter(BeforeUndelete.Handler handler) {
            super(handler);
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof BeforeUndelete.Bypassable) {
                return ((BeforeUndelete.Bypassable) this.handler).bypassOnBeforeUndeleteWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
            if (this.handler instanceof BeforeUndelete.NewRecordEnrichment) {
                return ((BeforeUndelete.NewRecordEnrichment) this.handler).newFieldsToEnrichOnBeforeUndelete();
            }

            return new Map<SObjectField, TriggerHandler.FieldSelection>();
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUndelete.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((BeforeUndelete.Handler) this.handler).qualifiesForBeforeUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((BeforeUndelete.Handler) this.handler).onBeforeUndelete(record);
        }

        protected override void finalizeHandler() {
            if (this.handler instanceof BeforeUndelete.Finalizer) {
                ((BeforeUndelete.Finalizer) this.handler).finalizeBeforeUndelete();
            }
        }
    }

    private class AfterUndeleteHandlerAdapter extends TriggerHandlerAdapter {
        public AfterUndeleteHandlerAdapter(AfterUndelete.Handler handler) {
            super(handler);
        }

        public override Boolean isBypassed() {
            if (this.handler instanceof AfterUndelete.Bypassable) {
                return ((AfterUndelete.Bypassable) this.handler).bypassOnAfterUndeleteWhen();
            }

            return false;
        }

        public override Map<SObjectField, TriggerHandler.FieldSelection> getNewFieldsToEnrich() {
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

        protected override void finalizeHandler() {
            if (this.handler instanceof AfterUndelete.Finalizer) {
                ((AfterUndelete.Finalizer) this.handler).finalizeAfterUndelete();
            }
        }
    }

    private class ParentRelationshipEnrichment {
        private List<TriggerHandlerAdapter> adapters;
        private List<TriggerHandler.TriggerRecord> recordsToEnrich;
        private Set<SObjectField> newRecordFieldsToEnrich = new Set<SObjectField>();
        private Set<SObjectField> oldRecordFieldsToEnrich = new Set<SObjectField>();
        private Map<SObjectField, SOQL.Queryable> queryByParentField = new Map<SObjectField, SOQL.Queryable>();

        public ParentRelationshipEnrichment(List<TriggerHandlerAdapter> adapters, List<TriggerHandler.TriggerRecord> recordsToEnrich) {
            this.adapters = adapters;
            this.recordsToEnrich = recordsToEnrich;
        }

        public void enrich() {
            this.declareParentFields();

            if (this.queryByParentField.isEmpty()) {
                return;
            }

            this.enrichRecords();
        }

        private void declareParentFields() {
            for (TriggerHandlerAdapter adapter : this.adapters) {
                this.declare(adapter.getNewFieldsToEnrich(), this.newRecordFieldsToEnrich);
                this.declare(adapter.getOldFieldsToEnrich(), this.oldRecordFieldsToEnrich);
            }
        }

        private void declare(Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich, Set<SObjectField> recordFieldsToEnrich) {
            for (SObjectField parentField : fieldsToEnrich.keySet()) {
                recordFieldsToEnrich.add(parentField);

                if (!this.queryByParentField.containsKey(parentField)) {
                    this.queryByParentField.put(parentField, SOQL.of(parentField.getDescribe().getReferenceTo()[0]));
                }

                this.queryByParentField.get(parentField).with(fieldsToEnrich.get(parentField).getFields());
            }
        }

        private void enrichRecords() {
            for (SObjectField parentField : this.queryByParentField.keySet()) {
                Boolean enrichNewSide = this.newRecordFieldsToEnrich.contains(parentField);
                Boolean enrichOldSide = this.oldRecordFieldsToEnrich.contains(parentField);

                Set<Id> parentIds = this.gatherParentIds(parentField, enrichNewSide, enrichOldSide);

                if (parentIds.isEmpty()) {
                    continue;
                }

                Map<Id, SObject> relatedRecordById = this.queryByParentField.get(parentField).byIds(parentIds).systemMode().withoutSharing().toMap();

                String relationshipName = parentField.getDescribe().getRelationshipName();

                for (TriggerHandler.TriggerRecord record : this.recordsToEnrich) {
                    SObject newRecord = record.getNewSObject();
                    SObject oldRecord = record.getOldSObject();

                    if (enrichNewSide && newRecord != null && newRecord.isSet(parentField)) {
                        record.enrichNew(relationshipName, relatedRecordById.get((Id) newRecord.get(parentField)));
                    }

                    if (enrichOldSide && oldRecord != null && oldRecord.isSet(parentField)) {
                        record.enrichOld(relationshipName, relatedRecordById.get((Id) oldRecord.get(parentField)));
                    }
                }
            }
        }

        private Set<Id> gatherParentIds(SObjectField parentField, Boolean fromNewSide, Boolean fromOldSide) {
            Set<Id> parentIds = new Set<Id>();

            for (TriggerHandler.TriggerRecord record : this.recordsToEnrich) {
                SObject newRecord = record.getNewSObject();
                SObject oldRecord = record.getOldSObject();

                if (fromNewSide && newRecord != null && newRecord.isSet(parentField)) {
                    parentIds.add((Id) newRecord.get(parentField));
                }

                if (fromOldSide && oldRecord != null && oldRecord.isSet(parentField)) {
                    parentIds.add((Id) oldRecord.get(parentField));
                }
            }

            return parentIds;
        }
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
