@IsTest(IsParallel=true)
private class OpportunityCloseDatePopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithoutCloseDate() {
        // Setup
        Date endOfQuarter = Date.today().toStartOfMonth().addMonths(3 - Math.mod(Date.today().month() - 1, 3)).addDays(-1);
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal');

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityCloseDatePopulator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityCloseDatePopulator());

        // Verify
        Assert.areEqual(endOfQuarter, renewal.CloseDate, 'The close date should default to the end of the quarter.');
    }

    @IsTest
    static void populateOnBeforeInsertWithCloseDate() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal', CloseDate = Date.newInstance(2030, 1, 15));

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityCloseDatePopulator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityCloseDatePopulator());

        // Verify
        Assert.areEqual(Date.newInstance(2030, 1, 15), renewal.CloseDate, 'The close date should be kept.');
    }
}
