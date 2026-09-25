@IsTest(IsParallel=true testFor='ApexClass:AccountParentDefaultsPopulator')
private class AccountParentDefaultsPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithBlankIndustry() {
        // Setup
        Account acmeGroup = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Group', Industry = 'Banking', AccountSource = 'Partner Referral');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id, AccountSource = 'Web');

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentDefaultsPopulator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentDefaultsPopulator());

        // Verify
        Assert.areEqual('Banking', acme.Industry, 'The industry should be copied from the parent.');
    }

    @IsTest
    static void populateOnBeforeInsertWithAccountSource() {
        // Setup
        Account acmeGroup = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Group', Industry = 'Banking', AccountSource = 'Partner Referral');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id, AccountSource = 'Web');

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentDefaultsPopulator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentDefaultsPopulator());

        // Verify
        Assert.areEqual('Web', acme.AccountSource, 'The account source should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithBlankAccountSource() {
        // Setup
        Account acmeGroup = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Group', Industry = 'Banking', AccountSource = 'Partner Referral');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id, Industry = 'Retail');

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentDefaultsPopulator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentDefaultsPopulator());

        // Verify
        Assert.areEqual('Partner Referral', acme.AccountSource, 'The account source should be copied from the parent.');
    }

    @IsTest
    static void populateOnBeforeInsertWithIndustry() {
        // Setup
        Account acmeGroup = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Group', Industry = 'Banking', AccountSource = 'Partner Referral');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id, Industry = 'Retail');

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentDefaultsPopulator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentDefaultsPopulator());

        // Verify
        Assert.areEqual('Retail', acme.Industry, 'The industry should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithBlankIndustryAndAccountSource() {
        // Setup
        Account acmeGroup = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Group', Industry = 'Banking', AccountSource = 'Partner Referral');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentDefaultsPopulator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentDefaultsPopulator());

        // Verify
        Assert.areEqual(
            new Account(Name = 'Acme', ParentId = acmeGroup.Id, Industry = 'Banking', AccountSource = 'Partner Referral'),
            acme,
            'The industry and account source should be copied from the parent.'
        );
    }

    @IsTest
    static void populateOnBeforeInsertWithoutParent() {
        // Setup
        Account acme = new Account(Name = 'Acme', ParentId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentDefaultsPopulator.class).with(acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentDefaultsPopulator());

        // Verify
        Assert.isNull(acme.Industry, 'The industry should stay blank without a parent.');
    }
}
