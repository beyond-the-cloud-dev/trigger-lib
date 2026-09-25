@IsTest(IsParallel=true testFor='ApexClass:OpportunityForecastPopulator')
private class OpportunityForecastPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithSmallAmount() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Prospecting', Amount = 4999, ForecastCategoryName = 'Pipeline');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Amount = 10000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

        // Verify
        Assert.areEqual('Omitted', renewal.ForecastCategoryName, 'The forecast category should be omitted.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithStageChange() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Qualification', Amount = 1000, ForecastCategoryName = 'Pipeline');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Amount = 1000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

        // Verify
        Assert.areEqual('Omitted', renewal.ForecastCategoryName, 'The forecast category should be omitted.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithAmountAtThreshold() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Prospecting', Amount = 5000, ForecastCategoryName = 'Pipeline');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Amount = 10000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

        // Verify
        Assert.areEqual('Pipeline', renewal.ForecastCategoryName, 'The forecast category should be kept.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithWonOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', Amount = 1000, ForecastCategoryName = 'Closed');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 1000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

        // Verify
        Assert.areEqual('Closed', renewal.ForecastCategoryName, 'The forecast category should be kept.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedAmountAndStage() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Prospecting', Amount = 1000, ForecastCategoryName = 'Pipeline');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Amount = 1000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

        // Verify
        Assert.areEqual('Pipeline', renewal.ForecastCategoryName, 'The forecast category should be kept.');
    }
}
