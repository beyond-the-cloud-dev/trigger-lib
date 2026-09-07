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
                logger = resolveLogger();
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
        //TODO maybe it should not be static so I can have access to this
        try {
            if (Trigger.operationType == null) {
                throw new TriggerOrchestratorException('Called outside of trigger context, or not supported operation type');
            }

            if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE || Trigger.operationType == System.TriggerOperation.AFTER_UPDATE) {
                guardRecursionDepth(orchestrator);
            }

            Invocation invocation = new Invocation();

            TriggerOrchestrator.invocationStack.add(invocation);

            List<TriggerHandlerAdapter> handlerAdapters = new List<TriggerHandlerAdapter>();
            List<TriggerHandler.TriggerRecord> triggerRecords = new List<TriggerHandler.TriggerRecord>();

            if (Trigger.operationType == System.TriggerOperation.BEFORE_INSERT && orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                for (TriggerHandler.BeforeInsert handler : ((TriggerOrchestrator.BeforeInsert) orchestrator).beforeInsertHandlers()) {
                    handlerAdapters.add(new BeforeInsertHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_INSERT && orchestrator instanceof TriggerOrchestrator.AfterInsert) {
                for (TriggerHandler.AfterInsert handler : ((TriggerOrchestrator.AfterInsert) orchestrator).afterInsertHandlers()) {
                    handlerAdapters.add(new AfterInsertHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE && orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                for (TriggerHandler.BeforeUpdate handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator).beforeUpdateHandlers()) {
                    handlerAdapters.add(new BeforeUpdateHandlerAdapter(handler));
                }

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UPDATE && orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                for (TriggerHandler.AfterUpdate handler : ((TriggerOrchestrator.AfterUpdate) orchestrator).afterUpdateHandlers()) {
                    handlerAdapters.add(new AfterUpdateHandlerAdapter(handler));
                }

                for (Integer i = 0; i < Trigger.new.size(); i++) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
                }
            } else if (Trigger.operationType == System.TriggerOperation.BEFORE_DELETE && orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
                for (TriggerHandler.BeforeDelete handler : ((TriggerOrchestrator.BeforeDelete) orchestrator).beforeDeleteHandlers()) {
                    handlerAdapters.add(new BeforeDeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.old) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_DELETE && orchestrator instanceof TriggerOrchestrator.AfterDelete) {
                for (TriggerHandler.AfterDelete handler : ((TriggerOrchestrator.AfterDelete) orchestrator).afterDeleteHandlers()) {
                    handlerAdapters.add(new AfterDeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.old) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
                }
            } else if (Trigger.operationType == System.TriggerOperation.AFTER_UNDELETE && orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
                for (TriggerHandler.AfterUndelete handler : ((TriggerOrchestrator.AfterUndelete) orchestrator).afterUndeleteHandlers()) {
                    handlerAdapters.add(new AfterUndeleteHandlerAdapter(handler));
                }

                for (SObject record : Trigger.new) {
                    triggerRecords.add(new TriggerHandler.TriggerRecord(record));
                }
            }

            new HandlerExecutor(handlerAdapters, triggerRecords).run();
        } catch (Exception e) {
            logError(e);

            throw e;
        } finally {
            TriggerOrchestrator.invocationStack.remove(TriggerOrchestrator.invocationStack.size() - 1);

            // finalize only for main chunk
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

    private static void guardRecursionDepth(Object orchestrator) {
        Integer orchestratorMaxDepth = 3;

        if (orchestrator instanceof TriggerOrchestrator.RecursiveUpdateGuard) {
            orchestratorMaxDepth = ((TriggerOrchestrator.RecursiveUpdateGuard) orchestrator).maxRecursionDepth();
        }

        Integer recordIdsHashCode = Trigger.newMap.keySet().hashCode();

        for (Id recordId : Trigger.newMap.keySet()) {
            // maybe instead of ids, just use List hashMap
            Map<Id, Integer> depthByRecordId = recursionDepth.get(Trigger.operationType);
            Integer currentDepth = depthByRecordId.get(recordId) ?? 0;

            if (currentDepth >= orchestratorMaxDepth) {
                throw new TriggerOrchestratorException('Maximum recursion depth reached for record: ' + recordId);
            }

            depthByRecordId.put(recordId, currentDepth + 1);
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
        private Integer recordCount;
        private Integer nestingLevel; //TODO nestingLevel?

        private Invocation() {
            this.operationType = Trigger.operationType;
            this.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
            this.recordCount = (Trigger.new ?? Trigger.old)?.size() ?? 0;
            this.nestingLevel = TriggerOrchestrator.invocationStack.size();
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

    private class HandlerExecutor {
        private List<TriggerHandlerAdapter> candidateAdapters;
        private List<TriggerHandlerAdapter> activeAdapters;
        private List<TriggerHandler.TriggerRecord> records;

        private HandlerExecutor(List<TriggerHandlerAdapter> candidateAdapters, List<TriggerHandler.TriggerRecord> records) {
            this.candidateAdapters = candidateAdapters;
            this.records = records;
            this.activeAdapters = new List<TriggerHandlerAdapter>();
        }

        public void run() {
            this.gatherActiveAdapters();
            this.qualifyRecordsWithoutRelatedData();
            this.qualifyRecordsNeedingRelatedData();
            this.executeHandlers();
        }

        private void gatherActiveAdapters() {
            for (TriggerHandlerAdapter adapter : this.candidateAdapters) {
                if (!this.shouldBeBypassed(adapter.getHandler())) {
                    this.activeAdapters.add(adapter);
                }
            }
        }

        private void qualifyRecordsWithoutRelatedData() {
            for (TriggerHandlerAdapter adapter : this.activeAdapters) {
                for (TriggerHandler.TriggerRecord record : records) {
                    if (adapter.isQualified(record)) {
                        adapter.registerRecord(record);
                    }
                }
            }
        }

        private void qualifyRecordsNeedingRelatedData() {
            List<TriggerHandler.TriggerRecord> recordsNeedingRelatedData = new List<TriggerHandler.TriggerRecord>();

            for (TriggerHandlerAdapter adapter : this.activeAdapters) {
                for (TriggerHandler.TriggerRecord record : records) {
                    if (!adapter.isRecordRegistered(record) && record.isQualificationNeedRelatedRecords()) {
                        recordsNeedingRelatedData.add(record);
                    }
                }
            }

            new ParentRelationshipEnrichment(this.activeAdapters, recordsNeedingRelatedData).enrich();

            for (TriggerHandlerAdapter adapter : this.activeAdapters) {
                for (TriggerHandler.TriggerRecord record : records) {
                    if (adapter.isRecordRegistered(record) || adapter.isQualified(record)) {
                        adapter.registerRecord(record);
                    }
                }
            }
        }

        private void executeHandlers() {
            for (TriggerHandlerAdapter adapter : this.activeAdapters) {
                if (!adapter.getQualifiedRecords().isEmpty()) {
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

        public Boolean isRecordRegistered(TriggerHandler.TriggerRecord record) {
            return this.qualifiedRecordByIdentifier.containsKey(record.getIdentifier());
        }

        public List<TriggerHandler.TriggerRecord> getQualifiedRecords() {
            return new List<TriggerHandler.TriggerRecord>(this.qualifiedRecordByIdentifier.values());
        }

        public void execute() {
            for (TriggerHandler.TriggerRecord record : this.getQualifiedRecords()) {
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
        private List<TriggerHandlerAdapter> enrichmentAdapters;
        private List<TriggerHandler.TriggerRecord> recordsToEnrich;
        private Map<SObjectField, SOQL.Queryable> queryByParentField;

        public ParentRelationshipEnrichment(List<TriggerHandlerAdapter> adapters, List<TriggerHandler.TriggerRecord> recordsToEnrich) {
            this.adapters = adapters;
            this.recordsToEnrich = recordsToEnrich;
            this.enrichmentAdapters = new List<TriggerHandlerAdapter>();
            this.queryByParentField = new Map<SObjectField, SOQL.Queryable>();
        }

        public void enrich() {
            this.gatherEnrichmentAdapters();

            if (enrichmentAdapters.isEmpty()) {
                return;
            }

            this.buildParentQueries();
            this.enrichRecords();
        }

        private void gatherEnrichmentAdapters() {
            for (TriggerHandlerAdapter adapter : adapters) {
                if (adapter.getHandler() instanceof TriggerHandler.RelationshipEnrichment) {
                    this.enrichmentAdapters.add(adapter);
                }
            }
        }

        private void buildParentQueries() {
            for (TriggerHandlerAdapter adapter : this.enrichmentAdapters) {
                Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich = ((TriggerHandler.RelationshipEnrichment) adapter.getHandler()).fieldsToEnrich();

                for (SObjectField parentField : fieldsToEnrich.keySet()) {
                    if (!this.queryByParentField.containsKey(parentField)) {
                        this.queryByParentField.put(parentField, SOQL.of(parentField.getDescribe().getReferenceTo()[0]));
                    }

                    this.queryByParentField.get(parentField).with(fieldsToEnrich.get(parentField).getFields());
                }
            }
        }

        private void enrichRecords() {
            for (SObjectField parentField : this.queryByParentField.keySet()) {
                Set<Id> parentIds = this.gatherParentIds(parentField);

                if (parentIds.isEmpty()) {
                    continue;
                }

                Map<Id, SObject> relatedRecordById = this.queryByParentField.get(parentField).byIds(parentIds).systemMode().withoutSharing().toMap();

                String relationshipName = parentField.getDescribe().getRelationshipName();

                for (TriggerHandler.TriggerRecord record : this.recordsToEnrich) {
                    SObject newRecord = record.getNewSObject();
                    SObject oldRecord = record.getOldSObject();

                    if (newRecord != null && newRecord.isSet(parentField)) {
                        record.enrichNew(relationshipName, relatedRecordById.get((Id) newRecord.get(parentField)));
                    }

                    if (oldRecord != null && oldRecord.isSet(parentField)) {
                        record.enrichOld(relationshipName, relatedRecordById.get((Id) oldRecord.get(parentField)));
                    }
                }
            }
        }

        private Set<Id> gatherParentIds(SObjectField parentField) {
            Set<Id> parentIds = new Set<Id>();

            for (TriggerHandler.TriggerRecord record : this.recordsToEnrich) {
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
