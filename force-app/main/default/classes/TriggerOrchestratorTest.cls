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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The handler without a role should be skipped.');
    }

    @IsTest
    static void qualifiedRecordsWhenRunTwice() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator firstRun = new TriggerOrchestrator(handlers);
        firstRun.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        firstRun.context.newRecords = new List<Contact>{ doe };

        TriggerOrchestrator secondRun = new TriggerOrchestrator(handlers);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        secondRun.context.newRecords = new List<Contact>{ roe };

        // Test
        firstRun.run();
        secondRun.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(1, logger.flushCalls, 'The logger should be flushed once.');
    }

    @IsTest
    static void loggerFlushWithNestedRun() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator nestedOrchestrator = new TriggerOrchestrator(new TestOrchestrator());
        nestedOrchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        nestedOrchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Roe') };

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new NestedRunPopulator(nestedOrchestrator));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator firstRun = new TriggerOrchestrator(handlers);
        firstRun.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        firstRun.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        TriggerOrchestrator secondRun = new TriggerOrchestrator(handlers);
        secondRun.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        secondRun.context.newRecords = new List<Contact>{ new Contact(LastName = 'Roe') };

        // Test
        firstRun.run();
        secondRun.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.isTrue(logger.errors[0].getException() === expectedException, 'The logger should receive the thrown exception.');
    }

    @IsTest
    static void loggedErrorOperation() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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
    static void beforeInsertPopulatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

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
    static void beforeInsertValidatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should reject the record.');
    }

    @IsTest
    static void afterInsertWriterWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterInsertDispatcherWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void beforeUpdateValidatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should reject the record.');
    }

    @IsTest
    static void afterUpdateWriterWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterUpdateDispatcherWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void beforeDeleteHandlerWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new DeletionBlocker());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void afterDeleteWriterWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterDeleteDispatcherWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void afterUndeleteWriterWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void bypassSObject() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().sObject(Contact.SObjectType);

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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
    static void bypassAll() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.bypass().all();

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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
    static void bypassSObjectByMetadataWhenObjectDoesNotMatch() {
        // Setup
        TriggerObject__mdt accountSetting = new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ accountSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

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
    static void bypassSObjectByMetadataWithOldRecords() {
        // Setup
        TriggerObject__mdt contactSetting = new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = true);
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ contactSetting });
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(populator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void beforeInsertPopulatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void beforeInsertPopulatorWithBypassableWhenBypassIsOff() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorWithBypassableOff());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void beforeInsertPopulatorWithBypassableWhenManyRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TitlePopulatorWithBypassCounter populator = new TitlePopulatorWithBypassCounter();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(populator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, populator.bypassChecks, 'The bypass should be checked once per run.');
    }

    @IsTest
    static void beforeInsertParentQueryWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulatorWithBypassable());
        handlers.beforeInsert.add(new AccountNamePopulatorWithoutParentQuery());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Department, 'The parent should not be queried.');
    }

    @IsTest
    static void beforeInsertValidatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidatorWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(doe.getErrors().isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void afterInsertWriterWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The handler should not run.');
    }

    @IsTest
    static void afterInsertDispatcherWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(dispatcher.dispatchedIds.isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulatorWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void beforeUpdateValidatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeValidatorWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(doe.getErrors().isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void afterUpdateWriterWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The handler should not run.');
    }

    @IsTest
    static void afterUpdateDispatcherWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(dispatcher.dispatchedIds.isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void beforeDeleteHandlerWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new DeletionBlockerWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(doe.getErrors().isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void afterDeleteWriterWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriterWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The handler should not run.');
    }

    @IsTest
    static void afterDeleteDispatcherWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(dispatcher.dispatchedIds.isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void afterUndeleteWriterWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriterWithBypassable());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The handler should not run.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(dispatcher.dispatchedIds.isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void beforeInsertPopulator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

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
    static void beforeInsertPopulatorWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(roe.Title, 'The populator should not set the title.');
    }

    @IsTest
    static void beforeInsertValidator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should reject the record.');
    }

    @IsTest
    static void beforeInsertValidatorWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(roe.getErrors().isEmpty(), 'The validator should not reject the record.');
    }

    @IsTest
    static void beforeInsertValidatorWithFieldError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeFieldValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<String>{ 'Email' }, doe.getErrors()[0].getFields(), 'The error should be attached to the field.');
    }

    @IsTest
    static void beforeInsertValidatorWithRecordError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(doe.getErrors()[0].getFields().isEmpty(), 'The error should not be attached to a field.');
    }

    @IsTest
    static void beforeInsertValidatorWithTwoErrors() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DoubleDoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(2, doe.getErrors().size(), 'Both errors should be attached.');
    }

    @IsTest
    static void beforeInsertValidatorWhenNoErrorIsAttached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new SilentValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'SilentValidator qualified a record in addErrorOnBeforeInsertWhen but attached no error in addErrorOnBeforeInsert.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void afterInsertWriter() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterInsertWriterWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not register an account.');
    }

    @IsTest
    static void afterInsertDispatcher() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void afterInsertDispatcherWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.dispatchedBatches.size(), 'The dispatcher should not be called.');
    }

    @IsTest
    static void afterInsertDispatcherWithMultipleRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact johnDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'John', LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ johnDoe, janeDoe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Set<Id>>{ new Set<Id>{ johnDoe.Id, janeDoe.Id } }, dispatcher.dispatchedBatches, 'The dispatcher should receive all records in one call.');
    }

    @IsTest
    static void afterInsertDispatcherBeforeFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithFinalizerSnapshot dispatcher = new IdDispatcherWithFinalizerSnapshot();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIdsWhenFinalized, 'The dispatcher should dispatch before it finalizes.');
    }

    @IsTest
    static void beforeUpdatePopulator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void beforeUpdatePopulatorWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(roe.Title, 'The populator should not set the title.');
    }

    @IsTest
    static void beforeUpdateValidator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should reject the record.');
    }

    @IsTest
    static void beforeUpdateValidatorWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(roe.getErrors().isEmpty(), 'The validator should not reject the record.');
    }

    @IsTest
    static void beforeUpdateValidatorWithFieldError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeFieldValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<String>{ 'Email' }, doe.getErrors()[0].getFields(), 'The error should be attached to the field.');
    }

    @IsTest
    static void beforeUpdateValidatorWithRecordError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(doe.getErrors()[0].getFields().isEmpty(), 'The error should not be attached to a field.');
    }

    @IsTest
    static void beforeUpdateValidatorWithTwoErrors() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoubleDoeValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(2, doe.getErrors().size(), 'Both errors should be attached.');
    }

    @IsTest
    static void beforeUpdateValidatorWhenNoErrorIsAttached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Id doeId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new SilentValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = doeId, LastName = 'Doe') };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doeId, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'SilentValidator qualified a record in addErrorOnBeforeUpdateWhen but attached no error in addErrorOnBeforeUpdate.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void afterUpdateWriter() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterUpdateWriterWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not register an account.');
    }

    @IsTest
    static void afterUpdateDispatcher() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void afterUpdateDispatcherWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.dispatchedBatches.size(), 'The dispatcher should not be called.');
    }

    @IsTest
    static void afterUpdateDispatcherWithMultipleRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact johnDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'John', LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ johnDoe, janeDoe };
        orchestrator.context.oldRecords = new List<Contact>{
            new Contact(Id = johnDoe.Id, FirstName = 'John', LastName = 'Doe'),
            new Contact(Id = janeDoe.Id, FirstName = 'Jane', LastName = 'Doe')
        };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Set<Id>>{ new Set<Id>{ johnDoe.Id, janeDoe.Id } }, dispatcher.dispatchedBatches, 'The dispatcher should receive all records in one call.');
    }

    @IsTest
    static void afterUpdateDispatcherBeforeFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithFinalizerSnapshot dispatcher = new IdDispatcherWithFinalizerSnapshot();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIdsWhenFinalized, 'The dispatcher should dispatch before it finalizes.');
    }

    @IsTest
    static void beforeDeleteHandler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new DeletionBlocker());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void beforeDeleteHandlerWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new DeletionBlocker());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isTrue(roe.getErrors().isEmpty(), 'The handler should not block the deletion.');
    }

    @IsTest
    static void beforeDeleteValidatorWhenNoErrorIsAttached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new SilentValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'SilentValidator qualified a record in addErrorOnBeforeDeleteWhen but attached no error in addErrorOnBeforeDelete.',
            expectedException?.getMessage(),
            'The validator should fail when it attaches no error.'
        );
    }

    @IsTest
    static void beforeDeleteWriter() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void beforeDeleteWriterWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new AccountWriterWithOwnUnitOfWork());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void beforeDeleteWriterWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new FailingAccountWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void afterDeleteWriter() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterDeleteWriterWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not register an account.');
    }

    @IsTest
    static void afterDeleteDispatcher() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void afterDeleteDispatcherWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.dispatchedBatches.size(), 'The dispatcher should not be called.');
    }

    @IsTest
    static void afterDeleteDispatcherWithMultipleRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact johnDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'John', LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ johnDoe, janeDoe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Set<Id>>{ new Set<Id>{ johnDoe.Id, janeDoe.Id } }, dispatcher.dispatchedBatches, 'The dispatcher should receive all records in one call.');
    }

    @IsTest
    static void afterDeleteDispatcherBeforeFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithFinalizerSnapshot dispatcher = new IdDispatcherWithFinalizerSnapshot();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIdsWhenFinalized, 'The dispatcher should dispatch before it finalizes.');
    }

    @IsTest
    static void afterUndeleteWriter() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void afterUndeleteWriterWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not register an account.');
    }

    @IsTest
    static void afterUndeleteDispatcher() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void afterUndeleteDispatcherWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.dispatchedBatches.size(), 'The dispatcher should not be called.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithMultipleRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact johnDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'John', LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ johnDoe, janeDoe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Set<Id>>{ new Set<Id>{ johnDoe.Id, janeDoe.Id } }, dispatcher.dispatchedBatches, 'The dispatcher should receive all records in one call.');
    }

    @IsTest
    static void afterUndeleteDispatcherBeforeFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithFinalizerSnapshot dispatcher = new IdDispatcherWithFinalizerSnapshot();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIdsWhenFinalized, 'The dispatcher should dispatch before it finalizes.');
    }

    @IsTest
    static void beforeInsertPopulatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(populator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe' }, populator.finalizedNames, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void beforeInsertValidatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(validator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe' }, validator.finalizedNames, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterInsertWriterWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, writer.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterInsertDispatcherWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, dispatcher.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(populator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe' }, populator.finalizedNames, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void beforeUpdateValidatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(validator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe' }, validator.finalizedNames, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterUpdateWriterWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, writer.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterUpdateDispatcherWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, dispatcher.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void beforeDeleteHandlerWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        DeletionBlockerWithFinalizer blocker = new DeletionBlockerWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(blocker);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, blocker.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterDeleteWriterWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, writer.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterDeleteDispatcherWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, dispatcher.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterUndeleteWriterWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, writer.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, dispatcher.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void beforeInsertPopulatorWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(populator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(populator.finalizedNames, 'The finalizer should not run.');
    }

    @IsTest
    static void beforeInsertValidatorWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(validator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(validator.finalizedNames, 'The finalizer should not run.');
    }

    @IsTest
    static void afterInsertWriterWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(writer.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void afterInsertDispatcherWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(dispatcher.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(populator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(populator.finalizedNames, 'The finalizer should not run.');
    }

    @IsTest
    static void beforeUpdateValidatorWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(validator);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(validator.finalizedNames, 'The finalizer should not run.');
    }

    @IsTest
    static void afterUpdateWriterWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(writer.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void afterUpdateDispatcherWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ roe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = roe.Id, LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(dispatcher.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void beforeDeleteHandlerWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        DeletionBlockerWithFinalizer blocker = new DeletionBlockerWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(blocker);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(blocker.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void afterDeleteWriterWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(writer.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void afterDeleteDispatcherWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(dispatcher.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void afterUndeleteWriterWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(writer);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(writer.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(dispatcher.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void finalizerAfterLastRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact janeDoe = new Contact(FirstName = 'Jane', LastName = 'Doe');
        Contact johnDoe = new Contact(FirstName = 'John', LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitleCopyingFinalizer());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ janeDoe, johnDoe };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Department, 'The next handler should see the finalized record.');
    }

    @IsTest
    static void beforeInsertPopulatorWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual('The populator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertValidatorWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual('The validator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterInsertWriterWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new FailingWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual('The writer failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterInsertDispatcherWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new FailingDispatcher());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual('The dispatcher failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeUpdatePopulatorWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The populator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeUpdateValidatorWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The validator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterUpdateWriterWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new FailingWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The writer failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterUpdateDispatcherWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new FailingDispatcher());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The dispatcher failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeDeleteHandlerWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new FailingDeleteHandler());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The handler failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterDeleteWriterWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new FailingWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The writer failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterDeleteDispatcherWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new FailingDispatcher());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The dispatcher failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterUndeleteWriterWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new FailingWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The writer failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void afterUndeleteDispatcherWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new FailingDispatcher());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The dispatcher failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertPopulatorWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The populator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertValidatorWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingValidatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The validator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterInsertWriterWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new FailingWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The writer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterInsertDispatcherWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new FailingDispatcherWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The populator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeUpdateValidatorWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingValidatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The validator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterUpdateWriterWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new FailingWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The writer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterUpdateDispatcherWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new FailingDispatcherWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeDeleteHandlerWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new FailingDeleteHandlerWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The handler failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterDeleteWriterWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new FailingWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The writer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterDeleteDispatcherWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new FailingDispatcherWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterUndeleteWriterWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new FailingWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The writer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new FailingDispatcherWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertPopulatorWithContinueOnErrorWhenFailingRecordIsNotLast() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorFailingOnDoeWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe, roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(roe.Title, 'The populator should stop at the failing record.');
    }

    @IsTest
    static void beforeInsertFinalizerWhenHandlerFailsWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnErrorAndFinalizer());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Description, 'The finalizer should not run.');
    }

    @IsTest
    static void beforeInsertPopulatorWhenPreviousHandlerFailsWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());
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
    static void beforeInsertPopulatorWithContinueOnErrorWhenQualificationFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new PopulatorFailingOnQualificationWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The qualification failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertPopulatorWithContinueOnErrorWhenFinalizerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorFailingOnFinalizeWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('The finalizer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertPopulatorWithContinueOnErrorWhenRelatedProviderIsNotRegistered() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new UnregisteredProviderReaderWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'No related records provider named unknown is declared. Return it from the queryRelatedOn method of the handler first.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorWithContinueOnErrorWhenNestedRunFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new NestedRunPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual('Called outside of a trigger context.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void loggerWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        try {
            orchestrator.run();
        } catch (TestException expected) {
        }

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'The failure should be logged once.');
    }

    @IsTest
    static void beforeInsertPopulatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DmlPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'DmlPopulator performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertValidatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DmlValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'DmlValidator performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DmlPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'DmlPopulator performed DML in before update. Move that work to an after update Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DmlValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'DmlValidator performed DML in before update. Move that work to an after update Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DmlPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(expectedException, logger.errors[0].getException(), 'The guard should log the exception it throws.');
    }

    @IsTest
    static void beforeInsertValidatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DmlValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(expectedException, logger.errors[0].getException(), 'The guard should log the exception it throws.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DmlPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(expectedException, logger.errors[0].getException(), 'The guard should log the exception it throws.');
    }

    @IsTest
    static void beforeUpdateValidatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DmlValidator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(expectedException, logger.errors[0].getException(), 'The guard should log the exception it throws.');
    }

    @IsTest
    static void beforeInsertPopulatorWhenQualificationPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new DmlQualificationPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'DmlQualificationPopulator performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorWhenFinalizerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorWithDmlFinalizer());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'TitlePopulatorWithDmlFinalizer performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorWhenRelatedQueryPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorWithDmlRelatedQuery());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'TitlePopulatorWithDmlRelatedQuery performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingDmlPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual('The populator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void beforeInsertPopulatorWhenDmlIsPerformedBeforeRun() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Database.setSavepoint();

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
    static void beforeDeleteHandlerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new DmlDeletionBlocker());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulator());

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Title, 'The populator should not run beyond the recursion depth.');
    }

    @IsTest
    static void afterUpdateWriterWithDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriter());

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(3, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not run beyond the recursion depth.');
    }

    @IsTest
    static void afterUpdateDispatcherWithDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcher dispatcher = new IdDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(3, dispatcher.dispatchedIds.size(), 'The dispatcher should not run beyond the recursion depth.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithRecursionGuard() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulatorWithRecursionGuard());

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Title, 'The populator should not run beyond its recursion depth.');
    }

    @IsTest
    static void afterUpdateWriterWithRecursionGuard() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithRecursionGuard());

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should not run beyond its recursion depth.');
    }

    @IsTest
    static void afterUpdateDispatcherWithRecursionGuard() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, dispatcher.dispatchedIds.size(), 'The dispatcher should not run beyond its recursion depth.');
    }

    @IsTest
    static void beforeUpdatePopulatorQualificationWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        QualificationCountingPopulator populator = new QualificationCountingPopulator();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(populator);

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(3, populator.qualificationCalls, 'The qualification should not be asked beyond the recursion depth.');
    }

    @IsTest
    static void afterUpdateWriterQualificationWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        QualificationCountingWriter writer = new QualificationCountingWriter();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(writer);

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(3, writer.qualificationCalls, 'The qualification should not be asked beyond the recursion depth.');
    }

    @IsTest
    static void afterUpdateDispatcherQualificationWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        QualificationCountingDispatcher dispatcher = new QualificationCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(3, dispatcher.qualificationCalls, 'The qualification should not be asked beyond the recursion depth.');
    }

    @IsTest
    static void beforeUpdatePopulatorWithRecursionGuardWhenEarlierRunDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulatorWithRecursionGuard());

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Roe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Roe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void afterUpdateWriterWithRecursionGuardWhenEarlierRunDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithRecursionGuard());

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Roe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Roe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should register the account.');
    }

    @IsTest
    static void afterUpdateDispatcherWithRecursionGuardWhenEarlierRunDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Roe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Roe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The dispatcher should receive the qualified records.');
    }

    @IsTest
    static void recursionDepthPerRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact janeDoe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), FirstName = 'Jane', LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new TitlePopulatorWithRecursionGuard());

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe, janeDoe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = janeDoe.Id, FirstName = 'Jane', LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator writerHandlers = new TestOrchestrator();
        writerHandlers.afterUpdate.add(new AccountWriterWithRecursionGuard());

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(writerHandlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.run();

        IdDispatcherWithRecursionGuard dispatcher = new IdDispatcherWithRecursionGuard();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, dispatcher.dispatchedIds, 'The recursion depth should be tracked per handler class.');
    }

    @IsTest
    static void recursionDepthSharedByHandlerInstances() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithRecursionGuard());
        handlers.afterUpdate.add(new AccountWriterWithRecursionGuard());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(depthOneHandler);
        handlers.afterUpdate.add(depthOneHandler);

        TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
        earlierRun.run();

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<Id>{ doe.Id }, depthOneHandler.dispatchedIds, 'The recursion depth should be tracked per context.');
    }

    @IsTest
    static void afterUpdateFinalizerWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        FinalizeCountingWriter writer = new FinalizeCountingWriter();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(writer);

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(3, writer.finalizeCalls, 'The finalizer should not run beyond the recursion depth.');
    }

    @IsTest
    static void beforeUpdateValidatorWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new DoeValidator());

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(handlers);
            earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            earlierRun.context.newRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };
            earlierRun.run();
        }

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should not be limited by the recursion depth.');
    }

    @IsTest
    static void beforeInsertPopulatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingDmlPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'FailingDmlPopulatorWithContinueOnError performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeInsertValidatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingDmlValidatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        Assert.areEqual(
            'FailingDmlValidatorWithContinueOnError performed DML in before insert. Move that work to an after insert Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingDmlPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'FailingDmlPopulatorWithContinueOnError performed DML in before update. Move that work to an after update Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new FailingDmlValidatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'FailingDmlValidatorWithContinueOnError performed DML in before update. Move that work to an after update Writer.',
            expectedException?.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void afterInsertWriterWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new DmlAccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The writer should register the account.');
    }

    @IsTest
    static void beforeInsertParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the account name.');
    }

    @IsTest
    static void afterInsertParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock(Contact.SObjectType).thenReturn(new Contact(Id = doe.Id, Account = acme));

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the account name.');
    }

    @IsTest
    static void beforeUpdateParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the account name.');
    }

    @IsTest
    static void beforeUpdatePriorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new PriorAccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the prior account name.');
    }

    @IsTest
    static void afterUpdateParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock(Contact.SObjectType).thenReturn(new Contact(Id = doe.Id, Account = acme));

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the account name.');
    }

    @IsTest
    static void afterUpdatePriorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new PriorAccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the prior account name.');
    }

    @IsTest
    static void beforeDeletePriorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new PriorAccountDeletionBlocker());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Contacts of Acme cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void afterDeletePriorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new PriorAccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the prior account name.');
    }

    @IsTest
    static void afterUndeleteParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock(Contact.SObjectType).thenReturn(new Contact(Id = doe.Id, Account = acme));

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the account name.');
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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe', AccountId = acme.Id) };

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        orchestrator.run();
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
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulator());
        handlers.beforeInsert.add(new AccountIndustryPopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new List<String>{ 'Acme', 'Technology' }, new List<String>{ doe.Department, doe.Description }, 'The populators should read the fields of both handlers.');
    }

    @IsTest
    static void parentQueryWhenDeclaredByLaterHandler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new UndeclaredAccountNamePopulator());
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Description, 'The populator should copy the account name.');
    }

    @IsTest
    static void parentQueryWhenLookupIsEmpty() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        orchestrator.run();
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
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Department, 'The populator should not find the account.');
    }

    @IsTest
    static void priorParentQueryWithoutParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new PriorAccountNamePopulator());
        handlers.beforeUpdate.add(new UndeclaredAccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.isNull(doe.Description, 'The populator should not find the account.');
    }

    @IsTest
    static void beforeUpdatePriorParentQueryWithParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        SOQL.mock(Account.SObjectType).thenReturn(new List<Account>{ acme, globex });

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new PriorAccountNamePopulatorWithParentQuery());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = globex.Id) };

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        orchestrator.run();
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The accounts should be queried once.');
    }

    @IsTest
    static void afterUpdatePriorParentQueryWithParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock(Contact.SObjectType).thenReturn(new Contact(Id = doe.Id, Account = acme));

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountNameWriterWithPriorParentQuery());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        orchestrator.run();
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The prior account should come from the saved records.');
    }

    @IsTest
    static void beforeInsertParentQueryWhenLookupIsRepointed() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        SOQL.mock(Account.SObjectType).thenReturn(globex);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountRepointingPopulator(globex.Id));
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Globex', doe.Department, 'The populator should copy the new account name.');
    }

    @IsTest
    static void beforeUpdateParentQueryWhenLookupIsRepointed() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        SOQL.mock(Account.SObjectType).thenReturn(globex);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new AccountRepointingPopulator(globex.Id));
        handlers.beforeUpdate.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Globex', doe.Department, 'The populator should copy the new account name.');
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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe', AccountId = acme.Id), new Contact(LastName = 'Roe', AccountId = globex.Id) };

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        orchestrator.run();
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
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountRepointingPopulator(null));
        handlers.beforeInsert.add(new AccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new AccountRepointingPopulator(globex.Id));
        handlers.beforeUpdate.add(new PriorAccountNamePopulatorWithParentQuery());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the prior account name.');
    }

    @IsTest
    static void beforeInsertRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new RelatedAccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the related account name.');
    }

    @IsTest
    static void afterInsertRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new RelatedAccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the related account name.');
    }

    @IsTest
    static void beforeUpdateRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new RelatedAccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the related account name.');
    }

    @IsTest
    static void afterUpdateRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new RelatedAccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the related account name.');
    }

    @IsTest
    static void beforeDeleteRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeDelete.add(new RelatedAccountDeletionBlocker());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Contacts of Acme cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void afterDeleteRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new RelatedAccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the related account name.');
    }

    @IsTest
    static void afterUndeleteRelatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new RelatedAccountNameWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the related account name.');
    }

    @IsTest
    static void relatedQueryWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        LastNameProvider provider = new LastNameProvider();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorWithRelatedQuery(provider));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe', 'Roe' }, provider.lastNames, 'The provider should receive every record.');
    }

    @IsTest
    static void relatedQueryWithNullProviders() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new TitlePopulatorWithNullRelatedQuery());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
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
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        ParentReadingProvider provider = new ParentReadingProvider();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulatorWithRelatedQuery(provider));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe', AccountId = acme.Id) };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingRelatedQueryPopulatorWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };

        // Test
        orchestrator.run();

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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new RelatedAccountNamePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe', AccountId = acme.Id), new Contact(LastName = 'Roe', AccountId = acme.Id) };

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        orchestrator.run();
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

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new RelatedAccountTitlePopulator());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should qualify by the related account.');
    }

    @IsTest
    static void afterInsertWriterWithSharedUnitOfWorkWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.committedAccounts, 'The shared unit of work should not commit before the next handler.');
    }

    @IsTest
    static void afterUpdateWriterWithSharedUnitOfWorkWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriter());
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.committedAccounts, 'The shared unit of work should not commit before the next handler.');
    }

    @IsTest
    static void afterDeleteWriterWithSharedUnitOfWorkWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriter());
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.committedAccounts, 'The shared unit of work should not commit before the next handler.');
    }

    @IsTest
    static void afterUndeleteWriterWithSharedUnitOfWorkWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriter());
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, dispatcher.committedAccounts, 'The shared unit of work should not commit before the next handler.');
    }

    @IsTest
    static void afterInsertWriterWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithOwnUnitOfWork());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void afterUpdateWriterWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithOwnUnitOfWork());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void afterDeleteWriterWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriterWithOwnUnitOfWork());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void afterUndeleteWriterWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriterWithOwnUnitOfWork());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void afterInsertWriterWithContinueOnErrorWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithContinueOnError());
        handlers.afterInsert.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, dispatcher.committedAccounts, 'The automatic unit of work should commit before the next handler.');
    }

    @IsTest
    static void afterUpdateWriterWithContinueOnErrorWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new AccountWriterWithContinueOnError());
        handlers.afterUpdate.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, dispatcher.committedAccounts, 'The automatic unit of work should commit before the next handler.');
    }

    @IsTest
    static void afterDeleteWriterWithContinueOnErrorWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new AccountWriterWithContinueOnError());
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, dispatcher.committedAccounts, 'The automatic unit of work should commit before the next handler.');
    }

    @IsTest
    static void afterUndeleteWriterWithContinueOnErrorWhenNextHandlerRuns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriterWithContinueOnError());
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, dispatcher.committedAccounts, 'The automatic unit of work should commit before the next handler.');
    }

    @IsTest
    static void afterInsertWriterWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new FailingAccountWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void afterUpdateWriterWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUpdate.add(new FailingAccountWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestrator.context.newRecords = new List<Contact>{ doe };
        orchestrator.context.oldRecords = new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe') };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void afterDeleteWriterWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterDelete.add(new FailingAccountWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestrator.context.oldRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void afterUndeleteWriterWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new FailingAccountWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void afterInsertWriterWithOwnUnitOfWorkWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithPrefilledOwnUnitOfWork());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ roe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records().size(), 'The own unit of work should not commit.');
    }

    @IsTest
    static void afterInsertWriterWithOwnUnitOfWorkAndContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithOwnUnitOfWorkAndContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void afterInsertWriterWithSharedUnitOfWorkWhenCommitFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').exceptionOnInserts();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        Exception expectedException = null;

        // Test
        try {
            orchestrator.run();
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.isInstanceOfType(expectedException, DmlException.class, 'The commit exception should propagate.');
    }

    @IsTest
    static void afterInsertWriterWithContinueOnErrorWhenCommitFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').exceptionOnInserts();

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriterWithContinueOnError());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.isInstanceOfType(logger.errors[0].getException(), DmlException.class, 'The commit exception should be logged.');
    }

    @IsTest
    static void unitOfWorkToInsertWithDmlRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new DmlRecordInsertWriter(new Account(Name = 'Acme')));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should insert the account.');
    }

    @IsTest
    static void unitOfWorkToUpdate() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountUpdateWriter(new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme')));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should update the account.');
    }

    @IsTest
    static void unitOfWorkToUpdateWithDmlRecord() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new DmlRecordUpdateWriter(new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme')));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should update the account.');
    }

    @IsTest
    static void unitOfWorkToUpsert() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountUpsertWriter(new Account(Name = 'Acme')));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').upsertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should upsert the account.');
    }

    @IsTest
    static void unitOfWorkToDelete() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountDeleteWriter(new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme')));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').deletesOf(Account.SObjectType).records()[0].get(Account.Name), 'The unit of work should delete the account.');
    }

    @IsTest
    static void unitOfWorkToPublish() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new EventPublishWriter(new FlowOrchestrationEvent()));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(1, DML.retrieveResultFor('triggerUow').eventsOf(FlowOrchestrationEvent.SObjectType).records().size(), 'The unit of work should publish the event.');
    }

    @IsTest
    static void sharedUnitOfWorkWithTwoWriters() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountWriter());
        handlers.afterInsert.add(new AccountWriter());

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

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
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterInsert.add(new AccountUpdateWriter(new Account(Id = acmeId, Name = 'Acme')));
        handlers.afterInsert.add(new AccountUpdateWriter(new Account(Id = acmeId, Industry = 'Technology')));

        TriggerOrchestrator orchestrator = new TriggerOrchestrator(handlers);
        orchestrator.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestrator.context.newRecords = new List<Contact>{ doe };

        // Test
        orchestrator.run();

        // Verify
        Assert.areEqual(
            new List<SObject>{ new Account(Id = acmeId, Name = 'Acme', Industry = 'Technology') },
            DML.retrieveResultFor('triggerUow').updatesOf(Account.SObjectType).records(),
            'The shared unit of work should merge both updates into one record.'
        );
    }

    @IsTest
    static void mockBeforeInsertForWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockBeforeInsertForWithList() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(new List<Contact>{ doe });

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockBeforeInsertForWithTwice() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The first row should still run.');
    }

    @IsTest
    static void mockBeforeInsertForWithParent() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountNamePopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The mocked parent should be served.');
    }

    @IsTest
    static void mockBeforeInsertForWithParentList() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountNamePopulator.class).with(doe).withParent(Contact.AccountId, new List<Account>{ acme });

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The mocked parent should be served.');
    }

    @IsTest
    static void mockBeforeInsertForWithoutId() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.isNull(doe.Id, 'The row should keep no Id.');
    }

    @IsTest
    static void mockBeforeInsertForOrchestrator() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitleOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitleOrchestrator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The mocked orchestrator should run.');
    }

    @IsTest
    static void mockAfterInsertForWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_INSERT', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockAfterInsertForWithParent() {
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
    static void mockAfterInsertForWithFakeId() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.isNotNull(doe.Id, 'The row should get a fake Id.');
    }

    @IsTest
    static void mockBeforeUpdateForWithPair() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(OperationStamper.class).with(doe, new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_UPDATE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockBeforeUpdateForWithPairLists() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(OperationStamper.class).with(new List<Contact>{ doe }, new List<Contact>{ new Contact(LastName = 'Doe') });

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_UPDATE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockBeforeUpdateForWithPairTwice() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(OperationStamper.class)
            .with(doe, new Contact(LastName = 'Doe'))
            .with(new Contact(LastName = 'Doe'), new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_UPDATE', doe.Description, 'The first pair should still run.');
    }

    @IsTest
    static void mockBeforeUpdateForWithParent() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeUpdateFor(AccountNamePopulator.class).with(doe, new Contact(LastName = 'Doe')).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The mocked parent should be served.');
    }

    @IsTest
    static void mockBeforeUpdateForWithPairSharingOldId() {
        // Setup
        Id doeId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(OperationStamper.class).with(doe, new Contact(Id = doeId, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual(doeId, doe.Id, 'The pair should share the old Id.');
    }

    @IsTest
    static void mockAfterUpdateForWithPair() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUpdateFor(OperationStamper.class).with(doe, new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_UPDATE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockAfterUpdateForWithParent() {
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

    @IsTest
    static void mockBeforeDeleteForWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_DELETE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockBeforeDeleteForWithParent() {
        // Setup
        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeDeleteFor(PriorAccountDeletionBlocker.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new PriorAccountDeletionBlocker());

        // Verify
        Assert.areEqual('Contacts of Acme cannot be deleted.', doe.getErrors()[0].getMessage(), 'The mocked parent should be served.');
    }

    @IsTest
    static void mockBeforeDeleteForWithFakeId() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.isNotNull(doe.Id, 'The row should get a fake Id.');
    }

    @IsTest
    static void mockAfterDeleteForWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterDeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_DELETE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockAfterDeleteForWithParent() {
        // Setup
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterDeleteFor(PriorAccountNameWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new PriorAccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The mocked parent should be served.');
    }

    @IsTest
    static void mockAfterUndeleteForWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_UNDELETE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockAfterUndeleteForWithParent() {
        // Setup
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterUndeleteFor(AccountNameWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The mocked parent should be served.');
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
        private TriggerOrchestrator nestedOrchestrator;

        public NestedRunPopulator(TriggerOrchestrator nestedOrchestrator) {
            this.nestedOrchestrator = nestedOrchestrator;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            this.nestedOrchestrator.run();
        }
    }

    private class BeforeInsertOnlyOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return new List<BeforeInsert.Handler>();
        }
    }

    private class TitlePopulatorWithBypassable extends TitlePopulator implements BeforeInsert.Bypassable, BeforeUpdate.Bypassable {
        public Boolean bypassOnBeforeInsertWhen() {
            return true;
        }

        public Boolean bypassOnBeforeUpdateWhen() {
            return true;
        }
    }

    private class TitlePopulatorWithBypassableOff extends TitlePopulator implements BeforeInsert.Bypassable {
        public Boolean bypassOnBeforeInsertWhen() {
            return false;
        }
    }

    private class TitlePopulatorWithBypassCounter extends TitlePopulator implements BeforeInsert.Bypassable {
        public Integer bypassChecks = 0;

        public Boolean bypassOnBeforeInsertWhen() {
            this.bypassChecks++;
            return false;
        }
    }

    private class DoeValidatorWithBypassable extends DoeValidator implements BeforeInsert.Bypassable, BeforeUpdate.Bypassable {
        public Boolean bypassOnBeforeInsertWhen() {
            return true;
        }

        public Boolean bypassOnBeforeUpdateWhen() {
            return true;
        }
    }

    private class AccountWriterWithBypassable extends AccountWriter implements AfterInsert.Bypassable, AfterUpdate.Bypassable, AfterDelete.Bypassable, AfterUndelete.Bypassable {
        public Boolean bypassOnAfterInsertWhen() {
            return true;
        }

        public Boolean bypassOnAfterUpdateWhen() {
            return true;
        }

        public Boolean bypassOnAfterDeleteWhen() {
            return true;
        }

        public Boolean bypassOnAfterUndeleteWhen() {
            return true;
        }
    }

    private class IdDispatcherWithBypassable extends IdDispatcher implements AfterInsert.Bypassable, AfterUpdate.Bypassable, AfterDelete.Bypassable, AfterUndelete.Bypassable {
        public Boolean bypassOnAfterInsertWhen() {
            return true;
        }

        public Boolean bypassOnAfterUpdateWhen() {
            return true;
        }

        public Boolean bypassOnAfterDeleteWhen() {
            return true;
        }

        public Boolean bypassOnAfterUndeleteWhen() {
            return true;
        }
    }

    private class DeletionBlockerWithBypassable extends DeletionBlocker implements BeforeDelete.Bypassable {
        public Boolean bypassOnBeforeDeleteWhen() {
            return true;
        }
    }

    private class AccountNamePopulatorWithBypassable extends AccountNamePopulator implements BeforeInsert.Bypassable {
        public Boolean bypassOnBeforeInsertWhen() {
            return true;
        }
    }

    private class AccountNamePopulatorWithoutParentQuery implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getNewParent('Account')?.get(Account.Name));
        }
    }

    private class BatchDispatcher implements AfterInsert.Dispatcher, AfterUpdate.Dispatcher, AfterDelete.Dispatcher, AfterUndelete.Dispatcher {
        public List<Set<Id>> dispatchedBatches = new List<Set<Id>>();

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }
    }

    private class IdDispatcherWithFinalizerSnapshot extends IdDispatcher implements AfterInsert.Finalizer, AfterUpdate.Finalizer, AfterDelete.Finalizer, AfterUndelete.Finalizer {
        public List<Id> dispatchedIdsWhenFinalized;

        public void finalizeOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }

        public void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }

        public void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }
    }

    private class TitlePopulatorWithFinalizer extends TitlePopulator implements BeforeInsert.Finalizer, BeforeUpdate.Finalizer {
        public Set<String> finalizedNames;

        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }

        public void finalizeOnBeforeUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }
    }

    private class DoeValidatorWithFinalizer extends DoeValidator implements BeforeInsert.Finalizer, BeforeUpdate.Finalizer {
        public Set<String> finalizedNames;

        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }

        public void finalizeOnBeforeUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }
    }

    private class AccountWriterWithFinalizer extends AccountWriter implements AfterInsert.Finalizer, AfterUpdate.Finalizer, AfterDelete.Finalizer, AfterUndelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.finalizedIds = records.getIds();
        }

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedIds = records.getIds();
        }

        public void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.finalizedIds = records.getIds();
        }

        public void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private class IdDispatcherWithFinalizer extends IdDispatcher implements AfterInsert.Finalizer, AfterUpdate.Finalizer, AfterDelete.Finalizer, AfterUndelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.finalizedIds = records.getIds();
        }

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedIds = records.getIds();
        }

        public void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.finalizedIds = records.getIds();
        }

        public void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private class DeletionBlockerWithFinalizer extends DeletionBlocker implements BeforeDelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnBeforeDelete(TriggerTypes.DeleteRecords records) {
            this.finalizedIds = records.getIds();
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

    private virtual class FailingValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            throw new TestException('The validator failed.');
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            throw new TestException('The validator failed.');
        }
    }

    private class FailingValidatorWithContinueOnError extends FailingValidator implements BeforeInsert.ContinueOnError, BeforeUpdate.ContinueOnError {
    }

    private virtual class FailingWriter implements AfterInsert.Writer, AfterUpdate.Writer, AfterDelete.Writer, AfterUndelete.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }
    }

    private class FailingWriterWithContinueOnError extends FailingWriter implements AfterInsert.ContinueOnError, AfterUpdate.ContinueOnError, AfterDelete.ContinueOnError, AfterUndelete.ContinueOnError {
    }

    private virtual class FailingDispatcher implements AfterInsert.Dispatcher, AfterUpdate.Dispatcher, AfterDelete.Dispatcher, AfterUndelete.Dispatcher {
        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            throw new TestException('The dispatcher failed.');
        }

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            throw new TestException('The dispatcher failed.');
        }

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            throw new TestException('The dispatcher failed.');
        }

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            throw new TestException('The dispatcher failed.');
        }
    }

    private class FailingDispatcherWithContinueOnError extends FailingDispatcher implements AfterInsert.ContinueOnError, AfterUpdate.ContinueOnError, AfterDelete.ContinueOnError, AfterUndelete.ContinueOnError {
    }

    private virtual class FailingDeleteHandler implements BeforeDelete.Writer {
        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The handler failed.');
        }
    }

    private class FailingDeleteHandlerWithContinueOnError extends FailingDeleteHandler implements BeforeDelete.ContinueOnError {
    }

    private class TitlePopulatorFailingOnDoeWithContinueOnError implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            if (record.equals(Contact.LastName, 'Doe')) {
                throw new TestException('The populator failed.');
            }

            record.put(Contact.Title, 'CEO');
        }
    }

    private class FailingPopulatorWithContinueOnErrorAndFinalizer extends FailingPopulator implements BeforeInsert.ContinueOnError, BeforeInsert.Finalizer {
        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            for (TriggerTypes.InsertRecord record : records.getRecords()) {
                record.put(Contact.Description, 'Finalized');
            }
        }
    }

    private class PopulatorFailingOnQualificationWithContinueOnError implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            throw new TestException('The qualification failed.');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private class TitlePopulatorFailingOnFinalizeWithContinueOnError extends TitlePopulator implements BeforeInsert.Finalizer, BeforeInsert.ContinueOnError {
        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            throw new TestException('The finalizer failed.');
        }
    }

    private class UnregisteredProviderReaderWithContinueOnError implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.getRelated('unknown');
        }
    }

    private class NestedRunPopulatorWithContinueOnError implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            new TriggerOrchestrator(new TestOrchestrator()).run();
        }
    }

    private class DmlPopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            Database.setSavepoint();
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            Database.setSavepoint();
        }
    }

    private class DmlValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            Database.setSavepoint();
            record.addError('Doe is not allowed.');
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            Database.setSavepoint();
            record.addError('Doe is not allowed.');
        }
    }

    private class DmlQualificationPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            Database.setSavepoint();
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private class TitlePopulatorWithDmlFinalizer extends TitlePopulator implements BeforeInsert.Finalizer {
        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            Database.setSavepoint();
        }
    }

    private class TitlePopulatorWithDmlRelatedQuery extends TitlePopulator implements BeforeInsert.RelatedQuery {
        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            Database.setSavepoint();
            return new Map<String, BeforeInsert.RecordsProvider>();
        }
    }

    private virtual class FailingDmlPopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            Database.setSavepoint();
            throw new TestException('The populator failed.');
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            Database.setSavepoint();
            throw new TestException('The populator failed.');
        }
    }

    private class FailingDmlPopulatorWithContinueOnError extends FailingDmlPopulator implements BeforeInsert.ContinueOnError, BeforeUpdate.ContinueOnError {
    }

    private virtual class FailingDmlValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            Database.setSavepoint();
            throw new TestException('The validator failed.');
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            Database.setSavepoint();
            throw new TestException('The validator failed.');
        }
    }

    private class FailingDmlValidatorWithContinueOnError extends FailingDmlValidator implements BeforeInsert.ContinueOnError, BeforeUpdate.ContinueOnError {
    }

    private class DmlDeletionBlocker implements BeforeDelete.Validator {
        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
            Database.setSavepoint();
            record.addError('Doe cannot be deleted.');
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

    private class QualificationCountingPopulator implements BeforeUpdate.Populator {
        public Integer qualificationCalls = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            this.qualificationCalls++;
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private class QualificationCountingWriter implements AfterUpdate.Writer {
        public Integer qualificationCalls = 0;

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            this.qualificationCalls++;
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private class QualificationCountingDispatcher implements AfterUpdate.Dispatcher {
        public Integer qualificationCalls = 0;

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            this.qualificationCalls++;
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
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

    private class FinalizeCountingWriter extends AccountWriter implements AfterUpdate.Finalizer {
        public Integer finalizeCalls = 0;

        public void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizeCalls++;
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

    private virtual class AccountNameWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUndelete.Writer, AfterUndelete.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getNewParent('Account')?.get(Account.Name)));
        }

        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getNewParent('Account')?.get(Account.Name)));
        }

        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUndelete() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getNewParent('Account')?.get(Account.Name)));
        }
    }

    private class AccountNameWriterWithPriorParentQuery extends AccountNameWriter implements AfterUpdate.PriorParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }
    }

    private class PriorAccountNameWriter implements AfterUpdate.Writer, AfterUpdate.PriorParentQuery, AfterDelete.Writer, AfterDelete.PriorParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getOldParent('Account')?.get(Account.Name)));
        }

        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterDelete() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Task(Subject = (String) record.getOldParent('Account')?.get(Account.Name)));
        }
    }

    private class PriorAccountDeletionBlocker implements BeforeDelete.Validator, BeforeDelete.PriorParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeDelete() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
            record.addError('Contacts of ' + (String) record.getOldParent('Account')?.get(Account.Name) + ' cannot be deleted.');
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

    private class RelatedAccountNameWriter implements AfterInsert.Writer, AfterInsert.RelatedQuery, AfterUpdate.Writer, AfterUpdate.RelatedQuery, AfterDelete.Writer, AfterDelete.RelatedQuery, AfterUndelete.Writer, AfterUndelete.RelatedQuery {
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

        public Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete() {
            return new Map<String, AfterDelete.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(
                new Task(Subject = (String) record.getRelated('accounts').getFirstWhereKeyEquals(record.getOldSObject().get(Contact.AccountId))?.get(Account.Name))
            );
        }

        public Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete() {
            return new Map<String, AfterUndelete.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(
                new Task(Subject = (String) record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name))
            );
        }
    }

    private class RelatedAccountDeletionBlocker implements BeforeDelete.Validator, BeforeDelete.RelatedQuery {
        public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
            return new Map<String, BeforeDelete.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
            record.addError(
                'Contacts of ' +
                    (String) record.getRelated('accounts').getFirstWhereKeyEquals(record.getOldSObject().get(Contact.AccountId))?.get(Account.Name) +
                    ' cannot be deleted.'
            );
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

    private class CommitCountingDispatcher implements AfterInsert.Dispatcher, AfterUpdate.Dispatcher, AfterDelete.Dispatcher, AfterUndelete.Dispatcher {
        public Integer committedAccounts;

        public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }

        public Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }
    }

    private virtual class AccountWriterWithOwnUnitOfWork extends AccountWriter implements AfterInsert.OwnUnitOfWork, AfterUpdate.OwnUnitOfWork, BeforeDelete.OwnUnitOfWork, AfterDelete.OwnUnitOfWork, AfterUndelete.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnAfterInsert() {
            return new DML().identifier('ownUnit');
        }

        public DML.Committable ownUnitOfWorkOnAfterUpdate() {
            return new DML().identifier('ownUnit');
        }

        public DML.Committable ownUnitOfWorkOnBeforeDelete() {
            return new DML().identifier('ownUnit');
        }

        public DML.Committable ownUnitOfWorkOnAfterDelete() {
            return new DML().identifier('ownUnit');
        }

        public DML.Committable ownUnitOfWorkOnAfterUndelete() {
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

    private class AccountWriterWithContinueOnError extends AccountWriter implements AfterInsert.ContinueOnError, AfterUpdate.ContinueOnError, BeforeDelete.ContinueOnError, AfterDelete.ContinueOnError, AfterUndelete.ContinueOnError {
    }

    private class FailingAccountWriterWithContinueOnError implements AfterInsert.Writer, AfterInsert.ContinueOnError, AfterUpdate.Writer, AfterUpdate.ContinueOnError, BeforeDelete.Writer, BeforeDelete.ContinueOnError, AfterDelete.Writer, AfterDelete.ContinueOnError, AfterUndelete.Writer, AfterUndelete.ContinueOnError {
        public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }

        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
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

    private class TitleOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return new List<BeforeInsert.Handler>{ new TitlePopulator() };
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

    private class DoeFieldValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            record.addError(Contact.Email, 'Doe is not allowed.');
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            record.addError(Contact.Email, 'Doe is not allowed.');
        }
    }

    private class DoubleDoeValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            record.addError('Doe is not allowed.');
            record.addError(Contact.Email, 'Doe is not allowed.');
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            record.addError('Doe is not allowed.');
            record.addError(Contact.Email, 'Doe is not allowed.');
        }
    }

    private class SilentValidator implements BeforeInsert.Validator, BeforeUpdate.Validator, BeforeDelete.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        }

        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        }

        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
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

    private virtual class DeletionBlocker implements BeforeDelete.Validator {
        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
            record.addError('Doe cannot be deleted.');
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
