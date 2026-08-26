trigger ProbeTaskTrigger on Task(after insert) {
    TriggerOrchestrator.run(new TriggerStackProbe.TaskOrchestrator());
}
