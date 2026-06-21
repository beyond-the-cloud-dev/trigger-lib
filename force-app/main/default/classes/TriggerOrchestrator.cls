public with sharing class TriggerOrchestrator {
    // TODO Maybe each interface should return more complex builder, not only list of handlers
    // that builder could set required permissions, bypass permission, etc, but maybe it should be on handler level? 

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

    // Implementations

    public static void run(Object orchestrator) {
        // if (orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
        //     TriggerOrchestrator.BeforeInsert beforeInsertOrchestrator = (TriggerOrchestrator.BeforeInsert) orchestrator;
        //     beforeInsertOrchestrator.beforeInsertHandlers();
        // }
        // if (orchestrator instanceof TriggerOrchestrator.AfterInsert) {
        //     TriggerOrchestrator.AfterInsert afterInsertOrchestrator = (TriggerOrchestrator.AfterInsert) orchestrator;
        //     afterInsertOrchestrator.afterInsertHandlers();
        // }
        // TODO Adapter to a common interface
        switch on System.Trigger.operationType {
            when BEFORE_INSERT {
                // if (orchestrator instanceof TriggerOrchestrator.BeforeInsert) {
                // logic for before insert
            }
            when BEFORE_UPDATE {
                // logic for before update
            }
            when AFTER_INSERT {
                // logic for after insert
            }
            when AFTER_UPDATE {
                // logic for after update
            }
            when BEFORE_DELETE {
                // logic for before delete
            }
            when AFTER_DELETE {
                // logic for after delete
            }
            when AFTER_UNDELETE {
                // logic for after undelete
            }
        }
    }
}
