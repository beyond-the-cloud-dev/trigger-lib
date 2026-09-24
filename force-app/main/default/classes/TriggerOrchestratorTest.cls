/**
 * @description Tests for the TriggerOrchestrator class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.1
 *
 * PMD False Positives:
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE test class
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.ExcessiveClassLength,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true)
private class TriggerOrchestratorTest {
    @IsTest
    static void runOutsideTriggerContext() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.run(new TestOrchestrator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('Called outside of a trigger context.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'Only the before insert handlers should run.');
    }

    @IsTest
    static void afterInsertOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('AFTER_INSERT', doe.Description, 'Only the after insert handlers should run.');
    }

    @IsTest
    static void beforeUpdateOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('BEFORE_UPDATE', doe.Description, 'Only the before update handlers should run.');
    }

    @IsTest
    static void afterUpdateOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('AFTER_UPDATE', doe.Description, 'Only the after update handlers should run.');
    }

    @IsTest
    static void beforeDeleteOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('BEFORE_DELETE', doe.Description, 'Only the before delete handlers should run.');
    }

    @IsTest
    static void afterDeleteOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('AFTER_DELETE', doe.Description, 'Only the after delete handlers should run.');
    }

    @IsTest
    static void afterUndeleteOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        OperationStamper stamper = new OperationStamper();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(stamper);
        handlers.afterInsert.add(stamper);
        handlers.beforeUpdate.add(stamper);
        handlers.afterUpdate.add(stamper);
        handlers.beforeDelete.add(stamper);
        handlers.afterDelete.add(stamper);
        handlers.afterUndelete.add(stamper);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('AFTER_UNDELETE', doe.Description, 'Only the after undelete handlers should run.');
    }

    @IsTest
    static void nullOrchestrator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(null);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isNull(expectedException, 'The run should not throw an exception.');
    }

    @IsTest
    static void handlerOrderAcrossRoles() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());
        handlers.beforeInsert.add(new RejectedRecordPopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('Rejected', doe.Description, 'The validator should run before the populator declared after it.');
    }

    @IsTest
    static void handlerOrderAcrossRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        LastNameCollector collector = new LastNameCollector();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(collector);
        handlers.beforeInsert.add(collector);

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') });

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(new List<String>{ 'Doe', 'Roe', 'Doe', 'Roe' }, collector.lastNames, 'Each handler should process every record before the next handler starts.');
    }

    @IsTest
    static void fieldsPopulatedByEarlierHandler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());
        handlers.beforeInsert.add(new CeoDepartmentPopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('Management', doe.Department, 'The later populator should see the title set by the earlier one.');
    }

    @IsTest
    static void handlerWithoutRole() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new RolelessHandler());
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The handler without a role should be skipped.');
    }

    @IsTest
    static void qualifiedRecordsWhenRunTwice() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterInsertFor(IdDispatcher.class).with(doe);
        TriggerOrchestrator.mock().afterInsertFor(IdDispatcher.class).with(roe);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The second run should not process the records of the first run.');
    }

    @IsTest
    static void loggerFlush() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual(1, logger.flushCalls, 'The logger should be flushed once.');
    }

    @IsTest
    static void loggerFlushWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingPopulator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(1, logger.flushCalls, 'The logger should be flushed once.');
    }

    @IsTest
    static void loggerFlushWithNestedRun() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(new Contact(LastName = 'Roe'));
        TriggerOrchestrator.mock().beforeInsertFor(NestedRunPopulator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new NestedRunPopulator(new TestOrchestrator()));

        // Verify
        Assert.areEqual(1, logger.flushCalls, 'Only the outermost run should flush the logger.');
    }

    @IsTest
    static void loggerFlushWhenBypassed() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.bypass().all();

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual(0, logger.flushCalls, 'The logger should not be flushed.');
    }

    @IsTest
    static void loggerFromApexTypeImplementor() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor')
            .thenReturn(
                (ApexTypeImplementor) JSON.deserialize(
                    '{"attributes":{"type":"ApexTypeImplementor"},"ClassName":"TriggerOrchestratorTest.TestLogger","ClassNamespacePrefix":null}',
                    ApexTypeImplementor.class
                )
            );

        // Test
        TriggerOrchestrator.Logger resolvedLogger = TriggerOrchestrator.triggerLogger.logger;

        // Verify
        Assert.isInstanceOfType(resolvedLogger, TestLogger.class, 'The logger should be resolved from ApexTypeImplementor.');
    }

    @IsTest
    static void loggerWithMultipleImplementations() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor')
            .thenReturn(
                (List<ApexTypeImplementor>) JSON.deserialize(
                    '[{"attributes":{"type":"ApexTypeImplementor"},"ClassName":"FirstLogger","ClassNamespacePrefix":null},{"attributes":{"type":"ApexTypeImplementor"},"ClassName":"SecondLogger","ClassNamespacePrefix":null}]',
                    List<ApexTypeImplementor>.class
                )
            );

        Exception expectedException = null;

        // Test
        try {
            new TriggerOrchestrator(new TestOrchestrator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void configurationQueriesWhenRunTwice() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(new Contact(LastName = 'Doe'));
        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual(2, SOQL.getQueries(), 'The framework should query its configuration once per transaction.');
    }

    @IsTest
    static void logWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnError());

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'The swallowed failure should be logged.');
    }

    @IsTest
    static void logWhenNothingFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isTrue(logger.errors.isEmpty(), 'The logger should log nothing.');
    }

    @IsTest
    static void loggedErrorHandlerName() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('FailingPopulatorWithContinueOnError', logger.errors[0].getHandlerName(), 'The logged handler name should match the failing handler.');
    }

    @IsTest
    static void loggedErrorSObjectType() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnError());

        // Verify
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'The logged SObject type should match the trigger records.');
    }

    @IsTest
    static void loggedErrorException() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingPopulator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isTrue(logger.errors[0].getException() === expectedException, 'The logger should receive the thrown exception.');
    }

    @IsTest
    static void loggedErrorOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingPopulatorWithContinueOnError.class).with(doe, new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnError());

        // Verify
        Assert.areEqual(System.TriggerOperation.BEFORE_UPDATE, logger.errors[0].getOperation(), 'The logged operation should match the trigger operation.');
    }

    @IsTest
    static void loggedErrorRecordIds() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(FailingPopulatorWithContinueOnError.class)
            .with(new List<Contact>{ doe, roe }, new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') });

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnError());

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id, roe.Id }, logger.errors[0].getRecordIds(), 'The logged record Ids should include every trigger record.');
    }

    @IsTest
    static void loggedErrorRecordIdsOnBeforeInsert() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnError());

        // Verify
        Assert.isTrue(logger.errors[0].getRecordIds().isEmpty(), 'The logged record Ids should be empty.');
    }

    @IsTest
    static void unimplementedOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(new BeforeInsertOnlyOrchestrator());
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isNull(expectedException, 'The run should not throw an exception.');
    }

    @IsTest
    static void bypassSObject() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().sObject(Contact.SObjectType);

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassSObjectWhenObjectDoesNotMatch() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().sObject(Account.SObjectType);

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassAll() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().all();

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassClear() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().sObject(Contact.SObjectType);
        TriggerOrchestrator.bypass().clear();

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassOrchestratorWhenTypeDoesNotMatch() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().orchestrator(TriggerTypes.class);

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassHandlerWhenTypeDoesNotMatch() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().handler(AccountWriter.class);

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassChaining() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        TriggerOrchestrator.Bypassable chained = TriggerOrchestrator.bypass().sObject(Account.SObjectType).orchestrator(TriggerTypes.class).handler(TriggerTypes.class);

        // Verify
        Assert.isTrue(chained === TriggerOrchestrator.bypass(), 'The bypass methods should return the same instance.');
    }

    @IsTest
    static void bypassSObjectByMetadata() {
        // Setup
        TriggerObject__mdt contactSetting = new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassSObjectByMetadataWhenBypassIsOff() {
        // Setup
        TriggerObject__mdt contactSetting = new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = false);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassSObjectByMetadataWhenObjectDoesNotMatch() {
        // Setup
        TriggerObject__mdt accountSetting = new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ accountSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassSObjectByMetadataWithOldRecords() {
        // Setup
        TriggerObject__mdt contactSetting = new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcher.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.isTrue(dispatcher.dispatchedIds.isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void bypassSObjectByMetadataWithPaddedName() {
        // Setup
        TriggerObject__mdt contactSetting = new TriggerObject__mdt(ObjectAPIName__c = ' Contact ', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassSObjectByMetadataWithUpperCaseName() {
        // Setup
        TriggerObject__mdt contactSetting = new TriggerObject__mdt(ObjectAPIName__c = 'CONTACT', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassHandlerByMetadata() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt contactSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Contact',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => 'TitlePopulator',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassHandlerByMetadataWithOtherHandlers() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt contactSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Contact',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => 'DoeValidator',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassHandlerByMetadataWithQualifiedName() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt contactSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Contact',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => 'TriggerOrchestratorTest.TitlePopulator',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassHandlerByMetadataWhenObjectDoesNotMatch() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt accountSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Account',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => 'TitlePopulator',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ accountSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void bypassHandlerByMetadataWithBypassable() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt contactSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Contact',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => 'TitlePopulatorWithBypassCounter',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TitlePopulatorWithBypassCounter populator = new TitlePopulatorWithBypassCounter();

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithBypassCounter.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(populator);

        // Verify
        Assert.areEqual(0, populator.bypassChecks, 'The bypass should not be checked.');
    }

    @IsTest
    static void bypassHandlerByMetadataWithPaddedName() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt contactSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Contact',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => ' TitlePopulator ',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void bypassHandlerByMetadataWithUpperCaseName() {
        // Setup
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        TriggerObject__mdt contactSetting = (TriggerObject__mdt) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
                    String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => 'Contact',
                    String.valueOf(TriggerObject__mdt.Bypass__c) => false,
                    namespacePrefix + 'TriggerHandlers__r' => new Map<String, Object>{
                        'totalSize' => 1,
                        'done' => true,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                                String.valueOf(TriggerHandler__mdt.ApexClassName__c) => 'TITLEPOPULATOR',
                                String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                            }
                        }
                    }
                }
            ),
            TriggerObject__mdt.class
        );
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void finalizerAfterLastRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact janeDoe = new Contact(FirstName = 'Jane', LastName = 'Doe');
        Contact johnDoe = new Contact(FirstName = 'John', LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitleCopyingFinalizer.class).with(new List<Contact>{ janeDoe, johnDoe });

        // Test
        TriggerOrchestrator.runTestFor(new TitleCopyingFinalizer());

        // Verify
        Assert.areEqual('CEO', johnDoe.Description, 'The finalizer should run after the last record is processed.');
    }

    @IsTest
    static void finalizerBeforeNextHandler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitleCopyingFinalizer());
        handlers.beforeInsert.add(new DescriptionCopyingPopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('CEO', doe.Department, 'The next handler should see the finalized record.');
    }

    @IsTest
    static void loggerWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulator.class).with(new Contact(LastName = 'Doe'));

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingPopulator());
        } catch (TestException expected) {
        }

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'The failure should be logged once.');
    }

    @IsTest
    static void recursionDepthPerRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact janeDoe = new Contact(FirstName = 'Jane', LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulatorWithRecursionGuard.class).with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(LastName = 'Doe'));
        TriggerOrchestrator.mock()
            .beforeUpdateFor(TitlePopulatorWithRecursionGuard.class)
            .with(new List<Contact>{ doe, janeDoe }, new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(FirstName = 'Jane', LastName = 'Doe') });

        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRecursionGuard());

        // Verify
        Assert.areEqual('CEO', janeDoe.Title, 'The recursion depth should be tracked per record.');
    }

    @IsTest
    static void recursionDepthPerHandlerClass() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TriggerOrchestrator.mock().afterUpdateFor(AccountWriterWithRecursionGuard.class).with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(LastName = 'Doe'));
        TriggerOrchestrator.mock().afterUpdateFor(IdDispatcherWithRecursionGuard.class).with(doe, new Contact(LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(new AccountWriterWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(dispatcher);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The recursion depth should be tracked per handler class.');
    }

    @IsTest
    static void recursionDepthSharedByHandlerInstances() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithRecursionGuard());
        handlers.afterUpdate.add(new AccountWriterWithRecursionGuard());

        TriggerOrchestrator.mock().afterUpdateFor(TestOrchestrator.class).with(doe, new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The recursion depth should be shared by handler instances.');
    }

    @IsTest
    static void recursionDepthPerContext() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        DepthOneUpdateHandler depthOneHandler = new DepthOneUpdateHandler();

        TriggerOrchestrator.mock().beforeUpdateFor(DepthOneUpdateHandler.class).with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(LastName = 'Doe'));
        TriggerOrchestrator.mock().afterUpdateFor(DepthOneUpdateHandler.class).with(doe, new Contact(LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(depthOneHandler);

        // Test
        TriggerOrchestrator.runTestFor(depthOneHandler);

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, depthOneHandler.dispatchedIds, 'The recursion depth should be tracked per context.');
    }

    @IsTest
    static void parentQueryWithTwoHandlers() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme', Industry = 'Technology');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulator());
        handlers.beforeInsert.add(new AccountIndustryPopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(new Contact(LastName = 'Doe', AccountId = acme.Id));

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        TriggerOrchestrator.runTestFor(handlers);
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The accounts should be queried once.');
    }

    @IsTest
    static void parentFieldsWithTwoHandlers() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme', Industry = 'Technology');

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulator());
        handlers.beforeInsert.add(new AccountIndustryPopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(new List<String>{ 'Acme', 'Technology' }, new List<String>{ doe.Department, doe.Description }, 'The populators should read the fields of both handlers.');
    }

    @IsTest
    static void parentQueryWhenDeclaredByLaterHandler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new UndeclaredAccountNamePopulator());
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('Acme', doe.Description, 'The populator should copy the account name.');
    }

    @IsTest
    static void parentQueryWhenLookupIsEmpty() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(AccountNamePopulator.class).with(new Contact(LastName = 'Doe'));

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, queriesAfter - queriesBefore, 'The accounts should not be queried.');
    }

    @IsTest
    static void parentQueryWhenParentIsNotFound() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

        Contact doe = new Contact(LastName = 'Doe', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        TriggerOrchestrator.mock().beforeInsertFor(AccountNamePopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.isNull(doe.Department, 'The populator should not find the account.');
    }

    @IsTest
    static void priorParentQueryWithoutParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new PriorAccountNamePopulator());
        handlers.beforeUpdate.add(new UndeclaredAccountNamePopulator());

        TriggerOrchestrator.mock().beforeUpdateFor(TestOrchestrator.class).with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id)).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.isNull(doe.Description, 'The populator should not find the account.');
    }

    @IsTest
    static void parentQueryWhenLookupIsRepointedToQueriedParent() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        SOQL.mock(Account.SObjectType).thenReturn(new List<Account>{ acme, globex });

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountRepointingPopulator(globex.Id));
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator.mock()
            .beforeInsertFor(TestOrchestrator.class)
            .with(new List<Contact>{ new Contact(LastName = 'Doe', AccountId = acme.Id), new Contact(LastName = 'Roe', AccountId = globex.Id) });

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        TriggerOrchestrator.runTestFor(handlers);
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The accounts should be queried once.');
    }

    @IsTest
    static void parentQueryWhenLookupIsCleared() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountRepointingPopulator(null));
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.isNull(doe.Department, 'The populator should not find the account.');
    }

    @IsTest
    static void priorParentQueryWhenLookupIsRepointed() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        SOQL.mock(Account.SObjectType).thenReturn(globex);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new AccountRepointingPopulator(globex.Id));
        handlers.beforeUpdate.add(new PriorAccountNamePopulatorWithParentQuery());

        TriggerOrchestrator.mock().beforeUpdateFor(TestOrchestrator.class).with(doe, new Contact(LastName = 'Doe', AccountId = acme.Id));

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the prior account name.');
    }

    @IsTest
    static void relatedQueryWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        LastNameProvider provider = new LastNameProvider();

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithRelatedQuery.class).with(new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') });

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRelatedQuery(provider));

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe', 'Roe' }, provider.lastNames, 'The provider should receive every record.');
    }

    @IsTest
    static void relatedQueryWithNullProviders() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithNullRelatedQuery.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithNullRelatedQuery());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void relatedQueryWhenDeclaredByAnotherHandler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        SOQL.mock(Account.SObjectType).thenReturn(new List<Account>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new RelatedAccountNamePopulator());
        handlers.beforeInsert.add(new UndeclaredRelatedAccountNamePopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(handlers);
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'No related records provider named accounts is declared. Return it from the queryRelatedOn method of the handler first.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void relatedQueryWithParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

        ParentReadingProvider provider = new ParentReadingProvider();

        TriggerOrchestrator.mock()
            .beforeInsertFor(AccountNamePopulatorWithRelatedQuery.class)
            .with(new Contact(LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulatorWithRelatedQuery(provider));

        // Verify
        Assert.areEqual(new Set<String>{ 'Acme' }, provider.accountNames, 'The provider should read the account name.');
    }

    @IsTest
    static void relatedQueryWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingRelatedQueryPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingRelatedQueryPopulatorWithContinueOnError());

        // Verify
        Assert.areEqual('The related query failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void relatedQueryWithManyRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        TriggerOrchestrator.mock()
            .beforeInsertFor(RelatedAccountNamePopulator.class)
            .with(new List<Contact>{ new Contact(LastName = 'Doe', AccountId = acme.Id), new Contact(LastName = 'Roe', AccountId = acme.Id) });

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        TriggerOrchestrator.runTestFor(new RelatedAccountNamePopulator());
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The related accounts should be queried once.');
    }

    @IsTest
    static void qualificationWithRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(RelatedAccountTitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new RelatedAccountTitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should qualify by the related account.');
    }

    @IsTest
    static void unitOfWorkToInsertWithDmlRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(DmlRecordInsertWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DmlRecordInsertWriter(acme));

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should insert the account.');
    }

    @IsTest
    static void unitOfWorkToUpdate() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(AccountUpdateWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new AccountUpdateWriter(acme));

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should update the account.');
    }

    @IsTest
    static void unitOfWorkToUpdateWithDmlRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(DmlRecordUpdateWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DmlRecordUpdateWriter(acme));

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should update the account.');
    }

    @IsTest
    static void unitOfWorkToUpsert() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(AccountUpsertWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new AccountUpsertWriter(acme));

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').upsertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should upsert the account.');
    }

    @IsTest
    static void unitOfWorkToDelete() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(AccountDeleteWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new AccountDeleteWriter(acme));

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').deletesOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should delete the account.');
    }

    @IsTest
    static void unitOfWorkToPublish() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(EventPublishWriter.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new EventPublishWriter(new FlowOrchestrationEvent()));

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').eventsOf(FlowOrchestrationEvent.SObjectType).records().size(), 'The unit of work should publish the event.');
    }

    @IsTest
    static void sharedUnitOfWorkWithTwoWriters() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());
        handlers.afterInsert.add(new AccountWriter());

        TriggerOrchestrator.mock().afterInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(2, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The shared unit of work should commit both accounts.');
    }

    @IsTest
    static void sharedUnitOfWorkWhenTwoWritersUpdateSameRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Id acmeId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountUpdateWriter(new Account(Id = acmeId, Name = 'Acme')));
        handlers.afterInsert.add(new AccountUpdateWriter(new Account(Id = acmeId, Industry = 'Technology')));

        TriggerOrchestrator.mock().afterInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual(
            new List<SObject>{ new Account(Id = acmeId, Name = 'Acme', Industry = 'Technology') },
            DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records(),
            'The shared unit of work should merge both updates into one record.'
        );
    }

    @IsTest
    static void mockQueueTakesFirstContext() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe);
        TriggerOrchestrator.mock().afterInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The first mocked context should run.');
    }

    @IsTest
    static void mockQueueTakesNextContext() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe);
        TriggerOrchestrator.mock().afterInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_INSERT', doe.Description, 'The next mocked context should run.');
    }

    @IsTest
    static void mockQueueReplaysLastContext() {
        // Setup
        Account acme = new Account(Name = 'Acme', NumberOfEmployees = 0);

        TriggerOrchestrator.mock().beforeInsertFor(EmployeeCounter.class).with(acme);

        // Test
        TriggerOrchestrator.runTestFor(new EmployeeCounter());
        TriggerOrchestrator.runTestFor(new EmployeeCounter());

        // Verify
        Assert.areEqual(2, acme.NumberOfEmployees, 'The last mocked context should run again.');
    }

    @IsTest
    static void mockForOtherClass() {
        // Setup
        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new OperationStamper());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('No trigger context is mocked for OperationStamper.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void mockWithParentWithUndeclaredField() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme', Industry = 'Banking');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(UndeclaredIndustryPopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new UndeclaredIndustryPopulator());

        // Verify
        Assert.isNull(doe.Description, 'Only the declared parent fields should be served.');
    }

    @IsTest
    static void mockWithParentWithNestedField() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme', Owner = new User(LastName = 'Smith'));
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountOwnerPopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountOwnerPopulator());

        // Verify
        Assert.areEqual('Smith', doe.Description, 'The nested parent field should be served.');
    }

    @IsTest
    static void mockWithoutParent() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        TriggerOrchestrator.mock().beforeInsertFor(AccountNamePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.isNull(doe.Department, 'No parent should be served.');
    }

    @IsTest
    static void mockBeforeUpdateForUnimplementedContext() {
        // Setup
        TriggerOrchestrator.mock().beforeUpdateFor(CeoDepartmentPopulator.class).with(new Contact(LastName = 'Doe'), new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new CeoDepartmentPopulator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isInstanceOfType(expectedException, System.TypeException.class, 'The unimplemented context should fail.');
    }

    @IsTest
    static void mockAfterInsertForUnimplementedOrchestratorContext() {
        // Setup
        TriggerOrchestrator.mock().afterInsertFor(BeforeInsertOnlyOrchestrator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new BeforeInsertOnlyOrchestrator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isInstanceOfType(expectedException, System.TypeException.class, 'The unimplemented context should fail.');
    }

    private class OperationStamper implements BeforeInsert.Populator, AfterInsert.Writer, BeforeUpdate.Populator, AfterUpdate.Writer, BeforeDelete.Writer, AfterDelete.Writer, AfterUndelete.Writer {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.getNewSObject().put(Contact.Description, 'BEFORE_INSERT');
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getNewSObject().put(Contact.Description, 'AFTER_INSERT');
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.getNewSObject().put(Contact.Description, 'BEFORE_UPDATE');
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getNewSObject().put(Contact.Description, 'AFTER_UPDATE');
        }

        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getOldSObject().put(Contact.Description, 'BEFORE_DELETE');
        }

        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getOldSObject().put(Contact.Description, 'AFTER_DELETE');
        }

        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getNewSObject().put(Contact.Description, 'AFTER_UNDELETE');
        }
    }

    private class RejectedRecordPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.getNewSObject().hasErrors();
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Description, 'Rejected');
        }
    }

    private class LastNameCollector implements BeforeInsert.Populator {
        public List<String> lastNames = new List<String>();

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            this.lastNames.add((String) record.getNewSObject().get(Contact.LastName));
        }
    }

    private class CeoDepartmentPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.Title, 'CEO');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, 'Management');
        }
    }

    private class RolelessHandler implements BeforeInsert.Handler {
    }

    private class NestedRunPopulator implements BeforeInsert.Populator {
        private Object nestedOrchestrator;

        public NestedRunPopulator(Object nestedOrchestrator) {
            this.nestedOrchestrator = nestedOrchestrator;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            TriggerOrchestrator.runTestFor(this.nestedOrchestrator);
        }
    }

    private class BeforeInsertOnlyOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return new List<BeforeInsert.Handler>();
        }
    }

    private class TitlePopulatorWithBypassCounter extends TitlePopulator implements BeforeInsert.Bypassable {
        public Integer bypassChecks = 0;

        public Boolean bypassOnBeforeInsertWhen() {
            this.bypassChecks++;
            return false;
        }
    }

    private class TitleCopyingFinalizer extends TitlePopulator implements BeforeInsert.Finalizer {
        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            for (TriggerTypes.InsertRecord record : records.getRecords()) {
                record.put(Contact.Description, record.getNewSObject().get(Contact.Title));
            }
        }
    }

    private class DescriptionCopyingPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getNewSObject().get(Contact.Description));
        }
    }

    private class TitlePopulatorWithRecursionGuard extends TitlePopulator implements BeforeUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnBeforeUpdate() {
            return 1;
        }
    }

    private class AccountWriterWithRecursionGuard extends AccountWriter implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private class IdDispatcherWithRecursionGuard extends IdDispatcher implements AfterUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private class DepthOneUpdateHandler implements BeforeUpdate.Populator, BeforeUpdate.RecursionGuard, AfterUpdate.Dispatcher, AfterUpdate.RecursionGuard {
        public List<Id> dispatchedIds = new List<Id>();

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Title, 'CEO');
        }

        public Integer maxRunsPerRecordOnBeforeUpdate() {
            return 1;
        }

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.dispatchedIds.addAll(records.getIds());
        }

        public Integer maxRunsPerRecordOnAfterUpdate() {
            return 1;
        }
    }

    private virtual class PriorAccountNamePopulator implements BeforeUpdate.Populator, BeforeUpdate.PriorParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Department, record.getOldParent('Account')?.get(Account.Name));
        }
    }

    private class PriorAccountNamePopulatorWithParentQuery extends PriorAccountNamePopulator implements BeforeUpdate.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }
    }

    private class UndeclaredAccountNamePopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Description, record.getNewParent('Account')?.get(Account.Name));
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Description, record.getNewParent('Account')?.get(Account.Name));
        }
    }

    private class AccountIndustryPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Industry) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Description, record.getNewParent('Account')?.get(Account.Industry));
        }
    }

    private class AccountRepointingPopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
        private Id accountId;

        public AccountRepointingPopulator(Id accountId) {
            this.accountId = accountId;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.AccountId, this.accountId);
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.AccountId, this.accountId);
        }
    }

    private class RelatedAccountProvider implements BeforeInsert.RecordsProvider, AfterInsert.RecordsProvider, BeforeUpdate.RecordsProvider, AfterUpdate.RecordsProvider, BeforeDelete.RecordsProvider, AfterDelete.RecordsProvider, AfterUndelete.RecordsProvider {
        public List<SObject> query(TriggerTypes.InsertRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public List<SObject> query(TriggerTypes.DeleteRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public List<SObject> query(TriggerTypes.UndeleteRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNamePopulator implements BeforeInsert.Populator, BeforeInsert.RelatedQuery, BeforeUpdate.Populator, BeforeUpdate.RelatedQuery {
        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name));
        }

        public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
            return new Map<String, BeforeUpdate.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Department, record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name));
        }
    }

    private class UndeclaredRelatedAccountNamePopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name));
        }
    }

    private class RelatedAccountTitlePopulator implements BeforeInsert.Populator, BeforeInsert.RelatedQuery {
        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId)) != null;
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private class LastNameProvider implements BeforeInsert.RecordsProvider {
        public Set<String> lastNames;

        public List<SObject> query(TriggerTypes.InsertRecords records) {
            this.lastNames = records.getValuesOf(Contact.LastName);
            return new List<Account>();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class ParentReadingProvider implements BeforeInsert.RecordsProvider {
        public Set<String> accountNames;

        public List<SObject> query(TriggerTypes.InsertRecords records) {
            this.accountNames = records.getValuesOf('Account', Account.Name);
            return new List<Account>();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class TitlePopulatorWithRelatedQuery extends TitlePopulator implements BeforeInsert.RelatedQuery {
        private BeforeInsert.RecordsProvider provider;

        public TitlePopulatorWithRelatedQuery(BeforeInsert.RecordsProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'lastNames' => this.provider };
        }
    }

    private class TitlePopulatorWithNullRelatedQuery extends TitlePopulator implements BeforeInsert.RelatedQuery {
        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return null;
        }
    }

    private class AccountNamePopulatorWithRelatedQuery extends AccountNamePopulator implements BeforeInsert.RelatedQuery {
        private BeforeInsert.RecordsProvider provider;

        public AccountNamePopulatorWithRelatedQuery(BeforeInsert.RecordsProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'accountNames' => this.provider };
        }
    }

    private class FailingRelatedQueryPopulatorWithContinueOnError extends TitlePopulator implements BeforeInsert.RelatedQuery, BeforeInsert.ContinueOnError {
        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            throw new TestException('The related query failed.');
        }
    }

    private class DmlRecordInsertWriter implements AfterInsert.Writer {
        private Account accountToInsert;

        public DmlRecordInsertWriter(Account accountToInsert) {
            this.accountToInsert = accountToInsert;
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(DML.Record(this.accountToInsert));
        }
    }

    private class AccountUpdateWriter implements AfterInsert.Writer {
        private Account accountToUpdate;

        public AccountUpdateWriter(Account accountToUpdate) {
            this.accountToUpdate = accountToUpdate;
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toUpdate(this.accountToUpdate);
        }
    }

    private class DmlRecordUpdateWriter implements AfterInsert.Writer {
        private Account accountToUpdate;

        public DmlRecordUpdateWriter(Account accountToUpdate) {
            this.accountToUpdate = accountToUpdate;
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toUpdate(DML.Record(this.accountToUpdate));
        }
    }

    private class AccountUpsertWriter implements AfterInsert.Writer {
        private Account accountToUpsert;

        public AccountUpsertWriter(Account accountToUpsert) {
            this.accountToUpsert = accountToUpsert;
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toUpsert(this.accountToUpsert, Account.Id);
        }
    }

    private class AccountDeleteWriter implements AfterInsert.Writer {
        private Account accountToDelete;

        public AccountDeleteWriter(Account accountToDelete) {
            this.accountToDelete = accountToDelete;
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toDelete(this.accountToDelete);
        }
    }

    private class EventPublishWriter implements AfterInsert.Writer {
        private SObject eventToPublish;

        public EventPublishWriter(SObject eventToPublish) {
            this.eventToPublish = eventToPublish;
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toPublish(this.eventToPublish);
        }
    }

    private class UndeclaredIndustryPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Description, record.getNewParent('Account')?.get(Account.Industry));
        }
    }

    private class AccountOwnerPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with('Owner', User.LastName) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Description, record.getNewParent('Account')?.getSObject('Owner')?.get(User.LastName));
        }
    }

    private class EmployeeCounter implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Account.NumberOfEmployees, ((Account) record.getNewSObject()).NumberOfEmployees + 1);
        }
    }

    private class TestOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.BeforeDelete, TriggerOrchestrator.AfterDelete, TriggerOrchestrator.AfterUndelete {
        public List<BeforeInsert.Handler> beforeInsert = new List<BeforeInsert.Handler>();
        public List<AfterInsert.Handler> afterInsert = new List<AfterInsert.Handler>();
        public List<BeforeUpdate.Handler> beforeUpdate = new List<BeforeUpdate.Handler>();
        public List<AfterUpdate.Handler> afterUpdate = new List<AfterUpdate.Handler>();
        public List<BeforeDelete.Handler> beforeDelete = new List<BeforeDelete.Handler>();
        public List<AfterDelete.Handler> afterDelete = new List<AfterDelete.Handler>();
        public List<AfterUndelete.Handler> afterUndelete = new List<AfterUndelete.Handler>();

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.beforeInsert;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.afterInsert;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.beforeUpdate;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.afterUpdate;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.beforeDelete;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.afterDelete;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.afterUndelete;
        }
    }

    private virtual class TitlePopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Title, 'CEO');
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private virtual class DoeValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            record.addError('Doe is not allowed.');
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            record.addError('Doe is not allowed.');
        }
    }

    private virtual class AccountWriter implements AfterInsert.Writer, AfterUpdate.Writer, BeforeDelete.Writer, AfterDelete.Writer, AfterUndelete.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }

        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
        }

        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
        }

        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private virtual class IdDispatcher implements AfterInsert.Dispatcher, AfterUpdate.Dispatcher, AfterDelete.Dispatcher, AfterUndelete.Dispatcher {
        public List<Id> dispatchedIds = new List<Id>();

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedIds.addAll(records.getIds());
        }

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.dispatchedIds.addAll(records.getIds());
        }

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.dispatchedIds.addAll(records.getIds());
        }

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.dispatchedIds.addAll(records.getIds());
        }
    }

    private virtual class AccountNamePopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery, BeforeUpdate.Populator, BeforeUpdate.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getNewParent('Account')?.get(Account.Name));
        }

        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Department, record.getNewParent('Account')?.get(Account.Name));
        }
    }

    private virtual class FailingPopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            throw new TestException('The populator failed.');
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            throw new TestException('The populator failed.');
        }
    }

    private class FailingPopulatorWithContinueOnError extends FailingPopulator implements BeforeInsert.ContinueOnError, BeforeUpdate.ContinueOnError {
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
