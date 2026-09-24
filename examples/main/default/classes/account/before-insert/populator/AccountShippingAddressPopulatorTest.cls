@IsTest(IsParallel=true)
private class AccountShippingAddressPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithBillingAddress() {
        // Setup
        Account acme = new Account(
            Name = 'Acme',
            BillingStreet = '1 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94105',
            BillingCountry = 'United States'
        );

        TriggerOrchestrator.mock().beforeInsertFor(AccountShippingAddressPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingAddressPopulator());

        // Verify
        Assert.areEqual(
            new Account(
                Name = 'Acme',
                BillingStreet = '1 Market St',
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingPostalCode = '94105',
                BillingCountry = 'United States',
                ShippingStreet = '1 Market St',
                ShippingCity = 'San Francisco',
                ShippingState = 'CA',
                ShippingPostalCode = '94105',
                ShippingCountry = 'United States'
            ),
            acme,
            'The shipping address should be copied from the billing address.'
        );
    }

    @IsTest
    static void populateOnBeforeInsertWithShippingStreet() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States', ShippingStreet = '5 Dock Rd');

        TriggerOrchestrator.mock().beforeInsertFor(AccountShippingAddressPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingAddressPopulator());

        // Verify
        Assert.areEqual('5 Dock Rd', acme.ShippingStreet, 'The shipping street should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithShippingCity() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States', ShippingCity = 'Oakland');

        TriggerOrchestrator.mock().beforeInsertFor(AccountShippingAddressPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingAddressPopulator());

        // Verify
        Assert.areEqual('Oakland', acme.ShippingCity, 'The shipping city should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithShippingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States', ShippingCountry = 'Canada');

        TriggerOrchestrator.mock().beforeInsertFor(AccountShippingAddressPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingAddressPopulator());

        // Verify
        Assert.areEqual('Canada', acme.ShippingCountry, 'The shipping country should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithoutBillingCountry() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco');

        TriggerOrchestrator.mock().beforeInsertFor(AccountShippingAddressPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingAddressPopulator());

        // Verify
        Assert.isNull(acme.ShippingStreet, 'The shipping address should stay blank.');
    }

    @IsTest
    static void bypassOnBeforeInsertWhenDisabled() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States');

        AccountShippingAddressPopulator.isDisabled = true;

        TriggerOrchestrator.mock().beforeInsertFor(AccountShippingAddressPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingAddressPopulator());

        // Verify
        Assert.isNull(acme.ShippingStreet, 'The disabled handler should not copy the address.');
    }
}
