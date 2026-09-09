public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert, TriggerOrchestrator.AfterUpdate {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{
            new ContactTriggerHandler()
        };
    }

    public List<AfterInsert.Handler> afterInsertHandlers() {
        return new List<AfterInsert.Handler>();
    }

    public List<AfterUpdate.Handler> afterUpdateHandlers() {
        return new List<AfterUpdate.Handler>{
            new ContactEnrichmentHandler()
        };
    }
}
