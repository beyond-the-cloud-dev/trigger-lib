@IsTest(IsParallel=true)
private class ContactEmailFormatValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithEmailWithoutAtSign() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe.acme.com');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailFormatValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailFormatValidator());

        // Verify
        Assert.areEqual('Email must be a full address, for example jane.doe@example.com.', doe.getErrors()[0].getMessage(), 'The incomplete email should be rejected.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithSharedMailbox() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'info@acme.com');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailFormatValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailFormatValidator());

        // Verify
        Assert.areEqual(
            'A shared mailbox cannot be used as a contact email. Use the person\'s own address.',
            doe.getErrors()[0].getMessage(),
            'The shared mailbox should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeInsertWithPersonalEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailFormatValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailFormatValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The personal email should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithoutEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailFormatValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailFormatValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The missing email should be accepted.');
    }
}
