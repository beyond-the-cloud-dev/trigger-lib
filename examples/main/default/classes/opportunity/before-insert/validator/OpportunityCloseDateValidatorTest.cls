@IsTest(IsParallel=true)
private class OpportunityCloseDateValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithPastCloseDate() {
        // Setup
        Date yesterday = Date.today().addDays(-1);
        Opportunity renewal = new Opportunity(CloseDate = yesterday);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityCloseDateValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityCloseDateValidator());

        // Verify
        Assert.areEqual(
            'Close Date ' + yesterday.format() + ' is in the past. Pick today or a later date.',
            renewal.getErrors()[0].getMessage(),
            'A past close date should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeInsertWithTodayCloseDate() {
        // Setup
        Opportunity renewal = new Opportunity(CloseDate = Date.today());

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityCloseDateValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityCloseDateValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Today as the close date should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithoutCloseDate() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal');

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityCloseDateValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityCloseDateValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'An empty close date should be accepted.');
    }
}
