@IsTest(IsParallel=true)
private class OpportunityWinAmountValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithoutAmount() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityWinAmountValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinAmountValidator());

        // Verify
        Assert.areEqual(
            'Set a positive Amount before moving this Opportunity to Closed Won.',
            renewal.getErrors()[0].getMessage(),
            'Winning a deal without an amount should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithZeroAmount() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', Amount = 0);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityWinAmountValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 0));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinAmountValidator());

        // Verify
        Assert.areEqual(
            'Set a positive Amount before moving this Opportunity to Closed Won.',
            renewal.getErrors()[0].getMessage(),
            'Winning a deal with a zero amount should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithPositiveAmount() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', Amount = 0.01);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityWinAmountValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 0.01));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinAmountValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Winning a deal with a positive amount should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithAlreadyWonDeal() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityWinAmountValidator.class).with(renewal, new Opportunity(StageName = 'Closed Won'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinAmountValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Editing an already won deal should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithOpenDeal() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Qualification');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityWinAmountValidator.class).with(renewal, new Opportunity(StageName = 'Prospecting'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinAmountValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Moving an open deal without an amount should be accepted.');
    }
}
