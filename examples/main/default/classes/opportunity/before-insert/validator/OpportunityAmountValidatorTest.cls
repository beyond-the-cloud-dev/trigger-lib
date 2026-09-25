@IsTest(IsParallel=true testFor='ApexClass:OpportunityAmountValidator')
private class OpportunityAmountValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithNegativeAmount() {
        // Setup
        Opportunity renewal = new Opportunity(Amount = -100);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityAmountValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityAmountValidator());

        // Verify
        Assert.areEqual(
            'Amount must be greater than zero. Leave it empty until the deal value is known.',
            renewal.getErrors()[0].getMessage(),
            'A negative amount should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeInsertWithZeroAmount() {
        // Setup
        Opportunity renewal = new Opportunity(Amount = 0);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityAmountValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityAmountValidator());

        // Verify
        Assert.areEqual(
            'Amount must be greater than zero. Leave it empty until the deal value is known.',
            renewal.getErrors()[0].getMessage(),
            'A zero amount should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeInsertWithPositiveAmount() {
        // Setup
        Opportunity renewal = new Opportunity(Amount = 0.01);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityAmountValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityAmountValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'A positive amount should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithoutAmount() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal');

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityAmountValidator.class).with(renewal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityAmountValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'An empty amount should be accepted.');
    }
}
