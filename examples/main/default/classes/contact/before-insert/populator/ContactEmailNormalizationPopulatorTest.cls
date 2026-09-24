@IsTest(IsParallel=true)
private class ContactEmailNormalizationPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithMixedCaseEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'Jane.Doe@Example.com');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailNormalizationPopulator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailNormalizationPopulator());

        // Verify
        Assert.areEqual('jane.doe@example.com', doe.Email, 'The email should be lowercased.');
    }

    @IsTest
    static void populateOnBeforeInsertWithPaddedEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = '  jane.doe@example.com  ');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailNormalizationPopulator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailNormalizationPopulator());

        // Verify
        Assert.areEqual('jane.doe@example.com', doe.Email, 'The email should be trimmed.');
    }

    @IsTest
    static void populateOnBeforeInsertWithoutEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(ContactEmailNormalizationPopulator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactEmailNormalizationPopulator());

        // Verify
        Assert.isNull(doe.Email, 'The missing email should be skipped.');
    }
}
