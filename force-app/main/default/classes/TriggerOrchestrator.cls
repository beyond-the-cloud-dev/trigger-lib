public with sharing class TriggerOrchestrator {
    public interface BeforeInsert {
        List<TriggerHandler.BeforeInsert> beforeInsertHandlers();
    }

    public interface AfterInsert {
        List<TriggerHandler.AfterInsert> afterInsertHandlers();
    }

    public interface BeforeUpdate {
        List<TriggerHandler.BeforeUpdate> beforeUpdateHandlers();
    }

    public interface AfterUpdate {
        List<TriggerHandler.AfterUpdate> afterUpdateHandlers();
    }

    public interface BeforeDelete {
        List<TriggerHandler.BeforeDelete> beforeDeleteHandlers();
    }

    public interface AfterDelete {
        List<TriggerHandler.AfterDelete> afterDeleteHandlers();
    }

    public interface AfterUndelete {
        List<TriggerHandler.AfterUndelete> afterUndeleteHandlers();
    }

    // TODO ContextProvider for unrelated records
    // public interface ContextProvider {

    // }

    public interface RecursiveUpdateGuard {
        Integer maxRecursionDepth();
        Boolean muteRecursionDepthExceededException(); // TODO
    }

    public interface Logger {
        void log(Error error);
        void finalize();
    }

    public interface Error {
        Exception getException();
        System.TriggerOperation getOperation();
        SObjectType getSObjectType();
        Set<Id> getRecordIds();
    }

    // TODO Asynchronous Actions - TODO Only in AfterUpdate, AfterDelete context

    // Implementations

    private static List<Invocation> invocationStack = new List<Invocation>();
    private static Boolean isLoggerResolved = false;

    @TestVisible
    private static Logger logger {
        get {
            if (!isLoggerResolved) {
                logger = loadLogger();
                isLoggerResolved = true;
            }
            return logger;
        }
        private set;
    }

    private static Map<System.TriggerOperation, Map<Id, Integer>> recursionDepth {
        get {
            if (recursionDepth == null) {
                recursionDepth = new Map<System.TriggerOperation, Map<Id, Integer>>{
                    System.TriggerOperation.BEFORE_UPDATE => new Map<Id, Integer>(),
                    System.TriggerOperation.AFTER_UPDATE => new Map<Id, Integer>()
                };
            }
            return recursionDepth;
        }
        private set;
    }

    public static void run(Object orchestrator) {
        //TODO maybe it shound not be static so I can have access to this
        try {
            if (Trigger.operationType == null) {
                throw new TriggerOrchestratorException('Called outside of trigger context, or not supported operation type');
            }

            if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE || Trigger.operationType == System.TriggerOperation.AFTER_UPDATE) {
                incrementRecursionDepth(orchestrator);
            }

            Invocation invocation = new Invocation();

            TriggerOrchestrator.invocationStack.add(invocation);

            List<TriggerHandlerAdapter> unifiedHandlers = new List<TriggerHandlerAdapter>();
            List<TriggerHandler.TriggerRecord> triggerRecords = new List<TriggerHandler.TriggerRecord>();

            if (Trigger.operationType == System.TriggerOperation.BEFORE_INSERT && orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                for (TriggerHandler.BeforeInsert handler : ((TriggerOrchestrator.BeforeInsert) orchestrator).beforeInsertHandlers()) {
                    unifiedHandlers.add(new BeforeInsertHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_INSERT && orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                for (TriggerHandler.AfterInsert handler : ((TriggerOrchestrator.AfterInsert) orchestrator).afterInsertHandlers()) {
                    unifiedHandlers.add(new AfterInsertHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE && orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                for (TriggerHandler.BeforeUpdate handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator).beforeUpdateHandlers()) {
                    unifiedHandlers.add(new BeforeUpdateHandlerAdapter(handler));
                }

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UPDATE && orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                for (TriggerHandler.AfterUpdate handler : ((TriggerOrchestrator.AfterUpdate) orchestrator).afterUpdateHandlers()) {
                    unifiedHandlers.add(new AfterUpdateHandlerAdapter(handler));
                }

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
                }
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_DELETE && orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                for (TriggerHandler.BeforeDelete handler : ((TriggerOrchestrator.BeforeDelete) orchestrator).beforeDeleteHandlers()) {
                    unifiedHandlers.add(new BeforeDeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.old) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_DELETE && orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                for (TriggerHandler.AfterDelete handler : ((TriggerOrchestrator.AfterDelete) orchestrator).afterDeleteHandlers()) {
                    unifiedHandlers.add(new AfterDeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.old) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UNDELETE && orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                for (TriggerHandler.AfterUndelete handler : ((TriggerOrchestrator.AfterUndelete) orchestrator).afterUndeleteHandlers()) {
                    unifiedHandlers.add(new AfterUndeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            }

            new Executor(unifiedHandlers, triggerRecords).run();
        } catch (Exception e) {
            logError(e);

            throw e;
        } finally {
            TriggerOrchestrator.invocationStack.remove(TriggerOrchestrator.invocationStack.size() - 1);

            // finalize onlu for main chunk
            if (TriggerOrchestrator.invocationStack.isEmpty()) {
                TriggerOrchestrator.logger?.finalize();
            }
        }
    }

    private static Logger loadLogger() {
        String className = TriggerOrchestrator.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : null;

        List<ApexTypeImplementor> implementors = [
            SELECT ClassName, ClassNamespacePrefix
            FROM ApexTypeImplementor
            WHERE InterfaceName = 'TriggerOrchestrator.Logger' AND InterfaceNamespacePrefix = :namespacePrefix AND IsConcrete = TRUE
            WITH SYSTEM_MODE
            LIMIT 1
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

    private static void incrementRecursionDepth(Object orchestrator) {
        Integer orchestratorMaxDepth = 3;

        if (orchestrator instanceof TriggerOrchestrator.RecursiveUpdateGuard) {
            orchestratorMaxDepth = ((TriggerOrchestrator.RecursiveUpdateGuard) orchestrator).maxRecursionDepth();
        }

        Integer recordIdsHashCode = Trigger.newMap.keySet().hashCode();

        for (Id recordId : Trigger.newMap.keySet()) {
            // maybe insteaf of ids, just use List hashMap
            Map<Id, Integer> idToUpdateCount = recursionDepth.get(Trigger.operationType);
            Integer updateCount = idToUpdateCount.get(recordId) ?? 0;

            if (updateCount >= orchestratorMaxDepth) {
                throw new TriggerOrchestratorException('Maximum recursion depth reached for record: ' + recordId);
            }

            idToUpdateCount.put(recordId, updateCount + 1);
        }
    }

    private static void logError(Exception e) {
        if (TriggerOrchestrator.logger == null) {
            return;
        }

        TriggerError error = new TriggerError();

        error.triggerException = e;
        error.operation = Trigger.operationType;
        error.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
        error.recordIds = (Trigger.newMap ?? Trigger.oldMap)?.keySet();

        TriggerOrchestrator.logger.log(error);
    }

    private class Invocation {
        private System.TriggerOperation operationType;
        private SObjectType sObjectType;
        private Integer totalRecordsProcessed;
        private Integer depth; //TODO nestingLevel?

        private Invocation() {
            this.operationType = Trigger.operationType;
            this.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
            this.totalRecordsProcessed = (Trigger.new ?? Trigger.old)?.size() ?? 0;
            this.depth = TriggerOrchestrator.invocationStack.size();
        }
    }

    private class TriggerError implements Error {
        public Exception triggerException;
        public System.TriggerOperation operation;
        public SObjectType sObjectType;
        public Set<Id> recordIds;

        public Exception getException() {
            return this.triggerException;
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

    private class Executor {
        private List<TriggerHandlerAdapter> handlersToExecute;
        private List<TriggerHandlerAdapter> activeHandlers;
        private List<TriggerHandler.TriggerRecord> records;

        private Executor(List<TriggerHandlerAdapter> handlersToExecute, List<TriggerHandler.TriggerRecord> records) {
            this.handlersToExecute = handlersToExecute;
            this.records = records;
            this.activeHandlers = new List<TriggerHandlerAdapter>();
        }

        public void run() {
            this.gatherActiveHandlers();
            this.qualifieRecordsWithoutRelatedData();
            this.qualifieRecordsNeedingRelatedData();
        }

        private void gatherActiveHandlers() {
            for (TriggerHandlerAdapter adapter : this.handlersToExecute) {
                if (!this.shouldBeBypassed(adapter.getHandler())) {
                    this.activeHandlers.add(adapter);
                }
            }
        }

        private void qualifieRecordsWithoutRelatedData() {
            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                for (TriggerHandler.TriggerRecord record : records) {
                    if (adapter.isQualified(record)) {
                        adapter.registerRecord(record);
                    }
                }
            }
        }

        private void qualifieRecordsNeedingRelatedData() {
            List<TriggerHandler.TriggerRecord> recordsNeedingRelatedData = new List<TriggerHandler.TriggerRecord>();

            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                for (TriggerHandler.TriggerRecord record : records) {
                    if (!adapter.hasRecordAlreadyRegistered(record) && record.isQualificationNeedRelatedRecords()) {
                        recordsNeedingRelatedData.add(record);
                    }
                }
            }

            new ParentRelationshipEnrichment(this.activeHandlers, recordsNeedingRelatedData).enrich();

            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                for (TriggerHandler.TriggerRecord record : records) {
                    if (adapter.hasRecordAlreadyRegistered(record) || adapter.isQualified(record)) {
                        adapter.registerRecord(record);
                    }
                }
            }
        }

        private void executeHandlers() {
            for (TriggerHandlerAdapter adapter : this.activeHandlers) {
                if (!adapter.getRecords().isEmpty()) {
                    adapter.execute();
                }
            }
        }

        private Boolean shouldBeBypassed(Object handler) {
            if (handler instanceof TriggerHandler.Bypassable) {
                return ((TriggerHandler.Bypassable) handler).bypassWhen();
            }

            return false;
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

        public void registerRecord(TriggerHandler.TriggerRecord record) {
            this.qualifiedRecordByIdentifier.put(record.getIdentifier(), record);
        }

        public Boolean hasRecordAlreadyRegistered(TriggerHandler.TriggerRecord record) {
            return this.qualifiedRecordByIdentifier.containsKey(record.getIdentifier());
        }

        public List<TriggerHandler.TriggerRecord> getRecords() {
            return new List<TriggerHandler.TriggerRecord>(this.qualifiedRecordByIdentifier.values());
        }

        public void execute() {
            for (TriggerHandler.TriggerRecord record : this.getRecords()) {
                // TODO Allow to override execute method so before methods will have logic to block DMLs
                this.executeOn(record);
            }
        }

        public abstract Boolean isQualified(TriggerHandler.TriggerRecord record);

        protected abstract void executeOn(TriggerHandler.TriggerRecord record);
    }

    private class BeforeInsertHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeInsertHandlerAdapter(TriggerHandler.BeforeInsert handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.BeforeInsert) this.handler).qualifiesForBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.BeforeInsert) this.handler).onBeforeInsert(record);
        }
    }

    private class AfterInsertHandlerAdapter extends TriggerHandlerAdapter {
        public AfterInsertHandlerAdapter(TriggerHandler.AfterInsert handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.AfterInsert) this.handler).qualifiesForAfterInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.AfterInsert) this.handler).onAfterInsert(record);
        }
    }

    private class BeforeUpdateHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeUpdateHandlerAdapter(TriggerHandler.BeforeUpdate handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.BeforeUpdate) this.handler).qualifiesForBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.BeforeUpdate) this.handler).onBeforeUpdate(record);
        }
    }

    private class AfterUpdateHandlerAdapter extends TriggerHandlerAdapter {
        public AfterUpdateHandlerAdapter(TriggerHandler.AfterUpdate handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.AfterUpdate) this.handler).qualifiesForAfterUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.AfterUpdate) this.handler).onAfterUpdate(record);
        }
    }

    private class BeforeDeleteHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeDeleteHandlerAdapter(TriggerHandler.BeforeDelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.BeforeDelete) this.handler).qualifiesForBeforeDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.BeforeDelete) this.handler).onBeforeDelete(record);
        }
    }

    private class AfterDeleteHandlerAdapter extends TriggerHandlerAdapter {
        public AfterDeleteHandlerAdapter(TriggerHandler.AfterDelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.AfterDelete) this.handler).qualifiesForAfterDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.AfterDelete) this.handler).onAfterDelete(record);
        }
    }

    private class BeforeUndeleteHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeUndeleteHandlerAdapter(TriggerHandler.BeforeUndelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.BeforeUndelete) this.handler).qualifiesForBeforeUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.BeforeUndelete) this.handler).onBeforeUndelete(record);
        }
    }

    private class AfterUndeleteHandlerAdapter extends TriggerHandlerAdapter {
        public AfterUndeleteHandlerAdapter(TriggerHandler.AfterUndelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.TriggerRecord record) {
            return ((TriggerHandler.AfterUndelete) this.handler).qualifiesForAfterUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.TriggerRecord record) {
            ((TriggerHandler.AfterUndelete) this.handler).onAfterUndelete(record);
        }
    }

    private class ParentRelationshipEnrichment {
        private List<TriggerHandlerAdapter> adapters;
        private List<TriggerHandlerAdapter> enrichmentHandlers;
        private List<TriggerHandler.TriggerRecord> records;
        private Map<SObjectField, SOQL.Queryable> parentFieldToQuery;

        public ParentRelationshipEnrichment(List<TriggerHandlerAdapter> adapters, List<TriggerHandler.TriggerRecord> records) {
            this.adapters = adapters;
            this.records = records;
            this.enrichmentHandlers = new List<TriggerHandlerAdapter>();
            this.parentFieldToQuery = new Map<SObjectField, SOQL.Queryable>();
        }

        public void enrich() {
            this.gatherRelationshipEnrichmentHandlers();

            if (enrichmentHandlers.isEmpty()) {
                return;
            }

            this.initDynamicQueries();
            this.enrichRecords();
        }

        private void gatherRelationshipEnrichmentHandlers() {
            for (TriggerHandlerAdapter adapter : adapters) {
                if (adapter.getHandler() instanceof TriggerHandler.RelationshipEnrichment) {
                    this.enrichmentHandlers.add(adapter);
                }
            }
        }

        private void initDynamicQueries() {
            for (TriggerHandlerAdapter adapter : this.enrichmentHandlers) {
                Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich = ((TriggerHandler.RelationshipEnrichment) adapter.getHandler()).fieldsToEnrich();

                for (SObjectField field : fieldsToEnrich.keySet()) {
                    if (!this.parentFieldToQuery.containsKey(field)) {
                        this.parentFieldToQuery.put(field, SOQL.of(field.getDescribe().getReferenceTo()[0]));
                    }

                    this.parentFieldToQuery.get(field).with(fieldsToEnrich.get(field).getFields());
                }
            }
        }

        private void enrichRecords() {
            for (SObjectField parentField : this.parentFieldToQuery.keySet()) {
                Set<Id> parentIds = this.gatherParentIds(parentField);

                if (parentIds.isEmpty()) {
                    continue;
                }

                Map<Id, SObject> relatedRecordsById = this.parentFieldToQuery.get(parentField).byIds(parentIds).systemMode().withoutSharing().toMap();

                String relationshipName = parentField.getDescribe().getRelationshipName();

                for (TriggerHandler.TriggerRecord record : this.records) {
                    SObject newRecord = record.getNewSObject();
                    SObject oldRecord = record.getOldSObject();

                    if (newRecord != null && newRecord.isSet(parentField)) {
                        record.enrichNew(relationshipName, relatedRecordsById.get((Id) newRecord.get(parentField)));
                    }

                    if (oldRecord != null && oldRecord.isSet(parentField)) {
                        record.enrichOld(relationshipName, relatedRecordsById.get((Id) oldRecord.get(parentField)));
                    }
                }
            }
        }

        private Set<Id> gatherParentIds(SObjectField parentField) {
            Set<Id> parentIds = new Set<Id>();

            for (TriggerHandler.TriggerRecord record : this.records) {
                SObject newRecord = record.getNewSObject();
                SObject oldRecord = record.getOldSObject();

                if (newRecord != null && newRecord.isSet(parentField)) {
                    parentIds.add((Id) newRecord.get(parentField));
                }

                if (oldRecord != null && oldRecord.isSet(parentField)) {
                    parentIds.add((Id) oldRecord.get(parentField));
                }
            }

            return parentIds;
        }
    }

    private class RelationshipEnrichment {
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
