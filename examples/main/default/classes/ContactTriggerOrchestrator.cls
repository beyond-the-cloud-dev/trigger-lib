public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert {
    public List<TriggerHandler.BeforeInsert> beforeInsertHandlers() {
        return new List<TriggerHandler.BeforeInsert>();
    }

    public List<TriggerHandler.AfterInsert> afterInsertHandlers() {
        return new List<TriggerHandler.AfterInsert>();
    }
}
