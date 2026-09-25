@IsTest(IsParallel=true testFor='ApexClass:AccountTypeAuditPopulator')
private class AccountTypeAuditPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithChangedType() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme', Type = 'Prospect'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual('Type Prospect -> Customer - Direct by ' + UserInfo.getName(), acme.Description.substringAfter(' - '), 'The type change should be stamped.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithBlankPreviousType() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Prospect');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual('Type none -> Prospect by ' + UserInfo.getName(), acme.Description.substringAfter(' - '), 'The blank type should be stamped as none.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithClearedType() {
        // Setup
        Account acme = new Account(Name = 'Acme');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme', Type = 'Prospect'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual('Type Prospect -> none by ' + UserInfo.getName(), acme.Description.substringAfter(' - '), 'The blank type should be stamped as none.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithDescription() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', Description = 'Key account.');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme', Type = 'Prospect', Description = 'Key account.'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual('Key account.', acme.Description.substringAfter('\n'), 'The existing description should be kept below the stamp.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithFullDescription() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', Description = 'x'.repeat(32000));

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme', Type = 'Prospect', Description = 'x'.repeat(32000)));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual(32000, acme.Description.length(), 'The description should be cut to the field length.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedType() {
        // Setup
        Account acme = new Account(Name = 'Acme Corp', Type = 'Prospect', Description = 'Key account.');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme', Type = 'Prospect', Description = 'Key account.'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual('Key account.', acme.Description, 'The description should be kept.');
    }

    @IsTest
    static void maxRunsPerRecordOnBeforeUpdateWhenUpdatedTwice() {
        // Setup
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct');

        TriggerOrchestrator.mock().beforeUpdateFor(AccountTypeAuditPopulator.class).with(acme, new Account(Name = 'Acme', Type = 'Prospect'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());
        TriggerOrchestrator.runTestFor(new AccountTypeAuditPopulator());

        // Verify
        Assert.areEqual(1, acme.Description.countMatches('Type Prospect -> Customer - Direct'), 'The type change should be stamped once.');
    }
}
