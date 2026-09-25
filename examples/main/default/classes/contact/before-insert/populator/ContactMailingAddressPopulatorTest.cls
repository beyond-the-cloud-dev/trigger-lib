@IsTest(IsParallel=true testFor='ApexClass:ContactMailingAddressPopulator')
private class ContactMailingAddressPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithAccountBillingAddress() {
        // Setup
        Account acme = new Account(
            Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType),
            BillingStreet = '1 Main St',
            BillingCity = 'Springfield',
            BillingState = 'IL',
            BillingPostalCode = '62701',
            BillingCountry = 'USA'
        );
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(ContactMailingAddressPopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactMailingAddressPopulator());

        // Verify
        Assert.areEqual(
            new List<String>{ '1 Main St', 'Springfield', 'IL', '62701', 'USA' },
            new List<String>{ doe.MailingStreet, doe.MailingCity, doe.MailingState, doe.MailingPostalCode, doe.MailingCountry },
            'The mailing address should be copied from the account.'
        );
    }

    @IsTest
    static void populateOnBeforeInsertWithOwnMailingStreet() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), BillingStreet = '1 Main St', BillingCity = 'Springfield');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id, MailingStreet = '5 Elm St');

        TriggerOrchestrator.mock().beforeInsertFor(ContactMailingAddressPopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactMailingAddressPopulator());

        // Verify
        Assert.areEqual('5 Elm St', doe.MailingStreet, 'The own mailing street should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithOwnMailingCity() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), BillingStreet = '1 Main St', BillingCity = 'Springfield');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id, MailingCity = 'Shelbyville');

        TriggerOrchestrator.mock().beforeInsertFor(ContactMailingAddressPopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactMailingAddressPopulator());

        // Verify
        Assert.areEqual('Shelbyville', doe.MailingCity, 'The own mailing city should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithOwnMailingCountry() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), BillingStreet = '1 Main St', BillingCity = 'Springfield', BillingCountry = 'USA');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id, MailingCountry = 'Canada');

        TriggerOrchestrator.mock().beforeInsertFor(ContactMailingAddressPopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new ContactMailingAddressPopulator());

        // Verify
        Assert.areEqual('USA', doe.MailingCountry, 'The whole address should be copied from the account.');
    }

    @IsTest
    static void populateOnBeforeInsertWithMissingAccount() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        TriggerOrchestrator.mock().beforeInsertFor(ContactMailingAddressPopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new ContactMailingAddressPopulator());

        // Verify
        Assert.isNull(doe.MailingStreet, 'No address should be copied without an account.');
    }
}
