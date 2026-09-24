@IsTest(IsParallel=true)
private class AccountWelcomeTaskWriterTest {
    @IsTest
    static void writeOnAfterInsertWithCustomer() {
        // Setup
        Id janeId = SOQL.IdGenerator.get(User.SObjectType);
        User jane = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + janeId + '","Name":"Jane Smith","Email":"jane.smith@acme.com"}', User.class);
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWelcomeTaskWriter.class).with(acme).withParent(Account.OwnerId, jane);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountWelcomeTaskWriter());

        // Verify
        Task onboardingCall = (Task) DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0];

        Assert.areEqual(
            new Task(
                Id = onboardingCall.Id,
                WhatId = acme.Id,
                OwnerId = jane.Id,
                Subject = 'Onboarding call - Acme',
                Description = 'New customer assigned to Jane Smith (jane.smith@acme.com). Confirm the billing address and the primary contact.',
                ActivityDate = Date.today().addDays(3),
                Priority = 'High',
                Status = 'Not Started'
            ),
            onboardingCall,
            'The onboarding call should be created.'
        );
    }

    @IsTest
    static void writeOnAfterInsertWithProspect() {
        // Setup
        Id janeId = SOQL.IdGenerator.get(User.SObjectType);
        User jane = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + janeId + '","Name":"Jane Smith","Email":"jane.smith@acme.com"}', User.class);
        Account acme = new Account(Name = 'Acme', Type = 'Prospect', OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWelcomeTaskWriter.class).with(acme).withParent(Account.OwnerId, jane);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountWelcomeTaskWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records().size(), 'No onboarding call should be created.');
    }

    @IsTest
    static void writeOnAfterInsertWithoutOwner() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', OwnerId = SOQL.IdGenerator.get(User.SObjectType));

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWelcomeTaskWriter.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountWelcomeTaskWriter());

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records().size(), 'The onboarding call should be created without the owner.');
    }
}
