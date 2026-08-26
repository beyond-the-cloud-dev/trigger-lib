trigger ProbeEventTrigger on Event(before insert) {
    TriggerOrchestrator.run(new TriggerStackProbe.EventOrchestrator());
}
