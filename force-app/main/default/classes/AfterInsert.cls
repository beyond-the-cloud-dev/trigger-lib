public class AfterInsert {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record);
        void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record);
        void dispatchOnAfterInsert(TriggerTypes.InsertRecords records);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert();
    }

    public interface RelatedQuery {
        Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.InsertRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterInsert();
    }

    public interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    public interface Finalizer {
        void finalizeOnAfterInsert(TriggerTypes.InsertRecords records);
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

            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) orchestrator.orchestrator).afterInsertHandlers()) {
                if (handler instanceof AfterInsert.Writer) {
                    adapters.add(new AfterInsert.WriterAdapter((AfterInsert.Writer) handler, orchestrator));
                } else if (handler instanceof AfterInsert.Dispatcher) {
                    adapters.add(new AfterInsert.DispatcherAdapter((AfterInsert.Dispatcher) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    public class WriterAdapter extends TriggerOrchestrator.HandlerAdapter {
        private AfterInsert.Writer writer;
        private TriggerOrchestrator.UnitOfWork unitOfWork;

        public WriterAdapter(AfterInsert.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterInsert.ParentDeclaration(this.writer);
            this.relatedLoader = new AfterInsert.RelatedLoader(this.writer);
            this.unitOfWork = new AfterInsert.UnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new AfterInsert.HandlerLifecycle(this.writer);
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

    public class DispatcherAdapter extends TriggerOrchestrator.HandlerAdapter {
        private AfterInsert.Dispatcher dispatcher;

        public DispatcherAdapter(AfterInsert.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterInsert.ParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterInsert.RelatedLoader(this.dispatcher);
            this.handlerLifecycle = new AfterInsert.HandlerLifecycle(this.dispatcher);
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

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private AfterInsert.Handler handler;

        public ParentDeclaration(AfterInsert.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof AfterInsert.ParentQuery) {
                return ((AfterInsert.ParentQuery) this.handler).queryParentsOnAfterInsert();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private AfterInsert.Handler handler;
        private Map<String, AfterInsert.RecordsProvider> providers;

        public RelatedLoader(AfterInsert.Handler handler) {
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

    public class UnitOfWorkResolver extends TriggerOrchestrator.UnitOfWorkResolver {
        private AfterInsert.Writer writer;

        public UnitOfWorkResolver(AfterInsert.Writer writer) {
            this.writer = writer;
        }

        public override TriggerOrchestrator.UnitOfWork resolve(TriggerOrchestrator.UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof AfterInsert.OwnUnitOfWork
                ? new TriggerOrchestrator.UnitOfWork(((AfterInsert.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterInsert())
                : this.writer instanceof AfterInsert.ContinueOnError ? new TriggerOrchestrator.UnitOfWork() : sharedUnitOfWork;
        }
    }

    public class HandlerLifecycle extends TriggerOrchestrator.HandlerLifecycle {
        private AfterInsert.Handler handler;

        public HandlerLifecycle(AfterInsert.Handler handler) {
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

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.AfterInsertMockable, TriggerOrchestrator.AfterInsert {
        public MockedContext() {
            super(System.TriggerOperation.AFTER_INSERT);
        }

        public TriggerOrchestrator.AfterInsertMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public TriggerOrchestrator.AfterInsertMockable with(List<SObject> rows) {
            this.newRecords.addAll(this.assignIds(rows));
            return this;
        }

        public TriggerOrchestrator.AfterInsertMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.AfterInsertMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterInsert
                ? ((TriggerOrchestrator.AfterInsert) this.handlerOrOrchestrator).afterInsertHandlers()
                : new List<AfterInsert.Handler>{ (AfterInsert.Handler) this.handlerOrOrchestrator };
        }
    }
}
