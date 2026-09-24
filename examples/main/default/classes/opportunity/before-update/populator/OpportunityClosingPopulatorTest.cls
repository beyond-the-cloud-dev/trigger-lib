@IsTest(IsParallel=true)
private class OpportunityClosingPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithWonOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityClosingPopulator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.areEqual(
            'Closed Won by ' + UserInfo.getName() + ' on ' + Date.today().format() + ' (previous stage: Negotiation/Review)',
            renewal.Description,
            'The closing note should be added.'
        );
    }

    @IsTest
    static void populateOnBeforeUpdateWithLostOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Lost');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityClosingPopulator.class).with(renewal, new Opportunity(StageName = 'Proposal/Price Quote'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.areEqual(
            'Closed Lost by ' + UserInfo.getName() + ' on ' + Date.today().format() + ' (previous stage: Proposal/Price Quote)',
            renewal.Description,
            'The closing note should be added.'
        );
    }

    @IsTest
    static void populateOnBeforeUpdateWithDescription() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', Description = 'Strategic account.');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityClosingPopulator.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review', Description = 'Strategic account.'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.areEqual(
            'Strategic account.\nClosed Won by ' + UserInfo.getName() + ' on ' + Date.today().format() + ' (previous stage: Negotiation/Review)',
            renewal.Description,
            'The closing note should be appended to the description.'
        );
    }

    @IsTest
    static void populateOnBeforeUpdateWithNextStep() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', NextStep = 'Send the contract');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityClosingPopulator.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review', NextStep = 'Send the contract'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.isNull(renewal.NextStep, 'The next step should be cleared.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithOpenStage() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Qualification', NextStep = 'Book a demo');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityClosingPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', NextStep = 'Book a demo'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.areEqual('Book a demo', renewal.NextStep, 'The next step should be kept.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedStage() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', NextStep = 'Send the invoice');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityClosingPopulator.class).with(renewal, new Opportunity(StageName = 'Closed Won'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.areEqual('Send the invoice', renewal.NextStep, 'The next step should be kept.');
    }

    @IsTest
    static void maxRunsPerRecordOnBeforeUpdateWithRepeatedUpdate() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityClosingPopulator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());
        TriggerOrchestrator.runTestFor(new OpportunityClosingPopulator());

        // Verify
        Assert.areEqual(
            'Closed Won by ' + UserInfo.getName() + ' on ' + Date.today().format() + ' (previous stage: Negotiation/Review)',
            renewal.Description,
            'The closing note should be added once.'
        );
    }
}
