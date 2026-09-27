global class AfterUpdate {
    // Roles - pick one

    global interface Writer extends Handler {
        Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record);
        void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    global interface Dispatcher extends Handler {
        Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record);
        void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records);
    }

    // Add-ons - pick as many as you need

    global interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate();
    }

    global interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate();
    }

    global interface RelatedQuery {
        Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate();
    }

    global interface RecordsProvider {
        List<SObject> query(TriggerTypes.UpdateRecords records);
        String keyOf(SObject row);
    }

    global interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterUpdate();
    }

    global interface Bypassable {
        Boolean bypassOnAfterUpdateWhen();
    }

    global interface RecursionGuard {
        Integer maxRunsPerRecordOnAfterUpdate();
    }

    global interface Finalizer {
        void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records);
    }

    global interface ContinueOnError {
    }

    // Marker

    global interface Handler {
    }

    // Implementation

    public class Operation extends TriggerOrchestrator.Operation {
        public override List<TriggerOrchestrator.HandlerExecutor> buildExecutors(TriggerOrchestrator orchestrator) {
            List<TriggerOrchestrator.HandlerExecutor> executors = new List<TriggerOrchestrator.HandlerExecutor>();

            for (AfterUpdate.Handler handler : ((TriggerOrchestrator.AfterUpdate) orchestrator.orchestrator).afterUpdateHandlers()) {
                if (handler instanceof AfterUpdate.Writer) {
                    executors.add(new AfterUpdate.WriterExecutor((AfterUpdate.Writer) handler, orchestrator));
                } else if (handler instanceof AfterUpdate.Dispatcher) {
                    executors.add(new AfterUpdate.DispatcherExecutor((AfterUpdate.Dispatcher) handler, orchestrator));
                }
            }

            return executors;
        }
    }

    public class WriterExecutor extends TriggerOrchestrator.HandlerExecutor {
        private AfterUpdate.Writer writer;
        private TriggerOrchestrator.UnitOfWork unitOfWork;
        private TriggerOrchestrator.RecursionTracker recursionTracker;

        public WriterExecutor(AfterUpdate.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterUpdate.ParentDeclaration(this.writer);
            this.relatedLoader = new AfterUpdate.RelatedLoader(this.writer);
            this.unitOfWork = new AfterUpdate.UnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerHooks = new AfterUpdate.HandlerHooks(this.writer);
            this.recursionTracker = new AfterUpdate.RecursionTracker(this.writer, this.handlerName);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.write(record);
                }

                this.handlerHooks.finalize(this.qualifiedRecords);
                this.commitOwnUnitOfWork();
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void write(TriggerTypes.TriggerRecord record) {
            if (!this.recursionTracker.isLimitReached(record) && this.writer.writeOnAfterUpdateWhen(record)) {
                this.recursionTracker.countRun(record);
                this.qualifiedRecords.add(record);
                this.writer.writeOnAfterUpdate(record, this.unitOfWork);
            }
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    public class DispatcherExecutor extends TriggerOrchestrator.HandlerExecutor {
        private AfterUpdate.Dispatcher dispatcher;
        private TriggerOrchestrator.RecursionTracker recursionTracker;

        public DispatcherExecutor(AfterUpdate.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterUpdate.ParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterUpdate.RelatedLoader(this.dispatcher);
            this.handlerHooks = new AfterUpdate.HandlerHooks(this.dispatcher);
            this.recursionTracker = new AfterUpdate.RecursionTracker(this.dispatcher, this.handlerName);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.qualify(record);
                }

                this.dispatch();
                this.handlerHooks.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void qualify(TriggerTypes.TriggerRecord record) {
            if (!this.recursionTracker.isLimitReached(record) && this.dispatcher.dispatchOnAfterUpdateWhen(record)) {
                this.recursionTracker.countRun(record);
                this.qualifiedRecords.add(record);
            }
        }

        private void dispatch() {
            if (this.qualifiedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterUpdate(new TriggerTypes.UpdateTriggerRecords(this.qualifiedRecords));
        }
    }

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private AfterUpdate.Handler handler;

        public ParentDeclaration(AfterUpdate.Handler handler) {
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

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private AfterUpdate.Handler handler;
        private Map<String, AfterUpdate.RecordsProvider> providers;

        public RelatedLoader(AfterUpdate.Handler handler) {
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

    public class UnitOfWorkResolver extends TriggerOrchestrator.UnitOfWorkResolver {
        private AfterUpdate.Writer writer;

        public UnitOfWorkResolver(AfterUpdate.Writer writer) {
            this.writer = writer;
        }

        public override TriggerOrchestrator.UnitOfWork resolve(TriggerOrchestrator.UnitOfWork sharedUnitOfWork) {
            if (this.writer instanceof AfterUpdate.OwnUnitOfWork) {
                return new TriggerOrchestrator.UnitOfWork(((AfterUpdate.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterUpdate());
            }

            if (this.writer instanceof AfterUpdate.ContinueOnError) {
                return new TriggerOrchestrator.UnitOfWork();
            }

            return sharedUnitOfWork;
        }
    }

    public class HandlerHooks extends TriggerOrchestrator.HandlerHooks {
        private AfterUpdate.Handler handler;

        public HandlerHooks(AfterUpdate.Handler handler) {
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

    public class RecursionTracker extends TriggerOrchestrator.RecursionTracker {
        public RecursionTracker(AfterUpdate.Handler handler, String handlerName) {
            super(handlerName + ':AFTER_UPDATE');

            if (handler instanceof AfterUpdate.RecursionGuard) {
                this.maxRunsPerRecord = ((AfterUpdate.RecursionGuard) handler).maxRunsPerRecordOnAfterUpdate();
            }
        }
    }

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.AfterUpdateMockable, TriggerOrchestrator.AfterUpdate {
        public MockedContext() {
            super(System.TriggerOperation.AFTER_UPDATE);
        }

        public TriggerOrchestrator.AfterUpdateMockable with(SObject newRow, SObject oldRow) {
            return this.with(new List<SObject>{ newRow }, new List<SObject>{ oldRow });
        }

        public TriggerOrchestrator.AfterUpdateMockable with(List<SObject> newRows, List<SObject> oldRows) {
            this.shareIds(newRows, oldRows);
            this.newRecords.addAll(newRows);
            this.oldRecords.addAll(oldRows);
            return this;
        }

        public TriggerOrchestrator.AfterUpdateMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.AfterUpdateMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            if (this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterUpdate) {
                return ((TriggerOrchestrator.AfterUpdate) this.handlerOrOrchestrator).afterUpdateHandlers();
            }

            return new List<AfterUpdate.Handler>{ (AfterUpdate.Handler) this.handlerOrOrchestrator };
        }
    }
}
