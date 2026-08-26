trigger ProbeLeadTrigger on Lead(after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.LeadOrchestrator());
}
