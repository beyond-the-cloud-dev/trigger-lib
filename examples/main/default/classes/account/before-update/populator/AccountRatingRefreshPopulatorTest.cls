@IsTest(IsParallel=true testFor='ApexClass:AccountRatingRefreshPopulator')
private class AccountRatingRefreshPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithFiveMillionRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 5000000, Rating = 'Cold');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountRatingRefreshPopulator.class).with(acme, new Account(Name = 'Acme', AnnualRevenue = 100000, Rating = 'Cold'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountRatingRefreshPopulator());

        // Verify
        Assert.areEqual('Hot', acme.Rating, 'The rating should follow the annual revenue.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithHalfMillionRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 500000, Rating = 'Cold');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountRatingRefreshPopulator.class).with(acme, new Account(Name = 'Acme', AnnualRevenue = 100000, Rating = 'Cold'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountRatingRefreshPopulator());

        // Verify
        Assert.areEqual('Warm', acme.Rating, 'The rating should follow the annual revenue.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithRevenueBelowHalfMillion() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 499999, Rating = 'Hot');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountRatingRefreshPopulator.class).with(acme, new Account(Name = 'Acme', AnnualRevenue = 6000000, Rating = 'Hot'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountRatingRefreshPopulator());

        // Verify
        Assert.areEqual('Cold', acme.Rating, 'The rating should follow the annual revenue.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 6000000, Rating = 'Cold');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountRatingRefreshPopulator.class).with(acme, new Account(Name = 'Acme', AnnualRevenue = 6000000, Rating = 'Hot'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountRatingRefreshPopulator());

        // Verify
        Assert.areEqual('Cold', acme.Rating, 'The rating should be kept.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithClearedRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', Rating = 'Hot');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountRatingRefreshPopulator.class).with(acme, new Account(Name = 'Acme', AnnualRevenue = 6000000, Rating = 'Hot'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountRatingRefreshPopulator());

        // Verify
        Assert.areEqual('Hot', acme.Rating, 'The rating should be kept.');
    }
}
