global class AfterInsert {
    // Roles - pick one

    global interface Writer extends Handler {
        Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record);
        void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    global interface Dispatcher extends Handler {
        Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record);
        void dispatchOnAfterInsert(TriggerTypes.InsertRecords records);
    }

    // Add-ons - pick as many as you need

    global interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert();
    }

    global interface RelatedQuery {
        Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert();
    }

    global interface RecordsProvider {
        List<SObject> query(TriggerTypes.InsertRecords records);
        String keyOf(SObject row);
    }

    global interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterInsert();
    }

    global interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    global interface Finalizer {
        void finalizeOnAfterInsert(TriggerTypes.InsertRecords records);
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

            for (AfterInsert.Handler handler : ((TriggerOrchestrator.AfterInsert) orchestrator.orchestrator).afterInsertHandlers()) {
                if (handler instanceof AfterInsert.Writer) {
                    executors.add(new AfterInsert.WriterExecutor((AfterInsert.Writer) handler, orchestrator));
                } else if (handler instanceof AfterInsert.Dispatcher) {
                    executors.add(new AfterInsert.DispatcherExecutor((AfterInsert.Dispatcher) handler, orchestrator));
                }
            }

            return executors;
        }
    }

    public class WriterExecutor extends TriggerOrchestrator.HandlerExecutor {
        private AfterInsert.Writer writer;
        private TriggerOrchestrator.UnitOfWork unitOfWork;

        public WriterExecutor(AfterInsert.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new AfterInsert.ParentDeclaration(this.writer);
            this.relatedLoader = new AfterInsert.RelatedLoader(this.writer);
            this.unitOfWork = new AfterInsert.UnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerHooks = new AfterInsert.HandlerHooks(this.writer);
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
            if (this.writer.writeOnAfterInsertWhen(record)) {
                this.qualifiedRecords.add(record);
                this.writer.writeOnAfterInsert(record, this.unitOfWork);
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
        private AfterInsert.Dispatcher dispatcher;

        public DispatcherExecutor(AfterInsert.Dispatcher dispatcher, TriggerOrchestrator orchestrator) {
            super(dispatcher, orchestrator);

            this.dispatcher = dispatcher;
            this.parentDeclaration = new AfterInsert.ParentDeclaration(this.dispatcher);
            this.relatedLoader = new AfterInsert.RelatedLoader(this.dispatcher);
            this.handlerHooks = new AfterInsert.HandlerHooks(this.dispatcher);
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
            if (this.dispatcher.dispatchOnAfterInsertWhen(record)) {
                this.qualifiedRecords.add(record);
            }
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
            if (this.writer instanceof AfterInsert.OwnUnitOfWork) {
                return new TriggerOrchestrator.UnitOfWork(((AfterInsert.OwnUnitOfWork) this.writer).ownUnitOfWorkOnAfterInsert());
            }

            if (this.writer instanceof AfterInsert.ContinueOnError) {
                return new TriggerOrchestrator.UnitOfWork();
            }

            return sharedUnitOfWork;
        }
    }

    public class HandlerHooks extends TriggerOrchestrator.HandlerHooks {
        private AfterInsert.Handler handler;

        public HandlerHooks(AfterInsert.Handler handler) {
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
            if (this.handlerOrOrchestrator instanceof TriggerOrchestrator.AfterInsert) {
                return ((TriggerOrchestrator.AfterInsert) this.handlerOrOrchestrator).afterInsertHandlers();
            }

            return new List<AfterInsert.Handler>{ (AfterInsert.Handler) this.handlerOrOrchestrator };
        }
    }
}
