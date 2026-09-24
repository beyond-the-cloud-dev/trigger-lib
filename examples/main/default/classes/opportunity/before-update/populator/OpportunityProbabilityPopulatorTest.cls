@IsTest(IsParallel=true)
private class OpportunityProbabilityPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithStageChange() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Proposal/Price Quote', Probability = 10);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityProbabilityPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Probability = 10));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityProbabilityPopulator());

        // Verify
        Assert.areEqual(75, renewal.Probability, 'The probability should follow the stage.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithLostOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Lost', Probability = 90);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityProbabilityPopulator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Probability = 90));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityProbabilityPopulator());

        // Verify
        Assert.areEqual(0, renewal.Probability, 'The probability should drop to zero.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedStage() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review', Probability = 85);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityProbabilityPopulator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Probability = 90));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityProbabilityPopulator());

        // Verify
        Assert.areEqual(85, renewal.Probability, 'The probability should be kept.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnknownStage() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Contract Signed', Probability = 95);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityProbabilityPopulator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Probability = 90));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityProbabilityPopulator());

        // Verify
        Assert.areEqual(95, renewal.Probability, 'The probability should be kept.');
    }
}
