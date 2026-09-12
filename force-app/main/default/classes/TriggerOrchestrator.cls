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

    // Implementations

    private static List<ExecutionStrategy> executionStack = new List<ExecutionStrategy>();
    private static Map<String, Integer> recursionDepthByHandlerRecord = new Map<String, Integer>();
    private static Map<String, MetadataSettings> metadataSettingsByObjectName;
    private static Boolean isLoggerResolved = false;

    @TestVisible
    private static Logger logger {
        get {
            if (!TriggerOrchestrator.isLoggerResolved) {
                logger = TriggerOrchestrator.resolveLogger();
                TriggerOrchestrator.isLoggerResolved = true;
            }
            return logger;
        }
        private set;
    }

    public static void run(Object orchestrator) {
        ExecutionStrategy executionStrategy;

        try {
            if (Trigger.operationType == null) {
                throw new TriggerOrchestratorException('Called outside of trigger context, or not supported operation type');
            }

            MetadataSettings metadataSettings = TriggerOrchestrator.resolveMetadataSettings((Trigger.new ?? Trigger.old)?.getSObjectType());

            if (metadataSettings?.isSObjectBypassed == true) {
                return;
            }

            if (Trigger.operationType == System.TriggerOperation.BEFORE_INSERT && orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                executionStrategy = new BeforeInsertExecutionStrategy();
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_INSERT && orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                executionStrategy = new AfterInsertExecutionStrategy();
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE && orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                executionStrategy = new BeforeUpdateExecutionStrategy();
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UPDATE && orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                executionStrategy = new AfterUpdateExecutionStrategy();
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_DELETE && orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                executionStrategy = new BeforeDeleteExecutionStrategy();
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_DELETE && orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                executionStrategy = new AfterDeleteExecutionStrategy();
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UNDELETE && orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                executionStrategy = new AfterUndeleteExecutionStrategy();
            } else {
                return;
            }

            TriggerOrchestrator.executionStack.add(executionStrategy);

            executionStrategy.execute(orchestrator);
        } finally {
            if (!TriggerOrchestrator.executionStack.isEmpty()) {
                TriggerOrchestrator.executionStack.remove(TriggerOrchestrator.executionStack.size() - 1);
            }

            if (TriggerOrchestrator.executionStack.isEmpty()) {
                TriggerOrchestrator.logger?.finalize();
            }
        }
    }

    private abstract class ExecutionStrategy {
        protected Object orchestrator;

        protected List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();
        protected List<TriggerHandlerAdapter> activeHandlers = new List<TriggerHandlerAdapter>();
        protected List<TriggerHandler.TriggerRecord> triggerRecords = new List<TriggerHandler.TriggerRecord>();

        public abstract void adaptHandlers();

        public void execute(Object orchestrator) {
            this.orchestrator = orchestrator;

            this.registerRecords();
            this.adaptHandlers();

            this.filterBypassedHandlers();
            this.enrichParentRelatioships();
            this.qualifyRecordsForHandlers();
            
            this.runHandlers();
        }

        private void registerRecords() {
            for (Integer i = 0; i < (Trigger.new ?? Trigger.old).size(); i++) {
                this.triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new?.get(i), Trigger.old?.get(i)));
            }
        }

        private void filterBypassedHandlers() {
            for (TriggerHandlerAdapter adapter : this.handlerAdapters) {
                if (!adapter.isBypassed()) {
                    this.activeHandlers.add(adapter);
                }
            }
        }

        private void enrichParentRelatioships() {
            new ParentRelationshipEnrichment(this.activeHandlers, this.triggerRecords).enrich();
        }

        private void qualifyRecordsForHandlers() {
            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                for (TriggerHandler.TriggerRecord record : this.triggerRecords) {
                    if (adapter.isRecursionDepthExceeded(record)) {
                        continue;
                    }

                    if (adapter.isQualified(record)) {
                        adapter.registerRecord(record);
                    }
                }
            }
        }

        private void runHandlers() {
            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                if (adapter.getQualifiedRecords().isEmpty()) {
                    continue;
                }

                try {
                    adapter.execute();
                } catch (Exception e) {
                    TriggerOrchestrator.logError(e, adapter);

                    if (e instanceof TriggerOrchestratorException || !adapter.continuesOnError()) {
                        throw e;
                    }
                }
            }
        }
    }

    private class BeforeInsertExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) this.orchestrator).beforeInsertHandlers()) {
                if (handler instanceof BeforeInsert.Populator && handler instanceof BeforeInsert.Validator) {
                    throw new TriggerOrchestratorException(
                        String.valueOf(handler).substringBefore(':') +
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
                        String.valueOf(handler).substringBefore(':') +
                        ' implements neither BeforeInsert.Populator nor BeforeInsert.Validator. A class must implement one main interface per context.'
                    );
                }
            }
        }
    }

    private class AfterInsertExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) this.orchestrator).afterInsertHandlers()) {
                this.handlerAdapters.add(new AfterInsertHandlerAdapter(handler));
            }
        }
    }

    private class BeforeUpdateExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) this.orchestrator).beforeUpdateHandlers()) {
                if (handler instanceof BeforeUpdate.Populator && handler instanceof BeforeUpdate.Validator) {
                    throw new TriggerOrchestratorException(
                        String.valueOf(handler).substringBefore(':') +
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
                        String.valueOf(handler).substringBefore(':') +
                        ' implements neither BeforeUpdate.Populator nor BeforeUpdate.Validator. A class must implement one main interface per context.'
                    );
                }
            }
        }
    }

    private class AfterUpdateExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) this.orchestrator).afterUpdateHandlers()) {
                this.handlerAdapters.add(new AfterUpdateHandlerAdapter(handler));
            }
        }
    }

    private class BeforeDeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) this.orchestrator).beforeDeleteHandlers()) {
                this.handlerAdapters.add(new BeforeDeleteHandlerAdapter(handler));
            }
        }
    }

    private class AfterDeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) this.orchestrator).afterDeleteHandlers()) {
                this.handlerAdapters.add(new AfterDeleteHandlerAdapter(handler));
            }
        }
    }

    private class AfterUndeleteExecutionStrategy extends ExecutionStrategy {
        public override void adaptHandlers() {
            for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) this.orchestrator).afterUndeleteHandlers()) {
                this.handlerAdapters.add(new AfterUndeleteHandlerAdapter(handler));
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

        return (Logger) Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();
    }

    private static Boolean isHandlerBypassedInMetadata(Object handler) {
        return TriggerOrchestrator.resolveMetadataSettings((Trigger.new ?? Trigger.old)?.getSObjectType())?.isHandlerBypassed(handler) == true;
    }

    private static MetadataSettings resolveMetadataSettings(SObjectType sObjectType) {
        if (TriggerOrchestrator.metadataSettingsByObjectName == null) {
            TriggerOrchestrator.metadataSettingsByObjectName = new Map<String, MetadataSettings>();

            for (TriggerObject__mdt triggerObject : [
                SELECT ObjectAPIName__c, Bypass__c, (SELECT ApexClassName__c, Bypass__c FROM TriggerHandlers__r)
                FROM TriggerObject__mdt
                WITH SYSTEM_MODE
            ]) {
                MetadataSettings metadataSettings = new MetadataSettings();

                metadataSettings.isSObjectBypassed = triggerObject.Bypass__c == true;

                for (TriggerHandler__mdt triggerHandler : triggerObject.TriggerHandlers__r ?? new List<TriggerHandler__mdt>()) {
                    if (triggerHandler.Bypass__c == true) {
                        String bypassedHandlerName = triggerHandler.ApexClassName__c.trim().toLowerCase();

                        metadataSettings.bypassedHandlerNames.add(bypassedHandlerName);

                        if (bypassedHandlerName.contains('.')) {
                            metadataSettings.bypassedHandlerNames.add(bypassedHandlerName.substringAfterLast('.'));
                        }
                    }
                }

                TriggerOrchestrator.metadataSettingsByObjectName.put(triggerObject.ObjectAPIName__c.trim().toLowerCase(), metadataSettings);
            }
        }

        return TriggerOrchestrator.metadataSettingsByObjectName?.get(String.valueOf(sObjectType).toLowerCase());
    }

    private static void logError(Exception e, TriggerHandlerAdapter adapter) {
        if (TriggerOrchestrator.logger == null) {
            return;
        }

        TriggerError error = new TriggerError();

        error.triggerException = e;
        error.handlerName = adapter == null ? null : String.valueOf(adapter.getHandler()).substringBefore(':');
        error.operation = Trigger.operationType;
        error.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
        error.recordIds = (Trigger.newMap ?? Trigger.oldMap)?.keySet();

        TriggerOrchestrator.logger.log(error);
    }

    private class MetadataSettings {
        private Boolean isSObjectBypassed = false;
        private Set<String> bypassedHandlerNames = new Set<String>();

        public Boolean isHandlerBypassed(Object handler) {
            return this.bypassedHandlerNames.contains(String.valueOf(handler).substringBefore(':').toLowerCase());
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

    private class BeforeInsertPopulatorHandlerAdapter extends TriggerHandlerAdapter {
        private BeforeInsert.Populator populator;

        public BeforeInsertPopulatorHandlerAdapter(BeforeInsert.Populator populator) {
            super(populator);
            this.populator = populator;
        }

        public override void execute() {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                    this.executeOn(record);
                }

                this.finalizeHandler();
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        String.valueOf(this.handler).substringBefore(':') +
                        ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
            return this.populator.populateOnBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            this.populator.populateOnBeforeInsert(record);
        }

        protected override void finalizeHandler() {
            if (this.handler instanceof BeforeInsert.Finalizer) {
                ((BeforeInsert.Finalizer) this.handler).finalizeBeforeInsert();
            }
        }
    }

    private class BeforeInsertValidatorHandlerAdapter extends TriggerHandlerAdapter {
        private BeforeInsert.Validator validator;

        public BeforeInsertValidatorHandlerAdapter(BeforeInsert.Validator validator) {
            super(validator);
            this.validator = validator;
        }

        public override void execute() {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                    this.executeOn(record);
                }

                this.finalizeHandler();
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        String.valueOf(this.handler).substringBefore(':') +
                        ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
            return this.validator.errorShouldBeAttachedOnBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            record.getNewSObject().addError(this.validator.beforeInsertValidationMessage(record));
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
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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

    private class BeforeUpdatePopulatorHandlerAdapter extends TriggerHandlerAdapter {
        private BeforeUpdate.Populator populator;

        public BeforeUpdatePopulatorHandlerAdapter(BeforeUpdate.Populator populator) {
            super(populator);
            this.populator = populator;
        }

        public override void execute() {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                    this.executeOn(record);
                }

                this.finalizeHandler();
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        String.valueOf(this.handler).substringBefore(':') +
                        ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
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

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return this.populator.populateOnBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            this.populator.populateOnBeforeUpdate(record);
        }

        protected override void finalizeHandler() {
            if (this.handler instanceof BeforeUpdate.Finalizer) {
                ((BeforeUpdate.Finalizer) this.handler).finalizeBeforeUpdate();
            }
        }
    }

    private class BeforeUpdateValidatorHandlerAdapter extends TriggerHandlerAdapter {
        private BeforeUpdate.Validator validator;

        public BeforeUpdateValidatorHandlerAdapter(BeforeUpdate.Validator validator) {
            super(validator);
            this.validator = validator;
        }

        public override void execute() {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
                    this.executeOn(record);
                }

                this.finalizeHandler();
            } finally {
                if (Limits.getDmlStatements() > dmlStatementsBefore || Limits.getPublishImmediateDML() > immediateEventsBefore) {
                    throw new TriggerOrchestratorException(
                        String.valueOf(this.handler).substringBefore(':') +
                        ' performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.'
                    );
                }
            }
        }

        public override Boolean isBypassed() {
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return this.validator.errorShouldBeAttachedOnBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            record.getNewSObject().addError(this.validator.beforeUpdateValidationMessage(record));
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
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
            if (TriggerOrchestrator.isHandlerBypassedInMetadata(this.handler)) {
                return true;
            }

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
                    if (enrichNewSide && record.getNewSObject()?.isSet(parentField) == true) {
                        record.enrichNew(relationshipName, relatedRecordById.get((Id) record.getNewSObject().get(parentField)));
                    }

                    if (enrichOldSide && record.getOldSObject()?.isSet(parentField) == true) {
                        record.enrichOld(relationshipName, relatedRecordById.get((Id) record.getOldSObject().get(parentField)));
                    }
                }
            }
        }

        private Set<Id> gatherParentIds(SObjectField parentField, Boolean fromNewSide, Boolean fromOldSide) {
            Set<Id> parentIds = new Set<Id>();

            for (TriggerHandler.TriggerRecord record : this.recordsToEnrich) {
                if (fromNewSide && record.getNewSObject()?.isSet(parentField) == true) {
                    parentIds.add((Id) record.getNewSObject().get(parentField));
                }

                if (fromOldSide && record.getOldSObject()?.isSet(parentField) == true) {
                    parentIds.add((Id) record.getOldSObject().get(parentField));
                }
            }

            return parentIds;
        }
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
