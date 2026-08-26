trigger ProbeCampaignSecondTrigger on Campaign(after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.CampaignSecondOrchestrator());
    TriggerOrchestrator.run(new TriggerStackProbe.CampaignThirdOrchestrator());
}
