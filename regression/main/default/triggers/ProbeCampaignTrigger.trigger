trigger ProbeCampaignTrigger on Campaign(after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.CampaignOrchestrator());
}
