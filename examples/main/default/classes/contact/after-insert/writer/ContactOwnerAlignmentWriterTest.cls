@IsTest(IsParallel=true)
private class ContactOwnerAlignmentWriterTest {
    @IsTest
    static void writeOnAfterInsertWithActiveAccountOwner() {
        // Setup
        User jane = new User(Id = SOQL.IdGenerator.get(User.SObjectType), IsActive = true);
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), OwnerId = jane.Id, Owner = jane);
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactOwnerAlignmentWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactOwnerAlignmentWriter());

        // Verify
        Contact updated = (Contact) DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records()[0];
        Assert.areEqual(jane.Id, updated.OwnerId, 'The contact should get the account owner.');
    }

    @IsTest
    static void writeOnAfterInsertWithInactiveAccountOwner() {
        // Setup
        User jane = new User(Id = SOQL.IdGenerator.get(User.SObjectType), IsActive = false);
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), OwnerId = jane.Id, Owner = jane);
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactOwnerAlignmentWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactOwnerAlignmentWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records().size(), 'No contact should be updated.');
    }

    @IsTest
    static void writeOnAfterInsertWithSameOwner() {
        // Setup
        User jane = new User(Id = SOQL.IdGenerator.get(User.SObjectType), IsActive = true);
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), OwnerId = jane.Id, Owner = jane);
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id, OwnerId = jane.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactOwnerAlignmentWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactOwnerAlignmentWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records().size(), 'No contact should be updated.');
    }

    @IsTest
    static void writeOnAfterInsertWithoutAccount() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactOwnerAlignmentWriter.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactOwnerAlignmentWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records().size(), 'No contact should be updated.');
    }

    @IsTest
    static void bypassOnAfterInsertWhenDisabled() {
        // Setup
        ContactOwnerAlignmentWriter.isDisabled = true;

        User jane = new User(Id = SOQL.IdGenerator.get(User.SObjectType), IsActive = true);
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), OwnerId = jane.Id, Owner = jane);
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactOwnerAlignmentWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactOwnerAlignmentWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records().size(), 'No contact should be updated.');
    }
}
