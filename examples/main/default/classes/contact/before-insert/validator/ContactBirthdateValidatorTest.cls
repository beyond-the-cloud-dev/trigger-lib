@IsTest(IsParallel=true)
private class ContactBirthdateValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertWithFutureBirthdate() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Birthdate = Date.today().addDays(1));

        TriggerOrchestrator.mock().beforeInsertFor(ContactBirthdateValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactBirthdateValidator());

        // Verify
        Assert.areEqual('Birthdate must be in the past and less than 120 years ago. Check the year.', doe.getErrors()[0].getMessage(), 'The future birthdate should be rejected.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithBirthdateOver120YearsAgo() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Birthdate = Date.today().addYears(-120).addDays(-1));

        TriggerOrchestrator.mock().beforeInsertFor(ContactBirthdateValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactBirthdateValidator());

        // Verify
        Assert.areEqual('Birthdate must be in the past and less than 120 years ago. Check the year.', doe.getErrors()[0].getMessage(), 'The too old birthdate should be rejected.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithBirthdateToday() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Birthdate = Date.today());

        TriggerOrchestrator.mock().beforeInsertFor(ContactBirthdateValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactBirthdateValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The birthdate today should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithBirthdate120YearsAgo() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Birthdate = Date.today().addYears(-120));

        TriggerOrchestrator.mock().beforeInsertFor(ContactBirthdateValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactBirthdateValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The birthdate exactly 120 years ago should be accepted.');
    }

    @IsTest
    static void addErrorOnBeforeInsertWithoutBirthdate() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(ContactBirthdateValidator.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactBirthdateValidator());

        // Verify
        Assert.isFalse(doe.hasErrors(), 'The missing birthdate should be accepted.');
    }
}
