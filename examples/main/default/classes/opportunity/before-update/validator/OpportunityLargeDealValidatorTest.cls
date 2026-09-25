@IsTest(IsParallel=true testFor='ApexClass:OpportunityLargeDealValidator')
private class OpportunityLargeDealValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithoutNextStep() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review', Amount = 150000);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityLargeDealValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 150000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityLargeDealValidator());

        // Verify
        Assert.areEqual(
            'Open Opportunities above 100,000 must have a Next Step. Document the agreed action with the customer.',
            renewal.getErrors()[0].getMessage(),
            'A large deal without a next step should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithNextStep() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review', Amount = 150000, NextStep = 'Send the contract');

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityLargeDealValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 150000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityLargeDealValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'A large deal with a next step should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithAmountAtThreshold() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review', Amount = 100000);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityLargeDealValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 100000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityLargeDealValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'A deal of exactly 100,000 should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithWonOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', Amount = 150000);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityLargeDealValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 150000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityLargeDealValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'A won large deal should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithLostOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Lost', Amount = 150000);

        TriggerOrchestrator.mock().beforeUpdateFor(OpportunityLargeDealValidator.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review', Amount = 150000));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityLargeDealValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'A lost large deal should be accepted.');
    }
}
