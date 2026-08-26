trigger ProbeOpportunityTrigger on Opportunity(before update, after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.OpportunityOrchestrator());
}
