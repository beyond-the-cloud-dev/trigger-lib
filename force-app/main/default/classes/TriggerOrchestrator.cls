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

    public static void run(Object orchestrator) { //TODO maybe it shound not be static so I can have access to this
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
            List<TriggerHandler.Record> triggerRecords = new List<TriggerHandler.Record>();

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

            runHandlers(unifiedHandlers, triggerRecords);
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
            WHERE InterfaceName = 'TriggerOrchestrator.Logger' AND InterfaceNamespacePrefix = :namespacePrefix AND IsConcrete = true
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

    private static void runHandlers(List<TriggerHandlerAdapter> adapters, List<TriggerHandler.Record> records) {
        if (records.isEmpty()) {
            return;
        }

        List<TriggerHandlerAdapter> qualifiedAdapters = new List<TriggerHandlerAdapter>();

        for (TriggerHandlerAdapter adapter : adapters) {
            if (shouldBeBypassed(adapter.getHandler())) {
                continue;
            }

            for (TriggerHandler.Record record : records) {
                // TODO isQualified can use related records, so we need to enrich them before calling isQualified
                // but maybe enrich data only when calling getRelated(..) method from records is used.
                if (adapter.isQualified(record)) {
                    adapter.registerRecord(record);
                }
            }

            if (adapter.getRecords().isEmpty()) {
                continue;
            }

            qualifiedAdapters.add(adapter);
        }

        if (qualifiedAdapters.isEmpty()) {
            return;
        }

        new ParentRelationshipEnrichment(qualifiedAdapters).enrich();

        for (TriggerHandlerAdapter adapter : qualifiedAdapters) {
            adapter.execute();
        }
    }

    private static Boolean shouldBeBypassed(Object handler) {
        if (handler instanceof TriggerHandler.Bypassable) {
            return ((TriggerHandler.Bypassable) handler).bypassWhen();
        }

        return false;
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

    private abstract class TriggerHandlerAdapter {
        protected Object handler;

        private List<TriggerHandler.Record> records;

        public TriggerHandlerAdapter(Object handler) {
            this.handler = handler;
            this.records = new List<TriggerHandler.Record>();
        }

        public Object getHandler() {
            return this.handler;
        }

        public void registerRecord(TriggerHandler.Record record) {
            this.records.add(record);
        }

        public List<TriggerHandler.Record> getRecords() {
            return this.records;
        }

        public void execute() {
            for (TriggerHandler.Record record : this.records) {
                // TODO Allow to override execute method so before methods will have logic to block DMLs
                this.executeOn(record);
            }
        }

        public abstract Boolean isQualified(TriggerHandler.Record record);

        protected abstract void executeOn(TriggerHandler.Record record);
    }

    private class BeforeInsertHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeInsertHandlerAdapter(TriggerHandler.BeforeInsert handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.BeforeInsert) this.handler).qualifiesForBeforeInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.BeforeInsert) this.handler).onBeforeInsert(record);
        }
    }

    private class AfterInsertHandlerAdapter extends TriggerHandlerAdapter {
        public AfterInsertHandlerAdapter(TriggerHandler.AfterInsert handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.AfterInsert) this.handler).qualifiesForAfterInsertWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.AfterInsert) this.handler).onAfterInsert(record);
        }
    }

    private class BeforeUpdateHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeUpdateHandlerAdapter(TriggerHandler.BeforeUpdate handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.BeforeUpdate) this.handler).qualifiesForBeforeUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.BeforeUpdate) this.handler).onBeforeUpdate(record);
        }
    }

    private class AfterUpdateHandlerAdapter extends TriggerHandlerAdapter {
        public AfterUpdateHandlerAdapter(TriggerHandler.AfterUpdate handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.AfterUpdate) this.handler).qualifiesForAfterUpdateWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.AfterUpdate) this.handler).onAfterUpdate(record);
        }
    }

    private class BeforeDeleteHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeDeleteHandlerAdapter(TriggerHandler.BeforeDelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.BeforeDelete) this.handler).qualifiesForBeforeDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.BeforeDelete) this.handler).onBeforeDelete(record);
        }
    }

    private class AfterDeleteHandlerAdapter extends TriggerHandlerAdapter {
        public AfterDeleteHandlerAdapter(TriggerHandler.AfterDelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.AfterDelete) this.handler).qualifiesForAfterDeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.AfterDelete) this.handler).onAfterDelete(record);
        }
    }

    private class BeforeUndeleteHandlerAdapter extends TriggerHandlerAdapter {
        public BeforeUndeleteHandlerAdapter(TriggerHandler.BeforeUndelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.BeforeUndelete) this.handler).qualifiesForBeforeUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.BeforeUndelete) this.handler).onBeforeUndelete(record);
        }
    }

    private class AfterUndeleteHandlerAdapter extends TriggerHandlerAdapter {
        public AfterUndeleteHandlerAdapter(TriggerHandler.AfterUndelete handler) {
            super(handler);
        }

        public override Boolean isQualified(TriggerHandler.Record record) {
            return ((TriggerHandler.AfterUndelete) this.handler).qualifiesForAfterUndeleteWhen(record);
        }

        protected override void executeOn(TriggerHandler.Record record) {
            ((TriggerHandler.AfterUndelete) this.handler).onAfterUndelete(record);
        }
    }

    private class ParentRelationshipEnrichment {
        private List<TriggerHandlerAdapter> adapters;
        private Map<SObjectField, SOQL.Queryable> parentFieldToQuery;

        public ParentRelationshipEnrichment(List<TriggerHandlerAdapter> adapters) {
            this.adapters = adapters;
            this.parentFieldToQuery = new Map<SObjectField, SOQL.Queryable>();
        }

        public void enrich() {
            if (!this.isEnrichmentNeeded()) {
                return;
            }

            this.initQueries();
            this.enrichRecords();
        }

        private Boolean isEnrichmentNeeded() {
            for (TriggerHandlerAdapter adapter : adapters) {
                if (adapter.getHandler() instanceof TriggerHandler.RelationshipEnrichment) {
                    return true;
            }
            }

            return false;
        }

        private void initQueries() {
            for (TriggerHandlerAdapter adapter : adapters) {
                if (adapter.getHandler() instanceof TriggerHandler.RelationshipEnrichment) {
                TriggerHandler.RelationshipEnrichment enrichmentHandler = (TriggerHandler.RelationshipEnrichment) adapter.getHandler();

                Map<SObjectField, TriggerHandler.FieldSelection> fieldsToEnrich = enrichmentHandler.fieldsToEnrich();

                    for (SObjectField field : fieldsToEnrich.keySet()) {
                        if (!parentFieldToQuery.containsKey(field)) {
                            parentFieldToQuery.put(field, SOQL.of(field.getDescribe().getReferenceTo()[0]));
                    }

                        parentFieldToQuery.get(field).with(fieldsToEnrich.get(field).getFields());
                }
            }
        }
        }

        private Set<Id> gatherParentIds(SObjectField parentField) {
            Set<Id> parentIds = new Set<Id>();

            for (TriggerHandlerAdapter adapter : this.adapters) {
                for (TriggerHandler.Record record : adapter.getRecords()) {
                    SObject newRecord = record.getNewSObject();
                    SObject oldRecord = record.getOldSObject();

                    if (newRecord != null && newRecord.get(parentField) != null) {
                        parentIds.add((Id) newRecord.get(parentField));
                    }

                    if (oldRecord != null && oldRecord.get(parentField) != null) {
                        parentIds.add((Id) oldRecord.get(parentField));
                    }
                }
            }

            return parentIds;
        }

        private void enrichRecords() {
            for (SObjectField parentField : this.parentFieldToQuery.keySet()) {
                Set<Id> parentIds = this.gatherParentIds(parentField);

                if (parentIds.isEmpty()) {
                    continue;
                }

                // TODO Do a signle query for after context
                Map<Id, SObject> relatedRecords = this.parentFieldToQuery.get(parentField).byIds(parentIds).systemMode().withoutSharing().toMap();

                String relationshipName = parentField.getDescribe().getRelationshipName();

                for (TriggerHandlerAdapter adapter : this.adapters) {
                    for (TriggerHandler.Record record : adapter.getRecords()) {
                    TriggerHandler.TriggerRecord triggerRecord = (TriggerHandler.TriggerRecord) record;

                    SObject newRecord = triggerRecord.getNewSObject();
                    SObject oldRecord = triggerRecord.getOldSObject();

                    if (newRecord != null && newRecord.get(parentField) != null) {
                        triggerRecord.enrichNew(relationshipName, relatedRecords.get((Id) newRecord.get(parentField)));
                    }

                    if (oldRecord != null && oldRecord.get(parentField) != null) {
                        triggerRecord.enrichOld(relationshipName, relatedRecords.get((Id) oldRecord.get(parentField)));
                    }
                }
            }
        }
        }
    }

    private class RelationshipEnrichment {
    }

    private class TriggerOrchestratorException extends Exception {
    }
}
