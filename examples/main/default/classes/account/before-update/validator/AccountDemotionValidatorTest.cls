@IsTest(IsParallel=true)
private class AccountDemotionValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithCustomerChangedToProspect() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Prospect');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountDemotionValidator.class).with(acme, new Account(Name = 'Acme', Type = 'Customer - Direct'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountDemotionValidator());

        // Verify
        Assert.areEqual(
            'This account is already Customer - Direct and cannot be moved back to Prospect. Close it as Lost instead.',
            acme.getErrors()[0].getMessage(),
            'The error message should match the expected one.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithOtherTypeChangedToProspect() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Prospect');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountDemotionValidator.class).with(acme, new Account(Name = 'Acme', Type = 'Other'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountDemotionValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The non-customer should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithBlankTypeChangedToProspect() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Prospect');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountDemotionValidator.class).with(acme, new Account(Name = 'Acme'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountDemotionValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The account without a type should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithCustomerChangedToOtherType() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Other');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountDemotionValidator.class).with(acme, new Account(Name = 'Acme', Type = 'Customer - Direct'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountDemotionValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The customer should be allowed to change to another type.');
    }
}
