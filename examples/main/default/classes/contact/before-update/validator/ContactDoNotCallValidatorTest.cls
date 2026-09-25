@IsTest(IsParallel=true testFor='ApexClass:ContactDoNotCallValidator')
private class ContactDoNotCallValidatorTest {
    @IsTest
    static void addErrorOnBeforeUpdateWithDoNotCallWithoutDescription() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', DoNotCall = true);

        TriggerOrchestrator.mock().beforeUpdateFor(ContactDoNotCallValidator.class).with(doe, new Contact(LastName = 'Doe', DoNotCall = false));

        // Test
        TriggerOrchestrator.runTestFor(new ContactDoNotCallValidator());

        // Verify
        Assert.areEqual(
            'Record who asked for Do Not Call, and when, in Description before ticking it.',
            doe.getErrors()[0].getMessage(),
            'The unexplained Do Not Call should be rejected.'
        );
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithDoNotCallAndDescription() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', DoNotCall = true, Description = 'Asked by phone on 2026-09-24.');

        TriggerOrchestrator.mock().beforeUpdateFor(ContactDoNotCallValidator.class).with(doe, new Contact(LastName = 'Doe', DoNotCall = false));

        // Test
        TriggerOrchestrator.runTestFor(new ContactDoNotCallValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The explained Do Not Call should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeUpdateWithDoNotCallAlreadyTicked() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', DoNotCall = true);

        TriggerOrchestrator.mock().beforeUpdateFor(ContactDoNotCallValidator.class).with(doe, new Contact(LastName = 'Doe', DoNotCall = true));

        // Test
        TriggerOrchestrator.runTestFor(new ContactDoNotCallValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The earlier Do Not Call should be accepted.');
    }
}
