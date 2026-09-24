@IsTest(IsParallel=true)
private class ContactTitleDepartmentPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithKnownTitle() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Title = 'CFO');

        TriggerOrchestrator.mock().beforeUpdateFor(ContactTitleDepartmentPopulator.class).with(doe, new Contact(LastName = 'Doe', Title = 'Analyst'));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactTitleDepartmentPopulator());

        // Verify
        Assert.areEqual('Finance', doe.Department, 'The department should follow the title.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithPaddedTitle() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Title = '  Office Manager  ');

        TriggerOrchestrator.mock().beforeUpdateFor(ContactTitleDepartmentPopulator.class).with(doe, new Contact(LastName = 'Doe', Title = 'Analyst'));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactTitleDepartmentPopulator());

        // Verify
        Assert.areEqual('Administration', doe.Department, 'The padded title should be matched.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnknownTitle() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Title = 'Engineer', Department = 'R&D');

        TriggerOrchestrator.mock().beforeUpdateFor(ContactTitleDepartmentPopulator.class).with(doe, new Contact(LastName = 'Doe', Title = 'Analyst', Department = 'R&D'));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactTitleDepartmentPopulator());

        // Verify
        Assert.areEqual('R&D', doe.Department, 'The department should be kept for an unknown title.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedTitle() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Title = 'CFO', Department = 'Accounting');

        TriggerOrchestrator.mock().beforeUpdateFor(ContactTitleDepartmentPopulator.class).with(doe, new Contact(LastName = 'Doe', Title = 'CFO', Department = 'Treasury'));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactTitleDepartmentPopulator());

        // Verify
        Assert.areEqual('Accounting', doe.Department, 'The department should be kept for an unchanged title.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithClearedTitle() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Department = 'Finance');

        TriggerOrchestrator.mock().beforeUpdateFor(ContactTitleDepartmentPopulator.class).with(doe, new Contact(LastName = 'Doe', Title = 'CFO', Department = 'Finance'));

        // Test
        TriggerOrchestrator.executeTestFor(new ContactTitleDepartmentPopulator());

        // Verify
        Assert.areEqual('Finance', doe.Department, 'The department should be kept for a cleared title.');
    }
}
