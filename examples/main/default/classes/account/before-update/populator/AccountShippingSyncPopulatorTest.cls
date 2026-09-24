@IsTest(IsParallel=true)
private class AccountShippingSyncPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithShippingMatchingBilling() {
        // Setup
        Account acme = new Account(
            Name = 'Acme',
            BillingStreet = '200 Harbor Blvd',
            BillingCity = 'Oakland',
            BillingState = 'CA',
            BillingPostalCode = '94607',
            BillingCountry = 'United States',
            ShippingStreet = '1 Market St',
            ShippingCity = 'San Francisco',
            ShippingState = 'CA',
            ShippingPostalCode = '94105',
            ShippingCountry = 'United States'
        );
        Account acmeBefore = new Account(
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
        );

        TriggerOrchestrator.mock().beforeUpdateFor(AccountShippingSyncPopulator.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingSyncPopulator());

        // Verify
        Assert.areEqual(
            new Account(
                Id = acme.Id,
                Name = 'Acme',
                BillingStreet = '200 Harbor Blvd',
                BillingCity = 'Oakland',
                BillingState = 'CA',
                BillingPostalCode = '94607',
                BillingCountry = 'United States',
                ShippingStreet = '200 Harbor Blvd',
                ShippingCity = 'Oakland',
                ShippingState = 'CA',
                ShippingPostalCode = '94607',
                ShippingCountry = 'United States'
            ),
            acme,
            'The shipping address should follow the billing address.'
        );
    }

    @IsTest
    static void populateOnBeforeUpdateWithBlankShipping() {
        // Setup
        Account acme = new Account(Name = 'Acme', BillingStreet = '200 Harbor Blvd', BillingCity = 'Oakland', BillingCountry = 'United States');
        Account acmeBefore = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountShippingSyncPopulator.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingSyncPopulator());

        // Verify
        Assert.areEqual('Oakland', acme.ShippingCity, 'The shipping address should follow the billing address.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithShippingDifferentFromBilling() {
        // Setup
        Account acme = new Account(
            Name = 'Acme',
            BillingStreet = '200 Harbor Blvd',
            BillingCity = 'Oakland',
            BillingCountry = 'United States',
            ShippingStreet = '5 Dock Rd',
            ShippingCity = 'Richmond',
            ShippingCountry = 'United States'
        );
        Account acmeBefore = new Account(
            Name = 'Acme',
            BillingStreet = '1 Market St',
            BillingCity = 'San Francisco',
            BillingCountry = 'United States',
            ShippingStreet = '5 Dock Rd',
            ShippingCity = 'Richmond',
            ShippingCountry = 'United States'
        );

        TriggerOrchestrator.mock().beforeUpdateFor(AccountShippingSyncPopulator.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingSyncPopulator());

        // Verify
        Assert.areEqual('5 Dock Rd', acme.ShippingStreet, 'The separate shipping address should be kept.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedBilling() {
        // Setup
        Account acme = new Account(Name = 'Acme Corp', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States');
        Account acmeBefore = new Account(Name = 'Acme', BillingStreet = '1 Market St', BillingCity = 'San Francisco', BillingCountry = 'United States');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountShippingSyncPopulator.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountShippingSyncPopulator());

        // Verify
        Assert.isNull(acme.ShippingStreet, 'The shipping address should stay blank.');
    }
}
