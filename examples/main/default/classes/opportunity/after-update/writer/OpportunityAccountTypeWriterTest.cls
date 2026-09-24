@IsTest(IsParallel=true)
private class OpportunityAccountTypeWriterTest {
    @IsTest
    static void writeOnAfterUpdateWithWonOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Type = 'Prospect');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(OpportunityAccountTypeWriter.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review'))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());

        // Verify
        Assert.areEqual(
            new List<SObject>{ new Account(Id = acme.Id, Type = 'Customer - Direct') },
            DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records(),
            'The account should become a direct customer.'
        );
    }

    @IsTest
    static void writeOnAfterUpdateWithDirectCustomerAccount() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Type = 'Customer - Direct');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(OpportunityAccountTypeWriter.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review'))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());

        // Verify
        Assert.isTrue(DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records().isEmpty(), 'The account should not be updated.');
    }

    @IsTest
    static void writeOnAfterUpdateWithoutAccount() {
        // Setup
        Opportunity renewal = new Opportunity(StageName = 'Closed Won');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterUpdateFor(OpportunityAccountTypeWriter.class).with(renewal, new Opportunity(StageName = 'Negotiation/Review'));

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());

        // Verify
        Assert.isTrue(DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records().isEmpty(), 'No account should be updated.');
    }

    @IsTest
    static void writeOnAfterUpdateWithAlreadyWonOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Type = 'Prospect');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(OpportunityAccountTypeWriter.class)
            .with(renewal, new Opportunity(StageName = 'Closed Won'))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());

        // Verify
        Assert.isTrue(DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records().isEmpty(), 'The account should not be updated.');
    }

    @IsTest
    static void writeOnAfterUpdateWithOpenOpportunity() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Type = 'Prospect');
        Opportunity renewal = new Opportunity(StageName = 'Negotiation/Review', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(OpportunityAccountTypeWriter.class)
            .with(renewal, new Opportunity(StageName = 'Proposal/Price Quote'))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());

        // Verify
        Assert.isTrue(DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records().isEmpty(), 'The account should not be updated.');
    }

    @IsTest
    static void maxRecursionDepthOnAfterUpdateWithRepeatedUpdate() {
        // Setup
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Type = 'Prospect');
        Opportunity renewal = new Opportunity(StageName = 'Closed Won', AccountId = acme.Id);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock()
            .afterUpdateFor(OpportunityAccountTypeWriter.class)
            .with(renewal, new Opportunity(StageName = 'Negotiation/Review'))
            .withParent(Opportunity.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());
        TriggerOrchestrator.executeTestFor(new OpportunityAccountTypeWriter());

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records().size(), 'The account should be updated once.');
    }
}
