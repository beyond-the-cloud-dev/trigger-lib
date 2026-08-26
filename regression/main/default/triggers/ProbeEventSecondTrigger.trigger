trigger ProbeEventSecondTrigger on Event(before insert) {
    TriggerOrchestrator.run(new TriggerStackProbe.EventSecondOrchestrator());
}
