public class AfterUndelete {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record);
        void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record);
        void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUndelete();
    }

    public interface RelatedQuery {
        Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.UndeleteRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterUndelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }

    // Implementation

    public class ExecutionStrategy extends TriggerOrchestrator.ExecutionStrategy {
        public override List<TriggerOrchestrator.HandlerAdapter> adaptHandlers(TriggerOrchestrator orchestrator) {
            List<TriggerOrchestrator.HandlerAdapter> adapters = new List<TriggerOrchestrator.HandlerAdapter>();

            for (AfterUndelete.Handler handler : ((TriggerOrchestrator.AfterUndelete) orchestrator.orchestrator).afterUndeleteHandlers()) {
                if (handler instanceof AfterUndelete.Writer) {
                    adapters.add(new AfterUndelete.WriterAdapter((AfterUndelete.Writer) handler, orchestrator));
                } else if (handler instanceof AfterUndelete.Dispatcher) {
                    adapters.add(new AfterUndelete.DispatcherAdapter((AfterUndelete.Dispatcher) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    public class WriterAdapter extends TriggerOrchestrator.HandlerAdapter {
        private AfterUndelete.Writer writer;
        private TriggerOrchestrator.UnitOfWork unitOfWork;

        public WriterAdapter(AfterUndelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterUndelete.ParentDeclaration(this.writer);
            this.relatedLoader = new AfterUndelete.RelatedLoader(this.writer);
            this.unitOfWork = new AfterUndelete.UnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new AfterUndelete.HandlerLifecycle(this.writer);
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

    public class DispatcherAdapter extends TriggerOrchestrator.HandlerAdapter {
        private AfterUndelete.Dispatcher dispatcher;

        public DispatcherAdapter(AfterUndelete.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterUndelete.ParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterUndelete.RelatedLoader(this.dispatcher);
            this.handlerLifecycle = new AfterUndelete.HandlerLifecycle(this.dispatcher);
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

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private AfterUndelete.Handler handler;

        public ParentDeclaration(AfterUndelete.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof AfterUndelete.ParentQuery) {
                return ((AfterUndelete.ParentQuery) this.handler).queryParentsOnAfterUndelete();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private AfterUndelete.Handler handler;
        private Map<String, AfterUndelete.RecordsProvider> providers;

        public RelatedLoader(AfterUndelete.Handler handler) {
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

    public class UnitOfWorkResolver extends TriggerOrchestrator.UnitOfWorkResolver {
        private AfterUndelete.Writer writer;

        public UnitOfWorkResolver(AfterUndelete.Writer writer) {
            this.writer = writer;
        }

        public override TriggerOrchestrator.UnitOfWork resolve(TriggerOrchestrator.UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof AfterUndelete.OwnUnitOfWork
                ? new TriggerOrchestrator.UnitOfWork(((AfterUndelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterUndelete())
                : this.writer instanceof AfterUndelete.ContinueOnError ? new TriggerOrchestrator.UnitOfWork() : sharedUnitOfWork;
        }
    }

    public class HandlerLifecycle extends TriggerOrchestrator.HandlerLifecycle {
        private AfterUndelete.Handler handler;

        public HandlerLifecycle(AfterUndelete.Handler handler) {
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

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.AfterUndeleteMockable, TriggerOrchestrator.AfterUndelete {
        public MockedContext() {
            super(System.TriggerOperation.AFTER_UNDELETE);
        }

        public TriggerOrchestrator.AfterUndeleteMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public TriggerOrchestrator.AfterUndeleteMockable with(List<SObject> rows) {
            this.newRecords.addAll(this.assignIds(rows));
            return this;
        }

        public TriggerOrchestrator.AfterUndeleteMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.AfterUndeleteMockable withParent(SObjectField lookupField, List<SObject> parents) {
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
