public class AfterDelete {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record);
        void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record);
        void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records);
    }

    // Add-ons - pick as many as you need

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterDelete();
    }

    public interface RelatedQuery {
        Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.DeleteRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterDelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterDeleteWhen();
    }

    public interface Finalizer {
        void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }

    // Implementation

    public class Operation extends TriggerOrchestrator.Operation {
        public override List<TriggerOrchestrator.HandlerExecutor> buildExecutors(TriggerOrchestrator orchestrator) {
            List<TriggerOrchestrator.HandlerExecutor> executors = new List<TriggerOrchestrator.HandlerExecutor>();

            for (AfterDelete.Handler handler : ((TriggerOrchestrator.AfterDelete) orchestrator.orchestrator).afterDeleteHandlers()) {
                if (handler instanceof AfterDelete.Writer) {
                    executors.add(new AfterDelete.WriterExecutor((AfterDelete.Writer) handler, orchestrator));
                } else if (handler instanceof AfterDelete.Dispatcher) {
                    executors.add(new AfterDelete.DispatcherExecutor((AfterDelete.Dispatcher) handler, orchestrator));
                }
            }

            return executors;
        }
    }

    public class WriterExecutor extends TriggerOrchestrator.HandlerExecutor {
        private AfterDelete.Writer writer;
        private TriggerOrchestrator.UnitOfWork unitOfWork;

        public WriterExecutor(AfterDelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterDelete.ParentDeclaration(this.writer);
            this.relatedLoader = new AfterDelete.RelatedLoader(this.writer);
            this.unitOfWork = new AfterDelete.UnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerHooks = new AfterDelete.HandlerHooks(this.writer);
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
            if (this.writer.writeOnAfterDeleteWhen(record)) {
                this.qualifiedRecords.add(record);
                this.writer.writeOnAfterDelete(record, this.unitOfWork);
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
        private AfterDelete.Dispatcher dispatcher;

        public DispatcherExecutor(AfterDelete.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterDelete.ParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterDelete.RelatedLoader(this.dispatcher);
            this.handlerHooks = new AfterDelete.HandlerHooks(this.dispatcher);
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
            if (this.dispatcher.dispatchOnAfterDeleteWhen(record)) {
                this.qualifiedRecords.add(record);
            }
        }

        private void dispatch() {
            if (this.qualifiedRecords.isEmpty()) {
                return;
            }

            this.dispatcher.dispatchOnAfterDelete(new TriggerTypes.DeleteTriggerRecords(this.qualifiedRecords));
        }
    }

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private AfterDelete.Handler handler;

        public ParentDeclaration(AfterDelete.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof AfterDelete.PriorParentQuery) {
                return ((AfterDelete.PriorParentQuery) this.handler).queryPriorParentsOnAfterDelete();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private AfterDelete.Handler handler;
        private Map<String, AfterDelete.RecordsProvider> providers;

        public RelatedLoader(AfterDelete.Handler handler) {
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

    public class UnitOfWorkResolver extends TriggerOrchestrator.UnitOfWorkResolver {
        private AfterDelete.Writer writer;

        public UnitOfWorkResolver(AfterDelete.Writer writer) {
            this.writer = writer;
        }

        public override TriggerOrchestrator.UnitOfWork resolve(TriggerOrchestrator.UnitOfWork sharedUnitOfWork) {
            if (this.writer instanceof AfterDelete.OwnUnitOfWork) {
                return new TriggerOrchestrator.UnitOfWork(((AfterDelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterDelete());
            }

            if (this.writer instanceof AfterDelete.ContinueOnError) {
                return new TriggerOrchestrator.UnitOfWork();
            }

            return sharedUnitOfWork;
        }
    }

    public class HandlerHooks extends TriggerOrchestrator.HandlerHooks {
        private AfterDelete.Handler handler;

        public HandlerHooks(AfterDelete.Handler handler) {
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

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.AfterDeleteMockable, TriggerOrchestrator.AfterDelete {
        public MockedContext() {
            super(System.TriggerOperation.AFTER_DELETE);
        }

        public TriggerOrchestrator.AfterDeleteMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public TriggerOrchestrator.AfterDeleteMockable with(List<SObject> rows) {
            this.oldRecords.addAll(this.assignIds(rows));
            return this;
        }

        public TriggerOrchestrator.AfterDeleteMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.AfterDeleteMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            if (this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterDelete) {
                return ((TriggerOrchestrator.AfterDelete) this.handlerOrOrchestrator).afterDeleteHandlers();
            }

            return new List<AfterDelete.Handler>{ (AfterDelete.Handler) this.handlerOrOrchestrator };
        }
    }
}
