public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert, TriggerOrchestrator.AfterUpdate {
    public List<TriggerHandler.BeforeInsert> beforeInsertHandlers() {
        return new List<TriggerHandler.BeforeInsert>{
            new ContactTriggerHandler()
        };
    }

    public List<TriggerHandler.AfterInsert> afterInsertHandlers() {
        return new List<TriggerHandler.AfterInsert>();
    }

    public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
        return new List<TriggerHandler.AfterUpdate>{
            new ContactEnrichmentHandler()
        };
    }
}
