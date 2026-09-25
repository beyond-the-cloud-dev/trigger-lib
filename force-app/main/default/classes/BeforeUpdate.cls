public class BeforeUpdate {
    // Roles - pick one

    public interface Populator extends Handler {
        Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record);
        void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record);
    }

    public interface Validator extends Handler {
        Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record);
        void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate();
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeUpdate();
    }

    public interface RelatedQuery {
        Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.UpdateRecords records);
        String keyOf(SObject row);
    }

    public interface Bypassable {
        Boolean bypassOnBeforeUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRunsPerRecordOnBeforeUpdate();
    }

    public interface Finalizer {
        void finalizeOnBeforeUpdate(TriggerTypes.UpdateRecords records);
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

            for (BeforeUpdate.Handler handler : ((TriggerOrchestrator.BeforeUpdate) orchestrator.orchestrator).beforeUpdateHandlers()) {
                if (handler instanceof BeforeUpdate.Populator) {
                    executors.add(new BeforeUpdate.PopulatorExecutor((BeforeUpdate.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeUpdate.Validator) {
                    executors.add(new BeforeUpdate.ValidatorExecutor((BeforeUpdate.Validator) handler, orchestrator));
                }
            }

            return executors;
        }
    }

    public class PopulatorExecutor extends TriggerOrchestrator.HandlerExecutor {
        private BeforeUpdate.Populator populator;
        private TriggerOrchestrator.RecursionTracker recursionTracker;

        public PopulatorExecutor(BeforeUpdate.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);

            this.populator = populator;
            this.parentDeclaration = new BeforeUpdate.ParentDeclaration(this.populator);
            this.relatedLoader = new BeforeUpdate.RelatedLoader(this.populator);
            this.handlerHooks = new BeforeUpdate.HandlerHooks(this.populator);
            this.recursionTracker = new BeforeUpdate.RecursionTracker(this.populator, this.handlerName);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.populate(record);
                }

                this.handlerHooks.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerTypes.TriggerLibException guardException = new TriggerTypes.TriggerLibException(
                    this.handlerName + ' performed DML in before update. Move that work to an after update Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }

            this.orchestrator.parentLoader.refreshNewParents(this.qualifiedRecords);
        }

        private void populate(TriggerTypes.TriggerRecord record) {
            if (!this.recursionTracker.isLimitReached(record) && this.populator.populateOnBeforeUpdateWhen(record)) {
                this.recursionTracker.countRun(record);
                this.qualifiedRecords.add(record);
                this.populator.populateOnBeforeUpdate(record);
            }
        }
    }

    public class ValidatorExecutor extends TriggerOrchestrator.HandlerExecutor {
        private BeforeUpdate.Validator validator;

        public ValidatorExecutor(BeforeUpdate.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);

            this.validator = validator;
            this.parentDeclaration = new BeforeUpdate.ParentDeclaration(this.validator);
            this.relatedLoader = new BeforeUpdate.RelatedLoader(this.validator);
            this.handlerHooks = new BeforeUpdate.HandlerHooks(this.validator);
        }

        public override void execute(List<TriggerTypes.TriggerRecord> records) {
            Integer dmlStatementsBefore = Limits.getDmlStatements();
            Integer immediateEventsBefore = Limits.getPublishImmediateDML();

            try {
                this.relatedLoader.attachTo(records);

                for (TriggerTypes.TriggerRecord record : records) {
                    this.validate(record);
                }

                this.handlerHooks.finalize(this.qualifiedRecords);
            } catch (Exception e) {
                this.handleException(e);
            }

            Integer dmlStatementsAfter = Limits.getDmlStatements();
            Integer immediateEventsAfter = Limits.getPublishImmediateDML();

            if (dmlStatementsAfter > dmlStatementsBefore || immediateEventsAfter > immediateEventsBefore) {
                TriggerTypes.TriggerLibException guardException = new TriggerTypes.TriggerLibException(
                    this.handlerName + ' performed DML in before update. Move that work to an after update Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }
        }

        private void validate(TriggerTypes.TriggerRecord record) {
            if (this.validator.addErrorOnBeforeUpdateWhen(record)) {
                this.qualifiedRecords.add(record);

                Integer errorsBefore = record.getNewSObject().getErrors().size();

                this.validator.addErrorOnBeforeUpdate(record);

                if (record.getNewSObject().getErrors().size() == errorsBefore) {
                    throw new TriggerTypes.TriggerLibException(
                        this.handlerName + ' qualified a record in addErrorOnBeforeUpdateWhen but attached no error in addErrorOnBeforeUpdate.'
                    );
                }
            }
        }
    }

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private BeforeUpdate.Handler handler;

        public ParentDeclaration(BeforeUpdate.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof BeforeUpdate.ParentQuery) {
                return ((BeforeUpdate.ParentQuery) this.handler).queryParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getOldParentFields() {
            if (this.handler instanceof BeforeUpdate.PriorParentQuery) {
                return ((BeforeUpdate.PriorParentQuery) this.handler).queryPriorParentsOnBeforeUpdate();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private BeforeUpdate.Handler handler;
        private Map<String, BeforeUpdate.RecordsProvider> providers;

        public RelatedLoader(BeforeUpdate.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof BeforeUpdate.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((BeforeUpdate.RelatedQuery) this.handler).queryRelatedOnBeforeUpdate() ?? new Map<String, BeforeUpdate.RecordsProvider>();
            }

            BeforeUpdate.RecordsProvider provider = this.providers.get(providerName);

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

    public class HandlerHooks extends TriggerOrchestrator.HandlerHooks {
        private BeforeUpdate.Handler handler;

        public HandlerHooks(BeforeUpdate.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof BeforeUpdate.Bypassable && ((BeforeUpdate.Bypassable) this.handler).bypassOnBeforeUpdateWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof BeforeUpdate.Finalizer)) {
                return;
            }

            ((BeforeUpdate.Finalizer) this.handler).finalizeOnBeforeUpdate(new TriggerTypes.UpdateTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeUpdate.ContinueOnError;
        }
    }

    public class RecursionTracker extends TriggerOrchestrator.RecursionTracker {
        public RecursionTracker(BeforeUpdate.Handler handler, String handlerName) {
            super(handlerName + ':BEFORE_UPDATE');

            if (handler instanceof BeforeUpdate.RecursionGuard) {
                this.maxRunsPerRecord = ((BeforeUpdate.RecursionGuard) handler).maxRunsPerRecordOnBeforeUpdate();
            }
        }
    }

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.BeforeUpdateMockable, TriggerOrchestrator.BeforeUpdate {
        public MockedContext() {
            super(System.TriggerOperation.BEFORE_UPDATE);
        }

        public TriggerOrchestrator.BeforeUpdateMockable with(SObject newRow, SObject oldRow) {
            return this.with(new List<SObject>{ newRow }, new List<SObject>{ oldRow });
        }

        public TriggerOrchestrator.BeforeUpdateMockable with(List<SObject> newRows, List<SObject> oldRows) {
            this.shareIds(newRows, oldRows);
            this.newRecords.addAll(newRows);
            this.oldRecords.addAll(oldRows);
            return this;
        }

        public TriggerOrchestrator.BeforeUpdateMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.BeforeUpdateMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            if (this.handlerOrOrchestrator instanceof TriggerOrchestrator.BeforeUpdate) {
                return ((TriggerOrchestrator.BeforeUpdate) this.handlerOrOrchestrator).beforeUpdateHandlers();
            }

            return new List<BeforeUpdate.Handler>{ (BeforeUpdate.Handler) this.handlerOrOrchestrator };
        }
    }
}
