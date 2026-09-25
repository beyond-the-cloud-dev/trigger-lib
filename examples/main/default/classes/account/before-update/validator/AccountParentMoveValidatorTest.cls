@IsTest(IsParallel=true testFor='ApexClass:AccountParentMoveValidator')
private class AccountParentMoveValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithParentInAnotherCountry() {
        // Setup
        Account acmePoland = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Poland', BillingCountry = 'Poland');
        Account acmeGermany = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Germany', BillingCountry = 'Germany');
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', ParentId = acmeGermany.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(AccountParentMoveValidator.class)
            .with(acme, new Account(Name = 'Acme', Type = 'Customer - Direct', ParentId = acmePoland.Id))
            .withParent(Account.ParentId, new List<Account>{ acmePoland, acmeGermany });

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentMoveValidator());

        // Verify
        Assert.areEqual(
            'Moving this customer from "Acme Poland" (Poland) to "Acme Germany" (Germany) changes the invoicing entity. Raise a finance request for the transfer.',
            acme.getErrors()[0].getMessage(),
            'The error message should match the expected one.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithParentInSameCountry() {
        // Setup
        Account acmePoland = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Poland', BillingCountry = 'Poland');
        Account acmeKrakow = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Krakow', BillingCountry = 'Poland');
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', ParentId = acmeKrakow.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(AccountParentMoveValidator.class)
            .with(acme, new Account(Name = 'Acme', Type = 'Customer - Direct', ParentId = acmePoland.Id))
            .withParent(Account.ParentId, new List<Account>{ acmePoland, acmeKrakow });

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentMoveValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The move within one country should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithProspect() {
        // Setup
        Account acmePoland = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Poland', BillingCountry = 'Poland');
        Account acmeGermany = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Germany', BillingCountry = 'Germany');
        Account acme = new Account(Name = 'Acme', Type = 'Prospect', ParentId = acmeGermany.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(AccountParentMoveValidator.class)
            .with(acme, new Account(Name = 'Acme', Type = 'Prospect', ParentId = acmePoland.Id))
            .withParent(Account.ParentId, new List<Account>{ acmePoland, acmeGermany });

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentMoveValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The prospect should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithFirstParent() {
        // Setup
        Account acmeGermany = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Germany', BillingCountry = 'Germany');
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct', ParentId = acmeGermany.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(AccountParentMoveValidator.class)
            .with(acme, new Account(Name = 'Acme', Type = 'Customer - Direct'))
            .withParent(Account.ParentId, acmeGermany);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentMoveValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The first parent should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithRemovedParent() {
        // Setup
        Account acmePoland = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme Poland', BillingCountry = 'Poland');
        Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(AccountParentMoveValidator.class)
            .with(acme, new Account(Name = 'Acme', Type = 'Customer - Direct', ParentId = acmePoland.Id))
            .withParent(Account.ParentId, acmePoland);

        // Test
        TriggerOrchestrator.runTestFor(new AccountParentMoveValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The removed parent should be accepted.');
    }
}
