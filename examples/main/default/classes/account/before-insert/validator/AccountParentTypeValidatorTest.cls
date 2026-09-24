@IsTest(IsParallel=true)
private class AccountParentTypeValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithProspectParent() {
        // Setup
        Account acmeGroup = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme Group', Type = 'Prospect');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentTypeValidator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountParentTypeValidator());

        // Verify
        Assert.areEqual(
            'Parent account "Acme Group" is still a Prospect and cannot head a hierarchy. Qualify it first.',
            acme.getErrors()[0].getMessage(),
            'The error message should match the expected one.'
        );
    }

    @IsTest
    static void addErrorOnBeforeInsertWithCustomerParent() {
        // Setup
        Account acmeGroup = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme Group', Type = 'Customer - Direct');
        Account acme = new Account(Name = 'Acme', ParentId = acmeGroup.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentTypeValidator.class).with(acme).withParent(Account.ParentId, acmeGroup);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountParentTypeValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The customer parent should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithoutParent() {
        // Setup
        Account acme = new Account(Name = 'Acme', ParentId = SOQL.IdGenerator.get(Account.SObjectType));

        TriggerOrchestrator.mock().beforeInsertFor(AccountParentTypeValidator.class).with(acme);

        // Test
        TriggerOrchestrator.executeTestFor(new AccountParentTypeValidator());

        // Verify
        Assert.isFalse(acme.hasErrors(), 'The account should be accepted without a parent.');
    }
}
