@IsTest(IsParallel=true)
private class AccountOwnerTransferWriterTest {
    @IsTest
    static void writeOnAfterUpdateWithoutOpenOpportunities() {
        // Setup
        Id janeId = SOQL.IdGenerator.get(User.SObjectType);
        Id johnId = SOQL.IdGenerator.get(User.SObjectType);
        User jane = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + janeId + '","Name":"Jane Smith"}', User.class);
        User john = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + johnId + '","Name":"John Doe"}', User.class);
        Account acme = new Account(Name = 'Acme', OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(AccountOwnerTransferWriter.class)
            .with(acme, new Account(Name = 'Acme', OwnerId = john.Id))
            .withParent(Account.OwnerId, new List<User>{ jane, john });

        // Test
        TriggerOrchestrator.executeTestFor(new AccountOwnerTransferWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Opportunity.SObjectType).records().size(), 'No opportunity should be updated.');
    }

    @IsTest
    static void writeOnAfterUpdateWithUnchangedOwner() {
        // Setup
        Id janeId = SOQL.IdGenerator.get(User.SObjectType);
        User jane = (User) JSON.deserialize('{"attributes":{"type":"User"},"Id":"' + janeId + '","Name":"Jane Smith"}', User.class);
        Account acme = new Account(Name = 'Acme Corp', OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(AccountOwnerTransferWriter.class).with(acme, new Account(Name = 'Acme', OwnerId = jane.Id)).withParent(Account.OwnerId, jane);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountOwnerTransferWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Opportunity.SObjectType).records().size(), 'No opportunity should be updated.');
    }

    @IsTest
    static void bypassOnAfterUpdateWhenDisabled() {
        // Setup
        Account acme = new Account(Name = 'Acme', OwnerId = SOQL.IdGenerator.get(User.SObjectType));

        AccountOwnerTransferWriter.isDisabled = true;

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(AccountOwnerTransferWriter.class).with(acme, new Account(Name = 'Acme', OwnerId = SOQL.IdGenerator.get(User.SObjectType)));

        // Test
        Test.startTest();
        TriggerOrchestrator.executeTestFor(new AccountOwnerTransferWriter());

        // Verify
        Assert.areEqual(0, Limits.getQueries(), 'The disabled handler should not query.');
    }
}
