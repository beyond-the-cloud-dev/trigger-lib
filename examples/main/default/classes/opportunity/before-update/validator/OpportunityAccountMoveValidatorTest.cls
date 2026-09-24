@IsTest(IsParallel=true)
private class OpportunityAccountMoveValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithMovedWonOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Globex');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = globex.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityAccountMoveValidator.class)
            .with(renewal, new Opportunity(StageName = 'Closed Won', AccountId = acme.Id))
            .withParent(Opportunity.AccountId, new List<Account>{ acme, globex });

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountMoveValidator());

        // Verify
        Assert.areEqual(
            'This Opportunity is Closed Won and stays with Acme. It cannot be moved to Globex.',
            renewal.getErrors()[0].getMessage(),
            'Moving a won opportunity should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithMovedClosingOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Globex');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = globex.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityAccountMoveValidator.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review', AccountId = acme.Id))
            .withParent(Opportunity.AccountId, new List<Account>{ acme, globex });

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountMoveValidator());

        // Verify
        Assert.areEqual(
            'This Opportunity is Closed Won and stays with Acme. It cannot be moved to Globex.',
            renewal.getErrors()[0].getMessage(),
            'Moving an opportunity while winning it should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithRemovedAccount() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityAccountMoveValidator.class)
            .with(renewal, new Opportunity(StageName = 'Closed Won', AccountId = acme.Id))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountMoveValidator());

        // Verify
        Assert.areEqual(
            'This Opportunity is Closed Won and stays with Acme. It cannot be moved to another Account.',
            renewal.getErrors()[0].getMessage(),
            'Removing the account of a won opportunity should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithMissingAccounts() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = SOQL.IdGenerator.get(Account.SObjectType));

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityAccountMoveValidator.class)
            .with(renewal, new Opportunity(StageName = 'Closed Won', AccountId = SOQL.IdGenerator.get(Account.SObjectType)));

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountMoveValidator());

        // Verify
        Assert.areEqual(
            'This Opportunity is Closed Won and stays with its original Account. It cannot be moved to another Account.',
            renewal.getErrors()[0].getMessage(),
            'Moving a won opportunity between missing accounts should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithMovedOpenOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Globex');
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review', AccountId = globex.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityAccountMoveValidator.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review', AccountId = acme.Id))
            .withParent(Opportunity.AccountId, new List<Account>{ acme, globex });

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountMoveValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Moving an open opportunity should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithUnmovedWonOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = acme.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OpportunityAccountMoveValidator.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review', AccountId = acme.Id))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountMoveValidator());

        // Verify
        Assert.isFalse(renewal.hasErrors(), 'Winning an opportunity on the same account should be accepted.');
    }
}
