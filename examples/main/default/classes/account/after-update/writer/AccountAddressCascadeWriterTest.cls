@IsTest(IsParallel=true)
private class AccountAddressCascadeWriterTest {
    @IsTest
    static void writeOnAfterUpdateWithoutContacts() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '200 Harbor Blvd', BillingCity = 'Oakland', BillingPostalCode = '94607', BillingCountry = 'United States');
        Account acmeBefore = new Account(
            Name = 'Acme',
            BillingStreet = '1 Market St',
            BillingCity = 'San Francisco',
            BillingPostalCode = '94105',
            BillingCountry = 'United States'
        );

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(AccountAddressCascadeWriter.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.runTestFor(new AccountAddressCascadeWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records().size(), 'No contact should be updated.');
    }

    @IsTest
    static void writeOnAfterUpdateWithUnchangedBillingAddress() {
        // Setup
        Account acme = new Account(Name = 'Acme Corp', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingPostalCode = '94105', BillingCountry = 'United States');
        Account acmeBefore = new Account(
            Name = 'Acme',
            BillingStreet = '1 Market St',
            BillingCity = 'San Francisco',
            BillingPostalCode = '94105',
            BillingCountry = 'United States'
        );

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(AccountAddressCascadeWriter.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.runTestFor(new AccountAddressCascadeWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records().size(), 'No contact should be updated.');
    }
}
