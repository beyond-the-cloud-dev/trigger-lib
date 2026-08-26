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

    public interface RecursiveUpdateGuard {
        Integer maxRecursionDepth();
        Boolean muteRecursionDepthExceededException(); // TODO
    }

    // Additional interfaces

    public interface Logger {
        void log(Error error);
        void flush();
    }

    public interface Error {
        Exception getException();
        System.TriggerOperation getOperation();
        SObjectType getSObjectType();
        Set<Id> getRecordIds();
        List<Invocation> getStack();
    }

    // TODO Asynchronous Actions - TODO Only in AfterUpdate, AfterDelete context
    // TODO ContextProvider for unrelated records public interface ContextProvider {}

    // Implementations

    private static Map<System.TriggerOperation, Map<Id, Integer>> recursionDepth {
        get {
            if (recursionDepth == null) {
                recursionDepth = new Map<System.TriggerOperation, Map<Id, Integer>>{ System.TriggerOperation.AFTER_UPDATE => new Map<Id, Integer>() };
            }
            return recursionDepth;
        }
        private set;
    }

    private static Logger logger {
        get {
            if (logger == null) {
                logger = loadLogger() ?? new DefaultLogger();
            }
            return logger;
        }
        private set;
    }


    public static void run(Object orchestrator) {
        if (Trigger.operationType == null) {
            throw new TriggerOrchestratorException('Called outside of trigger context, or not supported operation type');
        }

        // Before contexts perform no DML, so nothing nests under them: they need no invocation.
        Invocation invocation = Trigger.isAfter ? startInvocation() : null;

        try {
            // Two triggers on one object must not each spend the record's recursion budget.
            if (invocation?.sameChunkRerun != true) {
                incrementRecursionDepth(orchestrator);
            }

            dispatch(orchestrator);
        } catch (Exception e) {
            if (invocation?.isRoot() == true && TriggerOrchestrator.chainTracker.currentChain != null) {
                TriggerOrchestrator.chainTracker.currentChain.failed = true;
            }

            logError(e);
            throw e;
        } finally {
            finishInvocation(invocation);
        }
    }

    private static void dispatch(Object orchestrator) {
        List<TriggerHandlerAdapter> adapters = new List<TriggerHandlerAdapter>();
        List<TriggerHandler.Record> triggerRecords = new List<TriggerHandler.Record>();

        if (Trigger.operationType == System.TriggerOperation.BEFORE_INSERT && orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
            for (TriggerHandler.BeforeInsert handler : ((TriggerOrchestrator.BeforeInsert) orchestrator).beforeInsertHandlers()) {
                adapters.add(new BeforeInsertHandlerAdapter(handler));
            }

            for (SObject record : Trigger.new) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(record));
            }
        } else if (Trigger.operationType == System.TriggerOperation.AFTER_INSERT && orchestrator instanceof TriggerOrchestrator.AfterInsert) {
            for (TriggerHandler.AfterInsert handler : ((TriggerOrchestrator.AfterInsert) orchestrator).afterInsertHandlers()) {
                adapters.add(new AfterInsertHandlerAdapter(handler));
            }

            for (SObject record : Trigger.new) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(record));
            }
        } else if (Trigger.operationType == System.TriggerOperation.BEFORE_UPDATE && orchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
            for (TriggerHandler.BeforeUpdate handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator).beforeUpdateHandlers()) {
                adapters.add(new BeforeUpdateHandlerAdapter(handler));
            }

            for (Integer i = 0; i < Trigger.new.size(); i++) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
            }
        } else if (Trigger.operationType == System.TriggerOperation.AFTER_UPDATE && orchestrator instanceof TriggerOrchestrator.AfterUpdate) {
            for (TriggerHandler.AfterUpdate handler : ((TriggerOrchestrator.AfterUpdate) orchestrator).afterUpdateHandlers()) {
                adapters.add(new AfterUpdateHandlerAdapter(handler));
            }

            for (Integer i = 0; i < Trigger.new.size(); i++) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(Trigger.new[i], Trigger.old[i]));
            }
        } else if (Trigger.operationType == System.TriggerOperation.BEFORE_DELETE && orchestrator instanceof TriggerOrchestrator.BeforeDelete) {
            for (TriggerHandler.BeforeDelete handler : ((TriggerOrchestrator.BeforeDelete) orchestrator).beforeDeleteHandlers()) {
                adapters.add(new BeforeDeleteHandlerAdapter(handler));
            }

            for (SObject record : Trigger.old) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
            }
        } else if (Trigger.operationType == System.TriggerOperation.AFTER_DELETE && orchestrator instanceof TriggerOrchestrator.AfterDelete) {
            for (TriggerHandler.AfterDelete handler : ((TriggerOrchestrator.AfterDelete) orchestrator).afterDeleteHandlers()) {
                adapters.add(new AfterDeleteHandlerAdapter(handler));
            }

            for (SObject record : Trigger.old) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(null, record));
            }
        } else if (Trigger.operationType == System.TriggerOperation.AFTER_UNDELETE && orchestrator instanceof TriggerOrchestrator.AfterUndelete) {
            for (TriggerHandler.AfterUndelete handler : ((TriggerOrchestrator.AfterUndelete) orchestrator).afterUndeleteHandlers()) {
                adapters.add(new AfterUndeleteHandlerAdapter(handler));
            }

            for (SObject record : Trigger.new) {
                triggerRecords.add(new TriggerHandler.TriggerRecord(record));
            }
        }

        runHandlers(adapters, triggerRecords);
    }

    public class Invocation {
        private System.TriggerOperation operation;
        private SObjectType sObjectType;
        private Integer recordCount;
        private Integer depth;
        private Integer chainSequence;
        private Boolean chainEnding = false;
        private String chunkKey;
        private Boolean sameChunkRerun = false;
        private List<Invocation> children = new List<Invocation>();

        private Invocation() {
            List<SObject> triggerRows = Trigger.new ?? Trigger.old;

            this.operation = Trigger.operationType;
            this.sObjectType = triggerRows.getSObjectType();
            this.recordCount = triggerRows.size();
            this.depth = TriggerOrchestrator.stack.size() + 1;
            this.chunkKey = currentChunkKey();
            this.sameChunkRerun = TriggerOrchestrator.chainTracker.isSameChunkRerun(this);
        }

        public System.TriggerOperation getOperation() {
            return this.operation;
        }

        public SObjectType getSObjectType() {
            return this.sObjectType;
        }

        public Integer getRecordCount() {
            return this.recordCount;
        }

        public Integer getDepth() {
            return this.depth;
        }

        public Integer getChainSequence() {
            return this.chainSequence;
        }

        public Boolean isRoot() {
            return this.depth == 1;
        }

        public Boolean isChainEnding() {
            return this.chainEnding;
        }

        public List<Invocation> getChildren() {
            return this.children.clone();
        }
    }

    public static Integer getDepth() {
        return TriggerOrchestrator.stack.size();
    }

    public static List<Invocation> getStack() {
        return TriggerOrchestrator.stack.clone();
    }

    // The full map of the current chain — every invocation it has run, not just the live path.
    public static List<Invocation> getChainTree() {
        return TriggerOrchestrator.chainTracker.currentChain?.roots.clone() ?? new List<Invocation>();
    }

    public static Boolean isChainEnding() {
        return TriggerOrchestrator.stack.size() == 1 && TriggerOrchestrator.stack[0].chainEnding;
    }

    public static String getRequestId() {
        return Request.getCurrent().getRequestId();
    }

    // Implementation

    private static final Integer TRIGGER_CHUNK_SIZE = 200;

    private static List<Invocation> stack = new List<Invocation>();
    private static ChainTracker chainTracker = new ChainTracker();

    private static String currentChunkKey() {
        List<SObject> triggerRows = Trigger.new ?? Trigger.old;
        Set<Id> recordIds = (Trigger.newMap ?? Trigger.oldMap)?.keySet();
        // Before-insert rows have no Ids yet, so their field values identify the chunk instead.
        Integer identity = recordIds == null || recordIds.isEmpty() ? triggerRows.hashCode() : recordIds.hashCode();

        return Trigger.operationType.name() + ':' + triggerRows.size() + ':' + identity;
    }

    private class Chain {
        private Integer sequence;
        private SObjectType sObjectType;
        private Integer expectedRows;
        private Integer afterRowsSeen = 0;
        private Boolean failed = false;
        private Boolean flushed = false;
        private Boolean sizeUncertain = false;
        private List<Invocation> roots = new List<Invocation>();

        private Chain(Invocation invocation, Integer dmlRowsAtChunkStart, Integer dmlStatementsAtChunkStart) {
            TriggerOrchestrator.chainTracker.chainCount++;

            // Rows from objects with no orchestrated trigger are invisible here and would hide this end forever.
            this.sizeUncertain = dmlStatementsAtChunkStart - TriggerOrchestrator.chainTracker.dmlStatementsAccounted != 1;
            this.sequence = TriggerOrchestrator.chainTracker.chainCount;
            this.sObjectType = invocation.sObjectType;
            // Only the final chunk can be shorter than the platform chunk size.
            this.expectedRows = invocation.recordCount < TriggerOrchestrator.TRIGGER_CHUNK_SIZE || this.sizeUncertain
                ? invocation.recordCount
                : Math.max(dmlRowsAtChunkStart - TriggerOrchestrator.chainTracker.dmlRowsAtLastFinish, invocation.recordCount);
        }

        private Boolean isContinuedBy(Invocation invocation) {
            if (this.failed || (this.isComplete() && !this.sizeUncertain) || this.sObjectType != invocation.sObjectType) {
                return false;
            }

            // Every row is counted when the first chunk fires, so a real next chunk adds none.
            if (Limits.getDmlRows() > TriggerOrchestrator.chainTracker.dmlRowsAtLastFinish) {
                return false;
            }

            // With the size unknown, the same object and an unmoved counter is all a next chunk can show.
            return this.sizeUncertain || this.afterRowsSeen + invocation.recordCount <= this.expectedRows;
        }

        // Counts the after chunk into this chain and answers whether it is the chain's last one.
        private Boolean absorb(Invocation invocation) {
            if (this.sizeUncertain) {
                this.flushed = false;
            }

            this.afterRowsSeen += invocation.recordCount;

            // Only the final chunk can be shorter than the platform chunk size.
            return this.isComplete() || invocation.recordCount < TriggerOrchestrator.TRIGGER_CHUNK_SIZE;
        }

        private Boolean isComplete() {
            return this.afterRowsSeen >= this.expectedRows;
        }
    }

    private static Invocation startInvocation() {
        Invocation invocation = new Invocation();

        TriggerOrchestrator.chainTracker.onStart(invocation);
        TriggerOrchestrator.stack.add(invocation);

        return invocation;
    }

    private static void finishInvocation(Invocation invocation) {
        if (invocation == null) {
            // A partial-save retry re-runs the survivors' after chunk with the counter unmoved; the
            // before phase in between is what proves it is not the previous after chunk again. And
            // a before context that just threw dies with its statement, so its error flushes now.
            TriggerOrchestrator.chainTracker.lastPopped = null;
            flushPendingErrors();
            return;
        }

        try {
            TriggerOrchestrator.chainTracker.onFinish(invocation);
        } finally {
            TriggerOrchestrator.stack.remove(TriggerOrchestrator.stack.size() - 1);
        }
    }

    private static void flushPendingErrors() {
        if (!TriggerOrchestrator.chainTracker.hasPendingLoggedErrors) {
            return;
        }

        flushLogger();
        TriggerOrchestrator.chainTracker.hasPendingLoggedErrors = false;
    }

    private static void flushLogger() {
        try {
            TriggerOrchestrator.logger.flush();
        } catch (Exception loggerFailure) {
            // A broken logger must not abort the save or mask a propagating exception.
            System.debug(LoggingLevel.ERROR, 'TriggerOrchestrator logger flush failed: ' + loggerFailure.getMessage());
        }
    }

    // One owner for every piece of cross-invocation chain state. The onStart/onFinish order is
    // load-bearing — handlers read chainSequence and isChainEnding() mid-invocation.
    private class ChainTracker {
        private Chain currentChain;
        private Integer chainCount = 0;
        private Integer dmlStatementsAccounted = 0;
        private Boolean hasPendingLoggedErrors = false;
        private Invocation lastPopped;
        private Integer dmlRowsAtLastFinish = 0;

        private void onStart(Invocation invocation) {
            if (invocation.sameChunkRerun) {
                invocation.chainEnding = this.lastPopped.chainEnding;
            } else if (invocation.isRoot()) {
                this.track(invocation);
            }

            invocation.chainSequence = this.currentChain?.sequence;
            this.attach(invocation);
        }

        private void onFinish(Invocation invocation) {
            if (invocation.isRoot()) {
                Boolean flushesChain = (invocation.chainEnding || this.currentChain?.failed == true) && this.currentChain?.flushed == false;

                // A before-only trigger never reaches an end this class can detect.
                if (flushesChain || this.hasPendingLoggedErrors) {
                    flushLogger();
                }

                if (flushesChain) {
                    this.currentChain.flushed = true;
                }

                this.hasPendingLoggedErrors = false;
                this.dmlStatementsAccounted = Limits.getDmlStatements();
            }

            // Before-insert populators mutate the rows between two triggers of one chunk, so the
            // identity hashed at start is stale by finish; the next trigger hashes the mutated rows.
            invocation.chunkKey = currentChunkKey();
            this.lastPopped = invocation;
            this.dmlRowsAtLastFinish = Limits.getDmlRows();
        }

        // Only a genuine new DML can move Limits.getDmlRows() between two invocations.
        private Boolean isSameChunkRerun(Invocation invocation) {
            return this.lastPopped != null
                && invocation.depth == this.lastPopped.depth
                && invocation.chunkKey == this.lastPopped.chunkKey
                && Limits.getDmlRows() == this.dmlRowsAtLastFinish;
        }

        private void track(Invocation invocation) {
            // Both snapshots precede the late flush, so the logger's own DML counts as neither this
            // statement's rows nor a second statement.
            Integer dmlRowsAtChunkStart = Limits.getDmlRows();
            Integer dmlStatementsAtChunkStart = Limits.getDmlStatements();

            if (this.currentChain?.isContinuedBy(invocation) != true) {
                if (this.currentChain != null && !this.currentChain.isComplete() && !this.currentChain.flushed) {
                    flushLogger();
                    this.hasPendingLoggedErrors = false;
                }

                this.currentChain = new Chain(invocation, dmlRowsAtChunkStart, dmlStatementsAtChunkStart);
            }

            invocation.chainEnding = this.currentChain.absorb(invocation);
        }

        private void attach(Invocation invocation) {
            if (!TriggerOrchestrator.stack.isEmpty()) {
                TriggerOrchestrator.stack[TriggerOrchestrator.stack.size() - 1].children.add(invocation);
            } else {
                this.currentChain?.roots.add(invocation);
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
        ];

        if (implementors.size() > 1) {
            throw new TriggerOrchestratorException('Multiple implementations of TriggerOrchestrator.Logger found');
        }

        if (!implementors.isEmpty()) {
            Object instance = Type.forName(implementors[0].ClassNamespacePrefix, implementors[0].ClassName)?.newInstance();
            return instance instanceof Logger ? (Logger) instance : null;
        }

        return null;
    }

    private static void logError(Exception e) {
        TriggerError error = new TriggerError();

        error.triggerException = e;
        error.operation = Trigger.operationType;
        error.sObjectType = (Trigger.new ?? Trigger.old)?.getSObjectType();
        error.recordIds = (Trigger.newMap ?? Trigger.oldMap)?.keySet();
        error.stack = getStack();

        try {
            TriggerOrchestrator.logger.log(error);
            TriggerOrchestrator.chainTracker.hasPendingLoggedErrors = true;
        } catch (Exception loggerFailure) {
            // A broken logger must not mask the handler exception.
            System.debug(LoggingLevel.ERROR, 'TriggerOrchestrator logger log failed: ' + loggerFailure.getMessage());
        }
    }

    private class DefaultLogger implements Logger {
        // A missing implementation is cached as a do-nothing default, otherwise the
        // ApexTypeImplementor query would repeat on every access.

        public void log(Error error) {
        }

        public void flush() {
        }
    }

    private class TriggerError implements Error {
        public Exception triggerException;
        public System.TriggerOperation operation;
        public SObjectType sObjectType;
        public Set<Id> recordIds;
        public List<Invocation> stack;

        public Exception getException() {
            return this.triggerException;
        }

        public List<Invocation> getStack() {
            return this.stack;
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
        final List<System.TriggerOperation> OPERATION_SUPPORTING_RECURSION_DEPTH = new List<System.TriggerOperation>{ System.TriggerOperation.AFTER_UPDATE };

        if (!OPERATION_SUPPORTING_RECURSION_DEPTH.contains(Trigger.operationType)) {
            return;
        }

        Integer orchestratorMaxDepth = 3;

        if (orchestrator instanceof TriggerOrchestrator.RecursiveUpdateGuard) {
            orchestratorMaxDepth = ((TriggerOrchestrator.RecursiveUpdateGuard) orchestrator).maxRecursionDepth();
        }

        Integer recordIdsHashCode = Trigger.newMap.keySet().hashCode();

        for (Id recordId : Trigger.newMap.keySet()) {
            // maybe insteaf of ids, just use List hashMap
            Map<Id, Integer> idToUpdateCount = TriggerOrchestrator.recursionDepth.get(Trigger.operationType);
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
                // TODO No queries allowed 
                // TODO Maybe override execute in each adapter and in before do not allow dmls as well
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
