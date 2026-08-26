trigger ProbeCaseTrigger on Case(after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.CaseOrchestrator());
}
