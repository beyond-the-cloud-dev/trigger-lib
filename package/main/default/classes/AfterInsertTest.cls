/**
 * @description Tests for the AfterInsert context of the TriggerOrchestrator class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.2.0
 *
 * PMD False Positives:
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE test class
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.ExcessiveClassLength,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true testFor='ApexClass:AfterInsert, ApexClass:TriggerOrchestrator')
private class AfterInsertTest {
    @IsTest
    static void writerWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriter.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void dispatcherWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcher.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void writerWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithBypassable.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithBypassable());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The handler should not run.');
    }

    @IsTest
    static void dispatcherWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcherWithBypassable.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.isTrue(dispatcher.dispatchedIds.isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void writer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriter.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void writerWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriter.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not register an account.');
    }

    @IsTest
    static void dispatcher() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcher.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void dispatcherWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        BatchDispatcher dispatcher = new BatchDispatcher();

        TriggerOrchestrator.mock().afterInsertFor(BatchDispatcher.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(0, dispatcher.dispatchedBatches.size(), 'The dispatcher should not be called.');
    }

    @IsTest
    static void dispatcherWithMultipleRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact johnDoe = new Contact(FirstName = 'John', LastName = 'Doe');
        Contact janeDoe = new Contact(FirstName = 'Jane', LastName = 'Doe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TriggerOrchestrator.mock().afterInsertFor(BatchDispatcher.class).with(new List<Contact>{ johnDoe, janeDoe });

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Set<Id>>{ new Set<Id>{ johnDoe.Id, janeDoe.Id } }, dispatcher.dispatchedBatches, 'The dispatcher should receive all records in one call.');
    }

    @IsTest
    static void dispatcherBeforeFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        IdDispatcherWithFinalizerSnapshot dispatcher = new IdDispatcherWithFinalizerSnapshot();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcherWithFinalizerSnapshot.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIdsWhenFinalized, 'The dispatcher should dispatch before it finalizes.');
    }

    @IsTest
    static void writerWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithFinalizer.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(writer);

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, writer.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void dispatcherWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcherWithFinalizer.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, dispatcher.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void writerWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithFinalizer.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(writer);

        // Verify
        Assert.isNull(writer.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void dispatcherWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcherWithFinalizer.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.isNull(dispatcher.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void writerWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().afterInsertFor(FailingWriter.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingWriter());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The writer failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void dispatcherWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().afterInsertFor(FailingDispatcher.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDispatcher());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The dispatcher failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void writerWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().afterInsertFor(FailingWriterWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingWriterWithContinueOnError());

        // Verify
        Assert.areEqual('The writer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void dispatcherWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().afterInsertFor(FailingDispatcherWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingDispatcherWithContinueOnError());

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void writerWithContinueOnErrorWhenRetryIsRequested() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().afterInsertFor(RetryingWriterWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new RetryingWriterWithContinueOnError());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isInstanceOfType(expectedException, EventBus.RetryableException.class, 'The retry request should not be swallowed.');
    }

    @IsTest
    static void writerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(DmlAccountWriter.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new DmlAccountWriter());

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should register the account.');
    }

    @IsTest
    static void parentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock('SavedTriggerRecords').thenReturn(new Contact(Id = doe.Id, Account = acme));

        TriggerOrchestrator.mock().afterInsertFor(AccountNameWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the account name.');
    }

    @IsTest
    static void relatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        TriggerOrchestrator.mock().afterInsertFor(RelatedAccountNameWriter.class).with(new Contact(LastName = 'Doe', AccountId = acme.Id));

        // Test
        TriggerOrchestrator.runTestFor(new RelatedAccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the related account name.');
    }

    @IsTest
    static void writerWithSharedUnitOfWorkWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator.mock().afterInsertFor(TestOrchestrator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(0, dispatcher.committedAccounts, 'The shared unit of work should not commit before the next handler.');
    }

    @IsTest
    static void writerWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithOwnUnitOfWork.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithOwnUnitOfWork());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void writerWithContinueOnErrorWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithContinueOnError());
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator.mock().afterInsertFor(TestOrchestrator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(1, dispatcher.committedAccounts, 'The automatic unit of work should commit before the next handler.');
    }

    @IsTest
    static void writerWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(FailingAccountWriterWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingAccountWriterWithContinueOnError());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void writerWithOwnUnitOfWorkWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithPrefilledOwnUnitOfWork.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithPrefilledOwnUnitOfWork());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records().size(), 'The own unit of work should not commit.');
    }

    @IsTest
    static void writerWithOwnUnitOfWorkAndContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithOwnUnitOfWorkAndContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithOwnUnitOfWorkAndContinueOnError());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void writerWithSharedUnitOfWorkWhenCommitFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').exceptionOnInserts();

        TriggerOrchestrator.mock().afterInsertFor(AccountWriter.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new AccountWriter());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isInstanceOfType(expectedException, DmlException.class, 'The commit exception should propagate.');
    }

    @IsTest
    static void writerWithContinueOnErrorWhenCommitFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').exceptionOnInserts();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().afterInsertFor(AccountWriterWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithContinueOnError());

        // Verify
        Assert.isInstanceOfType(logger.errors[0].getException(), DmlException.class, 'The commit exception should be logged.');
    }

    @IsTest
    static void mockWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_INSERT', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithPlatformEvent() {
        // Setup
        EventCountingDispatcher dispatcher = new EventCountingDispatcher();

        TriggerOrchestrator.mock().afterInsertFor(EventCountingDispatcher.class).with(new BatchApexErrorEvent());

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(1, dispatcher.dispatchedEvents, 'The mocked event should be dispatched.');
    }

    @IsTest
    static void mockWithParent() {
        // Setup
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterInsertFor(AccountNameWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The mocked parent should be served.');
    }

    @IsTest
    static void mockWithParentWithoutRealQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterInsertFor(AccountNameWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNameWriter());

        // Verify
        Assert.areEqual(0, Limits.getQueries(), 'The mocked context should not query the org.');
    }

    @IsTest
    static void mockWithFakeId() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.isNotNull(doe.Id, 'The row should get a fake Id.');
    }

    private class OperationStamper implements AfterInsert.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getNewSObject().put(Contact.Description, 'AFTER_INSERT');
        }
    }

    private class EventCountingDispatcher implements AfterInsert.Dispatcher {
        public Integer dispatchedEvents = 0;

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return true;
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedEvents += records.size();
        }
    }

    private class AccountWriterWithBypassable extends AccountWriter implements AfterInsert.Bypassable {
        public Boolean bypassOnAfterInsertWhen() {
            return true;
        }
    }

    private class IdDispatcherWithBypassable extends IdDispatcher implements AfterInsert.Bypassable {
        public Boolean bypassOnAfterInsertWhen() {
            return true;
        }
    }

    private class BatchDispatcher implements AfterInsert.Dispatcher {
        public List<Set<Id>> dispatchedBatches = new List<Set<Id>>();

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }
    }

    private class IdDispatcherWithFinalizerSnapshot extends IdDispatcher implements AfterInsert.Finalizer {
        public List<Id> dispatchedIdsWhenFinalized;

        public void finalizeOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }
    }

    private class AccountWriterWithFinalizer extends AccountWriter implements AfterInsert.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private class IdDispatcherWithFinalizer extends IdDispatcher implements AfterInsert.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private virtual class FailingWriter implements AfterInsert.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }
    }

    private class FailingWriterWithContinueOnError extends FailingWriter implements AfterInsert.ContinueOnError {
    }

    private virtual class FailingDispatcher implements AfterInsert.Dispatcher {
        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            throw new TestException('The dispatcher failed.');
        }
    }

    private class FailingDispatcherWithContinueOnError extends FailingDispatcher implements AfterInsert.ContinueOnError {
    }

    private class RetryingWriterWithContinueOnError implements AfterInsert.Writer, AfterInsert.ContinueOnError {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new EventBus.RetryableException('The writer asked for a retry.');
        }
    }

    private class DmlAccountWriter implements AfterInsert.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            Database.setSavepoint();
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private virtual class AccountNameWriter implements AfterInsert.Writer, AfterInsert.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getNewParent(Contact.AccountId)?.get(Account.Name)));
        }
    }

    private class RelatedAccountProvider implements AfterInsert.RecordsProvider {
        public List<SObject> query(TriggerTypes.InsertRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNameWriter implements AfterInsert.Writer, AfterInsert.RelatedQuery {
        public Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert() {
            return new Map<String, AfterInsert.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(
                new Task(Subject = (String) record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name))
            );
        }
    }

    private class CommitCountingDispatcher implements AfterInsert.Dispatcher {
        public Integer committedAccounts;

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }
    }

    private virtual class AccountWriterWithOwnUnitOfWork extends AccountWriter implements AfterInsert.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnAfterInsert() {
            return new DML().identifier('ownUnit');
        }
    }

    private class AccountWriterWithOwnUnitOfWorkAndContinueOnError extends AccountWriterWithOwnUnitOfWork implements AfterInsert.ContinueOnError {
    }

    private class AccountWriterWithPrefilledOwnUnitOfWork extends AccountWriter implements AfterInsert.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnAfterInsert() {
            return new DML().toInsert(new Account(Name = 'Acme')).identifier('ownUnit');
        }
    }

    private class AccountWriterWithContinueOnError extends AccountWriter implements AfterInsert.ContinueOnError {
    }

    private class FailingAccountWriterWithContinueOnError implements AfterInsert.Writer, AfterInsert.ContinueOnError {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }
    }

    private class TestOrchestrator implements TriggerOrchestrator.AfterInsert {
        public List<AfterInsert.Handler> afterInsert = new List<AfterInsert.Handler>();

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.afterInsert;
        }
    }

    private virtual class AccountWriter implements AfterInsert.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private virtual class IdDispatcher implements AfterInsert.Dispatcher {
        public List<Id> dispatchedIds = new List<Id>();

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedIds.addAll(records.getIds());
        }
    }

    public class TestLogger implements TriggerOrchestrator.Logger {
        public List<TriggerOrchestrator.Error> errors = new List<TriggerOrchestrator.Error>();
        public Integer flushCalls = 0;

        public void log(TriggerOrchestrator.Error error) {
            this.errors.add(error);
        }

        public void flush() {
            this.flushCalls++;
        }
    }

    private class TestException extends Exception {
    }
}
