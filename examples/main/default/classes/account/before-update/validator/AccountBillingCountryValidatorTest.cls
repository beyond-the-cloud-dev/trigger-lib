@IsTest(IsParallel=true testFor='ApexClass:AccountBillingCountryValidator')
private class AccountBillingCountryValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithClearedBillingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountBillingCountryValidator.class).with(acme, new Account(Name = 'Acme', BillingCountry = 'Poland'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountBillingCountryValidator());

        // Verify
        Assert.areEqual(
            'Billing Country cannot be cleared. It is currently Poland; replace it with another country instead.',
            acme.getErrors()[0].getMessage(),
            'The error message should match the expected one.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithChangedBillingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingCountry = 'Germany');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountBillingCountryValidator.class).with(acme, new Account(Name = 'Acme', BillingCountry = 'Poland'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountBillingCountryValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The new country should be accepted.');
    }
}
