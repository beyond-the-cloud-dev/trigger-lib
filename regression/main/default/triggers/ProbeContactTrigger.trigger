trigger ProbeContactTrigger on Contact(before update, after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.ContactOrchestrator());
}
