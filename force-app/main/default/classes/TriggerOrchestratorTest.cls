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
 * - ExcessivePublicCount: Test handlers expose their recorded state so the assertions can read it
 * - TooManyFields: Test handlers expose their recorded state so the assertions can read it
 * - FieldDeclarationsShouldBeAtStart: The tests come first so the reader sees the behaviour before the fixture
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings(
    'PMD.ExcessiveClassLength,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ExcessivePublicCount,PMD.TooManyFields,PMD.FieldDeclarationsShouldBeAtStart,PMD.ApexUnitTestClassShouldHaveRunAs'
)
@IsTest(IsParallel=true)
private class TriggerOrchestratorTest {
    @IsTest
    static void staticRunEntryPointOutsideATriggerContextThrows() {
        mockFramework();
        String message;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator.run(new TestOrchestrator());
        } catch (Exception e) {
            message = e.getMessage();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            message,
            'It should be the missing trigger context message, because the entry point reads the operation of a trigger that is not running.'
        );
    }

    @IsTest
    static void beforeInsertOperationRunsOnlyTheBeforeInsertHandlers() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeInsert.action:Doe' }, calls('action'), 'It should be the before insert handler alone, because the operation is BEFORE_INSERT.');
    }

    @IsTest
    static void afterInsertOperationRunsOnlyTheAfterInsertHandlers() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterInsert.action:Doe' }, calls('action'), 'It should be the after insert handler alone, because the operation is AFTER_INSERT.');
    }

    @IsTest
    static void beforeUpdateOperationRunsOnlyTheBeforeUpdateHandlers() {
        mockFramework();
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeUpdate.action:Doe' }, calls('action'), 'It should be the before update handler alone, because the operation is BEFORE_UPDATE.');
    }

    @IsTest
    static void afterUpdateOperationRunsOnlyTheAfterUpdateHandlers() {
        mockFramework();
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterUpdate.action:Doe' }, calls('action'), 'It should be the after update handler alone, because the operation is AFTER_UPDATE.');
    }

    @IsTest
    static void beforeDeleteOperationRunsOnlyTheBeforeDeleteHandlers() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeDelete.action:Doe' }, calls('action'), 'It should be the before delete handler alone, because the operation is BEFORE_DELETE.');
    }

    @IsTest
    static void afterDeleteOperationRunsOnlyTheAfterDeleteHandlers() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterDelete.action:Doe' }, calls('action'), 'It should be the after delete handler alone, because the operation is AFTER_DELETE.');
    }

    @IsTest
    static void afterUndeleteOperationRunsOnlyTheAfterUndeleteHandlers() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleEveryContextOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterUndelete.action:Doe' }, calls('action'), 'It should be the after undelete handler alone, because the operation is AFTER_UNDELETE.');
    }

    @IsTest
    static void operationTheOrchestratorDoesNotImplementIsSkippedWithoutError() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(new LifecycleBeforeInsertOnlyOrchestrator());
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because an orchestrator that does not implement AfterInsert is skipped instead of being cast to it.');
    }

    @IsTest
    static void nullOrchestratorIsIgnoredWithoutError() {
        mockFramework();
        TriggerOrchestrator runner = new TriggerOrchestrator(null);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because a missing orchestrator implements no context and is skipped.');
    }

    @IsTest
    static void handlersRunInTheirDeclaredOrderAcrossRoles() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.label = 'first';
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.label = 'second';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'first.action:Doe', 'second.action:Doe' },
            calls('action'),
            'It should be the validator first, because it is declared before the populator.'
        );
    }

    @IsTest
    static void eachHandlerProcessesEveryRecordBeforeTheNextHandlerStarts() {
        mockFramework();
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.label = 'first';
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.label = 'second';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'first.when:Doe', 'first.when:Roe', 'second.when:Doe', 'second.when:Roe' },
            calls('when'),
            'It should be every record of the first handler before the second, because handlers run one after another over the whole batch.'
        );
    }

    @IsTest
    static void laterHandlerSeesFieldsPopulatedByAnEarlierHandler() {
        mockFramework();
        LifecyclePopulatedTitlePopulator titleReader = new LifecyclePopulatedTitlePopulator();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        orchestrator.beforeInsert.add(titleReader);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, titleReader.acted, 'It should be Doe, because the earlier populator set the Title the later one qualifies on.');
    }

    @IsTest
    static void handlerWithoutARoleIsSkipped() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new LifecycleRolelessHandler());
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the role-less entry is skipped without error.');
    }

    @IsTest
    static void beforeInsertPopulatorWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyBeforeInsertPopulator populator = new LifecycleRoleOnlyBeforeInsertPopulator();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the framework calls an optional interface only on a populator that implements it.');
    }

    @IsTest
    static void beforeInsertValidatorWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyBeforeInsertValidator validator = new LifecycleRoleOnlyBeforeInsertValidator();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, validator.acted, 'It should be Doe, because the framework calls an optional interface only on a validator that implements it.');
    }

    @IsTest
    static void afterInsertWriterWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterInsertWriter writer = new LifecycleRoleOnlyAfterInsertWriter();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe, because the framework calls an optional interface only on a writer that implements it.');
    }

    @IsTest
    static void afterInsertDispatcherWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterInsertDispatcher dispatcher = new LifecycleRoleOnlyAfterInsertDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            dispatcher.dispatched,
            'It should be Doe, because the framework calls an optional interface only on a dispatcher that implements it.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyBeforeUpdatePopulator populator = new LifecycleRoleOnlyBeforeUpdatePopulator();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the framework calls an optional interface only on a populator that implements it.');
    }

    @IsTest
    static void beforeUpdateValidatorWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyBeforeUpdateValidator validator = new LifecycleRoleOnlyBeforeUpdateValidator();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, validator.acted, 'It should be Doe, because the framework calls an optional interface only on a validator that implements it.');
    }

    @IsTest
    static void afterUpdateWriterWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterUpdateWriter writer = new LifecycleRoleOnlyAfterUpdateWriter();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe, because the framework calls an optional interface only on a writer that implements it.');
    }

    @IsTest
    static void afterUpdateDispatcherWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterUpdateDispatcher dispatcher = new LifecycleRoleOnlyAfterUpdateDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            dispatcher.dispatched,
            'It should be Doe, because the framework calls an optional interface only on a dispatcher that implements it.'
        );
    }

    @IsTest
    static void beforeDeleteHandlerWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyBeforeDeleteHandler handler = new LifecycleRoleOnlyBeforeDeleteHandler();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, handler.acted, 'It should be Doe, because the framework calls an optional interface only on a handler that implements it.');
    }

    @IsTest
    static void afterDeleteWriterWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterDeleteWriter writer = new LifecycleRoleOnlyAfterDeleteWriter();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe, because the framework calls an optional interface only on a writer that implements it.');
    }

    @IsTest
    static void afterDeleteDispatcherWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterDeleteDispatcher dispatcher = new LifecycleRoleOnlyAfterDeleteDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            dispatcher.dispatched,
            'It should be Doe, because the framework calls an optional interface only on a dispatcher that implements it.'
        );
    }

    @IsTest
    static void afterUndeleteWriterWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterUndeleteWriter writer = new LifecycleRoleOnlyAfterUndeleteWriter();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe, because the framework calls an optional interface only on a writer that implements it.');
    }

    @IsTest
    static void afterUndeleteDispatcherWithOnlyTheRoleInterfaceRuns() {
        mockFramework();
        LifecycleRoleOnlyAfterUndeleteDispatcher dispatcher = new LifecycleRoleOnlyAfterUndeleteDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            dispatcher.dispatched,
            'It should be Doe, because the framework calls an optional interface only on a dispatcher that implements it.'
        );
    }

    @IsTest
    static void processedRecordsDoNotCarryOverToTheNextRun() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator firstRun = new TriggerOrchestrator(orchestrator);
        firstRun.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        firstRun.context.newRecords = newContacts('Doe');
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        secondRun.context.newRecords = newContacts('Roe');

        // Test
        Test.startTest();
        firstRun.run();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Roe' }, populator.finalized, 'It should be Roe alone, because every run starts with no processed records.');
    }

    @IsTest
    static void successfulRunFinalizesTheLoggerOnce() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.finalizeCalls, 'It should be 1, because the run is the outermost one.');
    }

    @IsTest
    static void failedRunStillFinalizesTheLogger() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.finalizeCalls, 'It should be 1, because the logger is finalized even when the run throws.');
    }

    @IsTest
    static void nestedRunLeavesLoggerFinalizationToTheOutermostRun() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        TestOrchestrator nestedOrchestrator = new TestOrchestrator();
        nestedOrchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator nestedRunner = new TriggerOrchestrator(nestedOrchestrator);
        nestedRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        nestedRunner.context.newRecords = newContacts('Nested');
        BeforeInsertPopulatorSpy outerPopulator = new BeforeInsertPopulatorSpy();
        outerPopulator.runNestedAt('action:Doe', nestedRunner);
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(outerPopulator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.finalizeCalls, 'It should be 1, because only the outermost run finalizes the logger.');
    }

    @IsTest
    static void bypassedRunDoesNotFinalizeTheLogger() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        TriggerOrchestrator.bypass().all();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, logger.finalizeCalls, 'It should be 0, because a bypassed run returns before any execution starts.');
    }

    @IsTest
    static void loggerImplementationIsResolvedFromApexTypeImplementor() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor')
            .thenReturn(
                (ApexTypeImplementor) JSON.deserialize(
                    '{"attributes":{"type":"ApexTypeImplementor"},"ClassName":"TriggerOrchestratorTest.LoggerSpy","ClassNamespacePrefix":null}',
                    ApexTypeImplementor.class
                )
            );

        // Test
        Test.startTest();
        TriggerOrchestrator.Logger resolvedLogger = TriggerOrchestrator.triggerLogger.logger;
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(resolvedLogger, LoggerSpy.class, 'It should be LoggerSpy, because it is the only implementation ApexTypeImplementor returns.');
    }

    @IsTest
    static void moreThanOneLoggerImplementationThrowsOnFirstUse() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor')
            .thenReturn(
                (List<ApexTypeImplementor>) JSON.deserialize(
                    '[{"attributes":{"type":"ApexTypeImplementor"},"ClassName":"FirstLogger","ClassNamespacePrefix":null},{"attributes":{"type":"ApexTypeImplementor"},"ClassName":"SecondLogger","ClassNamespacePrefix":null}]',
                    List<ApexTypeImplementor>.class
                )
            );
        String message;

        // Test
        Test.startTest();
        try {
            new TriggerOrchestrator(new TestOrchestrator());
        } catch (Exception e) {
            message = e.getMessage();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.',
            message,
            'It should be the multiple implementations message, because ApexTypeImplementor returns two loggers.'
        );
    }

    @IsTest
    static void frameworkConfigurationIsQueriedOncePerTransaction() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator firstRun = new TriggerOrchestrator(orchestrator);
        firstRun.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        firstRun.context.newRecords = newContacts('Doe');
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        secondRun.context.newRecords = newContacts('Roe');

        // Test
        Test.startTest();
        firstRun.run();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, SOQL.getQueries(), 'It should be 2, because the bypass metadata and the logger are queried once at class initialisation and never per run.');
    }

    @IsTest
    static void propagatedFailureIsLoggedOnce() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because a failure that propagates is logged exactly once.');
    }

    @IsTest
    static void swallowedFailureIsStillLogged() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because a failure swallowed by ContinueOnError is still logged.');
    }

    @IsTest
    static void successfulRunLogsNothing() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isTrue(logger.errors.isEmpty(), 'It should be empty, because nothing failed.');
    }

    @IsTest
    static void loggedErrorNamesTheFailingHandler() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertValidatorSpy());
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertPopulatorSpy',
            logger.errors[0].getHandlerName(),
            'It should be BeforeInsertPopulatorSpy, because the populator threw after the validator had already run.'
        );
    }

    @IsTest
    static void loggedErrorCarriesTheSObjectType() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'It should be Contact, because the trigger records are Contacts.');
    }

    @IsTest
    static void loggedErrorCarriesTheThrownException() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        SpyException thrown = new SpyException('Boom');
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', thrown);
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isTrue(logger.errors[0].getException() === thrown, 'It should be the same exception instance, because the logger receives what the handler threw.');
    }

    @IsTest
    static void loggedErrorCarriesTheTriggerOperation() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(System.TriggerOperation.AFTER_UPDATE, logger.errors[0].getOperation(), 'It should be AFTER_UPDATE, because the handler failed in that operation.');
    }

    @IsTest
    static void loggedErrorCarriesTheIdsOfTheTriggerRecords() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new Set<Id>{ contacts[0].Id, contacts[1].Id },
            logger.errors[0].getRecordIds(),
            'It should be the Ids of Doe and Roe, because the error carries every trigger record, not only the failing one.'
        );
    }

    @IsTest
    static void loggedErrorOnBeforeInsertCarriesNoRecordIds() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isTrue(logger.errors[0].getRecordIds().isEmpty(), 'It should be empty, because records being inserted have no Id yet.');
    }

    private class LifecycleEveryContextOrchestrator extends TestOrchestrator {
        public LifecycleEveryContextOrchestrator() {
            BeforeInsertPopulatorSpy beforeInsertSpy = new BeforeInsertPopulatorSpy();
            beforeInsertSpy.label = 'beforeInsert';
            this.beforeInsert.add(beforeInsertSpy);

            AfterInsertWriterSpy afterInsertSpy = new AfterInsertWriterSpy();
            afterInsertSpy.label = 'afterInsert';
            this.afterInsert.add(afterInsertSpy);

            BeforeUpdatePopulatorSpy beforeUpdateSpy = new BeforeUpdatePopulatorSpy();
            beforeUpdateSpy.label = 'beforeUpdate';
            this.beforeUpdate.add(beforeUpdateSpy);

            AfterUpdateWriterSpy afterUpdateSpy = new AfterUpdateWriterSpy();
            afterUpdateSpy.label = 'afterUpdate';
            this.afterUpdate.add(afterUpdateSpy);

            BeforeDeleteHandlerSpy beforeDeleteSpy = new BeforeDeleteHandlerSpy();
            beforeDeleteSpy.label = 'beforeDelete';
            this.beforeDelete.add(beforeDeleteSpy);

            AfterDeleteWriterSpy afterDeleteSpy = new AfterDeleteWriterSpy();
            afterDeleteSpy.label = 'afterDelete';
            this.afterDelete.add(afterDeleteSpy);

            AfterUndeleteWriterSpy afterUndeleteSpy = new AfterUndeleteWriterSpy();
            afterUndeleteSpy.label = 'afterUndelete';
            this.afterUndelete.add(afterUndeleteSpy);
        }
    }

    private class LifecycleBeforeInsertOnlyOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return new List<BeforeInsert.Handler>();
        }
    }

    private class LifecyclePopulatedTitlePopulator extends BeforeInsertPopulatorSpy {
        public override Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return record.equals(Contact.Title, 'Populated');
        }
    }

    private class LifecycleRolelessHandler implements BeforeInsert.Handler {
    }

    private class LifecycleRoleOnlyBeforeInsertPopulator extends Spy implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyBeforeInsertValidator extends Spy implements BeforeInsert.Validator {
        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.act(record);
            return this.message;
        }
    }

    private class LifecycleRoleOnlyAfterInsertWriter extends Spy implements AfterInsert.Writer {
        public Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyAfterInsertDispatcher extends Spy implements AfterInsert.Dispatcher {
        public Boolean dispatchOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public void dispatchOnAfterInsert(TriggerHandler.InsertRecords records) {
            this.dispatchWith(records.getRecords());
        }
    }

    private class LifecycleRoleOnlyBeforeUpdatePopulator extends Spy implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyBeforeUpdateValidator extends Spy implements BeforeUpdate.Validator {
        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.act(record);
            return this.message;
        }
    }

    private class LifecycleRoleOnlyAfterUpdateWriter extends Spy implements AfterUpdate.Writer {
        public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyAfterUpdateDispatcher extends Spy implements AfterUpdate.Dispatcher {
        public Boolean dispatchOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public void dispatchOnAfterUpdate(TriggerHandler.UpdateRecords records) {
            this.dispatchWith(records.getRecords());
        }
    }

    private class LifecycleRoleOnlyBeforeDeleteHandler extends Spy implements BeforeDelete.Handler {
        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.evaluate(record);
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyAfterDeleteWriter extends Spy implements AfterDelete.Writer {
        public Boolean writeOnAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.evaluate(record);
        }

        public void writeOnAfterDelete(TriggerHandler.DeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyAfterDeleteDispatcher extends Spy implements AfterDelete.Dispatcher {
        public Boolean dispatchOnAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.evaluate(record);
        }

        public void dispatchOnAfterDelete(TriggerHandler.DeleteRecords records) {
            this.dispatchWith(records.getRecords());
        }
    }

    private class LifecycleRoleOnlyAfterUndeleteWriter extends Spy implements AfterUndelete.Writer {
        public Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return this.evaluate(record);
        }

        public void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
        }
    }

    private class LifecycleRoleOnlyAfterUndeleteDispatcher extends Spy implements AfterUndelete.Dispatcher {
        public Boolean dispatchOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return this.evaluate(record);
        }

        public void dispatchOnAfterUndelete(TriggerHandler.UndeleteRecords records) {
            this.dispatchWith(records.getRecords());
        }
    }

    @IsTest
    static void staticSObjectBypassSkipsTheRun() {
        mockFramework();
        TriggerOrchestrator.bypass().sObject(Contact.SObjectType);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because every Contact trigger run is bypassed.');
    }

    @IsTest
    static void staticSObjectBypassOfAnotherObjectLetsTheRunProceed() {
        mockFramework();
        TriggerOrchestrator.bypass().sObject(Account.SObjectType);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because only Account trigger runs are bypassed.');
    }

    @IsTest
    static void staticBypassAllSkipsTheRun() {
        mockFramework();
        TriggerOrchestrator.bypass().all();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because every trigger run is bypassed.');
    }

    @IsTest
    static void staticBypassClearLiftsEarlierBypasses() {
        mockFramework();
        TriggerOrchestrator.bypass().sObject(Contact.SObjectType);
        TriggerOrchestrator.bypass().clear();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because clear removed the Contact bypass.');
    }

    @IsTest
    static void staticOrchestratorBypassOfAnotherTypeLetsTheRunProceed() {
        mockFramework();
        TriggerOrchestrator.bypass().orchestrator(TriggerHandler.class);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the bypassed orchestrator type is not the one running.');
    }

    @IsTest
    static void staticHandlerBypassOfAnotherTypeLetsTheHandlerRun() {
        mockFramework();
        TriggerOrchestrator.bypass().handler(AfterInsertWriterSpy.class);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the bypassed handler type is not the populator.');
    }

    @IsTest
    static void staticBypassBuilderMethodsReturnTheSameInstance() {
        mockFramework();

        // Test
        Test.startTest();
        TriggerOrchestrator.Bypassable chained = TriggerOrchestrator.bypass().sObject(Account.SObjectType).orchestrator(TriggerHandler.class).handler(TriggerHandler.class);
        Test.stopTest();

        // Verify
        Assert.isTrue(chained === TriggerOrchestrator.bypass(), 'It should be the bypass instance itself, because every builder method returns it for chaining.');
    }

    @IsTest
    static void objectMetadataBypassSkipsTheRun() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', true, new List<String>()) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the Contact metadata record bypasses the object.');
    }

    @IsTest
    static void objectMetadataWithBypassOffLetsTheRunProceed() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>()) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the Contact metadata record has Bypass__c off.');
    }

    @IsTest
    static void objectMetadataOfAnotherObjectDoesNotBypass() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Account', true, new List<String>()) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because only the Account metadata record is bypassed.');
    }

    @IsTest
    static void objectMetadataNameIsTrimmed() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting(' Contact ', true, new List<String>()) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the spaces around the object name are trimmed.');
    }

    @IsTest
    static void objectMetadataNameIsCaseInsensitive() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('CONTACT', true, new List<String>()) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the object name is matched ignoring case.');
    }

    @IsTest
    static void objectMetadataBypassOnDeleteResolvesTheObjectFromTheOldRecords() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', true, new List<String>()) });
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), writer.evaluated, 'It should be empty, because the object is resolved from the old records when there are no new ones.');
    }

    @IsTest
    static void handlerMetadataBypassSkipsTheHandler() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>{ 'BeforeInsertPopulatorSpy' }) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the handler metadata record bypasses the populator.');
    }

    @IsTest
    static void handlerMetadataBypassLeavesOtherHandlersRunning() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>{ 'BeforeInsertValidatorSpy' }) });
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because only the validator is bypassed.');
    }

    @IsTest
    static void handlerMetadataOuterQualifiedNameBypassesAnInnerClassHandler() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>{ 'TriggerOrchestratorTest.BeforeInsertPopulatorSpy' }) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because a qualified name also matches by its part after the last dot.');
    }

    @IsTest
    static void handlerMetadataNameIsTrimmed() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>{ ' BeforeInsertPopulatorSpy ' }) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the spaces around the handler name are trimmed.');
    }

    @IsTest
    static void handlerMetadataNameIsCaseInsensitive() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>{ 'BEFOREINSERTPOPULATORSPY' }) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the handler name is matched ignoring case.');
    }

    @IsTest
    static void handlerMetadataUnderAnotherObjectDoesNotBypass() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Account', false, new List<String>{ 'BeforeInsertPopulatorSpy' }) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the handler is bypassed only for Account.');
    }

    @IsTest
    static void handlerMetadataBypassedHandlerIsNotAskedForItsOwnBypass() {
        mockFramework(new List<TriggerObject__mdt>{ objectSetting('Contact', false, new List<String>{ 'BeforeInsertPopulatorSpy' }) });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), calls('bypass'), 'It should be empty, because the metadata bypass is decided before the handler is asked.');
    }

    @IsTest
    static void beforeInsertPopulatorReturningBypassIsSkipped() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the populator returns true from bypassOnBeforeInsertWhen.');
    }

    @IsTest
    static void beforeInsertValidatorReturningBypassIsSkipped() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), validator.evaluated, 'It should be empty, because the validator returns true from bypassOnBeforeInsertWhen.');
    }

    @IsTest
    static void afterInsertWriterReturningBypassIsSkipped() {
        mockFramework();
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), writer.evaluated, 'It should be empty, because the writer returns true from bypassOnAfterInsertWhen.');
    }

    @IsTest
    static void afterInsertDispatcherReturningBypassIsSkipped() {
        mockFramework();
        AfterInsertDispatcherSpy dispatcher = new AfterInsertDispatcherSpy();
        dispatcher.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), dispatcher.evaluated, 'It should be empty, because the dispatcher returns true from bypassOnAfterInsertWhen.');
    }

    @IsTest
    static void beforeUpdatePopulatorReturningBypassIsSkipped() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), populator.evaluated, 'It should be empty, because the populator returns true from bypassOnBeforeUpdateWhen.');
    }

    @IsTest
    static void beforeUpdateValidatorReturningBypassIsSkipped() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), validator.evaluated, 'It should be empty, because the validator returns true from bypassOnBeforeUpdateWhen.');
    }

    @IsTest
    static void afterUpdateWriterReturningBypassIsSkipped() {
        mockFramework();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), writer.evaluated, 'It should be empty, because the writer returns true from bypassOnAfterUpdateWhen.');
    }

    @IsTest
    static void afterUpdateDispatcherReturningBypassIsSkipped() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        dispatcher.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), dispatcher.evaluated, 'It should be empty, because the dispatcher returns true from bypassOnAfterUpdateWhen.');
    }

    @IsTest
    static void beforeDeleteHandlerReturningBypassIsSkipped() {
        mockFramework();
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), handler.evaluated, 'It should be empty, because the handler returns true from bypassOnBeforeDeleteWhen.');
    }

    @IsTest
    static void afterDeleteWriterReturningBypassIsSkipped() {
        mockFramework();
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), writer.evaluated, 'It should be empty, because the writer returns true from bypassOnAfterDeleteWhen.');
    }

    @IsTest
    static void afterDeleteDispatcherReturningBypassIsSkipped() {
        mockFramework();
        AfterDeleteDispatcherSpy dispatcher = new AfterDeleteDispatcherSpy();
        dispatcher.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), dispatcher.evaluated, 'It should be empty, because the dispatcher returns true from bypassOnAfterDeleteWhen.');
    }

    @IsTest
    static void afterUndeleteWriterReturningBypassIsSkipped() {
        mockFramework();
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), writer.evaluated, 'It should be empty, because the writer returns true from bypassOnAfterUndeleteWhen.');
    }

    @IsTest
    static void afterUndeleteDispatcherReturningBypassIsSkipped() {
        mockFramework();
        AfterUndeleteDispatcherSpy dispatcher = new AfterUndeleteDispatcherSpy();
        dispatcher.bypassed = true;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), dispatcher.evaluated, 'It should be empty, because the dispatcher returns true from bypassOnAfterUndeleteWhen.');
    }

    @IsTest
    static void bypassableReturningFalseLetsTheHandlerRun() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.bypassed = false;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because the populator returns false from bypassOnBeforeInsertWhen.');
    }

    @IsTest
    static void bypassableIsAskedOncePerRunNotPerRecord() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('bypass').size(), 'It should be 1, because the bypass decision covers the whole run, not each of the two records.');
    }

    @IsTest
    static void bypassedHandlerContributesNoParentQuery() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.bypassed = true;
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>(), calls('parentQuery'), 'It should be empty, because parents are declared only by active handlers.');
    }

    @IsTest
    static void beforeInsertPopulatorPopulatesOnlyQualifiedRecords() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeInsertValidatorAsksAMessageOnlyForQualifiedRecords() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, validator.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterInsertWriterWritesOnlyQualifiedRecords() {
        mockFramework();
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterInsertDispatcherDispatchesOnlyQualifiedRecords() {
        mockFramework();
        AfterInsertDispatcherSpy dispatcher = new AfterInsertDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.dispatched, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeUpdatePopulatorPopulatesOnlyQualifiedRecords() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeUpdateValidatorAsksAMessageOnlyForQualifiedRecords() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, validator.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUpdateWriterWritesOnlyQualifiedRecords() {
        mockFramework();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUpdateDispatcherDispatchesOnlyQualifiedRecords() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.dispatched, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeDeleteHandlerHandlesOnlyQualifiedRecords() {
        mockFramework();
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, handler.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterDeleteWriterWritesOnlyQualifiedRecords() {
        mockFramework();
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterDeleteDispatcherDispatchesOnlyQualifiedRecords() {
        mockFramework();
        AfterDeleteDispatcherSpy dispatcher = new AfterDeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.dispatched, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUndeleteWriterWritesOnlyQualifiedRecords() {
        mockFramework();
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUndeleteDispatcherDispatchesOnlyQualifiedRecords() {
        mockFramework();
        AfterUndeleteDispatcherSpy dispatcher = new AfterUndeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.dispatched, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterInsertDispatcherIsNotCalledWhenNoRecordQualifies() {
        mockFramework();
        AfterInsertDispatcherSpy dispatcher = new AfterInsertDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.dispatched, 'It should be null, because an empty collection is never dispatched.');
    }

    @IsTest
    static void afterUpdateDispatcherIsNotCalledWhenNoRecordQualifies() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.dispatched, 'It should be null, because an empty collection is never dispatched.');
    }

    @IsTest
    static void afterDeleteDispatcherIsNotCalledWhenNoRecordQualifies() {
        mockFramework();
        AfterDeleteDispatcherSpy dispatcher = new AfterDeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.dispatched, 'It should be null, because an empty collection is never dispatched.');
    }

    @IsTest
    static void afterUndeleteDispatcherIsNotCalledWhenNoRecordQualifies() {
        mockFramework();
        AfterUndeleteDispatcherSpy dispatcher = new AfterUndeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.dispatched, 'It should be null, because an empty collection is never dispatched.');
    }

    @IsTest
    static void afterInsertDispatcherIsCalledOncePerRun() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new AfterInsertDispatcherSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('dispatch').size(), 'It should be 1, because the dispatcher receives both qualified records in a single call.');
    }

    @IsTest
    static void afterUpdateDispatcherIsCalledOncePerRun() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(new AfterUpdateDispatcherSpy());
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('dispatch').size(), 'It should be 1, because the dispatcher receives both qualified records in a single call.');
    }

    @IsTest
    static void afterDeleteDispatcherIsCalledOncePerRun() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(new AfterDeleteDispatcherSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('dispatch').size(), 'It should be 1, because the dispatcher receives both qualified records in a single call.');
    }

    @IsTest
    static void afterUndeleteDispatcherIsCalledOncePerRun() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(new AfterUndeleteDispatcherSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('dispatch').size(), 'It should be 1, because the dispatcher receives both qualified records in a single call.');
    }

    @IsTest
    static void afterInsertDispatcherDispatchesBeforeItsFinalizer() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new AfterInsertDispatcherSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Integer callCount = TriggerOrchestratorTest.callLog.size();
        Assert.areEqual(
            new List<String>{ 'spy.dispatch', 'spy.finalize' },
            new List<String>{ TriggerOrchestratorTest.callLog[callCount - 2], TriggerOrchestratorTest.callLog[callCount - 1] },
            'It should be dispatch followed by finalize, because the finalizer closes the handler run.'
        );
    }

    @IsTest
    static void afterUpdateDispatcherDispatchesBeforeItsFinalizer() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(new AfterUpdateDispatcherSpy());
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Integer callCount = TriggerOrchestratorTest.callLog.size();
        Assert.areEqual(
            new List<String>{ 'spy.dispatch', 'spy.finalize' },
            new List<String>{ TriggerOrchestratorTest.callLog[callCount - 2], TriggerOrchestratorTest.callLog[callCount - 1] },
            'It should be dispatch followed by finalize, because the finalizer closes the handler run.'
        );
    }

    @IsTest
    static void afterDeleteDispatcherDispatchesBeforeItsFinalizer() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(new AfterDeleteDispatcherSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Integer callCount = TriggerOrchestratorTest.callLog.size();
        Assert.areEqual(
            new List<String>{ 'spy.dispatch', 'spy.finalize' },
            new List<String>{ TriggerOrchestratorTest.callLog[callCount - 2], TriggerOrchestratorTest.callLog[callCount - 1] },
            'It should be dispatch followed by finalize, because the finalizer closes the handler run.'
        );
    }

    @IsTest
    static void afterUndeleteDispatcherDispatchesBeforeItsFinalizer() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(new AfterUndeleteDispatcherSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Integer callCount = TriggerOrchestratorTest.callLog.size();
        Assert.areEqual(
            new List<String>{ 'spy.dispatch', 'spy.finalize' },
            new List<String>{ TriggerOrchestratorTest.callLog[callCount - 2], TriggerOrchestratorTest.callLog[callCount - 1] },
            'It should be dispatch followed by finalize, because the finalizer closes the handler run.'
        );
    }

    @IsTest
    static void beforeInsertValidatorAttachesItsMessageToTheTriggerRecord() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.message = 'Rejected';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        List<Contact> contacts = newContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Rejected', contacts[0].getErrors()[0].getMessage(), 'It should be Rejected, because that is the message the validator returned for Doe.');
    }

    @IsTest
    static void beforeUpdateValidatorAttachesItsMessageToTheNewRecord() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.message = 'Rejected';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Rejected', contacts[0].getErrors()[0].getMessage(), 'It should be Rejected, because that is the message the validator returned for Doe.');
    }

    @IsTest
    static void beforeInsertPopulatorWritesLandOnTheTriggerRecord() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.populatedField = Contact.Title;
        populator.populatedValue = 'Populated';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        List<Contact> contacts = newContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Populated', contacts[0].Title, 'It should be Populated, because the populator put that Title on the trigger record.');
    }

    @IsTest
    static void beforeInsertPopulatorFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeInsertValidatorFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, validator.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterInsertWriterFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterInsertDispatcherFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterInsertDispatcherSpy dispatcher = new AfterInsertDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeUpdatePopulatorFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeUpdateValidatorFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, validator.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUpdateWriterFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUpdateDispatcherFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeDeleteHandlerFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, handler.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterDeleteWriterFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterDeleteDispatcherFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterDeleteDispatcherSpy dispatcher = new AfterDeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUndeleteWriterFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void afterUndeleteDispatcherFinalizerReceivesTheProcessedRecords() {
        mockFramework();
        AfterUndeleteDispatcherSpy dispatcher = new AfterUndeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>{ 'Doe' };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.finalized, 'It should be Doe alone, because Roe does not qualify.');
    }

    @IsTest
    static void beforeInsertPopulatorFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(populator.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void beforeInsertValidatorFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(validator.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterInsertWriterFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(writer.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterInsertDispatcherFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterInsertDispatcherSpy dispatcher = new AfterInsertDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void beforeUpdatePopulatorFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(populator.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void beforeUpdateValidatorFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(validator.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterUpdateWriterFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(writer.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterUpdateDispatcherFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void beforeDeleteHandlerFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(handler.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterDeleteWriterFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(writer.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterDeleteDispatcherFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterDeleteDispatcherSpy dispatcher = new AfterDeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterUndeleteWriterFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(writer.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void afterUndeleteDispatcherFinalizerIsSkippedWhenNoRecordQualifies() {
        mockFramework();
        AfterUndeleteDispatcherSpy dispatcher = new AfterUndeleteDispatcherSpy();
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(dispatcher.finalized, 'It should be null, because the finalizer is skipped when no record qualifies.');
    }

    @IsTest
    static void finalizerRunsAfterTheLastRecordIsProcessed() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isTrue(
            TriggerOrchestratorTest.callLog.indexOf('spy.finalize') > TriggerOrchestratorTest.callLog.indexOf('spy.action:Roe'),
            'It should come after Roe, because the finalizer waits until the last record is processed.'
        );
    }

    @IsTest
    static void finalizerRunsBeforeTheNextHandlerStarts() {
        mockFramework();
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.label = 'first';
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.label = 'second';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Integer firstFinalize = TriggerOrchestratorTest.callLog.indexOf('first.finalize');
        Assert.isTrue(
            firstFinalize != -1 && firstFinalize < TriggerOrchestratorTest.callLog.indexOf('second.when:Doe'),
            'It should come before the second handler evaluates Doe, because a handler finalizes before the next handler starts.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the populator exception, because the populator does not opt into ContinueOnError.');
    }

    @IsTest
    static void beforeInsertValidatorFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the validator exception, because the validator does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterInsertWriterFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the writer exception, because the writer does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterInsertDispatcherFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterInsertDispatcherSpy dispatcher = new AfterInsertDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the dispatcher exception, because the dispatcher does not opt into ContinueOnError.');
    }

    @IsTest
    static void beforeUpdatePopulatorFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the populator exception, because the populator does not opt into ContinueOnError.');
    }

    @IsTest
    static void beforeUpdateValidatorFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the validator exception, because the validator does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterUpdateWriterFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the writer exception, because the writer does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterUpdateDispatcherFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the dispatcher exception, because the dispatcher does not opt into ContinueOnError.');
    }

    @IsTest
    static void beforeDeleteHandlerFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the handler exception, because the handler does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterDeleteWriterFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the writer exception, because the writer does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterDeleteDispatcherFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterDeleteDispatcherSpy dispatcher = new AfterDeleteDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the dispatcher exception, because the dispatcher does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterUndeleteWriterFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the writer exception, because the writer does not opt into ContinueOnError.');
    }

    @IsTest
    static void afterUndeleteDispatcherFailureWithoutContinueOnErrorPropagates() {
        mockFramework();
        AfterUndeleteDispatcherSpy dispatcher = new AfterUndeleteDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the dispatcher exception, because the dispatcher does not opt into ContinueOnError.');
    }

    @IsTest
    static void beforeInsertPopulatorFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the populator opts into ContinueOnError.');
    }

    @IsTest
    static void beforeInsertValidatorFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingBeforeInsertValidatorSpy validator = new ContinuingBeforeInsertValidatorSpy();
        validator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the validator opts into ContinueOnError.');
    }

    @IsTest
    static void afterInsertWriterFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterInsertWriterSpy writer = new ContinuingAfterInsertWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the writer opts into ContinueOnError.');
    }

    @IsTest
    static void afterInsertDispatcherFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterInsertDispatcherSpy dispatcher = new ContinuingAfterInsertDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the dispatcher opts into ContinueOnError.');
    }

    @IsTest
    static void beforeUpdatePopulatorFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingBeforeUpdatePopulatorSpy populator = new ContinuingBeforeUpdatePopulatorSpy();
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the populator opts into ContinueOnError.');
    }

    @IsTest
    static void beforeUpdateValidatorFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingBeforeUpdateValidatorSpy validator = new ContinuingBeforeUpdateValidatorSpy();
        validator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the validator opts into ContinueOnError.');
    }

    @IsTest
    static void afterUpdateWriterFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterUpdateWriterSpy writer = new ContinuingAfterUpdateWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the writer opts into ContinueOnError.');
    }

    @IsTest
    static void afterUpdateDispatcherFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterUpdateDispatcherSpy dispatcher = new ContinuingAfterUpdateDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the dispatcher opts into ContinueOnError.');
    }

    @IsTest
    static void beforeDeleteHandlerFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingBeforeDeleteHandlerSpy handler = new ContinuingBeforeDeleteHandlerSpy();
        handler.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the handler opts into ContinueOnError.');
    }

    @IsTest
    static void afterDeleteWriterFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterDeleteWriterSpy writer = new ContinuingAfterDeleteWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the writer opts into ContinueOnError.');
    }

    @IsTest
    static void afterDeleteDispatcherFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterDeleteDispatcherSpy dispatcher = new ContinuingAfterDeleteDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the dispatcher opts into ContinueOnError.');
    }

    @IsTest
    static void afterUndeleteWriterFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterUndeleteWriterSpy writer = new ContinuingAfterUndeleteWriterSpy();
        writer.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the writer opts into ContinueOnError.');
    }

    @IsTest
    static void afterUndeleteDispatcherFailureWithContinueOnErrorIsSwallowed() {
        mockFramework();
        ContinuingAfterUndeleteDispatcherSpy dispatcher = new ContinuingAfterUndeleteDispatcherSpy();
        dispatcher.failAt('dispatch', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the dispatcher opts into ContinueOnError.');
    }

    @IsTest
    static void swallowedFailureStopsTheHandlerAtTheFailingRecord() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.evaluated, 'It should be Doe alone, because the failure on Doe ends the loop before Roe is evaluated.');
    }

    @IsTest
    static void swallowedFailureSkipsTheFailingHandlersFinalizer() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(populator.finalized, 'It should be null, because the failure skips the rest of the handler, including its finalizer.');
    }

    @IsTest
    static void handlerAfterASwallowedFailureStillRuns() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy first = new ContinuingBeforeInsertPopulatorSpy();
        first.label = 'first';
        first.failAt('action', new SpyException('Boom'));
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.label = 'second';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, second.acted, 'It should be Doe, because the first handler failure is swallowed.');
    }

    @IsTest
    static void predicateFailureIsSwallowedWithContinueOnError() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('when', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because ContinueOnError covers the predicate too.');
    }

    @IsTest
    static void finalizerFailureIsSwallowedWithContinueOnError() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('finalize', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because ContinueOnError covers the finalizer too.');
    }

    @IsTest
    static void relatedQueryFailureIsSwallowedWithContinueOnError() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.failAt('relatedQuery', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because ContinueOnError covers the related query too.');
    }

    @IsTest
    static void triggerHandlerExceptionPropagatesDespiteContinueOnError() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.readsProvider = 'unknown';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(
            failure,
            TriggerHandler.TriggerHandlerException.class,
            'It should be the TriggerHandlerException, because a misused framework API is never swallowed.'
        );
    }

    @IsTest
    static void frameworkExceptionPropagatesDespiteContinueOnError() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        TriggerOrchestrator nestedRunner = new TriggerOrchestrator(new TestOrchestrator());
        populator.runNestedAt('action:Doe', nestedRunner);
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            failure?.getMessage(),
            'It should be the nested run TriggerOrchestratorException, because framework exceptions are never swallowed.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorPerformingDmlThrows() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertPopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the populator performed DML in a before context.'
        );
    }

    @IsTest
    static void beforeInsertValidatorPerformingDmlThrows() {
        mockFramework();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertValidatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the validator performed DML in a before context.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorPerformingDmlThrows() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeUpdatePopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the populator performed DML in a before context.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorPerformingDmlThrows() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeUpdateValidatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the validator performed DML in a before context.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorDmlViolationIsLogged() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertPopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            logger.errors[0].getException().getMessage(),
            'It should be the DML guard message, because the guard logs the violation before it throws.'
        );
    }

    @IsTest
    static void beforeInsertValidatorDmlViolationIsLogged() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeInsertValidatorSpy validator = new BeforeInsertValidatorSpy();
        validator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertValidatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            logger.errors[0].getException().getMessage(),
            'It should be the DML guard message, because the guard logs the violation before it throws.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorDmlViolationIsLogged() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeUpdatePopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            logger.errors[0].getException().getMessage(),
            'It should be the DML guard message, because the guard logs the violation before it throws.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorDmlViolationIsLogged() {
        mockFramework();
        LoggerSpy logger = spyOnLogger();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        validator.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeUpdateValidatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            logger.errors[0].getException().getMessage(),
            'It should be the DML guard message, because the guard logs the violation before it throws.'
        );
    }

    @IsTest
    static void beforeInsertPopulatorGuardStillFiresAfterASwallowedFailure() {
        mockFramework();
        ContinuingBeforeInsertPopulatorSpy populator = new ContinuingBeforeInsertPopulatorSpy();
        populator.performDmlAt('action:Doe');
        populator.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'ContinuingBeforeInsertPopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because ContinueOnError swallows only the handler exception, not the guard.'
        );
    }

    @IsTest
    static void beforeInsertValidatorGuardStillFiresAfterASwallowedFailure() {
        mockFramework();
        ContinuingBeforeInsertValidatorSpy validator = new ContinuingBeforeInsertValidatorSpy();
        validator.performDmlAt('action:Doe');
        validator.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(validator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'ContinuingBeforeInsertValidatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because ContinueOnError swallows only the handler exception, not the guard.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorGuardStillFiresAfterASwallowedFailure() {
        mockFramework();
        ContinuingBeforeUpdatePopulatorSpy populator = new ContinuingBeforeUpdatePopulatorSpy();
        populator.performDmlAt('action:Doe');
        populator.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'ContinuingBeforeUpdatePopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because ContinueOnError swallows only the handler exception, not the guard.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorGuardStillFiresAfterASwallowedFailure() {
        mockFramework();
        ContinuingBeforeUpdateValidatorSpy validator = new ContinuingBeforeUpdateValidatorSpy();
        validator.performDmlAt('action:Doe');
        validator.failAt('action:Doe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'ContinuingBeforeUpdateValidatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because ContinueOnError swallows only the handler exception, not the guard.'
        );
    }

    @IsTest
    static void dmlInAPredicateTripsTheGuard() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.performDmlAt('when');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertPopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the guard also covers the predicate.'
        );
    }

    @IsTest
    static void dmlInAFinalizerTripsTheGuard() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.performDmlAt('finalize');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertPopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the guard also covers the finalizer.'
        );
    }

    @IsTest
    static void dmlInARelatedQueryTripsTheGuard() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.performDmlAt('relatedQuery');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'BeforeInsertPopulatorSpy performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            failure?.getMessage(),
            'It should be the DML guard message, because the guard also covers the related query.'
        );
    }

    @IsTest
    static void handlerFailureAfterDmlPropagatesTheHandlersOwnException() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.performDmlAt('action');
        populator.failAt('action', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, SpyException.class, 'It should be the handler exception, because it propagates before the guard runs.');
    }

    @IsTest
    static void dmlBeforeTheRunDoesNotTripTheGuard() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Database.setSavepoint();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the guard counts only the DML performed while the handler runs.');
    }

    @IsTest
    static void beforeDeleteHandlerMayPerformDml() {
        mockFramework();
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because before delete has no DML guard.');
    }

    @IsTest
    static void afterInsertWriterMayPerformDml() {
        mockFramework();
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.performDmlAt('action');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be null, because the after insert writer has no DML guard.');
    }

    @IsTest
    static void beforeUpdatePopulatorStopsAfterTheDefaultThreeRuns() {
        mockFramework();
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
            earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            earlierRun.context.newRecords = contacts;
            earlierRun.context.oldRecords = priorVersionsOf(contacts);
            earlierRun.run();
        }
        TriggerOrchestrator fourthRun = new TriggerOrchestrator(orchestrator);
        fourthRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        fourthRun.context.newRecords = contacts;
        fourthRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        fourthRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(3, populator.acted.size(), 'It should be 3, because the fourth run exceeds the default recursion depth of 3.');
    }

    @IsTest
    static void afterUpdateWriterStopsAfterTheDefaultThreeRuns() {
        mockFramework();
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = contacts;
            earlierRun.context.oldRecords = priorVersionsOf(contacts);
            earlierRun.run();
        }
        TriggerOrchestrator fourthRun = new TriggerOrchestrator(orchestrator);
        fourthRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        fourthRun.context.newRecords = contacts;
        fourthRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        fourthRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(3, writer.acted.size(), 'It should be 3, because the fourth run exceeds the default recursion depth of 3.');
    }

    @IsTest
    static void afterUpdateDispatcherStopsAfterTheDefaultThreeRuns() {
        mockFramework();
        AfterUpdateDispatcherSpy dispatcher = new AfterUpdateDispatcherSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
            earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            earlierRun.context.newRecords = contacts;
            earlierRun.context.oldRecords = priorVersionsOf(contacts);
            earlierRun.run();
        }
        TriggerOrchestrator fourthRun = new TriggerOrchestrator(orchestrator);
        fourthRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        fourthRun.context.newRecords = contacts;
        fourthRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        fourthRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(3, calls('dispatch').size(), 'It should be 3, because the fourth run exceeds the default recursion depth of 3.');
    }

    @IsTest
    static void beforeUpdatePopulatorRecursionGuardSetsItsOwnDepth() {
        mockFramework();
        GuardedBeforeUpdatePopulatorSpy populator = new GuardedBeforeUpdatePopulatorSpy();
        populator.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, populator.acted.size(), 'It should be 1, because the handler limits its own recursion depth to 1.');
    }

    @IsTest
    static void afterUpdateWriterRecursionGuardSetsItsOwnDepth() {
        mockFramework();
        GuardedAfterUpdateWriterSpy writer = new GuardedAfterUpdateWriterSpy();
        writer.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, writer.acted.size(), 'It should be 1, because the handler limits its own recursion depth to 1.');
    }

    @IsTest
    static void afterUpdateDispatcherRecursionGuardSetsItsOwnDepth() {
        mockFramework();
        GuardedAfterUpdateDispatcherSpy dispatcher = new GuardedAfterUpdateDispatcherSpy();
        dispatcher.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('dispatch').size(), 'It should be 1, because the handler limits its own recursion depth to 1.');
    }

    @IsTest
    static void beforeUpdatePopulatorSkipsAnExhaustedRecordBeforeItsPredicate() {
        mockFramework();
        GuardedBeforeUpdatePopulatorSpy populator = new GuardedBeforeUpdatePopulatorSpy();
        populator.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, populator.evaluated.size(), 'It should be 1, because the exhausted Doe is skipped before its predicate is asked.');
    }

    @IsTest
    static void afterUpdateWriterSkipsAnExhaustedRecordBeforeItsPredicate() {
        mockFramework();
        GuardedAfterUpdateWriterSpy writer = new GuardedAfterUpdateWriterSpy();
        writer.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, writer.evaluated.size(), 'It should be 1, because the exhausted Doe is skipped before its predicate is asked.');
    }

    @IsTest
    static void afterUpdateDispatcherSkipsAnExhaustedRecordBeforeItsPredicate() {
        mockFramework();
        GuardedAfterUpdateDispatcherSpy dispatcher = new GuardedAfterUpdateDispatcherSpy();
        dispatcher.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, dispatcher.evaluated.size(), 'It should be 1, because the exhausted Doe is skipped before its predicate is asked.');
    }

    @IsTest
    static void beforeUpdatePopulatorUnqualifiedRunDoesNotConsumeTheBudget() {
        mockFramework();
        GuardedBeforeUpdatePopulatorSpy populator = new GuardedBeforeUpdatePopulatorSpy();
        populator.maxDepth = 1;
        populator.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        populator.qualifying = null;
        TriggerOrchestrator qualifiedRun = new TriggerOrchestrator(orchestrator);
        qualifiedRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        qualifiedRun.context.newRecords = contacts;
        qualifiedRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        qualifiedRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, populator.acted, 'It should be Doe, because a run in which Doe does not qualify leaves its budget untouched.');
    }

    @IsTest
    static void afterUpdateWriterUnqualifiedRunDoesNotConsumeTheBudget() {
        mockFramework();
        GuardedAfterUpdateWriterSpy writer = new GuardedAfterUpdateWriterSpy();
        writer.maxDepth = 1;
        writer.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        writer.qualifying = null;
        TriggerOrchestrator qualifiedRun = new TriggerOrchestrator(orchestrator);
        qualifiedRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        qualifiedRun.context.newRecords = contacts;
        qualifiedRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        qualifiedRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, writer.acted, 'It should be Doe, because a run in which Doe does not qualify leaves its budget untouched.');
    }

    @IsTest
    static void afterUpdateDispatcherUnqualifiedRunDoesNotConsumeTheBudget() {
        mockFramework();
        GuardedAfterUpdateDispatcherSpy dispatcher = new GuardedAfterUpdateDispatcherSpy();
        dispatcher.maxDepth = 1;
        dispatcher.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        dispatcher.qualifying = null;
        TriggerOrchestrator qualifiedRun = new TriggerOrchestrator(orchestrator);
        qualifiedRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        qualifiedRun.context.newRecords = contacts;
        qualifiedRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        qualifiedRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe' }, dispatcher.dispatched, 'It should be Doe, because a run in which Doe does not qualify leaves its budget untouched.');
    }

    @IsTest
    static void recursionBudgetIsTrackedPerRecord() {
        mockFramework();
        GuardedAfterUpdateWriterSpy writer = new GuardedAfterUpdateWriterSpy();
        writer.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> doe = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = doe;
        earlierRun.context.oldRecords = priorVersionsOf(doe);
        earlierRun.run();
        List<Contact> doeAndRoe = savedContacts('Doe', 'Roe');
        doeAndRoe[0].Id = doe[0].Id;
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        secondRun.context.newRecords = doeAndRoe;
        secondRun.context.oldRecords = priorVersionsOf(doeAndRoe);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe', 'Roe' }, writer.acted, 'It should be Doe once and Roe once, because the budget Doe used up does not apply to Roe.');
    }

    @IsTest
    static void recursionBudgetIsTrackedPerHandlerClass() {
        mockFramework();
        GuardedAfterUpdateWriterSpy writer = new GuardedAfterUpdateWriterSpy();
        writer.maxDepth = 1;
        GuardedAfterUpdateDispatcherSpy dispatcher = new GuardedAfterUpdateDispatcherSpy();
        dispatcher.maxDepth = 1;
        TestOrchestrator writerOrchestrator = new TestOrchestrator();
        writerOrchestrator.afterUpdate.add(writer);
        TestOrchestrator dispatcherOrchestrator = new TestOrchestrator();
        dispatcherOrchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(writerOrchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator dispatcherRun = new TriggerOrchestrator(dispatcherOrchestrator);
        dispatcherRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        dispatcherRun.context.newRecords = contacts;
        dispatcherRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        dispatcherRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('dispatch').size(), 'It should be 1, because the budget the writer used up belongs to the writer class alone.');
    }

    @IsTest
    static void twoInstancesOfOneHandlerClassShareOneBudget() {
        mockFramework();
        GuardedAfterUpdateWriterSpy first = new GuardedAfterUpdateWriterSpy();
        first.maxDepth = 1;
        first.label = 'first';
        GuardedAfterUpdateWriterSpy second = new GuardedAfterUpdateWriterSpy();
        second.maxDepth = 1;
        second.label = 'second';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(first);
        orchestrator.afterUpdate.add(second);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'first.action:Doe' }, calls('action'), 'It should be the first instance alone, because both instances draw on one budget per class.');
    }

    @IsTest
    static void beforeUpdateAndAfterUpdateBudgetsAreIndependent() {
        mockFramework();
        GuardBothUpdateContextsSpy handler = new GuardBothUpdateContextsSpy();
        handler.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(handler);
        orchestrator.afterUpdate.add(handler);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator afterUpdateRun = new TriggerOrchestrator(orchestrator);
        afterUpdateRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        afterUpdateRun.context.newRecords = contacts;
        afterUpdateRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        afterUpdateRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe', 'Doe' }, handler.acted, 'It should be Doe in both contexts, because each context keeps its own budget.');
    }

    @IsTest
    static void exhaustedRecordsSkipTheFinalizer() {
        mockFramework();
        GuardedAfterUpdateWriterSpy writer = new GuardedAfterUpdateWriterSpy();
        writer.maxDepth = 1;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
        earlierRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        earlierRun.context.newRecords = contacts;
        earlierRun.context.oldRecords = priorVersionsOf(contacts);
        earlierRun.run();
        TriggerOrchestrator secondRun = new TriggerOrchestrator(orchestrator);
        secondRun.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        secondRun.context.newRecords = contacts;
        secondRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        secondRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('finalize').size(), 'It should be 1, because a run with only exhausted records processes nothing to finalize.');
    }

    @IsTest
    static void beforeUpdateValidatorHasNoRecursionLimit() {
        mockFramework();
        BeforeUpdateValidatorSpy validator = new BeforeUpdateValidatorSpy();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(validator);
        List<Contact> contacts = savedContacts('Doe');
        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator earlierRun = new TriggerOrchestrator(orchestrator);
            earlierRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            earlierRun.context.newRecords = contacts;
            earlierRun.context.oldRecords = priorVersionsOf(contacts);
            earlierRun.run();
        }
        TriggerOrchestrator fourthRun = new TriggerOrchestrator(orchestrator);
        fourthRun.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        fourthRun.context.newRecords = contacts;
        fourthRun.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        fourthRun.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(4, validator.acted.size(), 'It should be 4, because validators are not recursion tracked.');
    }

    private class GuardBothUpdateContextsSpy extends GuardedBeforeUpdatePopulatorSpy implements AfterUpdate.Writer, AfterUpdate.RecursionGuard {
        public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
        }

        public Integer maxRecursionDepthOnAfterUpdate() {
            return this.maxDepth;
        }
    }

    @IsTest
    static void beforeInsertParentQueryAttachesTheNewParent() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', populator.newParents[0].get(Account.Name), 'It should be Acme, because Doe points at it.');
    }

    @IsTest
    static void afterInsertParentQueryAttachesTheNewParentFromTheSavedRecords() {
        mockFramework();
        Account parent = savedAccount('Acme');
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = parent.Id;
        Contact saved = new Contact(Id = contacts[0].Id, AccountId = parent.Id);
        saved.Account = parent;
        SOQL.mock(Contact.SObjectType).thenReturn(saved);
        SOQL.mock(Account.SObjectType).thenReturn(new Account(Id = parent.Id, Name = 'Queried'));
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', writer.newParents[0].get(Account.Name), 'It should be Acme, because the saved Doe carries it.');
    }

    @IsTest
    static void beforeUpdateParentQueryAttachesTheNewParent() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        List<Contact> priorVersions = priorVersionsOf(contacts);
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersions;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', populator.newParents[0].get(Account.Name), 'It should be Acme, because the new Doe points at it.');
    }

    @IsTest
    static void beforeUpdatePriorParentQueryAttachesTheOldParent() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        List<Contact> priorVersions = priorVersionsOf(contacts);
        priorVersions[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersions;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', populator.oldParents[0].get(Account.Name), 'It should be Acme, because the old Doe points at it.');
    }

    @IsTest
    static void afterUpdateParentQueryAttachesTheNewParentFromTheSavedRecords() {
        mockFramework();
        Account parent = savedAccount('Acme');
        List<Contact> contacts = savedContacts('Doe');
        List<Contact> priorVersions = priorVersionsOf(contacts);
        contacts[0].AccountId = parent.Id;
        Contact saved = new Contact(Id = contacts[0].Id, AccountId = parent.Id);
        saved.Account = parent;
        SOQL.mock(Contact.SObjectType).thenReturn(saved);
        SOQL.mock(Account.SObjectType).thenReturn(new Account(Id = parent.Id, Name = 'Queried'));
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersions;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', writer.newParents[0].get(Account.Name), 'It should be Acme, because the saved Doe carries it.');
    }

    @IsTest
    static void afterUpdatePriorParentQueryAttachesTheOldParent() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        List<Contact> priorVersions = priorVersionsOf(contacts);
        priorVersions[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersions;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', writer.oldParents[0].get(Account.Name), 'It should be Acme, because the old Doe points at it.');
    }

    @IsTest
    static void beforeDeletePriorParentQueryAttachesTheOldParent() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', handler.oldParents[0].get(Account.Name), 'It should be Acme, because the deleted Doe points at it.');
    }

    @IsTest
    static void afterDeletePriorParentQueryAttachesTheOldParent() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', writer.oldParents[0].get(Account.Name), 'It should be Acme, because the deleted Doe points at it.');
    }

    @IsTest
    static void afterUndeleteParentQueryAttachesTheNewParentFromTheSavedRecords() {
        mockFramework();
        Account parent = savedAccount('Acme');
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = parent.Id;
        Contact saved = new Contact(Id = contacts[0].Id, AccountId = parent.Id);
        saved.Account = parent;
        SOQL.mock(Contact.SObjectType).thenReturn(saved);
        SOQL.mock(Account.SObjectType).thenReturn(new Account(Id = parent.Id, Name = 'Queried'));
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', writer.newParents[0].get(Account.Name), 'It should be Acme, because the saved Doe carries it.');
    }

    @IsTest
    static void lookupsDeclaredByTwoHandlersCostOneQuery() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        BeforeInsertValidatorSpy second = new BeforeInsertValidatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Industry) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        Integer queries = queriesIssuedBy(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queries, 'It should be 1, because both handlers declare the same lookup.');
    }

    @IsTest
    static void fieldsDeclaredByTwoHandlersAreMergedIntoTheParentQuery() {
        mockFramework();
        Account parent = savedAccount('Acme');
        parent.Industry = 'Tech';
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Industry) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<Object>{ 'Acme', 'Tech' },
            new List<Object>{ first.newParents[0].get(Account.Name), first.newParents[0].get(Account.Industry) },
            'It should be Acme and Tech, because one query requests the fields of both handlers and the mock strips the rest.'
        );
    }

    @IsTest
    static void parentDeclaredByALaterHandlerIsAvailableToAnEarlierOne() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', first.newParents[0].get(Account.Name), 'It should be Acme, because parents are attached before the first handler runs.');
    }

    @IsTest
    static void unsetLookupIssuesNoParentQuery() {
        mockFramework();
        SOQL.mock(Account.SObjectType).thenReturn(savedAccount('Acme'));
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Integer queries = queriesIssuedBy(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(0, queries, 'It should be 0, because Doe has no AccountId to resolve.');
    }

    @IsTest
    static void lookupToAMissingParentAttachesNull() {
        mockFramework();
        Account acme = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        List<Contact> contacts = newContacts('Doe', 'Roe');
        contacts[0].AccountId = acme.Id;
        contacts[1].AccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<Object>{ 'Acme', null },
            new List<Object>{ populator.newParents[0]?.get(Account.Name), populator.newParents[1] },
            'It should be Acme for Doe and null for Roe, because the query finds no Account for the lookup of Roe.'
        );
    }

    @IsTest
    static void priorParentQueryAloneLeavesTheNewSideUnenriched() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(populator.newParents[0], 'It should be null, because only the old side is declared.');
    }

    @IsTest
    static void changedLookupResolvesBothSidesInOneQuery() {
        mockFramework();
        Account acme = savedAccount('Acme');
        Account globex = savedAccount('Globex');
        SOQL.mock(Account.SObjectType).thenReturn(new List<Account>{ acme, globex });
        SOQL.mock(Account.SObjectType).thenReturn(new List<Account>());
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        populator.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        List<Contact> priorVersions = priorVersionsOf(contacts);
        contacts[0].AccountId = acme.Id;
        priorVersions[0].AccountId = globex.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersions;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<Object>{ 'Acme', 'Globex' },
            new List<Object>{ populator.newParents[0]?.get(Account.Name), populator.oldParents[0]?.get(Account.Name) },
            'It should be Acme new and Globex old, because both Ids go into the first query and a second query would find nothing.'
        );
    }

    @IsTest
    static void afterUpdateOldParentIsReusedFromTheSavedRecordQuery() {
        mockFramework();
        Account parent = savedAccount('Acme');
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = parent.Id;
        List<Contact> priorVersions = priorVersionsOf(contacts);
        Contact saved = new Contact(Id = contacts[0].Id, AccountId = parent.Id);
        saved.Account = parent;
        SOQL.mock(Contact.SObjectType).thenReturn(saved);
        SOQL.mock(Account.SObjectType).thenReturn(new Account(Id = parent.Id, Name = 'Requeried'));
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        writer.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersions;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', writer.oldParents[0]?.get(Account.Name), 'It should be Acme, because the old side reuses the parent cached by the saved record query.');
    }

    @IsTest
    static void beforeInsertPopulatorRepointingALookupRefreshesTheParentForLaterHandlers() {
        mockFramework();
        Account acme = savedAccount('Acme');
        Account globex = savedAccount('Globex');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        SOQL.mock(Account.SObjectType).thenReturn(globex);
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.populatedField = Contact.AccountId;
        first.populatedValue = globex.Id;
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = acme.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Globex', second.newParents[0].get(Account.Name), 'It should be Globex, because the first populator repointed Doe to it.');
    }

    @IsTest
    static void beforeUpdatePopulatorRepointingALookupRefreshesTheParentForLaterHandlers() {
        mockFramework();
        Account acme = savedAccount('Acme');
        Account globex = savedAccount('Globex');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        SOQL.mock(Account.SObjectType).thenReturn(globex);
        BeforeUpdatePopulatorSpy first = new BeforeUpdatePopulatorSpy();
        first.populatedField = Contact.AccountId;
        first.populatedValue = globex.Id;
        BeforeUpdatePopulatorSpy second = new BeforeUpdatePopulatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(first);
        orchestrator.beforeUpdate.add(second);
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = acme.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Globex', second.newParents[0].get(Account.Name), 'It should be Globex, because the first populator repointed Doe to it.');
    }

    @IsTest
    static void repointToAnAlreadyQueriedParentIssuesNoQuery() {
        mockFramework();
        Account acme = savedAccount('Acme');
        Account globex = savedAccount('Globex');
        SOQL.mock(Account.SObjectType).thenReturn(new List<Account>{ acme, globex });
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.qualifying = new Set<String>{ 'Doe' };
        populator.populatedField = Contact.AccountId;
        populator.populatedValue = globex.Id;
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        List<Contact> contacts = newContacts('Doe', 'Roe');
        contacts[0].AccountId = acme.Id;
        contacts[1].AccountId = globex.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        Integer queries = queriesIssuedBy(runner);
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queries, 'It should be the initial query alone, because Globex was already queried for Roe.');
    }

    @IsTest
    static void clearedLookupDetachesTheParentForLaterHandlers() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.populatedField = Contact.AccountId;
        first.populatedValue = null;
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(second.newParents[0], 'It should be null, because the first populator cleared the lookup.');
    }

    @IsTest
    static void repointedLookupLeavesTheOldParentUnchanged() {
        mockFramework();
        Account acme = savedAccount('Acme');
        Account globex = savedAccount('Globex');
        SOQL.mock(Account.SObjectType).thenReturn(acme);
        SOQL.mock(Account.SObjectType).thenReturn(globex);
        BeforeUpdatePopulatorSpy first = new BeforeUpdatePopulatorSpy();
        first.populatedField = Contact.AccountId;
        first.populatedValue = globex.Id;
        BeforeUpdatePopulatorSpy second = new BeforeUpdatePopulatorSpy();
        second.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        second.priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(first);
        orchestrator.beforeUpdate.add(second);
        List<Contact> contacts = savedContacts('Doe');
        contacts[0].AccountId = acme.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', second.oldParents[0].get(Account.Name), 'It should be Acme, because repointing refreshes the new side only.');
    }

    @IsTest
    static void beforeInsertRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        populator.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, populator.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void afterInsertRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        AfterInsertWriterSpy writer = new AfterInsertWriterSpy();
        writer.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        writer.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, writer.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void beforeUpdateRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        BeforeUpdatePopulatorSpy populator = new BeforeUpdatePopulatorSpy();
        populator.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        populator.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeUpdate.add(populator);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, populator.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void afterUpdateRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        AfterUpdateWriterSpy writer = new AfterUpdateWriterSpy();
        writer.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        writer.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, writer.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void beforeDeleteRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        BeforeDeleteHandlerSpy handler = new BeforeDeleteHandlerSpy();
        handler.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        handler.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeDelete.add(handler);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, handler.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void afterDeleteRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        AfterDeleteWriterSpy writer = new AfterDeleteWriterSpy();
        writer.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        writer.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, writer.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void afterUndeleteRelatedQueryProvidesRecordsByKey() {
        mockFramework();
        Account acme = savedAccount('Acme');
        AfterUndeleteWriterSpy writer = new AfterUndeleteWriterSpy();
        writer.providers.put('accounts', new Provider(new List<Account>{ acme }, Account.Id));
        writer.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(acme, writer.related.getFirstWhereKeyEquals(acme.Id), 'It should be Acme, because the provider keys its records by Id.');
    }

    @IsTest
    static void providerIsQueriedWithEveryTriggerRecord() {
        mockFramework();
        Provider provider = new Provider(new List<Account>{ savedAccount('Acme') }, Account.Id);
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.qualifying = new Set<String>{ 'Doe' };
        populator.providers.put('accounts', provider);
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'Doe', 'Roe' }, provider.queriedFor, 'It should be Doe and Roe, because the provider runs before qualification.');
    }

    @IsTest
    static void relatedQueryRunsOncePerHandler() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, calls('relatedQuery').size(), 'It should be 1, because providers are resolved once per handler, not once for each of the two records.');
    }

    @IsTest
    static void relatedQueryRunsBeforeTheFirstPredicate() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(new BeforeInsertPopulatorSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'spy.relatedQuery', 'spy.when:Doe' },
            enrichCallsOf(new Set<String>{ 'relatedQuery', 'when' }),
            'It should be the related query ahead of the predicate, because providers are resolved before records are evaluated.'
        );
    }

    @IsTest
    static void nullRelatedQueryResultMeansNoProviders() {
        mockFramework();
        BeforeInsertPopulatorSpy populator = new BeforeInsertPopulatorSpy();
        populator.providers = null;
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isNull(failure, 'It should be no exception, because a null provider map is treated as empty.');
    }

    @IsTest
    static void providersAreScopedToTheHandlerThatDeclaredThem() {
        mockFramework();
        BeforeInsertPopulatorSpy first = new BeforeInsertPopulatorSpy();
        first.providers.put('accounts', new Provider(new List<Account>{ savedAccount('Acme') }, Account.Id));
        BeforeInsertPopulatorSpy second = new BeforeInsertPopulatorSpy();
        second.readsProvider = 'accounts';
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(first);
        orchestrator.beforeInsert.add(second);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = newContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(
            failure,
            TriggerHandler.TriggerHandlerException.class,
            'It should be a TriggerHandlerException, because the accounts provider belongs to the first handler only.'
        );
    }

    @IsTest
    static void providerSeesTheParentsAttachedByParentQuery() {
        mockFramework();
        Account parent = savedAccount('Acme');
        SOQL.mock(Account.SObjectType).thenReturn(parent);
        EnrichParentReadingPopulator populator = new EnrichParentReadingPopulator();
        populator.parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.beforeInsert.add(populator);
        List<Contact> contacts = newContacts('Doe');
        contacts[0].AccountId = parent.Id;
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        runner.context.newRecords = contacts;

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Acme', populator.provider.parentNameSeen, 'It should be Acme, because parents are attached before any related query runs.');
    }

    private static List<String> enrichCallsOf(Set<String> steps) {
        List<String> matchingCalls = new List<String>();

        for (String call : TriggerOrchestratorTest.callLog) {
            if (steps.contains(call.substringAfter('.').substringBefore(':'))) {
                matchingCalls.add(call);
            }
        }

        return matchingCalls;
    }

    private class EnrichParentReadingPopulator extends BeforeInsertPopulatorSpy {
        public EnrichParentReadingProvider provider = new EnrichParentReadingProvider();

        public override Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'parents' => this.provider };
        }
    }

    private class EnrichParentReadingProvider implements BeforeInsert.RecordsProvider {
        public String parentNameSeen;

        public List<SObject> query(TriggerHandler.InsertRecords triggerRecords) {
            SObject parent = triggerRecords.getRecords()[0].getNewParent('Account');
            this.parentNameSeen = (String) parent?.get(Account.Name);
            return new List<SObject>();
        }

        public String keyOf(SObject record) {
            return null;
        }
    }

    @IsTest
    static void afterInsertWriterRegistrationsAreCommittedByTheSharedUnit() {
        mockFramework();
        UowAfterInsertSnapshotDispatcher dispatcher = new UowAfterInsertSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new AfterInsertWriterSpy());
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, dispatcher.committedAtDispatch, 'It should be 0, because the shared unit does not commit while a later handler still runs.');
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be the Account registered for Doe, because the shared unit commits once the last handler is done.'
        );
    }

    @IsTest
    static void afterUpdateWriterRegistrationsAreCommittedByTheSharedUnit() {
        mockFramework();
        UowAfterUpdateSnapshotDispatcher dispatcher = new UowAfterUpdateSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(new AfterUpdateWriterSpy());
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, dispatcher.committedAtDispatch, 'It should be 0, because the shared unit does not commit while a later handler still runs.');
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be the Account registered for Doe, because the shared unit commits once the last handler is done.'
        );
    }

    @IsTest
    static void afterDeleteWriterRegistrationsAreCommittedByTheSharedUnit() {
        mockFramework();
        UowAfterDeleteSnapshotDispatcher dispatcher = new UowAfterDeleteSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(new AfterDeleteWriterSpy());
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, dispatcher.committedAtDispatch, 'It should be 0, because the shared unit does not commit while a later handler still runs.');
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be the Account registered for Doe, because the shared unit commits once the last handler is done.'
        );
    }

    @IsTest
    static void afterUndeleteWriterRegistrationsAreCommittedByTheSharedUnit() {
        mockFramework();
        UowAfterUndeleteSnapshotDispatcher dispatcher = new UowAfterUndeleteSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(new AfterUndeleteWriterSpy());
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, dispatcher.committedAtDispatch, 'It should be 0, because the shared unit does not commit while a later handler still runs.');
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be the Account registered for Doe, because the shared unit commits once the last handler is done.'
        );
    }

    @IsTest
    static void afterInsertWriterWithOwnUnitOfWorkCommitsItsOwnUnit() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new OwnUnitAfterInsertWriterSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.OWN_UNIT),
            'It should be the Account registered for Doe, because the writer returns its own unit of work.'
        );
    }

    @IsTest
    static void afterUpdateWriterWithOwnUnitOfWorkCommitsItsOwnUnit() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(new OwnUnitAfterUpdateWriterSpy());
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.OWN_UNIT),
            'It should be the Account registered for Doe, because the writer returns its own unit of work.'
        );
    }

    @IsTest
    static void afterDeleteWriterWithOwnUnitOfWorkCommitsItsOwnUnit() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(new OwnUnitAfterDeleteWriterSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.OWN_UNIT),
            'It should be the Account registered for Doe, because the writer returns its own unit of work.'
        );
    }

    @IsTest
    static void afterUndeleteWriterWithOwnUnitOfWorkCommitsItsOwnUnit() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(new OwnUnitAfterUndeleteWriterSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.OWN_UNIT),
            'It should be the Account registered for Doe, because the writer returns its own unit of work.'
        );
    }

    @IsTest
    static void afterInsertContinueOnErrorWriterCommitsBeforeTheNextHandler() {
        mockFramework();
        UowAfterInsertSnapshotDispatcher dispatcher = new UowAfterInsertSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new ContinuingAfterInsertWriterSpy());
        orchestrator.afterInsert.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, dispatcher.committedAtDispatch, 'It should be 1, because a ContinueOnError writer commits its automatic unit before the next handler runs.');
    }

    @IsTest
    static void afterUpdateContinueOnErrorWriterCommitsBeforeTheNextHandler() {
        mockFramework();
        UowAfterUpdateSnapshotDispatcher dispatcher = new UowAfterUpdateSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(new ContinuingAfterUpdateWriterSpy());
        orchestrator.afterUpdate.add(dispatcher);
        List<Contact> contacts = savedContacts('Doe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, dispatcher.committedAtDispatch, 'It should be 1, because a ContinueOnError writer commits its automatic unit before the next handler runs.');
    }

    @IsTest
    static void afterDeleteContinueOnErrorWriterCommitsBeforeTheNextHandler() {
        mockFramework();
        UowAfterDeleteSnapshotDispatcher dispatcher = new UowAfterDeleteSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(new ContinuingAfterDeleteWriterSpy());
        orchestrator.afterDelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, dispatcher.committedAtDispatch, 'It should be 1, because a ContinueOnError writer commits its automatic unit before the next handler runs.');
    }

    @IsTest
    static void afterUndeleteContinueOnErrorWriterCommitsBeforeTheNextHandler() {
        mockFramework();
        UowAfterUndeleteSnapshotDispatcher dispatcher = new UowAfterUndeleteSnapshotDispatcher();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(new ContinuingAfterUndeleteWriterSpy());
        orchestrator.afterUndelete.add(dispatcher);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, dispatcher.committedAtDispatch, 'It should be 1, because a ContinueOnError writer commits its automatic unit before the next handler runs.');
    }

    @IsTest
    static void afterInsertContinueOnErrorWriterFailureDiscardsItsRegistrations() {
        mockFramework();
        ContinuingAfterInsertWriterSpy writer = new ContinuingAfterInsertWriterSpy();
        writer.failAt('action:Roe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>(),
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be empty, because the failure on Roe skips the commit of the Account registered for Doe.'
        );
    }

    @IsTest
    static void afterUpdateContinueOnErrorWriterFailureDiscardsItsRegistrations() {
        mockFramework();
        ContinuingAfterUpdateWriterSpy writer = new ContinuingAfterUpdateWriterSpy();
        writer.failAt('action:Roe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUpdate.add(writer);
        List<Contact> contacts = savedContacts('Doe', 'Roe');
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        runner.context.newRecords = contacts;
        runner.context.oldRecords = priorVersionsOf(contacts);

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>(),
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be empty, because the failure on Roe skips the commit of the Account registered for Doe.'
        );
    }

    @IsTest
    static void afterDeleteContinueOnErrorWriterFailureDiscardsItsRegistrations() {
        mockFramework();
        ContinuingAfterDeleteWriterSpy writer = new ContinuingAfterDeleteWriterSpy();
        writer.failAt('action:Roe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterDelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        runner.context.oldRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>(),
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be empty, because the failure on Roe skips the commit of the Account registered for Doe.'
        );
    }

    @IsTest
    static void afterUndeleteContinueOnErrorWriterFailureDiscardsItsRegistrations() {
        mockFramework();
        ContinuingAfterUndeleteWriterSpy writer = new ContinuingAfterUndeleteWriterSpy();
        writer.failAt('action:Roe', new SpyException('Boom'));
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterUndelete.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        runner.context.newRecords = savedContacts('Doe', 'Roe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>(),
            insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW),
            'It should be empty, because the failure on Roe skips the commit of the Account registered for Doe.'
        );
    }

    @IsTest
    static void registrationsOfEveryPlainWriterAreCommitted() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new AfterInsertWriterSpy());
        orchestrator.afterInsert.add(new AfterInsertWriterSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW).size(), 'It should be 2, because the registrations of both writers are committed.');
    }

    @IsTest
    static void sharedUnitMergesUpdatesOfTheSameRecordFromTwoWriters() {
        mockFramework();
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        UowSameAccountWriter first = new UowSameAccountWriter();
        first.target = new Account(Id = accountId, Name = 'Acme');
        UowSameAccountWriter second = new UowSameAccountWriter();
        second.target = new Account(Id = accountId, Industry = 'Technology');
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(first);
        orchestrator.afterInsert.add(second);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        List<SObject> updatedAccounts = DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).updatesOf(Account.SObjectType).records();
        Assert.areEqual(
            new List<Object>{ 'Acme', 'Technology' },
            new List<Object>{ updatedAccounts[0].get(Account.Name), updatedAccounts[0].get(Account.Industry) },
            'It should be Acme and Technology on one Account, because the shared unit merges the second update of the same Account into the first registration.'
        );
    }

    @IsTest
    static void ownUnitIsNotCommittedWhenNoRecordQualifies() {
        mockFramework();
        OwnUnitAfterInsertWriterSpy writer = new OwnUnitAfterInsertWriterSpy();
        writer.ownUnit.toInsert(new Account(Name = 'Preregistered'));
        writer.qualifying = new Set<String>();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(writer);
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>(),
            insertedAccountNames(TriggerOrchestratorTest.OWN_UNIT),
            'It should be empty, because no record qualifies, so the Preregistered Account is never committed.'
        );
    }

    @IsTest
    static void ownUnitOfWorkTakesPrecedenceOverTheAutomaticUnit() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowOwnContinuingWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Doe' },
            insertedAccountNames(TriggerOrchestratorTest.OWN_UNIT),
            'It should be the Account registered for Doe, because the own unit wins over the automatic unit of a ContinueOnError writer.'
        );
    }

    @IsTest
    static void failingSharedCommitPropagates() {
        mockFramework();
        DML.mock(TriggerOrchestratorTest.TRIGGER_UOW).exceptionOnInserts();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new AfterInsertWriterSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        Exception failure = runCatching(runner);
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(failure, DmlException.class, 'It should be the commit DmlException, because a failed commit of a plain writer\'s registrations propagates.');
    }

    @IsTest
    static void continueOnErrorWriterCommitFailureIsLogged() {
        mockFramework();
        DML.mock(TriggerOrchestratorTest.TRIGGER_UOW).exceptionOnInserts();
        LoggerSpy logger = spyOnLogger();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new ContinuingAfterInsertWriterSpy());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.isInstanceOfType(
            logger.errors[0].getException(),
            DmlException.class,
            'It should be the commit DmlException, because the automatic unit commits inside the error handling of the writer.'
        );
    }

    @IsTest
    static void unitOfWorkToInsertRecordRegistersAnInsert() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowInsertRecordWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).insertsOf(Account.SObjectType).records().size(),
            'It should be 1, because toInsert(DML.Record) registers the Account.'
        );
    }

    @IsTest
    static void unitOfWorkToUpdateRegistersAnUpdate() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowUpdateWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).updatesOf(Account.SObjectType).records().size(),
            'It should be 1, because toUpdate registers the Account.'
        );
    }

    @IsTest
    static void unitOfWorkToUpdateRecordRegistersAnUpdate() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowUpdateRecordWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).updatesOf(Account.SObjectType).records().size(),
            'It should be 1, because toUpdate(DML.Record) registers the Account.'
        );
    }

    @IsTest
    static void unitOfWorkToUpsertRegistersAnUpsert() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowUpsertWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).upsertsOf(Account.SObjectType).records().size(),
            'It should be 1, because toUpsert registers the Account.'
        );
    }

    @IsTest
    static void unitOfWorkToDeleteRegistersADelete() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowDeleteWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).deletesOf(Account.SObjectType).records().size(),
            'It should be 1, because toDelete registers the Account.'
        );
    }

    @IsTest
    static void unitOfWorkToPublishRegistersAnEvent() {
        mockFramework();
        TestOrchestrator orchestrator = new TestOrchestrator();
        orchestrator.afterInsert.add(new UowPublishWriter());
        TriggerOrchestrator runner = new TriggerOrchestrator(orchestrator);
        runner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        runner.context.newRecords = savedContacts('Doe');

        // Test
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            DML.retrieveResultFor(TriggerOrchestratorTest.TRIGGER_UOW).eventsOf(Account.SObjectType).records().size(),
            'It should be 1, because toPublish registers the event.'
        );
    }

    private class UowAfterInsertSnapshotDispatcher extends AfterInsertDispatcherSpy {
        public Integer committedAtDispatch;

        public override void dispatchOnAfterInsert(TriggerHandler.InsertRecords records) {
            this.committedAtDispatch = insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW).size();
        }
    }

    private class UowAfterUpdateSnapshotDispatcher extends AfterUpdateDispatcherSpy {
        public Integer committedAtDispatch;

        public override void dispatchOnAfterUpdate(TriggerHandler.UpdateRecords records) {
            this.committedAtDispatch = insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW).size();
        }
    }

    private class UowAfterDeleteSnapshotDispatcher extends AfterDeleteDispatcherSpy {
        public Integer committedAtDispatch;

        public override void dispatchOnAfterDelete(TriggerHandler.DeleteRecords records) {
            this.committedAtDispatch = insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW).size();
        }
    }

    private class UowAfterUndeleteSnapshotDispatcher extends AfterUndeleteDispatcherSpy {
        public Integer committedAtDispatch;

        public override void dispatchOnAfterUndelete(TriggerHandler.UndeleteRecords records) {
            this.committedAtDispatch = insertedAccountNames(TriggerOrchestratorTest.TRIGGER_UOW).size();
        }
    }

    private class UowOwnContinuingWriter extends OwnUnitAfterInsertWriterSpy implements AfterInsert.ContinueOnError {
    }

    private class UowInsertRecordWriter extends AfterInsertWriterSpy {
        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(DML.Record(new Account(Name = 'Doe')));
        }
    }

    private class UowUpdateWriter extends AfterInsertWriterSpy {
        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toUpdate(savedAccount('Acme'));
        }
    }

    private class UowUpdateRecordWriter extends AfterInsertWriterSpy {
        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toUpdate(DML.Record(savedAccount('Acme')));
        }
    }

    private class UowUpsertWriter extends AfterInsertWriterSpy {
        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toUpsert(new Account(Name = 'Acme'), Account.Id);
        }
    }

    private class UowDeleteWriter extends AfterInsertWriterSpy {
        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toDelete(savedAccount('Acme'));
        }
    }

    private class UowPublishWriter extends AfterInsertWriterSpy {
        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toPublish(new Account(Name = 'Acme'));
        }
    }

    private class UowSameAccountWriter extends AfterInsertWriterSpy {
        public Account target;

        public override void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toUpdate(this.target);
        }
    }

    private static final String TRIGGER_UOW = 'triggerUow';
    private static final String OWN_UNIT = 'OwnUnitOfWork';

    private static List<String> callLog = new List<String>();

    private static void mockFramework() {
        mockFramework(new List<TriggerObject__mdt>());
    }

    private static void mockFramework(List<TriggerObject__mdt> triggerSettings) {
        SOQL.mock('TriggerObject__mdt').thenReturn(triggerSettings);
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock(TriggerOrchestratorTest.TRIGGER_UOW).allDmls();
        DML.mock(TriggerOrchestratorTest.OWN_UNIT).allDmls();
    }

    private static TriggerObject__mdt objectSetting(String objectApiName, Boolean bypass, List<String> bypassedHandlers) {
        String namespacePrefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
        Map<String, Object> setting = new Map<String, Object>{
            'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
            String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => objectApiName,
            String.valueOf(TriggerObject__mdt.Bypass__c) => bypass
        };
        List<Map<String, Object>> handlerSettings = new List<Map<String, Object>>();

        for (String handlerName : bypassedHandlers) {
            handlerSettings.add(
                new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
                    String.valueOf(TriggerHandler__mdt.ApexClassName__c) => handlerName,
                    String.valueOf(TriggerHandler__mdt.Bypass__c) => true
                }
            );
        }

        if (!handlerSettings.isEmpty()) {
            setting.put(namespacePrefix + 'TriggerHandlers__r', new Map<String, Object>{ 'totalSize' => handlerSettings.size(), 'done' => true, 'records' => handlerSettings });
        }

        return (TriggerObject__mdt) JSON.deserialize(JSON.serialize(setting), TriggerObject__mdt.class);
    }

    private static LoggerSpy spyOnLogger() {
        LoggerSpy logger = new LoggerSpy();
        TriggerOrchestrator.triggerLogger.logger = logger;
        return logger;
    }

    private static List<Contact> newContacts(String lastName) {
        return new List<Contact>{ new Contact(LastName = lastName) };
    }

    private static List<Contact> newContacts(String firstLastName, String secondLastName) {
        return new List<Contact>{ new Contact(LastName = firstLastName), new Contact(LastName = secondLastName) };
    }

    private static List<Contact> savedContacts(String lastName) {
        return new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = lastName) };
    }

    private static List<Contact> savedContacts(String firstLastName, String secondLastName) {
        return new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = firstLastName),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = secondLastName)
        };
    }

    private static List<Contact> priorVersionsOf(List<Contact> contacts) {
        return contacts.deepClone(true);
    }

    private static Account savedAccount(String name) {
        return new Account(Id = TriggerHandler.IdGenerator.get(Account.SObjectType), Name = name);
    }

    private static Exception runCatching(TriggerOrchestrator runner) {
        try {
            runner.run();
        } catch (Exception e) {
            return e;
        }

        return null;
    }

    private static Integer queriesIssuedBy(TriggerOrchestrator runner) {
        Integer queriesBefore = SOQL.getQueries();
        runner.run();
        return SOQL.getQueries() - queriesBefore;
    }

    private static List<String> calls(String step) {
        List<String> matchingCalls = new List<String>();

        for (String call : TriggerOrchestratorTest.callLog) {
            if (call.substringAfter('.').substringBefore(':') == step) {
                matchingCalls.add(call);
            }
        }

        return matchingCalls;
    }

    private static List<String> insertedAccountNames(String unitOfWork) {
        List<String> names = new List<String>();

        for (SObject inserted : DML.retrieveResultFor(unitOfWork).insertsOf(Account.SObjectType).records()) {
            names.add((String) inserted.get(Account.Name));
        }

        return names;
    }

    private static List<String> lastNamesOf(List<Object> triggerRecords) {
        List<String> lastNames = new List<String>();

        for (Object triggerRecord : triggerRecords) {
            lastNames.add(lastNameOf(triggerRecord));
        }

        return lastNames;
    }

    private static String lastNameOf(Object triggerRecord) {
        return (String) ((TriggerHandler.TriggerRecord) triggerRecord).getSObject().get(Contact.LastName);
    }

    private virtual class TestOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.BeforeDelete, TriggerOrchestrator.AfterDelete, TriggerOrchestrator.AfterUndelete {
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

    public class LoggerSpy implements TriggerOrchestrator.Logger {
        public List<TriggerOrchestrator.Error> errors = new List<TriggerOrchestrator.Error>();
        public Integer finalizeCalls = 0;

        public void log(TriggerOrchestrator.Error error) {
            this.errors.add(error);
        }

        public void finalize() {
            this.finalizeCalls++;
        }
    }

    private class SpyException extends Exception {
    }

    private class Provider implements BeforeInsert.RecordsProvider, AfterInsert.RecordsProvider, BeforeUpdate.RecordsProvider, AfterUpdate.RecordsProvider, BeforeDelete.RecordsProvider, AfterDelete.RecordsProvider, AfterUndelete.RecordsProvider {
        public List<SObject> providedRecords;
        public SObjectField keyField;
        public List<String> queriedFor;

        public Provider(List<SObject> providedRecords, SObjectField keyField) {
            this.providedRecords = providedRecords;
            this.keyField = keyField;
        }

        public List<SObject> query(TriggerHandler.InsertRecords triggerRecords) {
            return this.provideFor(triggerRecords.getRecords());
        }

        public List<SObject> query(TriggerHandler.UpdateRecords triggerRecords) {
            return this.provideFor(triggerRecords.getRecords());
        }

        public List<SObject> query(TriggerHandler.DeleteRecords triggerRecords) {
            return this.provideFor(triggerRecords.getRecords());
        }

        public List<SObject> query(TriggerHandler.UndeleteRecords triggerRecords) {
            return this.provideFor(triggerRecords.getRecords());
        }

        public String keyOf(SObject record) {
            Object key = record.get(this.keyField);
            return key == null ? null : String.valueOf(key);
        }

        private List<SObject> provideFor(List<Object> triggerRecords) {
            this.queriedFor = TriggerOrchestratorTest.lastNamesOf(triggerRecords);
            return this.providedRecords;
        }
    }

    private virtual class Spy {
        public String label = 'spy';
        public Set<String> qualifying;
        public Boolean bypassed = false;
        public Map<SObjectField, TriggerHandler.ParentFields> parentQuery = new Map<SObjectField, TriggerHandler.ParentFields>();
        public Map<SObjectField, TriggerHandler.ParentFields> priorParentQuery = new Map<SObjectField, TriggerHandler.ParentFields>();
        public String relationship = 'Account';
        public Map<String, Provider> providers = new Map<String, Provider>();
        public String readsProvider;
        public SObjectField populatedField = Contact.Title;
        public Object populatedValue = 'Populated';
        public String message = 'Rejected';

        public List<String> evaluated = new List<String>();
        public List<String> acted = new List<String>();
        public List<String> finalized;
        public List<String> dispatched;
        public List<SObject> newParents = new List<SObject>();
        public List<SObject> oldParents = new List<SObject>();
        public TriggerHandler.RelatedRecords related;

        private String failingStep;
        private Exception failure;
        private String dmlStep;
        private String nestedStep;
        private TriggerOrchestrator nestedRun;

        public void failAt(String step, Exception failure) {
            this.failingStep = step;
            this.failure = failure;
        }

        public void performDmlAt(String step) {
            this.dmlStep = step;
        }

        public void runNestedAt(String step, TriggerOrchestrator nestedRun) {
            this.nestedStep = step;
            this.nestedRun = nestedRun;
        }

        protected Boolean evaluate(Object record) {
            TriggerHandler.TriggerRecord triggerRecord = (TriggerHandler.TriggerRecord) record;
            String lastName = TriggerOrchestratorTest.lastNameOf(triggerRecord);

            this.step('when', lastName);
            this.evaluated.add(lastName);
            this.newParents.add(triggerRecord.getNewParent(this.relationship));
            this.oldParents.add(triggerRecord.getOldParent(this.relationship));

            if (this.readsProvider != null) {
                this.related = triggerRecord.getRelated(this.readsProvider);
            }

            return this.qualifying == null || this.qualifying.contains(lastName);
        }

        protected void act(Object record) {
            String lastName = TriggerOrchestratorTest.lastNameOf(record);

            this.step('action', lastName);
            this.acted.add(lastName);
        }

        protected void register(Object record, TriggerHandler.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = TriggerOrchestratorTest.lastNameOf(record)));
        }

        protected void finalizeWith(List<Object> records) {
            this.step('finalize', null);
            this.finalized = TriggerOrchestratorTest.lastNamesOf(records);
        }

        protected void dispatchWith(List<Object> records) {
            this.step('dispatch', null);
            this.dispatched = TriggerOrchestratorTest.lastNamesOf(records);
        }

        protected Map<SObjectField, TriggerHandler.ParentFields> declareParents(String step, Map<SObjectField, TriggerHandler.ParentFields> parentFields) {
            this.step(step, null);
            return parentFields;
        }

        protected Boolean isBypassed() {
            this.step('bypass', null);
            return this.bypassed;
        }

        protected void step(String name, String lastName) {
            String call = lastName == null ? name : name + ':' + lastName;

            TriggerOrchestratorTest.callLog.add(this.label + '.' + call);

            if (this.nestedStep == name || this.nestedStep == call) {
                this.nestedRun.run();
            }

            if (this.dmlStep == name || this.dmlStep == call) {
                Database.setSavepoint();
            }

            if (this.failingStep == name || this.failingStep == call) {
                throw this.failure;
            }
        }
    }

    private virtual class BeforeInsertPopulatorSpy extends Spy implements BeforeInsert.Populator, BeforeInsert.ParentQuery, BeforeInsert.RelatedQuery, BeforeInsert.Bypassable, BeforeInsert.Finalizer {
        public virtual Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public virtual void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.act(record);
            record.put(this.populatedField, this.populatedValue);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            this.step('relatedQuery', null);
            return (Map<String, BeforeInsert.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnBeforeInsertWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeBeforeInsert(TriggerHandler.InsertRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class BeforeInsertValidatorSpy extends Spy implements BeforeInsert.Validator, BeforeInsert.ParentQuery, BeforeInsert.RelatedQuery, BeforeInsert.Bypassable, BeforeInsert.Finalizer {
        public virtual Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public virtual String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.act(record);
            return this.message;
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            this.step('relatedQuery', null);
            return (Map<String, BeforeInsert.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnBeforeInsertWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeBeforeInsert(TriggerHandler.InsertRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterInsertWriterSpy extends Spy implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.RelatedQuery, AfterInsert.Bypassable, AfterInsert.Finalizer {
        public virtual Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public virtual void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
            this.register(record, unitOfWork);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert() {
            this.step('relatedQuery', null);
            return (Map<String, AfterInsert.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterInsertWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterInsert(TriggerHandler.InsertRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterInsertDispatcherSpy extends Spy implements AfterInsert.Dispatcher, AfterInsert.ParentQuery, AfterInsert.RelatedQuery, AfterInsert.Bypassable, AfterInsert.Finalizer {
        public virtual Boolean dispatchOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return this.evaluate(record);
        }

        public virtual void dispatchOnAfterInsert(TriggerHandler.InsertRecords records) {
            this.dispatchWith(records.getRecords());
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert() {
            this.step('relatedQuery', null);
            return (Map<String, AfterInsert.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterInsertWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterInsert(TriggerHandler.InsertRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class BeforeUpdatePopulatorSpy extends Spy implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery, BeforeUpdate.RelatedQuery, BeforeUpdate.Bypassable, BeforeUpdate.Finalizer {
        public virtual Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public virtual void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.act(record);
            record.put(this.populatedField, this.populatedValue);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
            this.step('relatedQuery', null);
            return (Map<String, BeforeUpdate.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnBeforeUpdateWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeBeforeUpdate(TriggerHandler.UpdateRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class BeforeUpdateValidatorSpy extends Spy implements BeforeUpdate.Validator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery, BeforeUpdate.RelatedQuery, BeforeUpdate.Bypassable, BeforeUpdate.Finalizer {
        public virtual Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public virtual String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.act(record);
            return this.message;
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
            this.step('relatedQuery', null);
            return (Map<String, BeforeUpdate.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnBeforeUpdateWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeBeforeUpdate(TriggerHandler.UpdateRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterUpdateWriterSpy extends Spy implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery, AfterUpdate.RelatedQuery, AfterUpdate.Bypassable, AfterUpdate.Finalizer {
        public virtual Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public virtual void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
            this.register(record, unitOfWork);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
            this.step('relatedQuery', null);
            return (Map<String, AfterUpdate.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterUpdateWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterUpdate(TriggerHandler.UpdateRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterUpdateDispatcherSpy extends Spy implements AfterUpdate.Dispatcher, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery, AfterUpdate.RelatedQuery, AfterUpdate.Bypassable, AfterUpdate.Finalizer {
        public virtual Boolean dispatchOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.evaluate(record);
        }

        public virtual void dispatchOnAfterUpdate(TriggerHandler.UpdateRecords records) {
            this.dispatchWith(records.getRecords());
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
            this.step('relatedQuery', null);
            return (Map<String, AfterUpdate.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterUpdateWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterUpdate(TriggerHandler.UpdateRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class BeforeDeleteHandlerSpy extends Spy implements BeforeDelete.Handler, BeforeDelete.PriorParentQuery, BeforeDelete.RelatedQuery, BeforeDelete.Bypassable, BeforeDelete.Finalizer {
        public virtual Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.evaluate(record);
        }

        public virtual void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.act(record);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeDelete() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
            this.step('relatedQuery', null);
            return (Map<String, BeforeDelete.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnBeforeDeleteWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeBeforeDelete(TriggerHandler.DeleteRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterDeleteWriterSpy extends Spy implements AfterDelete.Writer, AfterDelete.PriorParentQuery, AfterDelete.RelatedQuery, AfterDelete.Bypassable, AfterDelete.Finalizer {
        public virtual Boolean writeOnAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.evaluate(record);
        }

        public virtual void writeOnAfterDelete(TriggerHandler.DeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
            this.register(record, unitOfWork);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterDelete() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete() {
            this.step('relatedQuery', null);
            return (Map<String, AfterDelete.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterDeleteWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterDelete(TriggerHandler.DeleteRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterDeleteDispatcherSpy extends Spy implements AfterDelete.Dispatcher, AfterDelete.PriorParentQuery, AfterDelete.RelatedQuery, AfterDelete.Bypassable, AfterDelete.Finalizer {
        public virtual Boolean dispatchOnAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.evaluate(record);
        }

        public virtual void dispatchOnAfterDelete(TriggerHandler.DeleteRecords records) {
            this.dispatchWith(records.getRecords());
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterDelete() {
            return this.declareParents('priorParentQuery', this.priorParentQuery);
        }

        public virtual Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete() {
            this.step('relatedQuery', null);
            return (Map<String, AfterDelete.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterDeleteWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterDelete(TriggerHandler.DeleteRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterUndeleteWriterSpy extends Spy implements AfterUndelete.Writer, AfterUndelete.ParentQuery, AfterUndelete.RelatedQuery, AfterUndelete.Bypassable, AfterUndelete.Finalizer {
        public virtual Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return this.evaluate(record);
        }

        public virtual void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
            this.act(record);
            this.register(record, unitOfWork);
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUndelete() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete() {
            this.step('relatedQuery', null);
            return (Map<String, AfterUndelete.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterUndeleteWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterUndelete(TriggerHandler.UndeleteRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class AfterUndeleteDispatcherSpy extends Spy implements AfterUndelete.Dispatcher, AfterUndelete.ParentQuery, AfterUndelete.RelatedQuery, AfterUndelete.Bypassable, AfterUndelete.Finalizer {
        public virtual Boolean dispatchOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return this.evaluate(record);
        }

        public virtual void dispatchOnAfterUndelete(TriggerHandler.UndeleteRecords records) {
            this.dispatchWith(records.getRecords());
        }

        public virtual Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUndelete() {
            return this.declareParents('parentQuery', this.parentQuery);
        }

        public virtual Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete() {
            this.step('relatedQuery', null);
            return (Map<String, AfterUndelete.RecordsProvider>) this.providers;
        }

        public virtual Boolean bypassOnAfterUndeleteWhen() {
            return this.isBypassed();
        }

        public virtual void finalizeAfterUndelete(TriggerHandler.UndeleteRecords records) {
            this.finalizeWith(records.getRecords());
        }
    }

    private virtual class ContinuingBeforeInsertPopulatorSpy extends BeforeInsertPopulatorSpy implements BeforeInsert.ContinueOnError {
    }

    private virtual class ContinuingBeforeInsertValidatorSpy extends BeforeInsertValidatorSpy implements BeforeInsert.ContinueOnError {
    }

    private virtual class ContinuingAfterInsertWriterSpy extends AfterInsertWriterSpy implements AfterInsert.ContinueOnError {
    }

    private virtual class ContinuingAfterInsertDispatcherSpy extends AfterInsertDispatcherSpy implements AfterInsert.ContinueOnError {
    }

    private virtual class ContinuingBeforeUpdatePopulatorSpy extends BeforeUpdatePopulatorSpy implements BeforeUpdate.ContinueOnError {
    }

    private virtual class ContinuingBeforeUpdateValidatorSpy extends BeforeUpdateValidatorSpy implements BeforeUpdate.ContinueOnError {
    }

    private virtual class ContinuingAfterUpdateWriterSpy extends AfterUpdateWriterSpy implements AfterUpdate.ContinueOnError {
    }

    private virtual class ContinuingAfterUpdateDispatcherSpy extends AfterUpdateDispatcherSpy implements AfterUpdate.ContinueOnError {
    }

    private virtual class ContinuingBeforeDeleteHandlerSpy extends BeforeDeleteHandlerSpy implements BeforeDelete.ContinueOnError {
    }

    private virtual class ContinuingAfterDeleteWriterSpy extends AfterDeleteWriterSpy implements AfterDelete.ContinueOnError {
    }

    private virtual class ContinuingAfterDeleteDispatcherSpy extends AfterDeleteDispatcherSpy implements AfterDelete.ContinueOnError {
    }

    private virtual class ContinuingAfterUndeleteWriterSpy extends AfterUndeleteWriterSpy implements AfterUndelete.ContinueOnError {
    }

    private virtual class ContinuingAfterUndeleteDispatcherSpy extends AfterUndeleteDispatcherSpy implements AfterUndelete.ContinueOnError {
    }

    private virtual class GuardedBeforeUpdatePopulatorSpy extends BeforeUpdatePopulatorSpy implements BeforeUpdate.RecursionGuard {
        public Integer maxDepth;

        public virtual Integer maxRecursionDepthOnBeforeUpdate() {
            return this.maxDepth;
        }
    }

    private virtual class GuardedAfterUpdateWriterSpy extends AfterUpdateWriterSpy implements AfterUpdate.RecursionGuard {
        public Integer maxDepth;

        public virtual Integer maxRecursionDepthOnAfterUpdate() {
            return this.maxDepth;
        }
    }

    private virtual class GuardedAfterUpdateDispatcherSpy extends AfterUpdateDispatcherSpy implements AfterUpdate.RecursionGuard {
        public Integer maxDepth;

        public virtual Integer maxRecursionDepthOnAfterUpdate() {
            return this.maxDepth;
        }
    }

    private virtual class OwnUnitAfterInsertWriterSpy extends AfterInsertWriterSpy implements AfterInsert.OwnUnitOfWork {
        public DML.Committable ownUnit = new DML().identifier(TriggerOrchestratorTest.OWN_UNIT);

        public virtual DML.Committable ownUnitOfWorkOnAfterInsert() {
            return this.ownUnit;
        }
    }

    private virtual class OwnUnitAfterUpdateWriterSpy extends AfterUpdateWriterSpy implements AfterUpdate.OwnUnitOfWork {
        public DML.Committable ownUnit = new DML().identifier(TriggerOrchestratorTest.OWN_UNIT);

        public virtual DML.Committable ownUnitOfWorkOnAfterUpdate() {
            return this.ownUnit;
        }
    }

    private virtual class OwnUnitAfterDeleteWriterSpy extends AfterDeleteWriterSpy implements AfterDelete.OwnUnitOfWork {
        public DML.Committable ownUnit = new DML().identifier(TriggerOrchestratorTest.OWN_UNIT);

        public virtual DML.Committable ownUnitOfWorkOnAfterDelete() {
            return this.ownUnit;
        }
    }

    private virtual class OwnUnitAfterUndeleteWriterSpy extends AfterUndeleteWriterSpy implements AfterUndelete.OwnUnitOfWork {
        public DML.Committable ownUnit = new DML().identifier(TriggerOrchestratorTest.OWN_UNIT);

        public virtual DML.Committable ownUnitOfWorkOnAfterUndelete() {
            return this.ownUnit;
        }
    }
}
