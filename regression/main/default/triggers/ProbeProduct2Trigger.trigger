trigger ProbeProduct2Trigger on Product2(after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.ProductOrchestrator());
}
