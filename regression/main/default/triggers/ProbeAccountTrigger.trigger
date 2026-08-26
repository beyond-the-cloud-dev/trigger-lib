trigger ProbeAccountTrigger on Account(before update, after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.AccountOrchestrator());
}
