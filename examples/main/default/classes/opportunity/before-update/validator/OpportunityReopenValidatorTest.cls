@IsTest(IsParallel=true testFor='ApexClass:OpportunityReopenValidator')
private class OpportunityReopenValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithReopenedDeal() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityReopenValidator.class).with(renewal, new Opportunity(StageName = 'Closed Won'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityReopenValidator());

        // Verify
        Assert.areEqual(
            'A Closed Won Opportunity cannot be moved back to Negotiation/Review. Raise a new Opportunity for the follow-up business.',
            renewal.getErrors()[0].getMessage(),
            'Reopening a won deal should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithWonDeal() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', Description = 'Signed by the CFO.');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityReopenValidator.class).with(renewal, new Opportunity(StageName = 'Closed Won'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityReopenValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Editing a won deal should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithReopenedLostDeal() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Prospecting');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityReopenValidator.class).with(renewal, new Opportunity(StageName = 'Closed Lost'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityReopenValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Reopening a lost deal should be accepted.');
    }

    @IsTest
    static void bypassOnBeforeUpdateWhenBypassed() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review');

        OpportunityReopenValidator.isBypassed = true;

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityReopenValidator.class).with(renewal, new Opportunity(StageName = 'Closed Won'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityReopenValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Reopening a won deal should be accepted when bypassed.');
    }
}
