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

    public interface BeforeUndelete {
        List<TriggerHandler.BeforeUndelete> beforeUndeleteHandlers();
    }

    public interface AfterUndelete {
        List<TriggerHandler.AfterUndelete> afterUndeleteHandlers();
    }

    // TODO Additional interface for master condition eg. RT = A so each team can have their own orchestators

    // Implementations

    public static void run(Object orchestrator) {
        // TODO Maybe Adapter to a common interface if possible
        switch on System.Trigger.operationType {
            when BEFORE_INSERT {
                runBeforeInsert(orchestrator);
            }
            when AFTER_INSERT {
                runAfterInsert(orchestrator);
            }
            when BEFORE_UPDATE {
                runBeforeUpdate(orchestrator);
            }
            when AFTER_UPDATE {
                runAfterUpdate(orchestrator);
            }
            when BEFORE_DELETE {
                runBeforeDelete(orchestrator);
            }
            when AFTER_DELETE {
                runAfterDelete(orchestrator);
            }
            when AFTER_UNDELETE {
                runAfterUndelete(orchestrator);
            }
            when else {
                // throw new TODO Called outside of trigger context, or not supported operation type
            }
        }
    }

    private static void runBeforeInsert(Object orchestrator) {
        if (!(orchestrator instanceof TriggerOrchestrator.BeforeInsert)) {
            return;
        }

        TriggerOrchestrator.BeforeInsert beforeInsertOrchestrator = (TriggerOrchestrator.BeforeInsert) orchestrator;

        for (TriggerHandler.BeforeInsert handler : beforeInsertOrchestrator.beforeInsertHandlers()) {
            for (SObject record : Trigger.new) {
                if (handler.qualifiesForBeforeInsertWhen(new TriggerHandler.RecordImpl(record))) {
                    handler.onBeforeInsert(record);
                }
            }
        }
    }

    private static void runAfterInsert(Object orchestrator) {
        if (!(orchestrator instanceof TriggerOrchestrator.AfterInsert)) {
            return;
        }

        TriggerOrchestrator.AfterInsert afterInsertOrchestrator = (TriggerOrchestrator.AfterInsert) orchestrator;

        for (TriggerHandler.AfterInsert handler : afterInsertOrchestrator.afterInsertHandlers()) {
            for (SObject record : Trigger.new) {
                if (handler.qualifiesForAfterInsertWhen(new TriggerHandler.RecordImpl(record))) {
                    handler.onAfterInsert(record);
                }
            }
        }
    }

    private static void runBeforeUpdate(Object orchestrator) { 
        if (!(orchestrator instanceof TriggerOrchestrator.BeforeUpdate)) {
            return;
        }

        TriggerOrchestrator.BeforeUpdate beforeUpdateOrchestrator = (TriggerOrchestrator.BeforeUpdate) orchestrator;

        for (TriggerHandler.BeforeUpdate handler : beforeUpdateOrchestrator.beforeUpdateHandlers()) {
            for (Integer i = 0; i < Trigger.new.size(); i++) {
                SObject newRecord = Trigger.new[i];
                SObject oldRecord = Trigger.old[i];

                if (handler.qualifiesForBeforeUpdateWhen(new TriggerHandler.RecordImpl(newRecord, oldRecord))) {
                    handler.onBeforeUpdate(newRecord, oldRecord);
                }
            }
        }   
    }

    private static void runAfterUpdate(Object orchestrator) { 
        if (!(orchestrator instanceof TriggerOrchestrator.AfterUpdate)) {
            return;
        }

        TriggerOrchestrator.AfterUpdate afterUpdateOrchestrator = (TriggerOrchestrator.AfterUpdate) orchestrator;

        for (TriggerHandler.AfterUpdate handler : afterUpdateOrchestrator.afterUpdateHandlers()) {
            for (Integer i = 0; i < Trigger.new.size(); i++) {
                SObject newRecord = Trigger.new[i];
                SObject oldRecord = Trigger.old[i];

                if (handler.qualifiesForAfterUpdateWhen(new TriggerHandler.RecordImpl(newRecord, oldRecord))) {
                    handler.onAfterUpdate(newRecord, oldRecord);
                }
            }
        }   
    }

    private static void runBeforeDelete(Object orchestrator) {
        if (!(orchestrator instanceof TriggerOrchestrator.BeforeDelete)) {
            return;
        }

        TriggerOrchestrator.BeforeDelete beforeDeleteOrchestrator = (TriggerOrchestrator.BeforeDelete) orchestrator;

        for (TriggerHandler.BeforeDelete handler : beforeDeleteOrchestrator.beforeDeleteHandlers()) {
            for (SObject record : Trigger.old) {
                if (handler.qualifiesForBeforeDeleteWhen(new TriggerHandler.RecordImpl(record))) {
                    handler.onBeforeDelete(record);
                }
            }
        }
    }

    private static void runAfterDelete(Object orchestrator) {
        if (!(orchestrator instanceof TriggerOrchestrator.AfterDelete)) {
            return;
        }

        TriggerOrchestrator.AfterDelete afterDeleteOrchestrator = (TriggerOrchestrator.AfterDelete) orchestrator;

        for (TriggerHandler.AfterDelete handler : afterDeleteOrchestrator.afterDeleteHandlers()) {
            for (SObject record : Trigger.old) {
                if (handler.qualifiesForAfterDeleteWhen(new TriggerHandler.RecordImpl(record))) {
                    handler.onAfterDelete(record);
                }
            }
        }
    }

    private static void runAfterUndelete(Object orchestrator) {
        if (!(orchestrator instanceof TriggerOrchestrator.AfterUndelete)) {
            return;
        }

        TriggerOrchestrator.AfterUndelete afterUndeleteOrchestrator = (TriggerOrchestrator.AfterUndelete) orchestrator;

        for (TriggerHandler.AfterUndelete handler : afterUndeleteOrchestrator.afterUndeleteHandlers()) {
            for (SObject record : Trigger.new) {
                if (handler.qualifiesForAfterUndeleteWhen(new TriggerHandler.RecordImpl(record))) {
                    handler.onAfterUndelete(record);
                }
            }
        }
    }
}
