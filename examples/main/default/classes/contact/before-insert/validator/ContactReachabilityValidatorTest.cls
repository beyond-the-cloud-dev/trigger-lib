@IsTest(IsParallel=true)
private class ContactReachabilityValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithoutContactDetails() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(ContactReachabilityValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactReachabilityValidator());

        // Verify
        Assert.areEqual(
            'A contact needs at least one way to be reached. Fill in Email, Phone or Mobile.',
            doe.getErrors()[0].getMessage(),
            'The unreachable contact should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeInsertWithEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com');

        TriggerOrchestrator.mock().beforeInsertFor(ContactReachabilityValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactReachabilityValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The contact with an email should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithPhone() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Phone = '555-0100');

        TriggerOrchestrator.mock().beforeInsertFor(ContactReachabilityValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactReachabilityValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The contact with a phone should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithMobilePhone() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', MobilePhone = '555-0101');

        TriggerOrchestrator.mock().beforeInsertFor(ContactReachabilityValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactReachabilityValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The contact with a mobile phone should be accepted.');
    }

    @IsTest
    static void bypassOnBeforeInsertWhenDisabled() {
        // Setup
        ContactReachabilityValidator.isDisabled = true;

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(ContactReachabilityValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactReachabilityValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The disabled validator should not reject the contact.');
    }
}
