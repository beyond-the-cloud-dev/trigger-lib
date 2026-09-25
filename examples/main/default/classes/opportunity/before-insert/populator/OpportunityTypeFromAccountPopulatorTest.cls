@IsTest(IsParallel=true testFor='ApexClass:OpportunityTypeFromAccountPopulator')
private class OpportunityTypeFromAccountPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithCustomerAccount() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Type = 'Customer - Direct');
        Opportunity upgrade = new Opportunity(AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(upgrade).withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.areEqual('Existing Customer - Upgrade', upgrade.Type, 'The type should be an upgrade for a customer account.');
    }

    @IsTest
    static void populateOnBeforeInsertWithProspectAccount() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Type = 'Prospect');
        Opportunity firstDeal = new Opportunity(AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(firstDeal).withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.areEqual('New Customer', firstDeal.Type, 'The type should be new customer for a prospect account.');
    }

    @IsTest
    static void populateOnBeforeInsertWithAccountWithoutType() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));
        Opportunity firstDeal = new Opportunity(AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(firstDeal).withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.areEqual('New Customer', firstDeal.Type, 'The type should be new customer for an account without a type.');
    }

    @IsTest
    static void populateOnBeforeInsertWithMissingAccount() {
        // Setup
        Opportunity firstDeal = new Opportunity(AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(firstDeal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.areEqual('New Customer', firstDeal.Type, 'The type should be new customer for a missing account.');
    }

    @IsTest
    static void populateOnBeforeInsertWithType() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Type = 'Customer - Direct');
        Opportunity replacement = new Opportunity(AccountId = acme.Id, Type = 'Existing Customer - Replacement');

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(replacement).withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.areEqual('Existing Customer - Replacement', replacement.Type, 'The type should be kept.');
    }

    @IsTest
    static void populateOnBeforeInsertWithoutAccount() {
        // Setup
        Opportunity privateDeal = new Opportunity(Name = 'Private Deal');

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(privateDeal);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.isNull(privateDeal.Type, 'The type should stay empty without an account.');
    }

    @IsTest
    static void bypassOnBeforeInsertWhenBypassed() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Type = 'Customer - Direct');
        Opportunity upgrade = new Opportunity(AccountId = acme.Id);

        OpportunityTypeFromAccountPopulator.isBypassed = true;

        TriggerOrchestrator.mock().beforeInsertFor(OpportunityTypeFromAccountPopulator.class).with(upgrade).withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new OpportunityTypeFromAccountPopulator());

        // Verify
        Assert.isNull(upgrade.Type, 'The type should stay empty when bypassed.');
    }
}
