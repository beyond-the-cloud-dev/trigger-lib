global class BeforeInsert {
    // Roles - pick one

    global interface Populator extends Handler {
        Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record);
        void populateOnBeforeInsert(TriggerTypes.InsertRecord record);
    }

    global interface Validator extends Handler {
        Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record);
        void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record);
    }

    // Add-ons - pick as many as you need

    global interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert();
    }

    global interface RelatedQuery {
        Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert();
    }

    global interface RecordsProvider {
        List<SObject> query(TriggerTypes.InsertRecords records);
        String keyOf(SObject row);
    }

    global interface Bypassable {
        Boolean bypassOnBeforeInsertWhen();
    }

    global interface Finalizer {
        void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records);
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

            for (BeforeInsert.Handler handler : ((TriggerOrchestrator.BeforeInsert) orchestrator.orchestrator).beforeInsertHandlers()) {
                if (handler instanceof BeforeInsert.Populator) {
                    executors.add(new BeforeInsert.PopulatorExecutor((BeforeInsert.Populator) handler, orchestrator));
                } else if (handler instanceof BeforeInsert.Validator) {
                    executors.add(new BeforeInsert.ValidatorExecutor((BeforeInsert.Validator) handler, orchestrator));
                }
            }

            return executors;
        }
    }

    public class PopulatorExecutor extends TriggerOrchestrator.HandlerExecutor {
        private BeforeInsert.Populator populator;

        public PopulatorExecutor(BeforeInsert.Populator populator, TriggerOrchestrator orchestrator) {
            super(populator, orchestrator);

            this.populator = populator;
            this.parentDeclaration = new BeforeInsert.ParentDeclaration(this.populator);
            this.relatedLoader = new BeforeInsert.RelatedLoader(this.populator);
            this.handlerHooks = new BeforeInsert.HandlerHooks(this.populator);
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
                    this.handlerName + ' performed DML in before insert. Move that work to an after insert Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }

            this.orchestrator.parentLoader.refreshNewParents(this.qualifiedRecords);
        }

        private void populate(TriggerTypes.TriggerRecord record) {
            if (this.populator.populateOnBeforeInsertWhen(record)) {
                this.qualifiedRecords.add(record);
                this.populator.populateOnBeforeInsert(record);
            }
        }
    }

    public class ValidatorExecutor extends TriggerOrchestrator.HandlerExecutor {
        private BeforeInsert.Validator validator;

        public ValidatorExecutor(BeforeInsert.Validator validator, TriggerOrchestrator orchestrator) {
            super(validator, orchestrator);

            this.validator = validator;
            this.parentDeclaration = new BeforeInsert.ParentDeclaration(this.validator);
            this.relatedLoader = new BeforeInsert.RelatedLoader(this.validator);
            this.handlerHooks = new BeforeInsert.HandlerHooks(this.validator);
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
                    this.handlerName + ' performed DML in before insert. Move that work to an after insert Writer.'
                );

                this.logError(guardException);

                throw guardException;
            }
        }

        private void validate(TriggerTypes.TriggerRecord record) {
            if (this.validator.addErrorOnBeforeInsertWhen(record)) {
                this.qualifiedRecords.add(record);

                Integer errorsBefore = record.getNewSObject().getErrors().size();

                this.validator.addErrorOnBeforeInsert(record);

                if (record.getNewSObject().getErrors().size() == errorsBefore) {
                    throw new TriggerTypes.TriggerLibException(
                        this.handlerName + ' qualified a record in addErrorOnBeforeInsertWhen but attached no error in addErrorOnBeforeInsert.'
                    );
                }
            }
        }
    }

    public class ParentDeclaration extends TriggerOrchestrator.ParentDeclaration {
        private BeforeInsert.Handler handler;

        public ParentDeclaration(BeforeInsert.Handler handler) {
            this.handler = handler;
        }

        public override Map<SObjectField, TriggerTypes.ParentFields> getNewParentFields() {
            if (this.handler instanceof BeforeInsert.ParentQuery) {
                return ((BeforeInsert.ParentQuery) this.handler).queryParentsOnBeforeInsert();
            }

            return new Map<SObjectField, TriggerTypes.ParentFields>();
        }
    }

    public class RelatedLoader extends TriggerOrchestrator.RelatedLoader {
        private BeforeInsert.Handler handler;
        private Map<String, BeforeInsert.RecordsProvider> providers;

        public RelatedLoader(BeforeInsert.Handler handler) {
            this.handler = handler;
        }

        public override TriggerTypes.RelatedRecords queryRelated(String providerName) {
            if (!(this.handler instanceof BeforeInsert.RelatedQuery)) {
                return null;
            }

            if (this.providers == null) {
                this.providers = ((BeforeInsert.RelatedQuery) this.handler).queryRelatedOnBeforeInsert() ?? new Map<String, BeforeInsert.RecordsProvider>();
            }

            BeforeInsert.RecordsProvider provider = this.providers.get(providerName);

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

    public class HandlerHooks extends TriggerOrchestrator.HandlerHooks {
        private BeforeInsert.Handler handler;

        public HandlerHooks(BeforeInsert.Handler handler) {
            this.handler = handler;
        }

        public override Boolean isBypassedByAddOn() {
            return (this.handler instanceof BeforeInsert.Bypassable && ((BeforeInsert.Bypassable) this.handler).bypassOnBeforeInsertWhen());
        }

        public override void finalize(List<TriggerTypes.TriggerRecord> qualifiedRecords) {
            if (qualifiedRecords.isEmpty() || !(this.handler instanceof BeforeInsert.Finalizer)) {
                return;
            }

            ((BeforeInsert.Finalizer) this.handler).finalizeOnBeforeInsert(new TriggerTypes.InsertTriggerRecords(qualifiedRecords));
        }

        public override Boolean continuesOnError() {
            return this.handler instanceof BeforeInsert.ContinueOnError;
        }
    }

    public class MockedContext extends TriggerOrchestrator.MockedContext implements TriggerOrchestrator.BeforeInsertMockable, TriggerOrchestrator.BeforeInsert {
        public MockedContext() {
            super(System.TriggerOperation.BEFORE_INSERT);
        }

        public TriggerOrchestrator.BeforeInsertMockable with(SObject row) {
            return this.with(new List<SObject>{ row });
        }

        public TriggerOrchestrator.BeforeInsertMockable with(List<SObject> rows) {
            this.newRecords.addAll(rows);
            return this;
        }

        public TriggerOrchestrator.BeforeInsertMockable withParent(SObjectField lookupField, SObject parent) {
            return this.withParent(lookupField, new List<SObject>{ parent });
        }

        public TriggerOrchestrator.BeforeInsertMockable withParent(SObjectField lookupField, List<SObject> parents) {
            this.addParents(lookupField, parents);
            return this;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            if (this.handlerOrOrchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                return ((TriggerOrchestrator.BeforeInsert) this.handlerOrOrchestrator).beforeInsertHandlers();
            }

            return new List<BeforeInsert.Handler>{ (BeforeInsert.Handler) this.handlerOrOrchestrator };
        }
    }
}
