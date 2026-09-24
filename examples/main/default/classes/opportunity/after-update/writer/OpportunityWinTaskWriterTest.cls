@IsTest(IsParallel=true)
private class OpportunityWinTaskWriterTest {
    @IsTest
    static void writeOnAfterUpdateWithWonOpportunity() {
        // Setup
        User jane = new User(Id = new TriggerTypes.RandomIdGenerator().get(User.SObjectType));
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal', StageName = 'Closed Won', AccountId = acme.Id, OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(OpportunityWinTaskWriter.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review'))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinTaskWriter());

        // Verify
        Task onboarding = (Task) DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0];

        Assert.areEqual(
            new Task(
                Id = onboarding.Id,
                WhatId = renewal.Id,
                OwnerId = jane.Id,
                Subject = 'Onboarding kick-off: Acme',
                Description = 'Won on ' + Date.today().format() + '. Agree the implementation plan with the customer.',
                ActivityDate = Date.today().addDays(7),
                Priority = 'High',
                Status = 'Not Started'
            ),
            onboarding,
            'The onboarding task should be created.'
        );
    }

    @IsTest
    static void writeOnAfterUpdateWithoutAccount() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal', StageName = 'Closed Won');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(OpportunityWinTaskWriter.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinTaskWriter());

        // Verify
        Assert.areEqual(
            'Onboarding kick-off: Acme Renewal',
            DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject),
            'The subject should fall back to the opportunity name.'
        );
    }

    @IsTest
    static void writeOnAfterUpdateWithAlreadyWonOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal', StageName = 'Closed Won');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(OpportunityWinTaskWriter.class).with(renewal, new Opportunity(StageName = 'Closed Won'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinTaskWriter());

        // Verify
        Assert.isTrue(DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records().isEmpty(), 'No task should be created.');
    }

    @IsTest
    static void writeOnAfterUpdateWithOpenOpportunity() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal', StageName = 'Negotiation/Review');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(OpportunityWinTaskWriter.class).with(renewal, new Opportunity(StageName = 'Proposal/Price Quote'));

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityWinTaskWriter());

        // Verify
        Assert.isTrue(DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records().isEmpty(), 'No task should be created.');
    }

    @IsTest
    static void writeOnAfterUpdateWithFailingTaskInsert() {
        // Setup
        Opportunity renewal = new Opportunity(Name = 'Acme Renewal', StageName = 'Closed Won');

        DML.mock('triggerUow').exceptionOnInserts();

        TriggerOrchestrator.mock().afterUpdateFor(OpportunityWinTaskWriter.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new OpportunityWinTaskWriter());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isNull(expectedException, 'A failed task insert should not block the update.');
    }
}
