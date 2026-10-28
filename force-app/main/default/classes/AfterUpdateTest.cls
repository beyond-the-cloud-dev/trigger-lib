/**
 * @description Tests for the AfterUpdate context of the TriggerOrchestrator class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.4.0
 *
 * PMD False Positives:
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE test class
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.ExcessiveClassLength,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true testFor='ApexClass:AfterUpdate, ApexClass:TriggerOrchestrator')
private class AfterUpdateTest {
    @IsTest
    static void writerWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithBypassable.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithBypassable.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock()
            .afterUpdateFor(IdDispatcher.class)
            .with(new List<Contact>{ doe, roe }, new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') });

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TriggerOrchestrator.mock().afterUpdateFor(BatchDispatcher.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact johnDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'John', LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TriggerOrchestrator.mock()
            .afterUpdateFor(BatchDispatcher.class)
            .with(
                new List<Contact>{ johnDoe, janeDoe },
                new List<Contact>{ new Contact(Id = johnDoe.Id, FirstName = 'John', LastName = 'Doe'), new Contact(Id = janeDoe.Id, FirstName = 'Jane', LastName = 'Doe') }
            );

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithFinalizerSnapshot dispatcher = new IdDispatcherWithFinalizerSnapshot();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithFinalizerSnapshot.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TriggerOrchestrator.mock()
            .afterUpdateFor(AccountWriterWithFinalizer.class)
            .with(new List<Contact>{ doe, roe }, new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') });

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TriggerOrchestrator.mock()
            .afterUpdateFor(IdDispatcherWithFinalizer.class)
            .with(new List<Contact>{ doe, roe }, new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') });

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithFinalizer.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithFinalizer.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(FailingWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(FailingDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(FailingWriterWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(FailingDispatcherWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingDispatcherWithContinueOnError());

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void writerWithDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriter());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual(4, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should run beyond the default recursion depth.');
    }

    @IsTest
    static void writerWithLoggerWhenDefaultRecursionDepthIsReached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriter());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual(
            'AccountWriter reached the recursion depth of 3 on record ' + doe.Id + ' in after update.',
            logger.errors[0].getException().getMessage(),
            'The logged exception message should match the expected one.'
        );
    }

    @IsTest
    static void writerWithLoggerWithinDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 2; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriter());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.isTrue(logger.errors.isEmpty(), 'Nothing should be logged within the recursion depth.');
    }

    @IsTest
    static void writerWithLoggerWhenRecordAtDefaultDepthDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = doe.Id, LastName = 'Doe'));
        }

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriter.class).with(new Contact(Id = doe.Id, LastName = 'Roe'), new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriter());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'The record should be logged when it comes back at the recursion depth.');
    }

    @IsTest
    static void writerWithLoggerWhenDefaultRecursionDepthIsReachedForTwoRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        TriggerOrchestrator.mock()
            .afterUpdateFor(AccountWriter.class)
            .with(
                new List<Contact>{ doe, janeDoe },
                new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = janeDoe.Id, FirstName = 'Jane', LastName = 'Doe') }
            );

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriter());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual(2, logger.errors.size(), 'Each record at the recursion depth should be logged.');
    }

    @IsTest
    static void dispatcherWithDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(dispatcher);
        }

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(4, dispatcher.dispatchedIds.size(), 'The dispatcher should run beyond the default recursion depth.');
    }

    @IsTest
    static void dispatcherWithLoggerWhenDefaultRecursionDepthIsReached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(dispatcher);
        }

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(
            'IdDispatcher reached the recursion depth of 3 on record ' + doe.Id + ' in after update.',
            logger.errors[0].getException().getMessage(),
            'The logged exception message should match the expected one.'
        );
    }

    @IsTest
    static void writerWithRecursionGuard() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not run beyond its recursion depth.');
    }

    @IsTest
    static void writerWithLoggerWhenRecursionGuardDepthIsReached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Verify
        Assert.areEqual(
            'AccountWriterWithRecursionGuard reached the recursion depth of 1 on record ' + doe.Id + ' in after update.',
            logger.errors[0].getException().getMessage(),
            'The logged exception message should match the expected one.'
        );
    }

    @IsTest
    static void writerWithRecursionGuardOfTwo() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuardOfTwo.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 2; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfTwo());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfTwo());

        // Verify
        Assert.areEqual(2, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not run beyond its recursion depth.');
    }

    @IsTest
    static void writerWithRecursionGuardOfNull() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuardOfNull.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfNull());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfNull());

        // Verify
        Assert.areEqual(4, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should run without a recursion depth.');
    }

    @IsTest
    static void writerWithLoggerAndRecursionGuardOfNull() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuardOfNull.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfNull());
        }

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfNull());

        // Verify
        Assert.isTrue(logger.errors.isEmpty(), 'Nothing should be logged without a recursion depth.');
    }

    @IsTest
    static void writerWithRecursionGuardOfZero() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuardOfZero.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuardOfZero());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should skip every record.');
    }

    @IsTest
    static void dispatcherWithRecursionGuard() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(dispatcher);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(1, dispatcher.dispatchedIds.size(), 'The dispatcher should not run beyond its recursion depth.');
    }

    @IsTest
    static void dispatcherWithLoggerWhenRecursionGuardDepthIsReached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(dispatcher);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(
            'IdDispatcherWithRecursionGuard reached the recursion depth of 1 on record ' + doe.Id + ' in after update.',
            logger.errors[0].getException().getMessage(),
            'The logged exception message should match the expected one.'
        );
    }

    @IsTest
    static void writerQualificationWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        QualificationCountingWriterWithRecursionGuard writer = new QualificationCountingWriterWithRecursionGuard();

        TriggerOrchestrator.mock().afterUpdateFor(QualificationCountingWriterWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(writer);

        // Test
        TriggerOrchestrator.runTestFor(writer);

        // Verify
        Assert.areEqual(1, writer.qualificationCalls, 'The qualification should not be asked beyond the recursion depth.');
    }

    @IsTest
    static void dispatcherQualificationWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        QualificationCountingDispatcherWithRecursionGuard dispatcher = new QualificationCountingDispatcherWithRecursionGuard();

        TriggerOrchestrator.mock().afterUpdateFor(QualificationCountingDispatcherWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(dispatcher);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(1, dispatcher.qualificationCalls, 'The qualification should not be asked beyond the recursion depth.');
    }

    @IsTest
    static void writerWithRecursionGuardWhenEarlierRunDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock()
            .afterUpdateFor(AccountWriterWithRecursionGuard.class)
            .with(new Contact(Id = doe.Id, LastName = 'Roe'), new Contact(Id = doe.Id, LastName = 'Roe'));
        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should register the account.');
    }

    @IsTest
    static void dispatcherWithRecursionGuardWhenEarlierRunDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TriggerOrchestrator.mock()
            .afterUpdateFor(IdDispatcherWithRecursionGuard.class)
            .with(new Contact(Id = doe.Id, LastName = 'Roe'), new Contact(Id = doe.Id, LastName = 'Roe'));
        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(dispatcher);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void finalizerWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        FinalizeCountingWriterWithRecursionGuard writer = new FinalizeCountingWriterWithRecursionGuard();

        TriggerOrchestrator.mock().afterUpdateFor(FinalizeCountingWriterWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(writer);

        // Test
        TriggerOrchestrator.runTestFor(writer);

        // Verify
        Assert.areEqual(1, writer.finalizeCalls, 'The finalizer should not run beyond the recursion depth.');
    }

    @IsTest
    static void writerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(DmlAccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlAccountWriter());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'DmlAccountWriter performed DML in writeOnAfterUpdateWhen or writeOnAfterUpdate. Register that work in the unit of work.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void dispatcherWhenQualificationPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(DmlQualificationDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlQualificationDispatcher());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'DmlQualificationDispatcher performed DML in dispatchOnAfterUpdateWhen. Move that work to an after update Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void writerWhenFinalizerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithDmlFinalizer.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithDmlFinalizer());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The Finalizer should be allowed to run DML.');
    }

    @IsTest
    static void dispatcherWhenDispatchPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        DmlDispatcher dispatcher = new DmlDispatcher();

        TriggerOrchestrator.mock().afterUpdateFor(DmlDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(1, dispatcher.dispatchedIds.size(), 'The dispatcher should be allowed to run DML.');
    }

    @IsTest
    static void writerWhenHandlerPerformsSoql() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(SoqlAccountWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new SoqlAccountWriter());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'SoqlAccountWriter performed SOQL in writeOnAfterUpdateWhen or writeOnAfterUpdate. Move that query to a ParentQuery, a PriorParentQuery or a RelatedQuery.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void dispatcherWhenQualificationPerformsSoql() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(SoqlQualificationDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new SoqlQualificationDispatcher());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'SoqlQualificationDispatcher performed SOQL in dispatchOnAfterUpdateWhen. Move that query to a ParentQuery, a PriorParentQuery or a RelatedQuery.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void writerWhenFinalizerPerformsSoql() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        AccountWriterWithSoqlFinalizer writer = new AccountWriterWithSoqlFinalizer();

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithSoqlFinalizer.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(writer);

        // Verify
        Assert.areEqual(0, writer.accounts, 'The finalizer should be allowed to query.');
    }

    @IsTest
    static void dispatcherWhenDispatchPerformsSoql() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        SoqlDispatcher dispatcher = new SoqlDispatcher();

        TriggerOrchestrator.mock().afterUpdateFor(SoqlDispatcher.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(0, dispatcher.accounts, 'The dispatcher should be allowed to query.');
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

        TriggerOrchestrator.mock().afterUpdateFor(AccountNameWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the account name.');
    }

    @IsTest
    static void priorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock()
            .afterUpdateFor(PriorAccountNameWriter.class)
            .with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new PriorAccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the prior account name.');
    }

    @IsTest
    static void priorParentQueryWithParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock('SavedTriggerRecords').thenReturn(new Contact(Id = doe.Id, Account = acme));

        TriggerOrchestrator.mock().afterUpdateFor(AccountNameWriterWithPriorParentQuery.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id));

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        TriggerOrchestrator.runTestFor(new AccountNameWriterWithPriorParentQuery());
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The prior account should come from the saved records.');
    }

    @IsTest
    static void relatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterUpdateFor(RelatedAccountNameWriter.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriter());
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator.mock().afterUpdateFor(TestOrchestrator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithOwnUnitOfWork.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithContinueOnError());
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator.mock().afterUpdateFor(TestOrchestrator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(FailingAccountWriterWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingAccountWriterWithContinueOnError());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void mockWithPair() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(OperationStamper.class).with(doe, new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_UPDATE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithParent() {
        // Setup
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterUpdateFor(AccountNameWriter.class).with(doe, new Contact(LastName = 'Doe')).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The mocked parent should be served.');
    }

    private class OperationStamper implements AfterUpdate.Writer {
        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getNewSObject().put(Contact.Description, 'AFTER_UPDATE');
        }
    }

    private class AccountWriterWithBypassable extends AccountWriter implements AfterUpdate.Bypassable {
        public Boolean bypassOnAfterUpdateWhen() {
            return true;
        }
    }

    private class IdDispatcherWithBypassable extends IdDispatcher implements AfterUpdate.Bypassable {
        public Boolean bypassOnAfterUpdateWhen() {
            return true;
        }
    }

    private class BatchDispatcher implements AfterUpdate.Dispatcher {
        public List<Set<Id>> dispatchedBatches = new List<Set<Id>>();

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }
    }

    private class IdDispatcherWithFinalizerSnapshot extends IdDispatcher implements AfterUpdate.Finalizer {
        public List<Id> dispatchedIdsWhenFinalized;

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }
    }

    private class AccountWriterWithFinalizer extends AccountWriter implements AfterUpdate.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private class IdDispatcherWithFinalizer extends IdDispatcher implements AfterUpdate.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private virtual class FailingWriter implements AfterUpdate.Writer {
        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }
    }

    private class FailingWriterWithContinueOnError extends FailingWriter implements AfterUpdate.ContinueOnError {
    }

    private virtual class FailingDispatcher implements AfterUpdate.Dispatcher {
        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            throw new TestException('The dispatcher failed.');
        }
    }

    private class FailingDispatcherWithContinueOnError extends FailingDispatcher implements AfterUpdate.ContinueOnError {
    }

    private class AccountWriterWithRecursionGuard extends AccountWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private class AccountWriterWithRecursionGuardOfTwo extends AccountWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 2;
        }
    }

    private class AccountWriterWithRecursionGuardOfNull extends AccountWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return null;
        }
    }

    private class AccountWriterWithRecursionGuardOfZero extends AccountWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 0;
        }
    }

    private class IdDispatcherWithRecursionGuard extends IdDispatcher implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private virtual class QualificationCountingWriter implements AfterUpdate.Writer {
        public Integer qualificationCalls = 0;

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            this.qualificationCalls++;
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private class QualificationCountingWriterWithRecursionGuard extends QualificationCountingWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private virtual class QualificationCountingDispatcher implements AfterUpdate.Dispatcher {
        public Integer qualificationCalls = 0;

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            this.qualificationCalls++;
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
        }
    }

    private class QualificationCountingDispatcherWithRecursionGuard extends QualificationCountingDispatcher implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private virtual class FinalizeCountingWriter extends AccountWriter implements AfterUpdate.Finalizer {
        public Integer finalizeCalls = 0;

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizeCalls++;
        }
    }

    private class FinalizeCountingWriterWithRecursionGuard extends FinalizeCountingWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private class DmlAccountWriter implements AfterUpdate.Writer {
        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            Database.setSavepoint();
            unitOfWork.toInsert(new Account(Name = 'Doe'));
        }
    }

    private class AccountWriterWithDmlFinalizer extends AccountWriter implements AfterUpdate.Finalizer {
        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            Database.setSavepoint();
        }
    }

    private class DmlQualificationDispatcher implements AfterUpdate.Dispatcher {
        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            Database.setSavepoint();
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
        }
    }

    private class DmlDispatcher implements AfterUpdate.Dispatcher {
        public Set<Id> dispatchedIds;

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            Database.setSavepoint();
            this.dispatchedIds = records.getIds();
        }
    }

    private class SoqlAccountWriter implements AfterUpdate.Writer {
        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = 'Accounts: ' + [SELECT COUNT() FROM Account]));
        }
    }

    private class SoqlQualificationDispatcher implements AfterUpdate.Dispatcher {
        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return [SELECT COUNT() FROM Account] == 0;
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
        }
    }

    private class SoqlDispatcher implements AfterUpdate.Dispatcher {
        public Integer accounts;

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.accounts = [SELECT COUNT() FROM Account];
        }
    }

    private class AccountWriterWithSoqlFinalizer extends AccountWriter implements AfterUpdate.Finalizer {
        public Integer accounts;

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.accounts = [SELECT COUNT() FROM Account];
        }
    }

    private virtual class AccountNameWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getNewParent(Contact.AccountId)?.get(Account.Name)));
        }
    }

    private class AccountNameWriterWithPriorParentQuery extends AccountNameWriter implements AfterUpdate.PriorParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }
    }

    private class PriorAccountNameWriter implements AfterUpdate.Writer, AfterUpdate.PriorParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getOldParent(Contact.AccountId)?.get(Account.Name)));
        }
    }

    private class RelatedAccountProvider implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNameWriter implements AfterUpdate.Writer, AfterUpdate.RelatedQuery {
        public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
            return new Map<String, AfterUpdate.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(
                new Task(Subject = (String) record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name))
            );
        }
    }

    private class CommitCountingDispatcher implements AfterUpdate.Dispatcher {
        public Integer committedAccounts;

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }
    }

    private virtual class AccountWriterWithOwnUnitOfWork extends AccountWriter implements AfterUpdate.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnAfterUpdate() {
            return new DML().identifier('ownUnit');
        }
    }

    private class AccountWriterWithContinueOnError extends AccountWriter implements AfterUpdate.ContinueOnError {
    }

    private class FailingAccountWriterWithContinueOnError implements AfterUpdate.Writer, AfterUpdate.ContinueOnError {
        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }
    }

    private class TestOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<AfterUpdate.Handler> afterUpdate = new List<AfterUpdate.Handler>();

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.afterUpdate;
        }
    }

    private virtual class AccountWriter implements AfterUpdate.Writer {
        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private virtual class IdDispatcher implements AfterUpdate.Dispatcher {
        public List<Id> dispatchedIds = new List<Id>();

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
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
