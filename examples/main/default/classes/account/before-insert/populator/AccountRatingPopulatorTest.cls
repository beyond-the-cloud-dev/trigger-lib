@IsTest(IsParallel=true)
private class AccountRatingPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithFiveMillionRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 5000000);

        TriggerOrchestrator.mock().beforeInsertFor(AccountRatingPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountRatingPopulator());

        // Verify
        Assert.areEqual('Hot', acme.Rating, 'The rating should follow the annual revenue.');
    }

    @IsTest
    static void populateOnBeforeInsertWithHalfMillionRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 500000);

        TriggerOrchestrator.mock().beforeInsertFor(AccountRatingPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountRatingPopulator());

        // Verify
        Assert.areEqual('Warm', acme.Rating, 'The rating should follow the annual revenue.');
    }

    @IsTest
    static void populateOnBeforeInsertWithRevenueBelowHalfMillion() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 499999);

        TriggerOrchestrator.mock().beforeInsertFor(AccountRatingPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountRatingPopulator());

        // Verify
        Assert.areEqual('Cold', acme.Rating, 'The rating should follow the annual revenue.');
    }

    @IsTest
    static void populateOnBeforeInsertWithRating() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 6000000, Rating = 'Cold');

        TriggerOrchestrator.mock().beforeInsertFor(AccountRatingPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountRatingPopulator());

        // Verify
        Assert.areEqual('Cold', acme.Rating, 'The rating should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithoutAnnualRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme');

        TriggerOrchestrator.mock().beforeInsertFor(AccountRatingPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountRatingPopulator());

        // Verify
        Assert.isNull(acme.Rating, 'The rating should stay blank.');
    }
}
