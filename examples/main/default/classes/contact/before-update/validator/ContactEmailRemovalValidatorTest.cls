@IsTest(IsParallel=true)
private class ContactEmailRemovalValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithClearedEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', HasOptedOutOfEmail = false);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactEmailRemovalValidator.class)
            .with(doe, new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', HasOptedOutOfEmail = false));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailRemovalValidator());

        // Verify
        Assert.areEqual(
            'Email cannot be cleared while the contact is still opted in. Tick Email Opt Out first, then remove the address.',
            doe.getErrors()[0].getMessage(),
            'The cleared email should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithClearedEmailAfterOptOut() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', HasOptedOutOfEmail = true);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactEmailRemovalValidator.class)
            .with(doe, new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', HasOptedOutOfEmail = true));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailRemovalValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The cleared email of an opted-out contact should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithChangedEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'j.doe@acme.com', HasOptedOutOfEmail = false);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(ContactEmailRemovalValidator.class)
            .with(doe, new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', HasOptedOutOfEmail = false));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailRemovalValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The changed email should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithoutEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', HasOptedOutOfEmail = false);

        TriggerOrchestrator.mock().beforeUpdateFor(ContactEmailRemovalValidator.class).with(doe, new Contact(LastName = 'Doe', HasOptedOutOfEmail = false));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailRemovalValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The contact without an email should be accepted.');
    }
}
