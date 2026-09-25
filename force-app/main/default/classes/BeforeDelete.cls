public class BeforeDelete {
    // Roles - pick one

    public interface Validator extends Handler {
        Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record);
        void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record);
    }

    public interface Writer extends Handler {
        Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record);
        void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    // Add-ons - pick as many as you need

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeDelete();
    }

    public interface RelatedQuery {
        Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.DeleteRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnBeforeDelete();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeDeleteWhen();
    }

    public interface Finalizer {
        void finalizeOnBeforeDelete(TriggerTypes.DeleteRecords records);
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

            for (BeforeDelete.Handler handler : ((TriggerOrchestrator.BeforeDelete) orchestrator.orchestrator).beforeDeleteHandlers()) {
                if (handler instanceof BeforeDelete.Validator) {
                    adapters.add(new BeforeDelete.ValidatorAdapter((BeforeDelete.Validator) handler, orchestrator));
                } else if (handler instanceof BeforeDelete.Writer) {
                    adapters.add(new BeforeDelete.WriterAdapter((BeforeDelete.Writer) handler, orchestrator));
                }
            }

            return adapters;
        }
    }

    public class ValidatorAdapter extends TriggerOrchestrator.HandlerAdapter {
        private BeforeDelete.Validator validator;

        public ValidatorAdapter(BeforeDelete.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);

            this.validator = validator;
            this.parentDeclaration = new BeforeDelete.ParentDeclaration(this.validator);
            this.relatedLoader = new BeforeDelete.RelatedLoader(this.validator);
            this.handlerLifecycle = new BeforeDelete.HandlerLifecycle(this.validator);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.handlerLifecycle.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }
        }

        private void validate(TriggerTypes.TriggerRecord record) {
            if (!this.validator.addErrorOnBeforeDeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);

            Integer errorsBefore = record.getOldSObject().getErrors().size();

            this.validator.addErrorOnBeforeDelete(record);

            if (record.getOldSObject().getErrors().size() == errorsBefore) {
                throw new TriggerTypes.TriggerLibException(this.handlerName + ' qualified a record in addErrorOnBeforeDeleteWhen but attached no error in addErrorOnBeforeDelete.');
            }
        }
    }

    public class WriterAdapter extends TriggerOrchestrator.HandlerAdapter {
        private BeforeDelete.Writer writer;
        private TriggerOrchestrator.UnitOfWork unitOfWork;

        public WriterAdapter(BeforeDelete.Writer writer, TriggerOrchestrator orchestrator) {
            super(writer, orchestrator);

            this.writer = writer;
            this.parentDeclaration = new BeforeDelete.ParentDeclaration(this.writer);
            this.relatedLoader = new BeforeDelete.RelatedLoader(this.writer);
            this.unitOfWork = new BeforeDelete.UnitOfWorkResolver(this.writer).resolve(this.orchestrator.sharedUnitOfWork);
            this.handlerLifecycle = new BeforeDelete.HandlerLifecycle(this.writer);
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
            if (!this.writer.writeOnBeforeDeleteWhen(record)) {
                return;
            }

            this.qualifiedRecords.add(record);
            this.writer.writeOnBeforeDelete(record, this.unitOfWork);
        }

        private void commitOwnUnitOfWork() {
            if (this.qualifiedRecords.isEmpty() || this.unitOfWork === this.orchestrator.sharedUnitOfWork) {
                return;
            }

            this.unitOfWork.commitWork();
        }
    }

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private BeforeDelete.Handler handler;

        public ParentDeclaration(BeforeDelete.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof BeforeDelete.PriorParentQuery) {
                return ((BeforeDelete.PriorParentQuery) this.handler).queryPriorParentsOnBeforeDelete();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private BeforeDelete.Handler handler;
        private Map<String, BeforeDelete.RecordsProvider> providers;

        public RelatedLoader(BeforeDelete.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof BeforeDelete.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((BeforeDelete.RelatedQuery) this.handler).queryRelatedOnBeforeDelete() ?? new Map<String, BeforeDelete.RecordsProvider>();
            }

            BeforeDelete.RecordsProvider provider = this.providers.get(providerName);

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
        private BeforeDelete.Writer writer;

        public UnitOfWorkResolver(BeforeDelete.Writer writer) {
            this.writer = writer;
        }

        public override TriggerOrchestrator.UnitOfWork resolve(TriggerOrchestrator.UnitOfWork sharedUnitOfWork) {
            return this.writer instanceof BeforeDelete.OwnUnitOfWork
                ? new TriggerOrchestrator.UnitOfWork(((BeforeDelete.OwnUnitOfWork) this.writer).ownUnitOfWorkOnBeforeDelete())
                : this.writer instanceof BeforeDelete.ContinueOnError ? new TriggerOrchestrator.UnitOfWork() : sharedUnitOfWork;
        }
    }

    public class HandlerLifecycle extends TriggerOrchestrator.HandlerLifecycle {
        private BeforeDelete.Handler handler;

        public HandlerLifecycle(BeforeDelete.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof BeforeDelete.Bypassable && ((BeforeDelete.Bypassable) this.handler).bypassOnBeforeDeleteWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof BeforeDelete.Finalizer)) {
                return;
            }

            ((BeforeDelete.Finalizer) this.handler).finalizeOnBeforeDelete(new TriggerTypes.DeleteTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeDelete.ContinueOnError;
        }
    }

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.BeforeDeleteMockable, TriggerOrchestrator.BeforeDelete {
        public MockedContext() {
            super(System.TriggerOperation.BEFORE_DELETE);
        }

        public TriggerOrchestrator.BeforeDeleteMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public TriggerOrchestrator.BeforeDeleteMockable with(List<SObject> rows) {
            this.oldRecords.addAll(this.assignIds(rows));
            return this;
        }

        public TriggerOrchestrator.BeforeDeleteMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.BeforeDeleteMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlerOrOrchestrator instanceof TriggerOrchestrator.BeforeDelete
                ? ((TriggerOrchestrator.BeforeDelete) this.handlerOrOrchestrator).beforeDeleteHandlers()
                : new List<BeforeDelete.Handler>{ (BeforeDelete.Handler) this.handlerOrOrchestrator };
        }
    }
}
