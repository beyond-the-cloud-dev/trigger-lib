trigger ProbeAssetTrigger on Asset(after update) {
    TriggerOrchestrator.run(new TriggerStackProbe.AssetOrchestrator());
}
