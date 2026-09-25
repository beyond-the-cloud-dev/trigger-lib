@IsTest(IsParallel=true testFor='ApexClass:AccountOwnerTransferWriter')
private class AccountOwnerTransferWriterTest {
    @IsTest
    static void writeOnAfterUpdateWithoutOpenOpportunities() {
        // Setup
        Id janeId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType);
        Id johnId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType);
        User jane = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + janeId + '","Name":"Jane Smith"}', User.class);
        User john = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + johnId + '","Name":"John Doe"}', User.class);
        Account acme = new Account(Name = 'Acme', OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(AccountOwnerTransferWriter.class)
            .with(acme, new Account(Name = 'Acme', OwnerId = john.Id))
            .withParent(Account.OwnerId, new List<User>{ jane, john });

        // Test
        TriggerOrchestrator.runTestFor(new AccountOwnerTransferWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Opportunity.SObjectType).records().size(), 'No opportunity should be updated.');
    }

    @IsTest
    static void writeOnAfterUpdateWithUnchangedOwner() {
        // Setup
        Id janeId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType);
        User jane = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + janeId + '","Name":"Jane Smith"}', User.class);
        Account acme = new Account(Name = 'Acme Corp', OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(AccountOwnerTransferWriter.class).with(acme, new Account(Name = 'Acme', OwnerId = jane.Id)).withParent(Account.OwnerId, jane);

        // Test
        TriggerOrchestrator.runTestFor(new AccountOwnerTransferWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Opportunity.SObjectType).records().size(), 'No opportunity should be updated.');
    }

    @IsTest
    static void bypassOnAfterUpdateWhenBypassed() {
        // Setup
        Account acme = new Account(Name = 'Acme', OwnerId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType));

        AccountOwnerTransferWriter.isBypassed = true;

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(AccountOwnerTransferWriter.class)
            .with(acme, new Account(Name = 'Acme', OwnerId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType)));

        // Test
        Test.startTest();
        TriggerOrchestrator.runTestFor(new AccountOwnerTransferWriter());

        // Verify
        Assert.areEqual(0, Limits.getQueries(), 'The bypassed handler should not query.');
    }
}
