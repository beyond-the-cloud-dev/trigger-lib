@IsTest(IsParallel=true)
private class AccountCustomerDataValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithBlankIndustry() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', BillingCountry = 'Poland');

        TriggerOrchestrator.mock().beforeInsertFor(AccountCustomerDataValidator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountCustomerDataValidator());

        // Verify
        Assert.areEqual('A customer account requires Industry.', acme.getErrors()[0].getMessage(), 'The error message should match the expected one.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithBlankBillingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', Industry = 'Banking');

        TriggerOrchestrator.mock().beforeInsertFor(AccountCustomerDataValidator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountCustomerDataValidator());

        // Verify
        Assert.areEqual('A customer account requires Billing Country.', acme.getErrors()[0].getMessage(), 'The error message should match the expected one.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithBlankIndustryAndBillingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct');

        TriggerOrchestrator.mock().beforeInsertFor(AccountCustomerDataValidator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountCustomerDataValidator());

        // Verify
        Assert.areEqual(2, acme.getErrors().size(), 'Both missing fields should be rejected.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithIndustryAndBillingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', Industry = 'Banking', BillingCountry = 'Poland');

        TriggerOrchestrator.mock().beforeInsertFor(AccountCustomerDataValidator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountCustomerDataValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The complete customer should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithProspect() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Prospect');

        TriggerOrchestrator.mock().beforeInsertFor(AccountCustomerDataValidator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountCustomerDataValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The prospect should be accepted.');
    }
}
