@IsTest(IsParallel=true)
private class ContactAccountTransferPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithTransferredAccount() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        Contact doe = new Contact(LastName = 'Doe', AccountId = globex.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactAccountTransferPopulator.class)
            .with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, new List<Account>{ acme, globex });

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.areEqual(Date.today().format() + ' - transferred from Acme to Globex.', doe.Description, 'The audit line should name both accounts.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithExistingDescription() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        Contact doe = new Contact(LastName = 'Doe', AccountId = globex.Id, Description = 'Met at Dreamforce.');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactAccountTransferPopulator.class)
            .with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id, Description = 'Met at Dreamforce.'))
            .withParent(Contact.AccountId, new List<Account>{ acme, globex });

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.areEqual(
            'Met at Dreamforce.\n' + Date.today().format() + ' - transferred from Acme to Globex.',
            doe.Description,
            'The audit line should be appended to the description.'
        );
    }

    @IsTest
    static void populateOnBeforeUpdateWithRemovedAccount() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactAccountTransferPopulator.class)
            .with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.areEqual(Date.today().format() + ' - transferred from Acme to no account.', doe.Description, 'The audit line should name no account.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithDeletedPriorAccount() {
        // Setup
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        Contact doe = new Contact(LastName = 'Doe', AccountId = globex.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactAccountTransferPopulator.class)
            .with(doe, new Contact(LastName = 'Doe', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType)))
            .withParent(Contact.AccountId, globex);

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.areEqual(Date.today().format() + ' - transferred from a deleted account to Globex.', doe.Description, 'The audit line should name a deleted account.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithFirstAccount() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeUpdateFor(ContactAccountTransferPopulator.class).with(doe, new Contact(LastName = 'Doe')).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.isNull(doe.Description, 'The first account should not be audited.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedAccount() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactAccountTransferPopulator.class)
            .with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.isNull(doe.Description, 'The unchanged account should not be audited.');
    }

    @IsTest
    static void maxRunsPerRecordOnBeforeUpdateWhenUpdatedTwice() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        Contact doe = new Contact(LastName = 'Doe', AccountId = globex.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactAccountTransferPopulator.class)
            .with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, new List<Account>{ acme, globex });

        // Test
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());
        TriggerOrchestrator.runTestFor(new ContactAccountTransferPopulator());

        // Verify
        Assert.areEqual(Date.today().format() + ' - transferred from Acme to Globex.', doe.Description, 'The audit line should be written once.');
    }
}
