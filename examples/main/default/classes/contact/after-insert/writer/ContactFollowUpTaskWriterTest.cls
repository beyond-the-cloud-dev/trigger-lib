@IsTest(IsParallel=true)
private class ContactFollowUpTaskWriterTest {
    @IsTest
    static void writeOnAfterInsertWithWebLeadSource() {
        // Setup
        Id janeId = SOQL.IdGenerator.get(User.SObjectType);
        Account acme = new Account(Id = SOQL.IdGenerator.get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', LeadSource = 'Web', AccountId = acme.Id, OwnerId = janeId);

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactFollowUpTaskWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactFollowUpTaskWriter());

        // Verify
        Task followUp = (Task) DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0];
        Assert.areEqual(
            new Task(
                Id = followUp.Id,
                WhoId = doe.Id,
                WhatId = acme.Id,
                OwnerId = janeId,
                Subject = 'Follow up with new web contactRecord from Acme',
                ActivityDate = Date.today().addDays(2),
                Priority = 'High',
                Status = 'Not Started'
            ),
            followUp,
            'The follow-up task should be inserted.'
        );
    }

    @IsTest
    static void writeOnAfterInsertWithoutAccount() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', LeadSource = 'Web');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactFollowUpTaskWriter.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactFollowUpTaskWriter());

        // Verify
        Task followUp = (Task) DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0];
        Assert.areEqual('Follow up with new web contactRecord', followUp.Subject, 'The subject should not name an account.');
    }

    @IsTest
    static void writeOnAfterInsertWithOtherLeadSource() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', LeadSource = 'Phone Inquiry');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactFollowUpTaskWriter.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactFollowUpTaskWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records().size(), 'No task should be inserted.');
    }

    @IsTest
    static void writeOnAfterInsertWithoutEmail() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', LeadSource = 'Web');

        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(ContactFollowUpTaskWriter.class).with(doe);

        // Test
        TriggerOrchestrator.executeTestFor(new ContactFollowUpTaskWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records().size(), 'No task should be inserted.');
    }

    @IsTest
    static void writeOnAfterInsertWhenTaskInsertFails() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@acme.com', LeadSource = 'Web');

        DML.mock('triggerUow').exceptionOnInserts();

        TriggerOrchestrator.mock().afterInsertFor(ContactFollowUpTaskWriter.class).with(doe);

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.executeTestFor(new ContactFollowUpTaskWriter());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isNull(expectedException, 'The failed task insert should not block the contact.');
    }
}
