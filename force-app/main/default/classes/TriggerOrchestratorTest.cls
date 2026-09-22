/**
 * @description Tests for the TriggerOrchestrator class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.1
 *
 * PMD False Positives:
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ExcessivePublicCount: Test handlers expose their recorded state so the assertions can read it
 * - TooManyFields: Test handlers expose their recorded state so the assertions can read it
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ExcessivePublicCount,PMD.TooManyFields,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true)
private class TriggerOrchestratorTest {
    @IsTest
    static void dispatchBeforeInsertRunsTheHandlersOfItsOwnList() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe', Department = 'Sales'), new Contact(LastName = 'Roe', Department = 'Legal') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeInsertHandlers' }, orchestrator.requestedHandlerLists, 'It should be beforeInsertHandlers alone.');
        Assert.areEqual(2, orchestrator.beforeInsertHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.beforeInsertHandler.runCount, 'It should be 2.');
        Assert.areEqual(
            'Doe',
            ((Contact) orchestrator.beforeInsertHandler.handledNewRecords[0]).LastName,
            'It should be Doe, because records reach the handler in the order the trigger set holds them.'
        );
        Assert.areEqual('Legal', ((Contact) orchestrator.beforeInsertHandler.handledNewRecords[1]).Department, 'It should be Legal.');
        Assert.isNull(orchestrator.beforeInsertHandler.handledIds[0], 'It should be null.');
    }

    @IsTest
    static void dispatchAfterInsertRunsTheHandlersOfItsOwnList() {
        List<SObject> newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Roe')
        };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterInsertHandlers' }, orchestrator.requestedHandlerLists, 'It should be afterInsertHandlers alone.');
        Assert.areEqual(2, orchestrator.afterInsertHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.afterInsertHandler.runCount, 'It should be 2.');
        Assert.areEqual('Doe', ((Contact) orchestrator.afterInsertHandler.handledNewRecords[0]).LastName, 'It should be Doe.');
        Assert.areEqual(newRecords[1].Id, orchestrator.afterInsertHandler.handledIds[1], 'It should be the id of the second inserted record.');
    }

    @IsTest
    static void dispatchBeforeUpdateRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'New One'), new Contact(Id = secondContactId, LastName = 'New Two') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Old One'), new Contact(Id = secondContactId, LastName = 'Old Two') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeUpdateHandlers' }, orchestrator.requestedHandlerLists, 'It should be beforeUpdateHandlers alone.');
        Assert.areEqual(2, orchestrator.beforeUpdateHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.beforeUpdateHandler.runCount, 'It should be 2.');
        Assert.areEqual('New One', ((Contact) orchestrator.beforeUpdateHandler.handledNewRecords[0]).LastName, 'It should be New One.');
        Assert.areEqual('Old One', ((Contact) orchestrator.beforeUpdateHandler.handledOldRecords[0]).LastName, 'It should be Old One.');
        Assert.areEqual('Old Two', ((Contact) orchestrator.beforeUpdateHandler.handledOldRecords[1]).LastName, 'It should be Old Two.');
    }

    @IsTest
    static void dispatchAfterUpdateRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'New One'), new Contact(Id = secondContactId, LastName = 'New Two') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Old One'), new Contact(Id = secondContactId, LastName = 'Old Two') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterUpdateHandlers' }, orchestrator.requestedHandlerLists, 'It should be afterUpdateHandlers alone.');
        Assert.areEqual(2, orchestrator.afterUpdateHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.afterUpdateHandler.runCount, 'It should be 2.');
        Assert.areEqual('New Two', ((Contact) orchestrator.afterUpdateHandler.handledNewRecords[1]).LastName, 'It should be New Two.');
        Assert.areEqual('Old Two', ((Contact) orchestrator.afterUpdateHandler.handledOldRecords[1]).LastName, 'It should be Old Two.');
        Assert.areEqual(newRecords[1].Id, orchestrator.afterUpdateHandler.handledIds[1], 'It should be the id of the second updated record.');
    }

    @IsTest
    static void dispatchBeforeDeleteRunsTheHandlersOfItsOwnList() {
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted One', Department = 'Sales'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted Two', Department = 'Legal')
        };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeDeleteHandlers' }, orchestrator.requestedHandlerLists, 'It should be beforeDeleteHandlers alone.');
        Assert.areEqual(2, orchestrator.beforeDeleteHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.beforeDeleteHandler.runCount, 'It should be 2.');
        Assert.areEqual('Deleted One', ((Contact) orchestrator.beforeDeleteHandler.handledOldRecords[0]).LastName, 'It should be Deleted One.');
        Assert.areEqual('Legal', ((Contact) orchestrator.beforeDeleteHandler.handledOldRecords[1]).Department, 'It should be Legal.');
        Assert.areEqual(oldRecords[1].Id, orchestrator.beforeDeleteHandler.handledIds[1], 'It should be the id of the second deleted record.');
    }

    @IsTest
    static void dispatchAfterDeleteRunsTheHandlersOfItsOwnList() {
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted One', Department = 'Sales'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted Two', Department = 'Legal')
        };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterDeleteHandlers' }, orchestrator.requestedHandlerLists, 'It should be afterDeleteHandlers alone.');
        Assert.areEqual(2, orchestrator.afterDeleteHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.afterDeleteHandler.runCount, 'It should be 2.');
        Assert.areEqual(
            'Deleted Two',
            ((Contact) orchestrator.afterDeleteHandler.handledOldRecords[1]).LastName,
            'It should be Deleted Two, because a delete context dispatches the deleted rows in trigger order.'
        );
        Assert.areEqual('Sales', ((Contact) orchestrator.afterDeleteHandler.handledOldRecords[0]).Department, 'It should be Sales.');
        Assert.areEqual(oldRecords[0].Id, orchestrator.afterDeleteHandler.handledIds[0], 'It should be the id of the first deleted record.');
    }

    @IsTest
    static void dispatchAfterUndeleteRunsTheHandlersOfItsOwnList() {
        List<SObject> newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored One'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored Two')
        };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'afterUndeleteHandlers' }, orchestrator.requestedHandlerLists, 'It should be afterUndeleteHandlers alone.');
        Assert.areEqual(2, orchestrator.afterUndeleteHandler.qualifyCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.afterUndeleteHandler.runCount, 'It should be 2.');
        Assert.areEqual('Restored One', ((Contact) orchestrator.afterUndeleteHandler.handledNewRecords[0]).LastName, 'It should be Restored One.');
        Assert.areEqual(newRecords[1].Id, orchestrator.afterUndeleteHandler.handledIds[1], 'It should be the id of the second restored record.');
    }

    @IsTest
    static void dispatchRunsEveryHandlerReturnedByTheList() {
        List<SObject> newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Roe')
        };
        DispatchTwoHandlersOrchestrator orchestrator = new DispatchTwoHandlersOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, orchestrator.firstHandler.runCount, 'It should be 2.');
        Assert.areEqual(2, orchestrator.secondHandler.runCount, 'It should be 2.');
    }

    @IsTest
    static void dispatchUnimplementedAfterInsertContextIsSilentNoOp() {
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe') };
        DispatchPartialOrchestrator orchestrator = new DispatchPartialOrchestrator();
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.isTrue(orchestrator.requestedHandlerLists.isEmpty(), 'It should be true.');
        Assert.areEqual(0, orchestrator.beforeInsertHandler.runCount + orchestrator.afterUpdateHandler.runCount, 'It should be 0.');
    }

    @IsTest
    static void dispatchUnimplementedBeforeDeleteContextIsSilentNoOp() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted One') };
        DispatchPartialOrchestrator orchestrator = new DispatchPartialOrchestrator();
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.isTrue(orchestrator.requestedHandlerLists.isEmpty(), 'It should be true.');
    }

    @IsTest
    static void dispatchImplementedContextStillRunsWhenOtherContextsAreNotImplemented() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchPartialOrchestrator orchestrator = new DispatchPartialOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, orchestrator.beforeInsertHandler.runCount, 'It should be 1.');
        Assert.areEqual(new List<String>{ 'beforeInsertHandlers' }, orchestrator.requestedHandlerLists, 'It should be beforeInsertHandlers alone.');
    }

    @IsTest
    static void dispatchOrchestratorWithoutContextInterfacesIsSilentNoOp() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DispatchNoInterfacesOrchestrator());
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
    }

    @IsTest
    static void dispatchNonOrchestratorArgumentIsSilentNoOpInTriggerContext() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DispatchNonOrchestrator());
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
    }

    @IsTest
    static void dispatchNullOrchestratorIsSilentNoOpInTriggerContext() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(null);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
    }

    @IsTest
    static void dispatchRunOutsideTriggerContextThrows() {
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator.run(orchestrator);
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message.'
        );
        Assert.isTrue(orchestratorException.getTypeName().endsWith('TriggerOrchestratorException'), 'It should be true.');
        Assert.isTrue(orchestrator.requestedHandlerLists.isEmpty(), 'It should be true.');
    }

    @IsTest
    static void dispatchRunOutsideTriggerContextWithNullArgumentThrows() {
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator.run(null);
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message.'
        );
    }

    @IsTest
    static void dispatchRunOutsideTriggerContextWithNonOrchestratorArgumentThrows() {
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator.run(new DispatchNonOrchestrator());
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message.'
        );
    }

    @IsTest
    static void dispatchRunWithRecordsButWithoutOperationTypeThrows() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator.run(new DispatchAllContextsOrchestrator());
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message.'
        );
    }

    @IsTest
    static void dispatchEmptyHandlerListRunsNothingOnBeforeInsert() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
        DispatchEmptyListOrchestrator orchestrator = new DispatchEmptyListOrchestrator();
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(new List<String>{ 'beforeInsertHandlers' }, orchestrator.requestedHandlerLists, 'It should be beforeInsertHandlers alone.');
    }

    @IsTest
    static void dispatchEmptyHandlerListRunsNothingOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New One') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old One') };
        DispatchEmptyListOrchestrator orchestrator = new DispatchEmptyListOrchestrator();
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(new List<String>{ 'afterUpdateHandlers' }, orchestrator.requestedHandlerLists, 'It should be afterUpdateHandlers alone.');
    }

    @IsTest
    static void dispatchEmptyTriggerRecordListLeavesHandlersUnused() {
        List<SObject> newRecords = new List<Contact>();
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'beforeInsertHandlers' }, orchestrator.requestedHandlerLists, 'It should be beforeInsertHandlers alone.');
        Assert.areEqual(0, orchestrator.beforeInsertHandler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, orchestrator.totalRunCount(), 'It should be 0.');
    }

    @IsTest
    static void dispatchObjectBypassedInMetadataRunsNoHandler() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = true));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(0, orchestrator.totalRunCount(), 'It should be 0.');
        Assert.isTrue(orchestrator.requestedHandlerLists.isEmpty(), 'It should be true.');
    }

    @IsTest
    static void dispatchObjectBypassedInMetadataAppliesInAfterContexts() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New One') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old One') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = true));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, orchestrator.totalRunCount(), 'It should be 0.');
        Assert.isTrue(orchestrator.requestedHandlerLists.isEmpty(), 'It should be true.');
    }

    @IsTest
    static void dispatchObjectBypassOfAnotherSObjectDoesNotStopDispatch() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, orchestrator.beforeInsertHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void dispatchObjectNotBypassedInMetadataRunsHandlers() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = false));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, orchestrator.beforeInsertHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void dispatchUnimplementedContextInANestedRunLeavesTheOuterInvocationAlone() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchFinalizeCountingLogger logger = new DispatchFinalizeCountingLogger();
        DispatchNestedRunOrchestrator orchestrator = new DispatchNestedRunOrchestrator();

        orchestrator.handler.logger = logger;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, orchestrator.handler.finalizeCountDuringHandler, 'It should be 0, because a nested run that resolves to no context is a silent no-op.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1.');
    }

    @IsTest
    static void beforeInsertPopulatorWritesFieldOnQualifiedRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertPopulator handler = new RolesInsertPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated.');
        Assert.areEqual(1, handler.populateCount, 'It should be 1.');
    }

    @IsTest
    static void beforeInsertPopulatorRunsOncePerQualifiedRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B') };
        RolesInsertPopulator handler = new RolesInsertPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.qualificationCount, 'It should be 2.');
        Assert.areEqual(2, handler.populateCount, 'It should be 2.');
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated.');
        Assert.areEqual('Populated', ((Contact) records[1]).Title, 'It should be Populated.');
    }

    @IsTest
    static void beforeInsertPopulatorActionIsSkippedWhenQualificationReturnsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertPopulator handler = new RolesInsertPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.qualifies = false;
        orchestrator.insertHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.qualificationCount, 'It should be 1.');
        Assert.areEqual(0, handler.populateCount, 'It should be 0.');
        Assert.isNull(((Contact) records[0]).Title, 'It should be null.');
    }

    @IsTest
    static void beforeInsertPopulatorActionRunsOnlyForQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B', Title = 'Existing') };
        RolesBlankTitlePopulator handler = new RolesBlankTitlePopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.populateCount, 'It should be 1.');
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated.');
        Assert.areEqual('Existing', ((Contact) records[1]).Title, 'It should be Existing.');
    }

    @IsTest
    static void beforeUpdatePopulatorWritesFieldOnQualifiedRecord() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesUpdatePopulator handler = new RolesUpdatePopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Populated', ((Contact) newRecords[0]).Department, 'It should be Populated.');
        Assert.areEqual(1, handler.populateCount, 'It should be 1.');
        Assert.isNull(((Contact) oldRecords[0]).Department, 'It should be null.');
    }

    @IsTest
    static void beforeUpdatePopulatorActionIsSkippedWhenQualificationReturnsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesUpdatePopulator handler = new RolesUpdatePopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.qualifies = false;
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.qualificationCount, 'It should be 1.');
        Assert.areEqual(0, handler.populateCount, 'It should be 0.');
        Assert.isNull(((Contact) newRecords[0]).Department, 'It should be null.');
    }

    @IsTest
    static void beforeUpdatePopulatorActionRunsOnlyForQualifiedRecords() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'A', Title = 'New'),
            new Contact(Id = secondContactId, LastName = 'B', Title = 'Same')
        };
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'A', Title = 'Old'),
            new Contact(Id = secondContactId, LastName = 'B', Title = 'Same')
        };
        RolesChangedTitlePopulator handler = new RolesChangedTitlePopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.populateCount, 'It should be 1.');
        Assert.areEqual('Populated', ((Contact) newRecords[0]).Department, 'It should be Populated.');
        Assert.isNull(((Contact) newRecords[1]).Department, 'It should be null.');
    }

    @IsTest
    static void beforeInsertValidatorAttachesErrorWhenPredicateReturnsTrue() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(new RolesInsertValidator());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Title is required on new contacts.', records[0].getErrors()[0].getMessage(), 'It should be the validator message.');
    }

    @IsTest
    static void beforeInsertValidatorUsesValidationMessageMethodAsErrorMessage() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertValidator handler = new RolesInsertValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.validationMessage = 'Contacts from this source are not allowed.';
        orchestrator.insertHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.messageCount, 'It should be 1.');
        Assert.areEqual(
            'Contacts from this source are not allowed.',
            records[0].getErrors()[0].getMessage(),
            'It should be the exact string returned by beforeInsertValidationMessage.'
        );
    }

    @IsTest
    static void beforeInsertValidatorLeavesRecordUntouchedWhenPredicateReturnsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A', Title = 'Existing') };
        RolesInsertValidator handler = new RolesInsertValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.errorShouldBeAttached = false;
        orchestrator.insertHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.isTrue(records[0].getErrors().isEmpty(), 'It should be empty.');
        Assert.areEqual(0, handler.messageCount, 'It should be 0.');
    }

    @IsTest
    static void beforeInsertValidatorAttachesErrorOnlyToQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B', Title = 'Existing') };
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(new RolesBlankTitleValidator());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
        Assert.isTrue(records[1].getErrors().isEmpty(), 'It should be empty.');
    }

    @IsTest
    static void beforeUpdateValidatorAttachesErrorWhenPredicateReturnsTrue() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(new RolesUpdateValidator());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Title cannot be changed.', newRecords[0].getErrors()[0].getMessage(), 'It should be the validator message.');
    }

    @IsTest
    static void beforeUpdateValidatorAttachesErrorToTheNewRecordSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(new RolesUpdateValidator());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
        Assert.isTrue(oldRecords[0].getErrors().isEmpty(), 'It should be empty.');
    }

    @IsTest
    static void beforeUpdateValidatorUsesValidationMessageMethodAsErrorMessage() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesUpdateValidator handler = new RolesUpdateValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.validationMessage = 'Closed contacts cannot be edited.';
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.messageCount, 'It should be 1.');
        Assert.areEqual('Closed contacts cannot be edited.', newRecords[0].getErrors()[0].getMessage(), 'It should be the exact string returned by beforeUpdateValidationMessage.');
    }

    @IsTest
    static void beforeUpdateValidatorLeavesRecordUntouchedWhenPredicateReturnsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesUpdateValidator handler = new RolesUpdateValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.errorShouldBeAttached = false;
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.isTrue(newRecords[0].getErrors().isEmpty(), 'It should be empty.');
        Assert.areEqual(0, handler.messageCount, 'It should be 0.');
    }

    @IsTest
    static void beforeUpdateValidatorAttachesErrorOnlyToQualifiedRecords() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'A', Title = 'New'),
            new Contact(Id = secondContactId, LastName = 'B', Title = 'Same')
        };
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'A', Title = 'Old'),
            new Contact(Id = secondContactId, LastName = 'B', Title = 'Same')
        };
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(new RolesChangedTitleValidator());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
        Assert.isTrue(newRecords[1].getErrors().isEmpty(), 'It should be empty.');
    }

    @IsTest
    static void beforeInsertHandlersRunInRegistrationOrderRegardlessOfRole() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        List<String> executionLog = new List<String>();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(new RolesLoggingInsertPopulator('First', executionLog));
        orchestrator.insertHandlers.add(new RolesLoggingInsertValidator('Second', executionLog));
        orchestrator.insertHandlers.add(new RolesLoggingInsertPopulator('Third', executionLog));

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'First qualify A,First populate A,Second qualify A,Second message A,Third qualify A,Third populate A',
            String.join(executionLog, ','),
            'It should be the registration order.'
        );
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
    }

    @IsTest
    static void beforeUpdateHandlersRunInRegistrationOrderRegardlessOfRole() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        List<String> executionLog = new List<String>();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(new RolesLoggingUpdateValidator('First', executionLog));
        orchestrator.updateHandlers.add(new RolesLoggingUpdatePopulator('Second', executionLog));

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('First qualify A,First message A,Second qualify A,Second populate A', String.join(executionLog, ','), 'It should be the registration order.');
    }

    @IsTest
    static void beforeInsertHandlerProcessesEveryRecordBeforeTheNextHandlerStarts() {
        List<String> executionLog = new List<String>();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(new RolesLoggingInsertPopulator('First', executionLog));
        orchestrator.insertHandlers.add(new RolesLoggingInsertPopulator('Second', executionLog));

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'First qualify A,First populate A,First qualify B,First populate B,Second qualify A,Second populate A,Second qualify B,Second populate B',
            String.join(executionLog, ','),
            'It should be handler by handler.'
        );
    }

    @IsTest
    static void oneClassWithARoleInTwoContextsRunsOnlyTheBeforeInsertMethods() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesDualContextPopulator handler = new RolesDualContextPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.beforeInsertPopulateCount, 'It should be 1.');
        Assert.areEqual(0, handler.beforeUpdatePopulateCount, 'It should be 0.');
        Assert.areEqual('Insert', ((Contact) records[0]).Title, 'It should be Insert.');
    }

    @IsTest
    static void oneClassWithARoleInTwoContextsRunsOnlyTheBeforeUpdateMethods() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesDualContextPopulator handler = new RolesDualContextPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.beforeUpdatePopulateCount, 'It should be 1.');
        Assert.areEqual(0, handler.beforeInsertPopulateCount, 'It should be 0.');
        Assert.areEqual('Update', ((Contact) newRecords[0]).Title, 'It should be Update.');
    }

    @IsTest
    static void oneClassWithARoleInTwoContextsFiresEachContextFinalizerOnce() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesDualContextPopulator handler = new RolesDualContextPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'A') };
        orchestratorRunner.run();

        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner2.context.newRecords = newRecords;
        orchestratorRunner2.context.oldRecords = oldRecords;
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.beforeInsertFinalizeCount, 'It should be 1.');
        Assert.areEqual(1, handler.beforeUpdateFinalizeCount, 'It should be 1.');
        Assert.areEqual(1, handler.beforeInsertPopulateCount, 'It should be 1.');
        Assert.areEqual(1, handler.beforeUpdatePopulateCount, 'It should be 1.');
    }

    @IsTest
    static void oneClassCanHoldADifferentRoleInEachBeforeContext() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesInsertPopulatorAndUpdateValidator handler = new RolesInsertPopulatorAndUpdateValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);
        orchestrator.updateHandlers.add(handler);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();

        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner2.context.newRecords = newRecords;
        orchestratorRunner2.context.oldRecords = oldRecords;
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated.');
        Assert.isTrue(records[0].getErrors().isEmpty(), 'It should be empty.');
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
    }

    @IsTest
    static void enrichmentAttachesParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Umbrella Corp', Industry = 'Technology');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', Email = 'sanders@example.com', AccountId = parentAccount.Id) };
        insert newRecords;

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.seenNewParents.size(), 'It should be 1.');
        Assert.areEqual(parentAccount.Id, handler.seenNewParents[0].Id, 'It should be the inserted account id.');
        Assert.areEqual('Umbrella Corp', ((Account) handler.seenNewParents[0]).Name, 'It should be Umbrella Corp.');
    }

    @IsTest
    static void enrichmentAttachesParentOnOldSide() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        Id contactId = new EnrichmentIdFactory().next(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        EnrichmentAfterUpdateHandler handler = new EnrichmentAfterUpdateHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Previous Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Previous Parent.');
        Assert.isNull(handler.seenNewParents[0], 'It should be null.');
    }

    @IsTest
    static void enrichmentUndeclaredRelationshipReturnsNullWithoutQuery() {
        Account parentAccount = new Account(Name = 'Never Queried');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBeforeRun = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfterRun = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.isNull(handler.seenNewParents[0], 'It should be null.');
        Assert.areEqual(0, queriesAfterRun - queriesBeforeRun, 'It should be 0, because no query is issued for an undeclared relationship.');
    }

    @IsTest
    static void enrichmentUnsetLookupAttachesNoParent() {
        Account parentAccount = new Account(Name = 'Umbrella Corp');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'With Parent', Email = 'with.parent@example.com', AccountId = parentAccount.Id),
            new Contact(LastName = 'Without Parent', Email = 'without.parent@example.com')
        };
        insert newRecords;

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because a record holding a value in the declared lookup still gets its parent.'
        );
        Assert.isNull(handler.seenNewParents[1], 'It should be null, because an unset lookup fetches nothing for that record and raises no error.');
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1.');
    }

    @IsTest
    static void enrichmentUnsetLookupOnEveryRecordAttachesNothing() {
        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'First', Email = 'first@example.com'),
            new Contact(LastName = 'Second', Email = 'second@example.com')
        };
        insert newRecords;

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBeforeRun = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfterRun = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfterRun - queriesBeforeRun, 'It should be 1, because saved records are read once whatever their lookups hold.');
        Assert.isNull(handler.seenNewParents[0], 'It should be null.');
        Assert.isNull(handler.seenNewParents[1], 'It should be null.');
    }

    @IsTest
    static void enrichmentSeveralHandlersDeclaringTheSameParentFieldCostOneQuery() {
        Account parentAccount = new Account(Name = 'Umbrella Corp', Industry = 'Technology', BillingCountry = 'Poland');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'First', Email = 'first@example.com', AccountId = parentAccount.Id),
            new Contact(LastName = 'Second', Email = 'second@example.com', AccountId = parentAccount.Id)
        };
        insert newRecords;

        EnrichmentAfterInsertHandler nameHandler = new EnrichmentAfterInsertHandler();
        nameHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        EnrichmentAfterInsertHandler industryHandler = new EnrichmentAfterInsertHandler();
        industryHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Industry));

        EnrichmentAfterInsertHandler countryHandler = new EnrichmentAfterInsertHandler();
        countryHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.BillingCountry));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ nameHandler, industryHandler, countryHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because every declared field is read through the saved records in one query.');
        Assert.areEqual(
            'Technology',
            ((Account) nameHandler.seenNewParents[0]).Industry,
            'It should be Technology, because the field selections of every active handler are merged into the one query issued for that lookup field.'
        );
        Assert.areEqual(
            'Poland',
            ((Account) industryHandler.seenNewParents[1]).BillingCountry,
            'It should be Poland, because declarations are pooled, so a handler reads fields it never declared itself.'
        );
    }

    @IsTest
    static void enrichmentTwoDeclaredLookupsCostOneQueryOnSavedRecords() {
        Account parentAccount = new Account(Name = 'Umbrella Corp');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'First', Email = 'first@example.com', AccountId = parentAccount.Id, OwnerId = UserInfo.getUserId()),
            new Contact(LastName = 'Second', Email = 'second@example.com', AccountId = parentAccount.Id, OwnerId = UserInfo.getUserId())
        };
        insert newRecords;

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        handler.declareNew(Contact.OwnerId, TriggerHandler.ParentFields.with(User.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because saved records carry every declared parent in one query.');
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because each declared lookup is attached under its own relationship name.'
        );
        Assert.areEqual(UserInfo.getUserId(), handler.seenNewOwners[0].Id, 'It should be the running user id.');
    }

    @IsTest
    static void enrichmentLookupPointingAtMissingParentAttachesNull() {
        Id missingAccountId = new EnrichmentIdFactory().next(Account.SObjectType);

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = missingAccountId) };

        EnrichmentBeforeInsertHandler handler = new EnrichmentBeforeInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.isNull(handler.seenNewParents[0], 'It should be null, because a lookup pointing at a record the query did not return attaches nothing and raises no error.');
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because a populated lookup is always queried, and the miss is cached like a hit.');
    }

    @IsTest
    static void enrichmentRepointedLookupIsVisibleToALaterHandler() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'First Parent'), new Account(Name = 'Second Parent') };
        insert accounts;

        Id contactId = new EnrichmentIdFactory().next(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = accounts[0].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = accounts[0].Id) };

        EnrichmentBeforeUpdateHandler repointingHandler = new EnrichmentBeforeUpdateHandler();
        repointingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        repointingHandler.accountIdsToSet = new List<Id>{ accounts[1].Id };

        EnrichmentBeforeUpdateHandler readingHandler = new EnrichmentBeforeUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'First Parent',
            ((Account) repointingHandler.seenNewParents[0]).Name,
            'It should be First Parent, because parents are resolved before the first handler runs, so it sees the lookup as the record arrived.'
        );
        Assert.areEqual(
            'Second Parent',
            ((Account) readingHandler.seenNewParents[0]).Name,
            'It should be Second Parent, because before update re-checks declared lookups at every handler boundary.'
        );
        Assert.areEqual(2, queriesAfter - queriesBefore, 'It should be 2, because the initial resolution costs one query and the changed lookup costs exactly one more.');
    }

    @IsTest
    static void enrichmentLookupPopulatedFromNullIsVisibleToALaterHandler() {
        Account parentAccount = new Account(Name = 'Umbrella Corp');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders') };

        EnrichmentBeforeInsertHandler populatingHandler = new EnrichmentBeforeInsertHandler();
        populatingHandler.accountIdsToSet = new List<Id>{ parentAccount.Id };

        EnrichmentBeforeInsertHandler readingHandler = new EnrichmentBeforeInsertHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ populatingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.isNull(populatingHandler.seenNewParents[0], 'It should be null, because the declared lookup was still empty when the first handler took its turn.');
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) readingHandler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because a lookup filled in from empty resolves at the next handler boundary instead of staying null.'
        );
        Assert.areEqual(
            1,
            queriesAfter - queriesBefore,
            'It should be 1, because an invocation whose lookups are all empty queries nothing, and the newly populated lookup costs a single query.'
        );
    }

    @IsTest
    static void enrichmentRepointOfManyRecordsCostsOneExtraQuery() {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < 11; i++) {
            accounts.add(new Account(Name = 'Parent ' + i));
        }

        insert accounts;

        EnrichmentIdFactory idFactory = new EnrichmentIdFactory();
        List<Contact> newContacts = new List<Contact>();
        List<Contact> oldContacts = new List<Contact>();
        List<Id> repointedAccountIds = new List<Id>();

        for (Integer i = 0; i < 10; i++) {
            Id contactId = idFactory.next(Contact.SObjectType);

            newContacts.add(new Contact(Id = contactId, LastName = 'Child ' + i, AccountId = accounts[10].Id));
            oldContacts.add(new Contact(Id = contactId, LastName = 'Child ' + i, AccountId = accounts[10].Id));
            repointedAccountIds.add(accounts[i].Id);
        }

        List<SObject> newRecords = newContacts;
        List<SObject> oldRecords = oldContacts;

        EnrichmentBeforeUpdateHandler repointingHandler = new EnrichmentBeforeUpdateHandler();
        repointingHandler.accountIdsToSet = repointedAccountIds;

        EnrichmentBeforeUpdateHandler readingHandler = new EnrichmentBeforeUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Account firstSeenNewParent = (Account) readingHandler.seenNewParents[0];
        Account tenthSeenNewParent = (Account) readingHandler.seenNewParents[9];
        Assert.areEqual(
            2,
            queriesAfter - queriesBefore,
            'It should be 2, because ten records re-pointed to ten different parents cost one additional query for the whole chunk, never one per record.'
        );
        Assert.areEqual(10, readingHandler.seenNewParents.size(), 'It should be 10, because the re-check covers every record of the chunk, not only the first.');
        Assert.areEqual('Parent 0', firstSeenNewParent.Name, 'It should be Parent 0, because the single extra query attaches the parent each record now points at.');
        Assert.areEqual('Parent 9', tenthSeenNewParent.Name, 'It should be Parent 9, because the single extra query covers every record whose lookup changed.');
    }

    @IsTest
    static void enrichmentManyHandlersChangingNothingCostNoExtraQueries() {
        Account parentAccount = new Account(Name = 'Umbrella Corp');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'First', AccountId = parentAccount.Id),
            new Contact(LastName = 'Second', AccountId = parentAccount.Id)
        };

        List<BeforeInsert.Handler> handlers = new List<BeforeInsert.Handler>();
        EnrichmentBeforeInsertHandler lastHandler = null;

        for (Integer i = 0; i < 10; i++) {
            lastHandler = new EnrichmentBeforeInsertHandler();
            lastHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
            handlers.add(lastHandler);
        }

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentBeforeInsertOrchestrator(handlers));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because the re-check between handlers costs nothing when no handler changed a declared lookup.');
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) lastHandler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because the tenth handler still reads the parent resolved on the first pass.'
        );
    }

    @IsTest
    static void enrichmentRepointToAnAlreadyCachedParentCostsNoQuery() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'First Parent'), new Account(Name = 'Second Parent') };
        insert accounts;

        EnrichmentIdFactory idFactory = new EnrichmentIdFactory();
        Id firstContactId = idFactory.next(Contact.SObjectType);
        Id secondContactId = idFactory.next(Contact.SObjectType);

        List<SObject> newRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'First', AccountId = accounts[0].Id),
            new Contact(Id = secondContactId, LastName = 'Second', AccountId = accounts[1].Id)
        };
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'First', AccountId = accounts[0].Id),
            new Contact(Id = secondContactId, LastName = 'Second', AccountId = accounts[1].Id)
        };

        EnrichmentBeforeUpdateHandler repointingHandler = new EnrichmentBeforeUpdateHandler();
        repointingHandler.accountIdsToSet = new List<Id>{ accounts[1].Id };

        EnrichmentBeforeUpdateHandler readingHandler = new EnrichmentBeforeUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            1,
            queriesAfter - queriesBefore,
            'It should be 1, because parents are cached by id for the whole invocation, so re-pointing a record at a parent already loaded for another record is free.'
        );
        Assert.areEqual(
            'Second Parent',
            ((Account) readingHandler.seenNewParents[0]).Name,
            'It should be Second Parent, because the re-pointed record is re-attached from the parent cache instead of keeping the old parent.'
        );
    }

    @IsTest
    static void enrichmentOldSideIsNeverRefreshed() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'First Parent'), new Account(Name = 'Second Parent') };
        insert accounts;

        Id contactId = new EnrichmentIdFactory().next(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = accounts[0].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = accounts[0].Id) };

        EnrichmentBeforeUpdateHandler repointingHandler = new EnrichmentBeforeUpdateHandler();
        repointingHandler.accountIdsToSet = new List<Id>{ accounts[1].Id };

        EnrichmentBeforeUpdateHandler readingHandler = new EnrichmentBeforeUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        readingHandler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'First Parent',
            ((Account) readingHandler.seenOldParents[0]).Name,
            'It should be First Parent, because Trigger.old is immutable, so the old side is resolved on the first pass and never follows a lookup a handler changed.'
        );
        Assert.areEqual(
            'Second Parent',
            ((Account) readingHandler.seenNewParents[0]).Name,
            'It should be Second Parent, because only the new side is re-checked when a handler changes a declared lookup.'
        );
        Assert.areEqual(2, queriesAfter - queriesBefore, 'It should be 2, because both sides resolve together in the first query and only the changed new side is queried again.');
    }

    @IsTest
    static void enrichmentInAfterUpdateResolvesOnceWithoutRecheck() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'First Parent'), new Account(Name = 'Second Parent') };
        insert accounts;

        Contact savedContact = new Contact(LastName = 'Sanders', Email = 'sanders@example.com', AccountId = accounts[0].Id);
        insert savedContact;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Sanders', AccountId = accounts[0].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Sanders', AccountId = accounts[0].Id) };

        EnrichmentAfterUpdateHandler repointingHandler = new EnrichmentAfterUpdateHandler();
        repointingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        repointingHandler.accountIdsToSet = new List<Id>{ accounts[1].Id };

        EnrichmentAfterUpdateHandler readingHandler = new EnrichmentAfterUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ repointingHandler, readingHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'First Parent',
            ((Account) readingHandler.seenNewParents[0]).Name,
            'It should be First Parent, because after update resolves parents once and never re-checks between handlers.'
        );
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because no re-check is performed in a context where no handler can change a record.');
    }

    @IsTest
    static void enrichmentChangedLookupCostsOneQueryPerSide() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        Contact savedContact = new Contact(LastName = 'Moved', Email = 'moved@example.com', AccountId = accounts[1].Id);
        insert savedContact;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Moved', AccountId = accounts[0].Id) };

        EnrichmentAfterUpdateHandler handler = new EnrichmentAfterUpdateHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because getOldParent returns the parent the record pointed at before the change.'
        );
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because getNewParent returns the parent the record points at now.'
        );
        Assert.areEqual(2, queriesAfter - queriesBefore, 'It should be 2, because the saved record carries the current parent and the previous one is fetched by id.');
    }

    @IsTest
    static void enrichmentUnchangedLookupResolvesBothSidesInOneQuery() {
        Account parentAccount = new Account(Name = 'Steady Parent');
        insert parentAccount;

        Contact savedContact = new Contact(LastName = 'Steady', Email = 'steady@example.com', AccountId = parentAccount.Id);
        insert savedContact;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Steady', AccountId = parentAccount.Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Steady', AccountId = parentAccount.Id) };

        EnrichmentAfterUpdateHandler handler = new EnrichmentAfterUpdateHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual('Steady Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Steady Parent.');
        Assert.areEqual('Steady Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Steady Parent.');
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because an unchanged lookup serves both sides from the saved record.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnBeforeInsert() {
        BypassBeforeInsertPopulator bypassedHandler = new BypassBeforeInsertPopulator();
        BypassBeforeInsertPopulator activeHandler = new BypassBeforeInsertPopulator();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnBeforeInsertWhenBypassIsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertPopulator handler = new BypassBeforeInsertPopulator();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated.');
    }

    @IsTest
    static void bypassableValidatorSkippedOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertValidator bypassedValidator = new BypassBeforeInsertValidator();
        BypassBeforeInsertPopulator activeHandler = new BypassBeforeInsertPopulator();
        bypassedValidator.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ bypassedValidator, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedValidator.messageCount, 'It should be 0.');
        Assert.areEqual(0, records[0].getErrors().size(), 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableValidatorRunsOnBeforeInsertWhenBypassIsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertValidator validator = new BypassBeforeInsertValidator();
        validator.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ validator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Before insert validation failed', records[0].getErrors()[0].getMessage(), 'It should be Before insert validation failed.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterInsert() {
        BypassAfterInsertHandler bypassedHandler = new BypassAfterInsertHandler();
        BypassAfterInsertHandler activeHandler = new BypassAfterInsertHandler();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterInsertWhenBypassIsFalse() {
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator bypassedHandler = new BypassBeforeUpdatePopulator();
        BypassBeforeUpdatePopulator activeHandler = new BypassBeforeUpdatePopulator();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnBeforeUpdateWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator handler = new BypassBeforeUpdatePopulator();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual('Populated', ((Contact) newRecords[0]).Title, 'It should be Populated.');
    }

    @IsTest
    static void bypassableValidatorSkippedOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdateValidator bypassedValidator = new BypassBeforeUpdateValidator();
        BypassBeforeUpdatePopulator activeHandler = new BypassBeforeUpdatePopulator();
        bypassedValidator.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ bypassedValidator, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedValidator.messageCount, 'It should be 0.');
        Assert.areEqual(0, newRecords[0].getErrors().size(), 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableValidatorRunsOnBeforeUpdateWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdateValidator validator = new BypassBeforeUpdateValidator();
        validator.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ validator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Before update validation failed', newRecords[0].getErrors()[0].getMessage(), 'It should be Before update validation failed.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler bypassedHandler = new BypassAfterUpdateHandler();
        BypassAfterUpdateHandler activeHandler = new BypassAfterUpdateHandler();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterUpdateWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler handler = new BypassAfterUpdateHandler();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnBeforeDelete() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassBeforeDeleteHandler bypassedHandler = new BypassBeforeDeleteHandler();
        BypassBeforeDeleteHandler activeHandler = new BypassBeforeDeleteHandler();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnBeforeDeleteWhenBypassIsFalse() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassBeforeDeleteHandler handler = new BypassBeforeDeleteHandler();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterDelete() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassAfterDeleteHandler bypassedHandler = new BypassAfterDeleteHandler();
        BypassAfterDeleteHandler activeHandler = new BypassAfterDeleteHandler();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterDeleteWhenBypassIsFalse() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassAfterDeleteHandler handler = new BypassAfterDeleteHandler();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterUndelete() {
        BypassAfterUndeleteHandler bypassedHandler = new BypassAfterUndeleteHandler();
        BypassAfterUndeleteHandler activeHandler = new BypassAfterUndeleteHandler();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterUndeleteWhenBypassIsFalse() {
        BypassAfterUndeleteHandler handler = new BypassAfterUndeleteHandler();
        handler.isBypassed = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassIsAskedOncePerInvocation() {
        List<SObject> records = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'One'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Two'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Three')
        };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.bypassCheckCount, 'It should be 1.');
        Assert.areEqual(3, handler.runCount, 'It should be 3.');
    }

    @IsTest
    static void bypassedHandlerQualificationIsNeverEvaluated() {
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'One'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Two')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void handlerWithoutBypassableInterfaceAlwaysRuns() {
        BypassPlainAfterInsertHandler handler = new BypassPlainAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void bypassedHandlerContributesNoEnrichmentFields() {
        BypassEnrichmentAfterInsertHandler bypassedHandler = new BypassEnrichmentAfterInsertHandler();
        BypassRelatedReaderAfterInsertHandler readerHandler = new BypassRelatedReaderAfterInsertHandler();
        bypassedHandler.isBypassed = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBeforeRun = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, readerHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass', AccountId = TriggerHandler.IdGenerator.get(Account.SObjectType))
        };
        orchestratorRunner.run();

        Integer queriesAfterRun = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, queriesAfterRun - queriesBeforeRun, 'It should be 0, because parent fields are declared from the surviving handlers only.');
        Assert.areEqual(1, readerHandler.runCount, 'It should be 1.');
        Assert.isNull(readerHandler.relatedAccount, 'It should be null.');
    }

    @IsTest
    static void bypassWholeContextWithEmptyHandlerList() {
        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>());
        Exception orchestratorException = null;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.isTrue(orchestrator.areHandlersRequested, 'It should be true.');
    }

    @IsTest
    static void metadataBypassedHandlerIsSkipped() {
        BypassMetadataHandler bypassedHandler = new BypassMetadataHandler();
        BypassAfterInsertHandler activeHandler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "bypassmetadatahandler", "Bypass__c": true}]}, "Bypass__c": false}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void metadataBypassedHandlerIsNeverAskedForItsCodeBypass() {
        BypassMetadataHandler handler = new BypassMetadataHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "bypassmetadatahandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.bypassCheckCount, 'It should be 0, because metadata is checked first and short circuits.');
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void metadataBypassedPopulatorIsSkippedOnBeforeInsert() {
        BypassMetadataPopulator bypassedHandler = new BypassMetadataPopulator();
        BypassBeforeInsertPopulator activeHandler = new BypassBeforeInsertPopulator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "bypassmetadatapopulator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0, because the metadata bypass is keyed by class name alone.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void metadataObjectBypassSkipsEveryHandler() {
        BypassAfterInsertHandler firstHandler = new BypassAfterInsertHandler();
        BypassAfterInsertHandler secondHandler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ firstHandler, secondHandler });

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = true));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(0, firstHandler.runCount, 'It should be 0.');
        Assert.areEqual(0, secondHandler.runCount, 'It should be 0.');
        Assert.isFalse(orchestrator.areHandlersRequested, 'It should be false.');
    }

    @IsTest
    static void metadataObjectBypassAppliesOnlyToTheNamedObject() {
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void metadataObjectRecordWithoutBypassLetsHandlersRun() {
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Contact', Bypass__c = false));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void metadataInnerClassQualifiedNameBypassesHandler() {
        BypassMetadataHandler handler = new BypassMetadataHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "triggerorchestratortest.bypassmetadatahandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void metadataInnerClassSimpleNameBypassesHandler() {
        BypassMetadataHandler handler = new BypassMetadataHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "bypassmetadatahandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void metadataQualifiedNameBypassesInnerClassByEitherSpelling() {
        BypassMetadataHandler handler = new BypassMetadataHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "triggerorchestratortest.bypassmetadatahandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because the loader stores a dotted name under both spellings.');
    }

    @IsTest
    static void metadataNameOfAnotherOuterClassBypassesTheSameSimpleName() {
        BypassMetadataHandler handler = new BypassMetadataHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "someotherouterclass.bypassmetadatahandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void zeroMetadataRecordsRunEveryHandler() {
        BypassMetadataHandler firstHandler = new BypassMetadataHandler();
        BypassAfterInsertHandler secondHandler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ firstHandler, secondHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, firstHandler.runCount, 'It should be 1.');
        Assert.areEqual(1, secondHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void metadataSettingsAreLoadedOnceAndBypassNothingWhenNoRecordExists() {
        BypassMetadataHandler handler = new BypassMetadataHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBeforeRun = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();
        Integer queriesAfterRun = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, queriesAfterRun - queriesBeforeRun, 'It should be 0, because the settings are loaded once and then read from the cache.');
        Assert.areEqual(1, handler.runCount, 'It should be 1, because no metadata record names the handler.');
    }

    @IsTest
    static void metadataReadConsumesNoSoqlWhenCacheIsPopulated() {
        BypassMetadataHandler bypassedHandler = new BypassMetadataHandler();
        BypassAfterInsertHandler activeHandler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "bypassmetadatahandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBeforeRun = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, activeHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Bypass') };
        orchestratorRunner.run();

        Integer queriesAfterRun = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, queriesAfterRun - queriesBeforeRun, 'It should be 0.');
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0, because the cached settings still bypass the named handler.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because the cached settings leave the other handlers running.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterInsert() {
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Qualified') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterInsert() {
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Skipped') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
        Assert.areEqual(1, handler.qualifyCount, 'It should be 1.');
    }

    @IsTest
    static void qualificationIsEvaluatedPerRecord() {
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Skipped'),
            new Contact(Id = secondContactId, LastName = 'Qualified'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Skipped')
        };
        BypassLastNameAfterInsertHandler handler = new BypassLastNameAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.processedRecordIds.size(), 'It should be 1.');
        Assert.areEqual(secondContactId, String.valueOf(handler.processedRecordIds[0]).left(15), 'It should be the second record.');
    }

    @IsTest
    static void qualificationPredicateRunsOncePerRecord() {
        List<SObject> records = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'One'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Two'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Three')
        };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(3, handler.qualifyCount, 'It should be 3.');
        Assert.areEqual(3, handler.runCount, 'It should be 3.');
    }

    @IsTest
    static void qualifiedRecordRunsPopulatorOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Qualified') };
        BypassBeforeInsertPopulator handler = new BypassBeforeInsertPopulator();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated.');
    }

    @IsTest
    static void unqualifiedRecordSkipsPopulatorOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Skipped') };
        BypassBeforeInsertPopulator handler = new BypassBeforeInsertPopulator();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
        Assert.isNull(((Contact) records[0]).Title, 'It should be null.');
    }

    @IsTest
    static void qualifiedRecordAttachesValidatorMessageOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Qualified') };
        BypassBeforeInsertValidator validator = new BypassBeforeInsertValidator();
        validator.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ validator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Before insert validation failed', records[0].getErrors()[0].getMessage(), 'It should be Before insert validation failed.');
    }

    @IsTest
    static void unqualifiedRecordSkipsValidatorOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Skipped') };
        BypassBeforeInsertValidator validator = new BypassBeforeInsertValidator();
        validator.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ validator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, records[0].getErrors().size(), 'It should be 0.');
        Assert.areEqual(0, validator.messageCount, 'It should be 0.');
    }

    @IsTest
    static void qualifiedRecordRunsPopulatorOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator handler = new BypassBeforeUpdatePopulator();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual('Populated', ((Contact) newRecords[0]).Title, 'It should be Populated.');
    }

    @IsTest
    static void unqualifiedRecordSkipsPopulatorOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator handler = new BypassBeforeUpdatePopulator();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
        Assert.isNull(((Contact) newRecords[0]).Title, 'It should be null.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler handler = new BypassAfterUpdateHandler();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler handler = new BypassAfterUpdateHandler();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
        Assert.areEqual(1, handler.qualifyCount, 'It should be 1.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnBeforeDelete() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassBeforeDeleteHandler handler = new BypassBeforeDeleteHandler();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnBeforeDelete() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassBeforeDeleteHandler handler = new BypassBeforeDeleteHandler();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterDelete() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassAfterDeleteHandler handler = new BypassAfterDeleteHandler();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterDelete() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        BypassAfterDeleteHandler handler = new BypassAfterDeleteHandler();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterUndelete() {
        BypassAfterUndeleteHandler handler = new BypassAfterUndeleteHandler();
        handler.isQualified = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterUndelete() {
        BypassAfterUndeleteHandler handler = new BypassAfterUndeleteHandler();
        handler.isQualified = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0.');
    }

    @IsTest
    static void qualificationReadsValuesWrittenByEarlierHandler() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Pipeline') };
        BypassTitlePopulator firstHandler = new BypassTitlePopulator();
        BypassTitleReaderPopulator secondHandler = new BypassTitleReaderPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ firstHandler, secondHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, firstHandler.runCount, 'It should be 1.');
        Assert.areEqual(1, secondHandler.runCount, 'It should be 1.');
        Assert.areEqual('Priority', ((Contact) records[0]).Department, 'It should be Priority.');
    }

    @IsTest
    static void predicateDoesNotSeeWritesOfHandlersBelowItInTheList() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Pipeline') };
        BypassTitleReaderPopulator firstHandler = new BypassTitleReaderPopulator();
        BypassTitlePopulator secondHandler = new BypassTitlePopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ firstHandler, secondHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, firstHandler.runCount, 'It should be 0.');
        Assert.areEqual(1, secondHandler.runCount, 'It should be 1.');
        Assert.isNull(((Contact) records[0]).Department, 'It should be null.');
    }

    @IsTest
    static void objectBypassInNestedInvocationDoesNotFinalizeLogger() {
        BypassFinalizeCountingLogger loggerStub = new BypassFinalizeCountingLogger();
        BypassNestedRunHandler handler = new BypassNestedRunHandler();

        TriggerOrchestrator.triggerLogger.logger = loggerStub;
        SOQL.mock('TriggerObject__mdt').thenReturn(new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true));
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Outer') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual(0, handler.finalizeCountAfterNestedRun, 'It should be 0.');
        Assert.areEqual(1, loggerStub.finalizeCount, 'It should be 1.');
    }

    @IsTest
    static void defaultRecursionDepthStopsBeforeUpdateHandlerAfterThreePasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionBeforeUpdateHandler handler = new RecursionBeforeUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, handler.runCount, 'It should be 3.');
    }

    @IsTest
    static void defaultRecursionDepthStopsAfterUpdateHandlerAfterThreePasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionAfterUpdateHandler handler = new RecursionAfterUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, handler.runCount, 'It should be 3.');
    }

    @IsTest
    static void handlerRecursionGuardStopsBeforeUpdateHandlerAfterTwoPasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedBeforeUpdateHandler handler = new RecursionGuardedBeforeUpdateHandler(2);

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.runCount, 'It should be 2.');
    }

    @IsTest
    static void handlerRecursionGuardStopsAfterUpdateHandlerAfterTwoPasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(2);

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.runCount, 'It should be 2.');
    }

    @IsTest
    static void noRecursionGuardAnywhereFallsBackToThreePassesOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionBeforeUpdateHandler firstHandler = new RecursionBeforeUpdateHandler();
        RecursionSecondBeforeUpdateHandler secondHandler = new RecursionSecondBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ firstHandler, secondHandler });

        // Test
        Test.startTest();
        for (Integer i = 0; i < 6; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, firstHandler.runCount, 'It should be 3, because neither the orchestrator nor the handler declares a RecursionGuard.');
        Assert.areEqual(3, secondHandler.runCount, 'It should be 3.');
    }

    @IsTest
    static void noRecursionGuardAnywhereFallsBackToThreePassesOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionAfterUpdateHandler firstHandler = new RecursionAfterUpdateHandler();
        RecursionSecondAfterUpdateHandler secondHandler = new RecursionSecondAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ firstHandler, secondHandler });

        // Test
        Test.startTest();
        for (Integer i = 0; i < 6; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, firstHandler.runCount, 'It should be 3, because neither the orchestrator nor the handler declares a RecursionGuard.');
        Assert.areEqual(3, secondHandler.runCount, 'It should be 3.');
    }

    @IsTest
    static void everyRecordCarriesItsOwnRecursionBudgetOnBeforeUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedBeforeUpdateHandler handler = new RecursionGuardedBeforeUpdateHandler(2);

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(4, handler.runCount, 'It should be 4.');
        Assert.areEqual(2, handler.runCountByRecordId.get(firstContactId), 'It should be 2.');
        Assert.areEqual(2, handler.runCountByRecordId.get(secondContactId), 'It should be 2.');
    }

    @IsTest
    static void everyRecordCarriesItsOwnRecursionBudgetOnAfterUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(2);

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(4, handler.runCount, 'It should be 4.');
        Assert.areEqual(2, handler.runCountByRecordId.get(firstContactId), 'It should be 2.');
        Assert.areEqual(2, handler.runCountByRecordId.get(secondContactId), 'It should be 2.');
    }

    @IsTest
    static void exhaustedRecordDoesNotConsumeAnotherRecordBudgetOnAfterUpdate() {
        Id exhaustedContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id lateContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Contact exhaustedContact = new Contact(Id = exhaustedContactId, LastName = 'Ada');
        Contact lateContact = new Contact(Id = lateContactId, LastName = 'Bob');

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(2);
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        for (Integer i = 0; i < 3; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = new List<Contact>{ exhaustedContact };
            orchestratorRunner.context.oldRecords = new List<Contact>{ exhaustedContact.clone(true) };
            orchestratorRunner.run();
        }

        // Test
        Test.startTest();
        for (Integer i = 0; i < 3; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner2.context.newRecords = new List<Contact>{ exhaustedContact, lateContact };
            orchestratorRunner2.context.oldRecords = new List<Contact>{ exhaustedContact.clone(true), lateContact.clone(true) };
            orchestratorRunner2.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.runCountByRecordId.get(exhaustedContactId), 'It should be 2.');
        Assert.areEqual(2, handler.runCountByRecordId.get(lateContactId), 'It should be 2.');
        Assert.areEqual(4, handler.runCount, 'It should be 4.');
    }

    @IsTest
    static void unqualifiedRecordDoesNotConsumeRecursionBudgetOnBeforeUpdate() {
        Id qualifiedContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id rejectedContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Contact qualifiedContact = new Contact(Id = qualifiedContactId, LastName = 'Qualified');
        Contact rejectedContact = new Contact(Id = rejectedContactId, LastName = 'Rejected');
        List<SObject> newRecords = new List<Contact>{ qualifiedContact, rejectedContact };
        List<SObject> oldRecords = new List<Contact>{ qualifiedContact.clone(true), rejectedContact.clone(true) };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionSelectiveBeforeUpdateHandler handler = new RecursionSelectiveBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }

        rejectedContact.LastName = 'Qualified';

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner2.context.newRecords = newRecords;
            orchestratorRunner2.context.oldRecords = oldRecords;
            orchestratorRunner2.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, handler.runCountByRecordId.get(qualifiedContactId), 'It should be 3.');
        Assert.areEqual(3, handler.runCountByRecordId.get(rejectedContactId), 'It should be 3.');
    }

    @IsTest
    static void unqualifiedRecordDoesNotConsumeRecursionBudgetOnAfterUpdate() {
        Id qualifiedContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id rejectedContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Contact qualifiedContact = new Contact(Id = qualifiedContactId, LastName = 'Qualified');
        Contact rejectedContact = new Contact(Id = rejectedContactId, LastName = 'Rejected');
        List<SObject> newRecords = new List<Contact>{ qualifiedContact, rejectedContact };
        List<SObject> oldRecords = new List<Contact>{ qualifiedContact.clone(true), rejectedContact.clone(true) };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionSelectiveAfterUpdateHandler handler = new RecursionSelectiveAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }

        rejectedContact.LastName = 'Qualified';

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner2.context.newRecords = newRecords;
            orchestratorRunner2.context.oldRecords = oldRecords;
            orchestratorRunner2.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, handler.runCountByRecordId.get(qualifiedContactId), 'It should be 3.');
        Assert.areEqual(3, handler.runCountByRecordId.get(rejectedContactId), 'It should be 3.');
    }

    @IsTest
    static void exhaustedRecordIsSkippedBeforeItsQualificationRunsOnAfterUpdate() {
        Contact qualifiedContact = new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Qualified');
        Contact rejectedContact = new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Rejected');
        List<SObject> newRecords = new List<Contact>{ qualifiedContact, rejectedContact };
        List<SObject> oldRecords = new List<Contact>{ qualifiedContact.clone(true), rejectedContact.clone(true) };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionSelectiveAfterUpdateHandler handler = new RecursionSelectiveAfterUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 4; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(7, handler.qualificationCount, 'It should be 7.');
    }

    @IsTest
    static void recursionBudgetIsIndependentPerHandlerOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedBeforeUpdateHandler guardedHandler = new RecursionGuardedBeforeUpdateHandler(1);
        RecursionBeforeUpdateHandler unguardedHandler = new RecursionBeforeUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ guardedHandler, unguardedHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(1, guardedHandler.runCount, 'It should be 1.');
        Assert.areEqual(3, unguardedHandler.runCount, 'It should be 3.');
    }

    @IsTest
    static void recursionBudgetIsIndependentPerHandlerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedAfterUpdateHandler guardedHandler = new RecursionGuardedAfterUpdateHandler(1);
        RecursionAfterUpdateHandler unguardedHandler = new RecursionAfterUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ guardedHandler, unguardedHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(1, guardedHandler.runCount, 'It should be 1.');
        Assert.areEqual(3, unguardedHandler.runCount, 'It should be 3.');
    }

    @IsTest
    static void beforeUpdateAndAfterUpdateBudgetsAreIndependentForOneHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionBothUpdatesHandler handler = new RecursionBothUpdatesHandler();
        RecursionBothUpdatesOrchestrator orchestrator = new RecursionBothUpdatesOrchestrator(handler);

        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner2.context.newRecords = newRecords;
            orchestratorRunner2.context.oldRecords = oldRecords;
            orchestratorRunner2.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, handler.beforeUpdateRunCount, 'It should be 3.');
        Assert.areEqual(3, handler.afterUpdateRunCount, 'It should be 3.');
    }

    @IsTest
    static void recordOverTheRecursionLimitIsSkippedSilentlyOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionLogger logger = new RecursionLogger();

        TriggerOrchestrator.triggerLogger.logger = logger;

        RecursionGuardedBeforeUpdateHandler handler = new RecursionGuardedBeforeUpdateHandler(1);
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            for (Integer i = 0; i < 3; i++) {
                TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
                orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
                orchestratorRunner.context.newRecords = newRecords;
                orchestratorRunner.context.oldRecords = oldRecords;
                orchestratorRunner.run();
            }
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual(0, logger.loggedErrors.size(), 'It should be 0.');
        Assert.areEqual(3, logger.finalizeCount, 'It should be 3.');
    }

    @IsTest
    static void recordOverTheRecursionLimitIsSkippedSilentlyOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionLogger logger = new RecursionLogger();

        TriggerOrchestrator.triggerLogger.logger = logger;

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(1);
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            for (Integer i = 0; i < 3; i++) {
                TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
                orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
                orchestratorRunner.context.newRecords = newRecords;
                orchestratorRunner.context.oldRecords = oldRecords;
                orchestratorRunner.run();
            }
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual(0, logger.loggedErrors.size(), 'It should be 0.');
        Assert.areEqual(3, logger.finalizeCount, 'It should be 3.');
    }

    @IsTest
    static void exhaustedRecursionBudgetSkipsTheFinalizerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionFinalizingAfterUpdateHandler handler = new RecursionFinalizingAfterUpdateHandler(1);

        // Test
        Test.startTest();
        for (Integer i = 0; i < 3; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because a handler whose records are all over the recursion budget qualifies nothing.');
    }

    @IsTest
    static void twoInstancesOfOneHandlerClassShareOneRecursionBudget() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionAfterUpdateHandler firstInstance = new RecursionAfterUpdateHandler();
        RecursionAfterUpdateHandler secondInstance = new RecursionAfterUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ firstInstance, secondInstance }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(3, firstInstance.runCount + secondInstance.runCount, 'It should be 3.');
        Assert.areEqual(2, firstInstance.runCount, 'It should be 2.');
        Assert.areEqual(1, secondInstance.runCount, 'It should be 1.');
    }

    @IsTest
    static void chunkingIsNotRecursionOnBeforeUpdate() {
        List<SObject> newRecords = new List<Contact>();
        List<SObject> oldRecords = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);

            newRecords.add(new Contact(Id = contactId, LastName = 'Ada'));
            oldRecords.add(new Contact(Id = contactId, LastName = 'Ada'));
        }

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionBeforeUpdateHandler handler = new RecursionBeforeUpdateHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(201, handler.runCount, 'It should be 201.');
        Assert.areEqual(201, handler.runCountByRecordId.size(), 'It should be 201.');
        Assert.areEqual(1, handler.runCountByRecordId.get(newRecords[0].Id), 'It should be 1.');
        Assert.areEqual(1, handler.runCountByRecordId.get(newRecords[200].Id), 'It should be 1, because chunking is not recursion.');
    }

    @IsTest
    static void chunkingDoesNotConsumeExtraRecursionBudgetOnAfterUpdate() {
        List<SObject> newRecords = new List<Contact>();
        List<SObject> oldRecords = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);

            newRecords.add(new Contact(Id = contactId, LastName = 'Ada'));
            oldRecords.add(new Contact(Id = contactId, LastName = 'Ada'));
        }

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionAfterUpdateHandler handler = new RecursionAfterUpdateHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 4; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(603, handler.runCount, 'It should be 603.');
        Assert.areEqual(3, handler.runCountByRecordId.get(newRecords[200].Id), 'It should be 3.');
    }

    @IsTest
    static void recursionGuardDoesNotApplyToAfterInsert() {
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionAfterInsertHandler handler = new RecursionAfterInsertHandler();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(5, handler.runCount, 'It should be 5, because recursion control covers the update contexts only.');
    }

    @IsTest
    static void recursionGuardDoesNotApplyToBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionBeforeUpdateValidator handler = new RecursionBeforeUpdateValidator();

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(5, handler.runCount, 'It should be 5.');
    }

    @IsTest
    static void handlerRecursionGuardIsInertOnABeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        RecursionGuardedBeforeUpdateValidator handler = new RecursionGuardedBeforeUpdateValidator(2);

        // Test
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(5, handler.runCount, 'It should be 5.');
    }

    @IsTest
    static void continueOnErrorHandlerFailureLetsTheRunFinish() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingMutedFailingHandler failingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Continue') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
    }

    @IsTest
    static void continueOnErrorHandlerStopsAtItsFailingRecord() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingMutedFailingHandler failingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(2, laterHandler.executionCount, 'It should be 2.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
    }

    @IsTest
    static void continueOnErrorLogsEveryFailingHandler() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedFailingHandler(), new ErrorsLoggingMutedBadCastHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Continue') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, logger.errors.size(), 'It should be 2.');
        Assert.areEqual('ErrorsLoggingMutedFailingHandler', logger.errors[0].getHandlerName(), 'It should be ErrorsLoggingMutedFailingHandler.');
        Assert.areEqual('ErrorsLoggingMutedBadCastHandler', logger.errors[1].getHandlerName(), 'It should be ErrorsLoggingMutedBadCastHandler.');
    }

    @IsTest
    static void handlerWithoutContinueOnErrorAbortsTheRun() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingFailingHandler failingHandler = new ErrorsLoggingFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void handlerWithoutContinueOnErrorPropagatesItsOwnExceptionType() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isTrue(orchestratorException instanceof ErrorsLoggingException, 'It should be the handler own exception type.');
    }

    @IsTest
    static void loggerReceivesContinueOnErrorFailureWithHandlerNameAndOperation() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedFailingHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Continue') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual('ErrorsLoggingMutedFailingHandler', logger.errors[0].getHandlerName(), 'It should be ErrorsLoggingMutedFailingHandler.');
        Assert.areEqual(System.TriggerOperation.AFTER_INSERT, logger.errors[0].getOperation(), 'It should be AFTER_INSERT.');
        Assert.areEqual('Handler failed on purpose.', logger.errors[0].getException().getMessage(), 'It should be the handler message.');
    }

    @IsTest
    static void loggerReceivesUncaughtErrorBeforeItPropagates() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual(orchestratorException.getMessage(), logger.errors[0].getException().getMessage(), 'It should be the exception that propagated.');
        Assert.areEqual(0, logger.finalizeCountWhenLogged[0], 'It should be 0.');
    }

    @IsTest
    static void loggerErrorCarriesHandlerNameSObjectTypeOperationAndRecordIds() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ new ErrorsLoggingMutedFailingAfterUpdateHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual('ErrorsLoggingMutedFailingAfterUpdateHandler', logger.errors[0].getHandlerName(), 'It should be ErrorsLoggingMutedFailingAfterUpdateHandler.');
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'It should be Contact.');
        Assert.areEqual(System.TriggerOperation.AFTER_UPDATE, logger.errors[0].getOperation(), 'It should be AFTER_UPDATE.');
        Assert.areEqual(new Set<Id>{ contactId }, logger.errors[0].getRecordIds(), 'It should be the ids of the whole chunk.');
        Assert.isTrue(logger.errors[0].getException() instanceof ErrorsLoggingException, 'It should be the handler exception.');
    }

    @IsTest
    static void loggerErrorCarriesRecordIdsFromTheOldMapInAfterDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ new ErrorsLoggingMutedFailingAfterDeleteHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual(new Set<Id>{ contactId }, logger.errors[0].getRecordIds(), 'It should be the ids of the deleted records.');
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'It should be Contact.');
        Assert.areEqual(System.TriggerOperation.AFTER_DELETE, logger.errors[0].getOperation(), 'It should be AFTER_DELETE.');
    }

    @IsTest
    static void loggerErrorCarriesNoRecordIdsInBeforeInsert() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingFailingPopulator() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Insert') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.isTrue(logger.errors[0].getRecordIds().isEmpty(), 'It should be empty.');
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'It should be Contact.');
    }

    @IsTest
    static void loggerReceivesErrorFromQualificationPredicate() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingQualifierHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Qualify') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual('ErrorsLoggingFailingQualifierHandler', logger.errors[0].getHandlerName(), 'It should be ErrorsLoggingFailingQualifierHandler.');
        Assert.areEqual('Qualification failed on purpose.', logger.errors[0].getException().getMessage(), 'It should be the predicate message.');
    }

    @IsTest
    static void loggerReceivesErrorFromFinalizer() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingFinalizerHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Finalize') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the finalizer runs inside the handler turn.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the logger covers the handler finalizer too.');
        Assert.areEqual(
            'ErrorsLoggingFailingFinalizerHandler',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingFailingFinalizerHandler, because the error names the handler whose finalizer failed.'
        );
        Assert.areEqual('Finalizer failed on purpose.', logger.errors[0].getException().getMessage(), 'It should be the finalizer message.');
    }

    @IsTest
    static void loggerReceivesNothingWhenEveryHandlerSucceeds() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler handler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Clean') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.executionCount, 'It should be 1, because the handler qualifies the only record in the chunk.');
        Assert.areEqual(0, logger.errors.size(), 'It should be 0.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1.');
    }

    @IsTest
    static void loggerFinalizeRunsOnceOnAFailedInvocation() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because finalize runs whether the invocation succeeded or failed.');
    }

    @IsTest
    static void loggerFinalizeRunsOncePerInvocation() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Chunk') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingCountingHandler(), new ErrorsLoggingCountingHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingCountingHandler(), new ErrorsLoggingCountingHandler() })
        );
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.newRecords = records;
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, logger.finalizeCount, 'It should be 2.');
    }

    @IsTest
    static void loggerFinalizeIsSkippedForANestedInvocation() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler nestedHandler = new ErrorsLoggingCountingHandler();
        ErrorsLoggingNestedRunHandler outerHandler = new ErrorsLoggingNestedRunHandler(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ nestedHandler }),
            logger
        );

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ outerHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, nestedHandler.executionCount, 'It should be 1, because a nested run dispatches its own handler list over the same chunk.');
        Assert.areEqual(0, outerHandler.finalizeCountAfterNestedRun, 'It should be 0.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because a nested invocation does not call finalize, only the outermost one does.');
    }

    @IsTest
    static void loggerFinalizeIsSkippedForANestedInvocationThatDispatchesNothing() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingNestedRunHandler outerHandler = new ErrorsLoggingNestedRunHandler(new ErrorsLoggingNoInterfaceOrchestrator(), logger);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ outerHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, outerHandler.finalizeCountAfterNestedRun, 'It should be 0.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1.');
    }

    @IsTest
    static void frameworkExceptionIsRethrownForAContinueOnErrorHandler() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingPopulator laterHandler = new ErrorsLoggingCountingPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingMutedDmlPopulator(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'ErrorsLoggingMutedDmlPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler.'
        );
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void loggerReceivesFrameworkGuardViolationBeforeItPropagates() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingMutedDmlPopulator() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual('ErrorsLoggingMutedDmlPopulator', logger.errors[0].getHandlerName(), 'It should be ErrorsLoggingMutedDmlPopulator.');
        Assert.areEqual(System.TriggerOperation.BEFORE_INSERT, logger.errors[0].getOperation(), 'It should be BEFORE_INSERT.');
        Assert.areEqual(
            'ErrorsLoggingMutedDmlPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            logger.errors[0].getException().getMessage(),
            'It should be the guard message.'
        );
        Assert.areEqual(0, logger.finalizeCountWhenLogged[0], 'It should be 0.');
    }

    @IsTest
    static void frameworkExceptionFromANestedInvocationIsRethrownForAContinueOnErrorHandler() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingPopulator laterHandler = new ErrorsLoggingCountingPopulator();
        ErrorsLoggingMutedNestedRunPopulator outerHandler = new ErrorsLoggingMutedNestedRunPopulator(
            new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingMutedRecordApiPopulator() })
        );

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ outerHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.',
            orchestratorException.getMessage(),
            'It should be the handler exception message, because the nested invocation rethrows it unwrapped.'
        );
        Assert.areEqual(2, logger.errors.size(), 'It should be 2.');
        Assert.areEqual('ErrorsLoggingMutedRecordApiPopulator', logger.errors[0].getHandlerName(), 'It should be ErrorsLoggingMutedRecordApiPopulator.');
        Assert.areEqual('ErrorsLoggingMutedNestedRunPopulator', logger.errors[1].getHandlerName(), 'It should be ErrorsLoggingMutedNestedRunPopulator.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void triggerHandlerExceptionIsRethrownForAContinueOnErrorHandler() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerHandler.TriggerHandlerException recordApiException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedRecordApiHandler(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Record API') };
            orchestratorRunner.run();
        } catch (TriggerHandler.TriggerHandlerException e) {
            recordApiException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(recordApiException, 'It should be thrown.');
        Assert.areEqual('Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.', recordApiException.getMessage(), 'It should be the record API message.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void loggerReceivesTriggerHandlerExceptionBeforeItPropagates() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedRecordApiHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Record API') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.isInstanceOfType(logger.errors[0].getException(), TriggerHandler.TriggerHandlerException.class, 'It should be TriggerHandler.TriggerHandlerException.');
        Assert.areEqual(0, logger.finalizeCountWhenLogged[0], 'It should be 0.');
    }

    @IsTest
    static void platformBadCastPropagatesUnchanged() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingBadCastHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Platform') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('System.TypeException', orchestratorException.getTypeName(), 'It should be System.TypeException.');
        Assert.areEqual('Invalid conversion from runtime type String to Integer', orchestratorException.getMessage(), 'It should be the original Salesforce message.');
    }

    @IsTest
    static void platformNullDereferencePropagatesUnchanged() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingNullDereferenceHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Platform') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.areEqual('System.NullPointerException', orchestratorException.getTypeName(), 'It should be System.NullPointerException.');
        Assert.areEqual('Attempt to de-reference a null object', orchestratorException.getMessage(), 'It should be the original Salesforce message.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
    }

    @IsTest
    static void platformExceptionIsSwallowedByContinueOnError() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedBadCastHandler(), laterHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Platform') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1.');
        Assert.areEqual('System.TypeException', logger.errors[0].getException().getTypeName(), 'It should be System.TypeException.');
    }

    @IsTest
    static void emptyHandlerListRunsNothing() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Empty') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(0, logger.errors.size(), 'It should be 0.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because finalize runs once per top level invocation even when no handler ran.');
    }

    @IsTest
    static void withoutALoggerAFailureStillPropagates() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = null;

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'No logger') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
    }

    @IsTest
    static void withoutALoggerAContinueOnErrorFailureIsStillSwallowed() {
        ErrorsLoggingMutedFailingHandler failingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = null;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'No logger') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
    }

    @IsTest
    static void beforeInsertPopulatorPerformingDmlThrows() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertPopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the populator.'
        );
        Assert.isTrue(orchestratorException.getTypeName().endsWith('TriggerOrchestratorException'), 'It should be a TriggerOrchestratorException.');
    }

    @IsTest
    static void beforeInsertValidatorPerformingDmlThrows() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertValidator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertValidator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the validator.'
        );
    }

    @IsTest
    static void beforeInsertFinalizerPerformingDmlThrows() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardInsertFinalizer handler = new DmlGuardInsertFinalizer();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isTrue(handler.isFinalized, 'It should be true, because a handler that qualified at least one record always gets its finalizer.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the finalizer runs inside the same measured span as the action method.');
        Assert.areEqual(
            'DmlGuardInsertFinalizer performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler.'
        );
    }

    @IsTest
    static void beforeInsertQualificationPerformingDmlThrows() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardInsertQualifier handler = new DmlGuardInsertQualifier();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.populateCount, 'It should be 0.');
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertQualifier performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler.'
        );
    }

    @IsTest
    static void beforeInsertDmlBelowTheHandlerThrows() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertServicePopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertServicePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler and not the service class.'
        );
    }

    @IsTest
    static void beforeInsertWithoutDmlDoesNotThrow() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardInsertSilentPopulator handler = new DmlGuardInsertSilentPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, handler.populateCount, 'It should be 1.');
        Assert.areEqual('Guard', records[0].get(Contact.Department), 'It should be Guard.');
    }

    @IsTest
    static void beforeInsertGuardNamesTheHandlerThatPerformedDml() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardInsertSilentPopulator cleanHandler = new DmlGuardInsertSilentPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new DmlGuardBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ cleanHandler, new DmlGuardInsertPopulator() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(1, cleanHandler.populateCount, 'It should be 1.');
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the second handler.'
        );
    }

    @IsTest
    static void beforeInsertContinueOnErrorDoesNotSuppressGuard() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardInsertSilentPopulator laterHandler = new DmlGuardInsertSilentPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new DmlGuardBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new DmlGuardInsertContinuePopulator(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertContinuePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message.'
        );
        Assert.areEqual(0, laterHandler.populateCount, 'It should be 0.');
    }

    @IsTest
    static void beforeInsertGuardSurvivesHandlerException() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertContinueThrowingPopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardInsertContinueThrowingPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message and not the handler own message.'
        );
    }

    @IsTest
    static void beforeInsertHandlerExceptionWithoutDmlStaysSilent() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardInsertContinueFailingPopulator handler = new DmlGuardInsertContinueFailingPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isTrue(handler.hasThrown, 'It should be true.');
        Assert.isNull(orchestratorException, 'It should be null.');
    }

    @IsTest
    static void beforeUpdatePopulatorPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdatePopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardUpdatePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the populator.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdateValidator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardUpdateValidator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the validator.'
        );
    }

    @IsTest
    static void beforeUpdateFinalizerPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardUpdateFinalizer handler = new DmlGuardUpdateFinalizer();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isTrue(handler.isFinalized, 'It should be true, because a handler that qualified at least one record always gets its finalizer.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the finalizer runs inside the same measured span as the action method.');
        Assert.areEqual(
            'DmlGuardUpdateFinalizer performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler.'
        );
    }

    @IsTest
    static void beforeUpdateQualificationPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardUpdateQualifier handler = new DmlGuardUpdateQualifier();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.populateCount, 'It should be 0.');
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardUpdateQualifier performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler.'
        );
    }

    @IsTest
    static void beforeUpdateUpdateStatementThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account existingAccount = new Account(Name = 'Guard');
        insert existingAccount;
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdateStatementPopulator(existingAccount)));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardUpdateStatementPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the populator.'
        );
    }

    @IsTest
    static void beforeUpdateWithoutDmlDoesNotThrow() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardUpdateSilentPopulator handler = new DmlGuardUpdateSilentPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, handler.populateCount, 'It should be 1.');
        Assert.areEqual('Guard', newRecords[0].get(Contact.Department), 'It should be Guard.');
    }

    @IsTest
    static void beforeUpdateContinueOnErrorDoesNotSuppressGuard() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardUpdateSilentPopulator laterHandler = new DmlGuardUpdateSilentPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new DmlGuardBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ new DmlGuardUpdateContinuePopulator(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardUpdateContinuePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message.'
        );
        Assert.areEqual(0, laterHandler.populateCount, 'It should be 0.');
    }

    @IsTest
    static void beforeUpdateGuardSurvivesHandlerException() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdateContinueThrowingPopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual(
            'DmlGuardUpdateContinueThrowingPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message and not the handler own message.'
        );
    }

    @IsTest
    static void beforeUpdateHandlerExceptionWithoutDmlStaysSilent() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardUpdateContinueFailingPopulator handler = new DmlGuardUpdateContinueFailingPopulator();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isTrue(handler.hasThrown, 'It should be true.');
        Assert.isNull(orchestratorException, 'It should be null.');
    }

    @IsTest
    static void afterInsertHandlerPerformingDmlIsAllowed() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterInsertOrchestrator(new DmlGuardAfterInsertHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1.');
    }

    @IsTest
    static void afterInsertFinalizerPerformingDmlIsAllowed() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DmlGuardAfterInsertFinalizer handler = new DmlGuardAfterInsertFinalizer();
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Guard') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.handledCount, 'It should be 1.');
        Assert.isTrue(handler.isFinalized, 'It should be true, because a handler that qualified at least one record always gets its finalizer.');
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1.');
    }

    @IsTest
    static void afterUpdateHandlerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterUpdateOrchestrator(new DmlGuardAfterUpdateHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1.');
    }

    @IsTest
    static void afterDeleteHandlerPerformingDmlIsAllowed() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterDeleteOrchestrator(new DmlGuardAfterDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1.');
    }

    @IsTest
    static void afterUndeleteHandlerPerformingDmlIsAllowed() {
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterUndeleteOrchestrator(new DmlGuardAfterUndeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1.');
    }

    @IsTest
    static void beforeDeleteHandlerPerformingDmlIsAllowed() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted') };
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeDeleteOrchestrator(new DmlGuardBeforeDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeInsert() {
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeInsertValidator() {
        ShapesBeforeInsertValidator handler = new ShapesBeforeInsertValidator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the Finalizer interface fires once per handler in the validator role too.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterInsert() {
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeUpdate() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id firstId = fakeIds.next();
        Id secondId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'New First'), new Contact(Id = secondId, LastName = 'New Second') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'Old First'), new Contact(Id = secondId, LastName = 'Old Second') };
        ShapesBeforeUpdatePopulator handler = new ShapesBeforeUpdatePopulator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeUpdateValidator() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id firstId = fakeIds.next();
        Id secondId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'New First'), new Contact(Id = secondId, LastName = 'New Second') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'Old First'), new Contact(Id = secondId, LastName = 'Old Second') };
        ShapesBeforeUpdateValidator handler = new ShapesBeforeUpdateValidator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the Finalizer interface fires once per handler in the validator role too.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterUpdate() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id firstId = fakeIds.next();
        Id secondId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'New First'), new Contact(Id = secondId, LastName = 'New Second') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'Old First'), new Contact(Id = secondId, LastName = 'Old Second') };
        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeDelete() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        ShapesBeforeDeleteHandler handler = new ShapesBeforeDeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'First'), new Contact(Id = fakeIds.next(), LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterDelete() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'First'), new Contact(Id = fakeIds.next(), LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterUndelete() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'First'), new Contact(Id = fakeIds.next(), LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeInsertWithoutQualifiedRecords() {
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeInsertValidatorWithoutQualifiedRecords() {
        ShapesBeforeInsertValidator handler = new ShapesBeforeInsertValidator();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterInsertWithoutQualifiedRecords() {
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeUpdateWithoutQualifiedRecords() {
        Id recordId = new ShapesFakeIds().next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };
        ShapesBeforeUpdatePopulator handler = new ShapesBeforeUpdatePopulator();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeUpdateValidatorWithoutQualifiedRecords() {
        Id recordId = new ShapesFakeIds().next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };
        ShapesBeforeUpdateValidator handler = new ShapesBeforeUpdateValidator();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterUpdateWithoutQualifiedRecords() {
        Id recordId = new ShapesFakeIds().next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };
        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeDeleteWithoutQualifiedRecords() {
        ShapesBeforeDeleteHandler handler = new ShapesBeforeDeleteHandler();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterDeleteWithoutQualifiedRecords() {
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterUndeleteWithoutQualifiedRecords() {
        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();
        handler.qualifies = false;

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerRunsAfterTheLastQualifiedRecord() {
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'record', 'record', 'finalize' }, handler.events, 'It should be record, record, finalize.');
    }

    @IsTest
    static void finalizerRunsBeforeTheNextHandlerStarts() {
        ShapesSharedState state = new ShapesSharedState();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ShapesAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ShapesAfterInsertHandler('First', state), new ShapesAfterInsertHandler('Second', state) })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Only') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new List<String>{ 'First record', 'First finalize', 'Second record', 'Second finalize' },
            state.events,
            'It should be the whole first handler before any of the second.'
        );
    }

    @IsTest
    static void finalizerFiresOnceWhenOnlyOneRecordQualifies() {
        List<SObject> records = new List<Contact>{
            new Contact(LastName = 'First', LeadSource = 'Web'),
            new Contact(LastName = 'Second', LeadSource = 'Phone'),
            new Contact(LastName = 'Third', LeadSource = 'Phone')
        };
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();
        handler.qualifyingLeadSource = 'Web';

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.actionCount, 'It should be 1.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because a single qualified record is enough to fire the finalizer exactly once.');
    }

    @IsTest
    static void finalizerDoesNotFireWhenEveryRecordIsSkippedByTheRecursionGuard() {
        Id recordId = new ShapesFakeIds().next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };

        ShapesGuardedBeforeUpdatePopulator firstPass = new ShapesGuardedBeforeUpdatePopulator(1);
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(firstPass));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        ShapesGuardedBeforeUpdatePopulator secondPass = new ShapesGuardedBeforeUpdatePopulator(1);

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(secondPass));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner2.context.newRecords = newRecords;
        orchestratorRunner2.context.oldRecords = oldRecords;
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, secondPass.actionCount, 'It should be 0.');
        Assert.areEqual(0, secondPass.finalizeCount, 'It should be 0, because records the recursion guard skips never qualify.');
        Assert.areEqual(1, firstPass.finalizeCount, 'It should be 1, because the first pass was still inside the budget.');
    }

    @IsTest
    static void finalizerFiresAgainOnASecondInvocationOfTheSameHandlerInstance() {
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'First') };
        orchestratorRunner.run();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.newRecords = new List<Contact>{ new Contact(LastName = 'Second') };
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<String>{ 'record', 'finalize', 'record', 'finalize' }, handler.events, 'It should be record, finalize, record, finalize.');
    }

    @IsTest
    static void finalizerDoesNotFireWhenTheRecordListIsEmpty() {
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>();
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because the finalizer fires only after at least one record qualified.');
    }

    @IsTest
    static void bulkInvocationProcessesTwoHundredAndOneRecordsExactlyOnce() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            contacts.add(new Contact(Id = fakeIds.next(), LastName = 'Bulk ' + i));
        }

        List<SObject> records = contacts;
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(201, handler.actionCount, 'It should be 201, because every record of the invocation reaches the handler, with no internal 200-record cap.');
        Assert.areEqual(201, new Set<Id>(handler.recordIds).size(), 'It should be 201, because each record is processed exactly once per invocation, never twice.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires once per invocation regardless of how many records it holds.');
    }

    @IsTest
    static void bulkInvocationQualifiesEveryRecordOnce() {
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            contacts.add(new Contact(LastName = 'Bulk ' + i, LeadSource = Math.mod(i, 2) == 0 ? 'Web' : 'Phone'));
        }

        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();
        handler.qualifyingLeadSource = 'Web';

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = contacts;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(201, handler.qualifyCount, 'It should be 201.');
        Assert.areEqual(101, handler.actionCount, 'It should be 101.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because a partially qualified chunk still finalizes exactly once.');
    }

    @IsTest
    static void bulkInvocationPopulatesEveryRecordOnBeforeInsert() {
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            contacts.add(new Contact(LastName = 'Bulk ' + i));
        }

        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = contacts;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(201, handler.actionCount, 'It should be 201.');
        Assert.areEqual('Populated', contacts[0].Description, 'It should be Populated.');
        Assert.areEqual('Populated', contacts[200].Description, 'It should be Populated.');
    }

    @IsTest
    static void bulkUpdateProcessesTwoHundredAndOneRecordsExactlyOnce() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<Contact> newContacts = new List<Contact>();
        List<Contact> oldContacts = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            Id recordId = fakeIds.next();

            newContacts.add(new Contact(Id = recordId, LastName = 'New ' + i));
            oldContacts.add(new Contact(Id = recordId, LastName = 'Old ' + i));
        }

        List<SObject> newRecords = newContacts;
        List<SObject> oldRecords = oldContacts;
        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(201, handler.actionCount, 'It should be 201, because the recursion budget is keyed per record, so chunk size never exhausts it.');
        Assert.areEqual(201, new Set<Id>(handler.recordIds).size(), 'It should be 201, because each record of the invocation is processed exactly once.');
    }

    @IsTest
    static void staticStateAcrossChunksDoesNotSkipRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<Contact> firstChunk = new List<Contact>();

        for (Integer i = 0; i < 200; i++) {
            firstChunk.add(new Contact(Id = fakeIds.next(), LastName = 'Chunk one ' + i));
        }

        Id lastRecordId = fakeIds.next();

        ShapesSharedState state = new ShapesSharedState();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(new ShapesAfterInsertHandler('Chunk', state)));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = firstChunk;
        orchestratorRunner.run();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(new ShapesAfterInsertHandler('Chunk', state)));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.newRecords = new List<Contact>{ new Contact(Id = lastRecordId, LastName = 'Chunk two') };
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(201, state.processedCount, 'It should be 201.');
        Assert.isTrue(state.processedIds.contains(lastRecordId), 'It should be true, because the record past the 200 boundary is processed by the second chunk.');
        Assert.areEqual(2, state.finalizeCount, 'It should be 2.');
    }

    @IsTest
    static void partialSaveRetryRunsHandlersAgainForSurvivors() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id survivorId = fakeIds.next();
        Id failingId = fakeIds.next();

        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Survivor'), new Contact(Id = failingId, LastName = 'Failing') };
        orchestratorRunner.run();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.newRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Survivor') };
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<Id>{ survivorId, failingId, survivorId }, handler.recordIds, 'It should be survivor, failing, survivor.');
        Assert.areEqual(2, handler.finalizeCount, 'It should be 2, because every attempt is its own invocation and fires its own finalizer.');
    }

    @IsTest
    static void partialSaveRetryOnUpdateIsNotSkippedByTheRecursionGuard() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id survivorId = fakeIds.next();
        Id failingId = fakeIds.next();

        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'New Survivor'), new Contact(Id = failingId, LastName = 'New Failing') };
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Old Survivor'), new Contact(Id = failingId, LastName = 'Old Failing') };
        orchestratorRunner.run();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner2.context.newRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'New Survivor') };
        orchestratorRunner2.context.oldRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Old Survivor') };
        orchestratorRunner2.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<Id>{ survivorId, failingId, survivorId }, handler.recordIds, 'It should be survivor, failing, survivor.');
        Assert.areEqual(2, handler.finalizeCount, 'It should be 2, because every attempt is its own invocation and fires its own finalizer.');
    }

    @IsTest
    static void beforeDeleteRecordShapeHasNoNewRecord() {
        ShapesBeforeDeleteHandler handler = new ShapesBeforeDeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted', LeadSource = 'Web') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(handler.newRecords[0], 'It should be null.');
        Assert.areEqual('Deleted', handler.oldRecords[0].get(Contact.LastName), 'It should be Deleted.');
    }

    @IsTest
    static void afterDeleteRecordShapeHasNoNewRecord() {
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted', LeadSource = 'Web') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(handler.newRecords[0], 'It should be null.');
        Assert.areEqual('Deleted', handler.oldRecords[0].get(Contact.LastName), 'It should be Deleted.');
    }

    @IsTest
    static void deleteRecordIdComesFromTheOldRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id firstId = fakeIds.next();
        Id secondId = fakeIds.next();

        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'First'), new Contact(Id = secondId, LastName = 'Second') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(new List<Id>{ firstId, secondId }, handler.recordIds, 'It should be the deleted record ids.');
    }

    @IsTest
    static void deleteRecordPredicatesReadTheOldRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{
            new Contact(Id = fakeIds.next(), LastName = 'Web', LeadSource = 'Web'),
            new Contact(Id = fakeIds.next(), LastName = 'Phone', LeadSource = 'Phone')
        };
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();
        handler.qualifyingLeadSource = 'Web';

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.actionCount, 'It should be 1.');
        Assert.areEqual('Web', handler.oldRecords[0].get(Contact.LeadSource), 'It should be Web.');
    }

    @IsTest
    static void afterDeleteHandlerReadsTheDeletedFieldValues() {
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted', Description = 'Gone') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Gone', handler.oldRecords[0].get(Contact.Description), 'It should be Gone.');
    }

    @IsTest
    static void putOnAfterDeleteRecordThrowsNullPointerException() {
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(new ShapesPuttingAfterDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('System.NullPointerException', orchestratorException.getTypeName(), 'It should be System.NullPointerException.');
    }

    @IsTest
    static void putOnBeforeDeleteRecordThrowsNullPointerException() {
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(new ShapesPuttingBeforeDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.oldRecords = new List<Contact>{ new Contact(Id = new ShapesFakeIds().next(), LastName = 'Deleted') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('System.NullPointerException', orchestratorException.getTypeName(), 'It should be System.NullPointerException.');
    }

    @IsTest
    static void beforeInsertRecordShapeHasNoOldRecord() {
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Inserted') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Inserted', handler.newRecords[0].get(Contact.LastName), 'It should be Inserted.');
        Assert.isNull(handler.oldRecords[0], 'It should be null.');
    }

    @IsTest
    static void beforeInsertRecordHasNoIdYet() {
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Inserted') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.isNull(handler.recordIds[0], 'It should be null.');
    }

    @IsTest
    static void afterInsertRecordShapeHasNoOldRecord() {
        Id recordId = new ShapesFakeIds().next();

        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Inserted') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Inserted', handler.newRecords[0].get(Contact.LastName), 'It should be Inserted.');
        Assert.isNull(handler.oldRecords[0], 'It should be null.');
        Assert.areEqual(recordId, handler.recordIds[0], 'It should be the saved id.');
    }

    @IsTest
    static void updateRecordShapePairsNewAndOldByIndex() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id firstId = fakeIds.next();
        Id secondId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'New First'), new Contact(Id = secondId, LastName = 'New Second') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstId, LastName = 'Old First'), new Contact(Id = secondId, LastName = 'Old Second') };
        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('New First', handler.newRecords[0].get(Contact.LastName), 'It should be New First.');
        Assert.areEqual('Old First', handler.oldRecords[0].get(Contact.LastName), 'It should be Old First.');
        Assert.areEqual('New Second', handler.newRecords[1].get(Contact.LastName), 'It should be New Second.');
        Assert.areEqual('Old Second', handler.oldRecords[1].get(Contact.LastName), 'It should be Old Second.');
    }

    @IsTest
    static void afterUndeleteRecordShapeHasEmptyOldSide() {
        Id recordId = new ShapesFakeIds().next();

        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Restored', handler.newRecords[0].get(Contact.LastName), 'It should be Restored.');
        Assert.isNull(handler.oldRecords[0], 'It should be null.');
        Assert.areEqual(recordId, handler.recordIds[0], 'It should be the restored id.');
    }

    @IsTest
    static void afterUndeleteHandlerReadsTheRestoredRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{
            new Contact(Id = fakeIds.next(), LastName = 'Web', LeadSource = 'Web'),
            new Contact(Id = fakeIds.next(), LastName = 'Phone', LeadSource = 'Phone')
        };
        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();
        handler.qualifyingLeadSource = 'Web';

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.actionCount, 'It should be 1.');
        Assert.areEqual('Web', handler.newRecords[0].get(Contact.LeadSource), 'It should be Web.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeInsertPopulator() {
        GapMetadataBypassMutedInsertPopulator mutedPopulator = new GapMetadataBypassMutedInsertPopulator();
        GapMetadataBypassLiveInsertPopulator livePopulator = new GapMetadataBypassLiveInsertPopulator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedinsertpopulator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ mutedPopulator, livePopulator })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Gap') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedPopulator.qualifyCount, 'It should be 0, because the before insert populator adapter reads the metadata bypass before anything else.');
        Assert.areEqual(0, mutedPopulator.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its populate method.');
        Assert.areEqual(1, livePopulator.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeInsertValidator() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Gap') };
        GapMetadataBypassMutedInsertValidator mutedValidator = new GapMetadataBypassMutedInsertValidator();
        GapMetadataBypassLiveInsertValidator liveValidator = new GapMetadataBypassLiveInsertValidator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedinsertvalidator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ mutedValidator, liveValidator })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = records;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedValidator.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, mutedValidator.messageCount, 'It should be 0.');
        Assert.areEqual(1, liveValidator.messageCount, 'It should be 1, because the validator that metadata does not name keeps validating every qualified record.');
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Live before insert validation', records[0].getErrors()[0].getMessage(), 'It should be Live before insert validation.');
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterInsertHandler() {
        GapMetadataBypassMutedAfterInsertHandler mutedHandler = new GapMetadataBypassMutedAfterInsertHandler();
        GapMetadataBypassLiveAfterInsertHandler liveHandler = new GapMetadataBypassLiveAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedafterinserthandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapMetadataBypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ mutedHandler, liveHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Gap') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedHandler.qualifyCount, 'It should be 0, because the after insert adapter reads the metadata bypass before anything else.');
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeUpdatePopulator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassMutedUpdatePopulator mutedPopulator = new GapMetadataBypassMutedUpdatePopulator();
        GapMetadataBypassLiveUpdatePopulator livePopulator = new GapMetadataBypassLiveUpdatePopulator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedupdatepopulator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ mutedPopulator, livePopulator })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedPopulator.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, mutedPopulator.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its populate method.');
        Assert.areEqual(1, livePopulator.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassMutedUpdateValidator mutedValidator = new GapMetadataBypassMutedUpdateValidator();
        GapMetadataBypassLiveUpdateValidator liveValidator = new GapMetadataBypassLiveUpdateValidator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedupdatevalidator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ mutedValidator, liveValidator })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedValidator.qualifyCount, 'It should be 0, because the before update validator adapter checks the metadata bypass first.');
        Assert.areEqual(0, mutedValidator.messageCount, 'It should be 0.');
        Assert.areEqual(1, liveValidator.messageCount, 'It should be 1, because the validator that metadata does not name keeps validating every qualified record.');
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
        Assert.areEqual('Live before update validation', newRecords[0].getErrors()[0].getMessage(), 'It should be Live before update validation.');
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterUpdateHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassMutedAfterUpdateHandler mutedHandler = new GapMetadataBypassMutedAfterUpdateHandler();
        GapMetadataBypassLiveAfterUpdateHandler liveHandler = new GapMetadataBypassLiveAfterUpdateHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedafterupdatehandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapMetadataBypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ mutedHandler, liveHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedHandler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeDeleteHandler() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Gone') };
        GapMetadataBypassMutedBeforeDeleteHandler mutedHandler = new GapMetadataBypassMutedBeforeDeleteHandler();
        GapMetadataBypassLiveBeforeDeleteHandler liveHandler = new GapMetadataBypassLiveBeforeDeleteHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedbeforedeletehandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ mutedHandler, liveHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedHandler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterDeleteHandler() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Gone') };
        GapMetadataBypassMutedAfterDeleteHandler mutedHandler = new GapMetadataBypassMutedAfterDeleteHandler();
        GapMetadataBypassLiveAfterDeleteHandler liveHandler = new GapMetadataBypassLiveAfterDeleteHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedafterdeletehandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapMetadataBypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ mutedHandler, liveHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedHandler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterUndeleteHandler() {
        GapMetadataBypassMutedAfterUndeleteHandler mutedHandler = new GapMetadataBypassMutedAfterUndeleteHandler();
        GapMetadataBypassLiveAfterUndeleteHandler liveHandler = new GapMetadataBypassLiveAfterUndeleteHandler();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "gapmetadatabypassmutedafterundeletehandler", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ mutedHandler, liveHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Restored') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, mutedHandler.qualifyCount, 'It should be 0.');
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1.');
    }

    @IsTest
    static void gapMetadataBypassDottedEntryTailSkipsBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassDottedNameValidator dottedValidator = new GapMetadataBypassDottedNameValidator();
        GapMetadataBypassLiveUpdateValidator liveValidator = new GapMetadataBypassLiveUpdateValidator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "triggerorchestratortest.gapmetadatabypassdottednamevalidator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ dottedValidator, liveValidator })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, dottedValidator.messageCount, 'It should be 0.');
        Assert.areEqual(1, liveValidator.messageCount, 'It should be 1, because the two spellings of one metadata entry still name a single class.');
    }

    @IsTest
    static void gapMetadataBypassDottedEntryStopsBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassDottedNameValidator dottedValidator = new GapMetadataBypassDottedNameValidator();

        SOQL.mock('TriggerObject__mdt')
            .thenReturn(
                (TriggerObject__mdt) JSON.deserialize(
                    '{"ObjectAPIName__c": "Contact", "TriggerHandlers__r": {"totalSize": 1, "done": true, "records": [{"attributes": {"type": "TriggerHandler__mdt"}, "ApexClassName__c": "triggerorchestratortest.gapmetadatabypassdottednamevalidator", "Bypass__c": true}]}}',
                    TriggerObject__mdt.class
                )
            );
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ dottedValidator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, dottedValidator.messageCount, 'It should be 0, because the loader stores a dotted name under both spellings.');
    }

    @IsTest
    static void gapEnrichmentBeforeInsertPopulatorReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Populator Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeInsertPopulator handler = new GapEnrichmentBeforeInsertPopulator();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(parentAccount.Id, handler.seenNewParents[0].Id, 'It should be the inserted account id.');
        Assert.areEqual('Populator Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Populator Parent.');
    }

    @IsTest
    static void gapEnrichmentBeforeInsertValidatorReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Validator Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeInsertValidator handler = new GapEnrichmentBeforeInsertValidator();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Validator Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Validator Parent.');
        Assert.areEqual(
            'Account Validator Parent does not accept new contacts.',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be the message naming the enriched parent.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeInsertPopulatorAndValidatorShareOneParentQuery() {
        Account parentAccount = new Account(Name = 'Shared Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeInsertPopulator populator = new GapEnrichmentBeforeInsertPopulator();
        populator.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        GapEnrichmentBeforeInsertValidator validator = new GapEnrichmentBeforeInsertValidator();
        validator.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ populator, validator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Shared Parent',
            ((Account) populator.seenNewParents[0]).Name,
            'It should be Shared Parent, because the populator adapter returns its own declaration and the parent it names reaches the populator.'
        );
        Assert.areEqual(
            'Shared Parent',
            ((Account) validator.seenNewParents[0]).Name,
            'It should be Shared Parent, because the validator adapter returns its own declaration and the parent it names reaches the validator.'
        );
        Assert.areEqual(
            1,
            queriesAfter - queriesBefore,
            'It should be 1, because declarations of every active handler are merged per lookup field, so the same parent is fetched once for the whole invocation.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeUpdatePopulatorReceivesDeclaredParentOnNewSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Current Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = parentAccount.Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeUpdatePopulator handler = new GapEnrichmentBeforeUpdatePopulator();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Current Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Current Parent.');
        Assert.isNull(handler.seenOldParents[0], 'It should be null.');
    }

    @IsTest
    static void gapEnrichmentBeforeUpdatePopulatorReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentBeforeUpdatePopulator handler = new GapEnrichmentBeforeUpdatePopulator();
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(accounts[0].Id, handler.seenOldParents[0].Id, 'It should be the previous account id.');
        Assert.areEqual('Previous Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Previous Parent.');
    }

    @IsTest
    static void gapEnrichmentBeforeUpdatePopulatorReceivesBothDeclaredSidesInOneQuery() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentBeforeUpdatePopulator handler = new GapEnrichmentBeforeUpdatePopulator();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because a handler declaring both sides still reads the new side through getNewParent.'
        );
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because a handler declaring both sides reads the old side through getOldParent.'
        );
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because both sides of the same lookup field are gathered into a single query for the invocation.');
    }

    @IsTest
    static void gapEnrichmentBeforeUpdateValidatorReceivesDeclaredParentOnNewSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Current Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = parentAccount.Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeUpdateValidator handler = new GapEnrichmentBeforeUpdateValidator();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Current Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Current Parent.');
        Assert.areEqual('Account Current Parent is locked.', newRecords[0].getErrors()[0].getMessage(), 'It should be the message naming the enriched parent.');
    }

    @IsTest
    static void gapEnrichmentBeforeUpdateValidatorReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentBeforeUpdateValidator handler = new GapEnrichmentBeforeUpdateValidator();
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Previous Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Previous Parent.');
        Assert.isNull(handler.seenNewParents[0], 'It should be null.');
    }

    @IsTest
    static void gapEnrichmentAfterInsertHandlerReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Inserted Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', Email = 'sanders@example.com', AccountId = parentAccount.Id) };
        insert newRecords;

        GapEnrichmentAfterInsertHandler handler = new GapEnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(parentAccount.Id, handler.seenNewParents[0].Id, 'It should be the inserted account id.');
        Assert.areEqual('Inserted Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Inserted Parent.');
    }

    @IsTest
    static void gapEnrichmentAfterUpdateHandlerReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Current Parent');
        insert parentAccount;

        Contact savedContact = new Contact(LastName = 'Moved', Email = 'moved@example.com', AccountId = parentAccount.Id);
        insert savedContact;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Moved', AccountId = parentAccount.Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = savedContact.Id, LastName = 'Moved', AccountId = parentAccount.Id) };

        GapEnrichmentAfterUpdateHandler handler = new GapEnrichmentAfterUpdateHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual('Current Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Current Parent.');
        Assert.isNull(handler.seenOldParents[0], 'It should be null.');
    }

    @IsTest
    static void gapEnrichmentAfterUpdateHandlerReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentAfterUpdateHandler handler = new GapEnrichmentAfterUpdateHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(accounts[0].Id, handler.seenOldParents[0].Id, 'It should be the previous account id.');
        Assert.areEqual('Previous Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Previous Parent.');
    }

    @IsTest
    static void gapEnrichmentBeforeDeleteHandlerReceivesDeclaredParentOnOldSide() {
        Account parentAccount = new Account(Name = 'Deleted Child Parent');
        insert parentAccount;

        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeDeleteHandler handler = new GapEnrichmentBeforeDeleteHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(parentAccount.Id, handler.seenOldParents[0].Id, 'It should be the inserted account id, because a delete context carries no new record.');
        Assert.areEqual('Deleted Child Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Deleted Child Parent.');
    }

    @IsTest
    static void gapEnrichmentAfterDeleteHandlerReceivesDeclaredParentOnOldSide() {
        Account parentAccount = new Account(Name = 'Removed Child Parent');
        insert parentAccount;

        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Deleted', AccountId = parentAccount.Id) };

        GapEnrichmentAfterDeleteHandler handler = new GapEnrichmentAfterDeleteHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = oldRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(parentAccount.Id, handler.seenOldParents[0].Id, 'It should be the inserted account id, because a delete context carries no new record.');
        Assert.areEqual('Removed Child Parent', ((Account) handler.seenOldParents[0]).Name, 'It should be Removed Child Parent.');
    }

    @IsTest
    static void gapEnrichmentAfterUndeleteHandlerReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Restored Child Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Restored', Email = 'restored@example.com', AccountId = parentAccount.Id) };
        insert newRecords;

        GapEnrichmentAfterUndeleteHandler handler = new GapEnrichmentAfterUndeleteHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(parentAccount.Id, handler.seenNewParents[0].Id, 'It should be the inserted account id, because an undelete context carries only restored records.');
        Assert.areEqual('Restored Child Parent', ((Account) handler.seenNewParents[0]).Name, 'It should be Restored Child Parent.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertPopulatorSwallowsItsFailure() {
        GapContinueOnErrorMutedBeforeInsertPopulator failingPopulator = new GapContinueOnErrorMutedBeforeInsertPopulator();
        GapContinueOnErrorCountingBeforeInsertPopulator laterPopulator = new GapContinueOnErrorCountingBeforeInsertPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Continue') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterPopulator.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertPopulatorWithoutOptInPropagatesItsFailure() {
        GapContinueOnErrorFailingBeforeInsertPopulator failingPopulator = new GapContinueOnErrorFailingBeforeInsertPopulator();
        GapContinueOnErrorCountingBeforeInsertPopulator laterPopulator = new GapContinueOnErrorCountingBeforeInsertPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Before insert populator failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterPopulator.executionCount, 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertValidatorSwallowsItsFailure() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Continue') };
        GapContinueOnErrorMutedBeforeInsertValidator failingValidator = new GapContinueOnErrorMutedBeforeInsertValidator();
        GapContinueOnErrorCountingBeforeInsertValidator laterValidator = new GapContinueOnErrorCountingBeforeInsertValidator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterValidator.executionCount, 'It should be 1.');
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertValidatorWithoutOptInPropagatesItsFailure() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        GapContinueOnErrorFailingBeforeInsertValidator failingValidator = new GapContinueOnErrorFailingBeforeInsertValidator();
        GapContinueOnErrorCountingBeforeInsertValidator laterValidator = new GapContinueOnErrorCountingBeforeInsertValidator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Before insert validator failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterValidator.executionCount, 'It should be 0.');
        Assert.areEqual(0, records[0].getErrors().size(), 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorAfterInsertHandlerSwallowsItsFailure() {
        GapContinueOnErrorMutedAfterInsertHandler failingHandler = new GapContinueOnErrorMutedAfterInsertHandler();
        GapContinueOnErrorCountingAfterInsertHandler laterHandler = new GapContinueOnErrorCountingAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Continue') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorAfterInsertHandlerWithoutOptInPropagatesItsFailure() {
        GapContinueOnErrorFailingAfterInsertHandler failingHandler = new GapContinueOnErrorFailingAfterInsertHandler();
        GapContinueOnErrorCountingAfterInsertHandler laterHandler = new GapContinueOnErrorCountingAfterInsertHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('After insert handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdatePopulatorSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Continue') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Continue') };
        GapContinueOnErrorMutedBeforeUpdatePopulator failingPopulator = new GapContinueOnErrorMutedBeforeUpdatePopulator();
        GapContinueOnErrorCountingBeforeUpdatePopulator laterPopulator = new GapContinueOnErrorCountingBeforeUpdatePopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterPopulator.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdatePopulatorWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Abort') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Abort') };
        GapContinueOnErrorFailingBeforeUpdatePopulator failingPopulator = new GapContinueOnErrorFailingBeforeUpdatePopulator();
        GapContinueOnErrorCountingBeforeUpdatePopulator laterPopulator = new GapContinueOnErrorCountingBeforeUpdatePopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Before update populator failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterPopulator.executionCount, 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdateValidatorSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Continue') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Continue') };
        GapContinueOnErrorMutedBeforeUpdateValidator failingValidator = new GapContinueOnErrorMutedBeforeUpdateValidator();
        GapContinueOnErrorCountingBeforeUpdateValidator laterValidator = new GapContinueOnErrorCountingBeforeUpdateValidator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterValidator.executionCount, 'It should be 1.');
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdateValidatorWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Abort') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Abort') };
        GapContinueOnErrorFailingBeforeUpdateValidator failingValidator = new GapContinueOnErrorFailingBeforeUpdateValidator();
        GapContinueOnErrorCountingBeforeUpdateValidator laterValidator = new GapContinueOnErrorCountingBeforeUpdateValidator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Before update validator failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterValidator.executionCount, 'It should be 0.');
        Assert.areEqual(0, newRecords[0].getErrors().size(), 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUpdateHandlerSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Continue') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Continue') };
        GapContinueOnErrorMutedAfterUpdateHandler failingHandler = new GapContinueOnErrorMutedAfterUpdateHandler();
        GapContinueOnErrorCountingAfterUpdateHandler laterHandler = new GapContinueOnErrorCountingAfterUpdateHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUpdateHandlerWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Abort') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Abort') };
        GapContinueOnErrorFailingAfterUpdateHandler failingHandler = new GapContinueOnErrorFailingAfterUpdateHandler();
        GapContinueOnErrorCountingAfterUpdateHandler laterHandler = new GapContinueOnErrorCountingAfterUpdateHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('After update handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeDeleteHandlerSwallowsItsFailure() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Continue') };
        GapContinueOnErrorMutedBeforeDeleteHandler failingHandler = new GapContinueOnErrorMutedBeforeDeleteHandler();
        GapContinueOnErrorCountingBeforeDeleteHandler laterHandler = new GapContinueOnErrorCountingBeforeDeleteHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeDeleteHandlerWithoutOptInPropagatesItsFailure() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Abort') };
        GapContinueOnErrorFailingBeforeDeleteHandler failingHandler = new GapContinueOnErrorFailingBeforeDeleteHandler();
        GapContinueOnErrorCountingBeforeDeleteHandler laterHandler = new GapContinueOnErrorCountingBeforeDeleteHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('Before delete handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorAfterDeleteHandlerSwallowsItsFailure() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Continue') };
        GapContinueOnErrorMutedAfterDeleteHandler failingHandler = new GapContinueOnErrorMutedAfterDeleteHandler();
        GapContinueOnErrorCountingAfterDeleteHandler laterHandler = new GapContinueOnErrorCountingAfterDeleteHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorAfterDeleteHandlerWithoutOptInPropagatesItsFailure() {
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Abort') };
        GapContinueOnErrorFailingAfterDeleteHandler failingHandler = new GapContinueOnErrorFailingAfterDeleteHandler();
        GapContinueOnErrorCountingAfterDeleteHandler laterHandler = new GapContinueOnErrorCountingAfterDeleteHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('After delete handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUndeleteHandlerSwallowsItsFailure() {
        GapContinueOnErrorMutedAfterUndeleteHandler failingHandler = new GapContinueOnErrorMutedAfterUndeleteHandler();
        GapContinueOnErrorCountingAfterUndeleteHandler laterHandler = new GapContinueOnErrorCountingAfterUndeleteHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Continue') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUndeleteHandlerWithoutOptInPropagatesItsFailure() {
        GapContinueOnErrorFailingAfterUndeleteHandler failingHandler = new GapContinueOnErrorFailingAfterUndeleteHandler();
        GapContinueOnErrorCountingAfterUndeleteHandler laterHandler = new GapContinueOnErrorCountingAfterUndeleteHandler();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Abort') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown.');
        Assert.areEqual('After undelete handler failed on purpose.', orchestratorException.getMessage(), 'It should be the handler message.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnBeforeInsert() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void twoHandlersDeclaringTheSameProviderQueryOnce() {
        TriggerOrchestratorTest.relatedPooledQueries = 0;
        RelatedBeforeInsertPopulator first = new RelatedBeforeInsertPopulator(new RelatedPooledProvider('shared'));
        RelatedBeforeInsertPopulator second = new RelatedBeforeInsertPopulator(new RelatedPooledProvider('shared'));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ first, second }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, TriggerOrchestratorTest.relatedPooledQueries, 'It should be 1, because two handlers declaring the same provider share one query.');
        Assert.areEqual(2, first.predicateReads, 'It should be 2, because the first handler read the provider for both records.');
        Assert.areEqual(2, second.predicateReads, 'It should be 2, because the second handler read the same loaded provider.');
    }

    @IsTest
    static void handlersDeclaringDifferentProvidersQuerySeparately() {
        TriggerOrchestratorTest.relatedPooledQueries = 0;
        RelatedBeforeInsertPopulator first = new RelatedBeforeInsertPopulator(new RelatedPooledProvider('first'));
        RelatedBeforeInsertPopulator second = new RelatedBeforeInsertPopulator(new RelatedPooledProvider('second'));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ first, second }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, TriggerOrchestratorTest.relatedPooledQueries, 'It should be 2, because providers that differ are not shared.');
    }

    @IsTest
    static void declaredProviderIsNotQueriedUntilItIsRead() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(provider);
        handler.readProviders = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook still names the provider.');
        Assert.areEqual(0, provider.loadCount, 'It should be 0, because a provider nobody reads is never queried.');
    }

    @IsTest
    static void readingOneParentDoesNotQueryTheOtherDeclaredLookup() {
        Account parentAccount = new Account(Name = 'Read Me');
        insert parentAccount;
        Contact reportsTo = new Contact(LastName = 'Manager', Email = 'manager@example.com');
        insert reportsTo;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe', Email = 'doe@example.com', AccountId = parentAccount.Id, ReportsToId = reportsTo.Id) };

        LazySilentBeforeUpdateHandler handler = new LazySilentBeforeUpdateHandler();
        handler.relationshipToRead = 'Account';
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));
        handler.declareNew(Contact.ReportsToId, TriggerHandler.ParentFields.with(Contact.LastName));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.context.oldRecords = newRecords.deepClone(false, false, false);
        orchestratorRunner.run();
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because only the lookup the handler read is resolved.');
        Assert.areEqual('Read Me', ((Account) handler.seenParent).Name, 'It should be the account name, because that is the lookup the handler read.');
    }

    @IsTest
    static void declaredParentIsNotQueriedUntilItIsRead() {
        Account parentAccount = new Account(Name = 'Never Read');
        insert parentAccount;
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe', Email = 'doe@example.com', AccountId = parentAccount.Id) };
        insert newRecords;

        LazySilentAfterInsertHandler handler = new LazySilentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, queriesAfter - queriesBefore, 'It should be 0, because a declared parent nobody reads is never queried.');
        Assert.areEqual(1, handler.runCount, 'It should be 1, because the handler still ran.');
    }

    @IsTest
    static void declaredParentIsQueriedOnceWhenItIsRead() {
        Account parentAccount = new Account(Name = 'Read Once');
        insert parentAccount;
        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'Doe', Email = 'doe@example.com', AccountId = parentAccount.Id),
            new Contact(LastName = 'Roe', Email = 'roe@example.com', AccountId = parentAccount.Id)
        };
        insert newRecords;

        LazySilentAfterInsertHandler handler = new LazySilentAfterInsertHandler();
        handler.readsParent = true;
        handler.declareNew(Contact.AccountId, TriggerHandler.ParentFields.with(Account.Name));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = newRecords;
        orchestratorRunner.run();
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because the first read resolves every declared parent for every record at once.');
        Assert.areEqual('Read Once', ((Account) handler.seenParent).Name, 'It should be the parent name, because the read returns the resolved parent.');
    }

    @IsTest
    static void relatedQueryNotCalledForABypassedHandler() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>());
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(provider);
        handler.bypass = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(0, handler.hookCount, 'It should be 0, because a bypassed handler never has its hook called.');
        Assert.areEqual(0, provider.loadCount, 'It should be 0, because nothing is loaded for a bypassed handler.');
    }

    @IsTest
    static void relatedQueryRunsWhenNoRecordQualifies() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>());
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(provider);
        handler.qualify = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs before qualification and does not depend on it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because loading happens before the first predicate.');
        Assert.areEqual(0, handler.finalizerReads, 'It should be 0, because the finalizer does not run when nothing qualified.');
    }

    @IsTest
    static void handlerWithoutRelatedQueryCannotReadAProvider() {
        RelatedReaderBeforeInsertPopulator handler = new RelatedReaderBeforeInsertPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because no provider is registered for a handler without the hook.');
        Assert.isTrue(orchestratorException.getTypeName().endsWith('TriggerHandlerException'), 'It should be a TriggerHandlerException.');
        Assert.areEqual(
            'No related records provider is registered under related. Return it from the RelatedQuery method of the context first.',
            orchestratorException.getMessage(),
            'It should name the missing provider.'
        );
    }

    @IsTest
    static void nextHandlerSeesAnEmptyProviderMapAtPredicateTimeAndInsideItsHook() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>());
        RelatedBeforeInsertPopulator first = new RelatedBeforeInsertPopulator(provider);
        RelatedPeekingBeforeInsertPopulator second = new RelatedPeekingBeforeInsertPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ first, second }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.isFalse(second.previousProviderReachableInQuery, 'It should be unreachable while the provider queries, because each handler starts from an empty map.');
        Assert.isFalse(second.previousProviderReachableInPredicate, 'It should be unreachable in the predicate, because each handler gets its own map.');
        Assert.isTrue(second.ownProviderReachableInPredicate, 'It should be reachable, because the second handler registered its own provider.');
    }

    @IsTest
    static void relatedQueryExceptionIsLoggedWithTheHandlerNameAndRethrown() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(new RelatedCountingProvider(new List<Contact>()));
        handler.throwInHook = true;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the handler does not implement ContinueOnError.');
        Assert.areEqual('Hook failed on purpose.', orchestratorException.getMessage(), 'It should be the hook exception.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the hook runs inside the handler turn.');
        Assert.areEqual('RelatedBeforeInsertPopulator', logger.errors[0].getHandlerName(), 'It should name the handler whose hook failed.');
        Assert.areEqual(0, handler.predicateReads, 'It should be 0, because the loop never started.');
    }

    @IsTest
    static void providerLoadExceptionIsSwallowedWithContinueOnError() {
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        RelatedMutedBeforeInsertPopulator failing = new RelatedMutedBeforeInsertPopulator(new RelatedFailingProvider());
        RelatedBeforeInsertPopulator later = new RelatedBeforeInsertPopulator(new RelatedCountingProvider(new List<Contact>()));

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        TriggerOrchestrator.triggerLogger.logger = logger;
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failing, later }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because ContinueOnError swallows the provider failure.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the failure is still logged.');
        Assert.areEqual('RelatedMutedBeforeInsertPopulator', logger.errors[0].getHandlerName(), 'It should name the handler whose provider failed.');
        Assert.areEqual('Provider failed on purpose.', logger.errors[0].getException().getMessage(), 'It should be the provider exception.');
        Assert.areEqual(1, failing.predicateReads, 'It should be 1, because the failure surfaces at the first read and stops that handler.');
        Assert.areEqual(1, later.predicateReads, 'It should be 1, because the next handler still runs.');
    }

    @IsTest
    static void providerPerformingDmlInABeforeContextTripsTheGuard() {
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(new RelatedDmlProvider());

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a provider query sits inside the DML guard.');
        Assert.areEqual(
            'RelatedBeforeInsertPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler.'
        );
    }

    @IsTest
    static void nullHookResultIsTreatedAsAnEmptyMap() {
        RelatedBeforeInsertPopulator handler = new RelatedBeforeInsertPopulator(null);
        handler.returnNull = true;
        handler.readProviders = false;

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because a null hook result counts as no providers.');
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook still ran.');
    }

    @IsTest
    static void relatedQueryRunsAfterParentEnrichmentOnBeforeInsert() {
        Account parentAccount = new Account(Name = 'Enriched First');
        insert parentAccount;
        RelatedEnrichedBeforeInsertPopulator handler = new RelatedEnrichedBeforeInsertPopulator();

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe', AccountId = parentAccount.Id) };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(
            new Set<String>{ 'Enriched First' },
            handler.parentNamesSeenInQuery,
            'It should hold the parent name, because enrichment runs before the providers and the collection reads the enriched parent.'
        );
    }

    @IsTest
    static void relatedQueryReceivesRecursionSkippedRecordsOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>());
        RelatedGuardedBeforeUpdatePopulator handler = new RelatedGuardedBeforeUpdatePopulator(provider);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        for (Integer pass = 0; pass < 2; pass++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = newRecords;
            orchestratorRunner.context.oldRecords = oldRecords;
            orchestratorRunner.run();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(2, handler.hookCount, 'It should be 2, because the hook runs on every invocation.');
        Assert.areEqual(
            new List<Integer>{ 1 },
            provider.recordCounts,
            'It should be 1 for the pass that ran, because a pass whose records are all skipped by the recursion guard reads nothing and so queries nothing.'
        );
        Assert.areEqual(1, handler.actionCount, 'It should be 1, because the recursion guard with depth 1 skipped the second pass.');
    }

    @IsTest
    static void twoHopProviderRunsBothQueriesInOneLoad() {
        Account parentAccount = new Account(Name = 'Hop Source');
        insert parentAccount;
        insert new Contact(LastName = 'Hop Target', Email = 'hop.target@example.com', AccountId = parentAccount.Id);
        RelatedTwoHopProvider provider = new RelatedTwoHopProvider(new Set<Id>{ parentAccount.Id });

        // Test
        Test.startTest();
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(provider, new TriggerHandler.InsertTriggerRecords(new List<TriggerHandler.TriggerRecord>()));
        Integer queriesBeforeRead = Limits.getQueries();
        related.load();
        Integer queriesAfterRead = Limits.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(2, queriesAfterRead - queriesBeforeRead, 'It should be 2, because both hops run inside one query() call, when the provider is loaded.');
        Assert.areEqual(1, related.getAllWhereKeyEquals(parentAccount.Id).size(), 'It should be 1, because the second hop is keyed by the first hop result.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnBeforeInsertValidator() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedBeforeInsertValidator handler = new RelatedBeforeInsertValidator(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because addError on a record outside a real trigger set raises nothing.');
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnAfterInsert() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedAfterInsertHandler handler = new RelatedAfterInsertHandler(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Roe')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnBeforeUpdatePopulator() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedBeforeUpdatePopulator handler = new RelatedBeforeUpdatePopulator(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Doe'), new Contact(Id = secondContactId, LastName = 'Roe') };
        orchestratorRunner.context.oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'Old Doe'),
            new Contact(Id = secondContactId, LastName = 'Old Roe')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnBeforeUpdateValidator() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedBeforeUpdateValidator handler = new RelatedBeforeUpdateValidator(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        Exception orchestratorException = null;

        // Test
        Test.startTest();
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Doe'), new Contact(Id = secondContactId, LastName = 'Roe') };
            orchestratorRunner.context.oldRecords = new List<Contact>{
                new Contact(Id = firstContactId, LastName = 'Old Doe'),
                new Contact(Id = secondContactId, LastName = 'Old Roe')
            };
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }
        Test.stopTest();

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because addError on a record outside a real trigger set raises nothing.');
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnAfterUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedAfterUpdateHandler handler = new RelatedAfterUpdateHandler(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Doe'), new Contact(Id = secondContactId, LastName = 'Roe') };
        orchestratorRunner.context.oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'Old Doe'),
            new Contact(Id = secondContactId, LastName = 'Old Roe')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnBeforeDelete() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedBeforeDeleteHandler handler = new RelatedBeforeDeleteHandler(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Roe')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnAfterDelete() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedAfterDeleteHandler handler = new RelatedAfterDeleteHandler(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.oldRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Roe')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    @IsTest
    static void relatedQueryRunsOnceAndQueriesOnFirstReadOnAfterUndelete() {
        RelatedCountingProvider provider = new RelatedCountingProvider(new List<Contact>{ new Contact(LastName = 'Doe') });
        RelatedAfterUndeleteHandler handler = new RelatedAfterUndeleteHandler(provider);

        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        // Test
        Test.startTest();
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new RelatedAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.newRecords = new List<Contact>{
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Doe'),
            new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Roe')
        };
        orchestratorRunner.run();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, handler.hookCount, 'It should be 1, because the hook runs once per handler per invocation.');
        Assert.areEqual(2, provider.lastRecordCount, 'It should be 2, because the collection the provider is queried with covers every trigger record.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the framework loads each provider once.');
        Assert.areEqual(0, handler.loadCountAtFirstPredicate, 'It should be 0, because a provider is not queried until a handler reads it.');
        Assert.areEqual(1, provider.loadCount, 'It should be 1, because the provider is queried once however many records read it.');
        Assert.areEqual(2, handler.predicateReads, 'It should be 2, because the provider is readable in every predicate call.');
        Assert.areEqual(2, handler.actionReads, 'It should be 2, because the provider is readable in every action call.');
        Assert.areEqual(1, handler.finalizerReads, 'It should be 1, because the provider stays attached through the finalizer.');
    }

    private class DispatchBeforeInsertPopulator implements BeforeInsert.Populator {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledNewRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
            this.handledNewRecords.add(record.getNewSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchAfterInsertHandler implements AfterInsert.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledNewRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
            this.handledNewRecords.add(record.getNewSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchBeforeUpdatePopulator implements BeforeUpdate.Populator {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledNewRecords = new List<SObject>();
        public List<SObject> handledOldRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            this.handledNewRecords.add(record.getNewSObject());
            this.handledOldRecords.add(record.getOldSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledNewRecords = new List<SObject>();
        public List<SObject> handledOldRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            this.handledNewRecords.add(record.getNewSObject());
            this.handledOldRecords.add(record.getOldSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchBeforeDeleteHandler implements BeforeDelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledOldRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
            this.handledOldRecords.add(record.getOldSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchAfterDeleteHandler implements AfterDelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledOldRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
            this.handledOldRecords.add(record.getOldSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchAfterUndeleteHandler implements AfterUndelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;
        public List<SObject> handledNewRecords = new List<SObject>();
        public List<Id> handledIds = new List<Id>();

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.runCount++;
            this.handledNewRecords.add(record.getNewSObject());
            this.handledIds.add(record.getId());
        }
    }

    private class DispatchAllContextsOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.BeforeDelete, TriggerOrchestrator.AfterDelete, TriggerOrchestrator.AfterUndelete {
        public DispatchBeforeInsertPopulator beforeInsertHandler = new DispatchBeforeInsertPopulator();
        public DispatchAfterInsertHandler afterInsertHandler = new DispatchAfterInsertHandler();
        public DispatchBeforeUpdatePopulator beforeUpdateHandler = new DispatchBeforeUpdatePopulator();
        public DispatchAfterUpdateHandler afterUpdateHandler = new DispatchAfterUpdateHandler();
        public DispatchBeforeDeleteHandler beforeDeleteHandler = new DispatchBeforeDeleteHandler();
        public DispatchAfterDeleteHandler afterDeleteHandler = new DispatchAfterDeleteHandler();
        public DispatchAfterUndeleteHandler afterUndeleteHandler = new DispatchAfterUndeleteHandler();

        public List<String> requestedHandlerLists = new List<String>();

        public Integer totalRunCount() {
            return this.beforeInsertHandler.runCount +
                this.afterInsertHandler.runCount +
                this.beforeUpdateHandler.runCount +
                this.afterUpdateHandler.runCount +
                this.beforeDeleteHandler.runCount +
                this.afterDeleteHandler.runCount +
                this.afterUndeleteHandler.runCount;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            this.requestedHandlerLists.add('beforeInsertHandlers');
            return new List<BeforeInsert.Handler>{ this.beforeInsertHandler };
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            this.requestedHandlerLists.add('afterInsertHandlers');
            return new List<AfterInsert.Handler>{ this.afterInsertHandler };
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            this.requestedHandlerLists.add('beforeUpdateHandlers');
            return new List<BeforeUpdate.Handler>{ this.beforeUpdateHandler };
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            this.requestedHandlerLists.add('afterUpdateHandlers');
            return new List<AfterUpdate.Handler>{ this.afterUpdateHandler };
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            this.requestedHandlerLists.add('beforeDeleteHandlers');
            return new List<BeforeDelete.Handler>{ this.beforeDeleteHandler };
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            this.requestedHandlerLists.add('afterDeleteHandlers');
            return new List<AfterDelete.Handler>{ this.afterDeleteHandler };
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            this.requestedHandlerLists.add('afterUndeleteHandlers');
            return new List<AfterUndelete.Handler>{ this.afterUndeleteHandler };
        }
    }

    private class DispatchPartialOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterUpdate {
        public DispatchBeforeInsertPopulator beforeInsertHandler = new DispatchBeforeInsertPopulator();
        public DispatchAfterUpdateHandler afterUpdateHandler = new DispatchAfterUpdateHandler();

        public List<String> requestedHandlerLists = new List<String>();

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            this.requestedHandlerLists.add('beforeInsertHandlers');
            return new List<BeforeInsert.Handler>{ this.beforeInsertHandler };
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            this.requestedHandlerLists.add('afterUpdateHandlers');
            return new List<AfterUpdate.Handler>{ this.afterUpdateHandler };
        }
    }

    private class DispatchTwoHandlersOrchestrator implements TriggerOrchestrator.AfterInsert {
        public DispatchAfterInsertHandler firstHandler = new DispatchAfterInsertHandler();
        public DispatchAfterInsertHandler secondHandler = new DispatchAfterInsertHandler();

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return new List<AfterInsert.Handler>{ this.firstHandler, this.secondHandler };
        }
    }

    private class DispatchEmptyListOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterUpdate {
        public List<String> requestedHandlerLists = new List<String>();

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            this.requestedHandlerLists.add('beforeInsertHandlers');
            return new List<BeforeInsert.Handler>();
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            this.requestedHandlerLists.add('afterUpdateHandlers');
            return new List<AfterUpdate.Handler>();
        }
    }

    private class DispatchNoInterfacesOrchestrator {
    }

    private class DispatchFinalizeCountingLogger implements TriggerOrchestrator.Logger {
        public Integer finalizeCount = 0;

        public List<TriggerOrchestrator.Error> loggedErrors = new List<TriggerOrchestrator.Error>();

        public void log(TriggerOrchestrator.Error error) {
            this.loggedErrors.add(error);
        }

        public void finalize() {
            this.finalizeCount++;
        }
    }

    private class DispatchNestedRunOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public DispatchNestedRunPopulator handler = new DispatchNestedRunPopulator();

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return new List<BeforeInsert.Handler>{ this.handler };
        }
    }

    private class DispatchNestedRunPopulator implements BeforeInsert.Populator {
        public DispatchFinalizeCountingLogger logger;
        public Integer finalizeCountDuringHandler = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new DispatchNestedUnimplementedContextOrchestrator());
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner2.context.newRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
            orchestratorRunner2.run();
            this.finalizeCountDuringHandler = this.logger.finalizeCount;
        }
    }

    private class DispatchNestedUnimplementedContextOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return new List<AfterUpdate.Handler>();
        }
    }

    private class RolesOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate {
        private List<BeforeInsert.Handler> insertHandlers = new List<BeforeInsert.Handler>();
        private List<BeforeUpdate.Handler> updateHandlers = new List<BeforeUpdate.Handler>();

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.insertHandlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.updateHandlers;
        }
    }

    private class RolesInsertPopulator implements BeforeInsert.Populator {
        private Boolean qualifies = true;
        private Integer qualificationCount = 0;
        private Integer populateCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualificationCount++;
            return this.qualifies;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.populateCount++;
            record.put(Contact.Title, 'Populated');
        }
    }

    private class RolesBlankTitlePopulator implements BeforeInsert.Populator {
        private Integer populateCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return record.isBlank(Contact.Title);
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.populateCount++;
            record.put(Contact.Title, 'Populated');
        }
    }

    private class RolesUpdatePopulator implements BeforeUpdate.Populator {
        private Boolean qualifies = true;
        private Integer qualificationCount = 0;
        private Integer populateCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualificationCount++;
            return this.qualifies;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.populateCount++;
            record.put(Contact.Department, 'Populated');
        }
    }

    private class RolesChangedTitlePopulator implements BeforeUpdate.Populator {
        private Integer populateCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return record.isChanged(Contact.Title);
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.populateCount++;
            record.put(Contact.Department, 'Populated');
        }
    }

    private class RolesInsertValidator implements BeforeInsert.Validator {
        private Boolean errorShouldBeAttached = true;
        private String validationMessage = 'Title is required on new contacts.';
        private Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.errorShouldBeAttached;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.messageCount++;
            return this.validationMessage;
        }
    }

    private class RolesBlankTitleValidator implements BeforeInsert.Validator {
        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return record.isBlank(Contact.Title);
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            return 'Title is required on new contacts.';
        }
    }

    private class RolesUpdateValidator implements BeforeUpdate.Validator {
        private Boolean errorShouldBeAttached = true;
        private String validationMessage = 'Title cannot be changed.';
        private Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.errorShouldBeAttached;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.messageCount++;
            return this.validationMessage;
        }
    }

    private class RolesChangedTitleValidator implements BeforeUpdate.Validator {
        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return record.isChanged(Contact.Title);
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            return 'Title cannot be changed.';
        }
    }

    private class RolesLoggingInsertPopulator implements BeforeInsert.Populator {
        private String handlerName;
        private List<String> executionLog;

        private RolesLoggingInsertPopulator(String handlerName, List<String> executionLog) {
            this.handlerName = handlerName;
            this.executionLog = executionLog;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.executionLog.add(this.handlerName + ' qualify ' + record.getNewSObject().get(Contact.LastName));
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.executionLog.add(this.handlerName + ' populate ' + record.getNewSObject().get(Contact.LastName));
        }
    }

    private class RolesLoggingInsertValidator implements BeforeInsert.Validator {
        private String handlerName;
        private List<String> executionLog;

        private RolesLoggingInsertValidator(String handlerName, List<String> executionLog) {
            this.handlerName = handlerName;
            this.executionLog = executionLog;
        }

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.executionLog.add(this.handlerName + ' qualify ' + record.getNewSObject().get(Contact.LastName));
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.executionLog.add(this.handlerName + ' message ' + record.getNewSObject().get(Contact.LastName));
            return 'Blocked by ' + this.handlerName + '.';
        }
    }

    private class RolesLoggingUpdatePopulator implements BeforeUpdate.Populator {
        private String handlerName;
        private List<String> executionLog;

        private RolesLoggingUpdatePopulator(String handlerName, List<String> executionLog) {
            this.handlerName = handlerName;
            this.executionLog = executionLog;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.executionLog.add(this.handlerName + ' qualify ' + record.getNewSObject().get(Contact.LastName));
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.executionLog.add(this.handlerName + ' populate ' + record.getNewSObject().get(Contact.LastName));
        }
    }

    private class RolesLoggingUpdateValidator implements BeforeUpdate.Validator {
        private String handlerName;
        private List<String> executionLog;

        private RolesLoggingUpdateValidator(String handlerName, List<String> executionLog) {
            this.handlerName = handlerName;
            this.executionLog = executionLog;
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.executionLog.add(this.handlerName + ' qualify ' + record.getNewSObject().get(Contact.LastName));
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.executionLog.add(this.handlerName + ' message ' + record.getNewSObject().get(Contact.LastName));
            return 'Blocked by ' + this.handlerName + '.';
        }
    }

    private class RolesDualContextPopulator implements BeforeInsert.Populator, BeforeUpdate.Populator, BeforeInsert.Finalizer, BeforeUpdate.Finalizer {
        private Integer beforeInsertPopulateCount = 0;
        private Integer beforeUpdatePopulateCount = 0;
        private Integer beforeInsertFinalizeCount = 0;
        private Integer beforeUpdateFinalizeCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.beforeInsertPopulateCount++;
            record.put(Contact.Title, 'Insert');
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.beforeUpdatePopulateCount++;
            record.put(Contact.Title, 'Update');
        }

        public void finalizeBeforeInsert() {
            this.beforeInsertFinalizeCount++;
        }

        public void finalizeBeforeUpdate() {
            this.beforeUpdateFinalizeCount++;
        }
    }

    private class RolesInsertPopulatorAndUpdateValidator implements BeforeInsert.Populator, BeforeUpdate.Validator {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            record.put(Contact.Title, 'Populated');
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            return 'Title cannot be changed.';
        }
    }

    private class EnrichmentIdFactory {
        private Integer counter = 1;

        public Id next(SObjectType sObjectType) {
            String uniquePart = String.valueOf(this.counter++);

            return Id.valueOf(sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() + '0'.repeat(12 - uniquePart.length()) + uniquePart);
        }
    }

    private class EnrichmentBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public EnrichmentBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class EnrichmentAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public EnrichmentAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class EnrichmentBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public EnrichmentBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class EnrichmentAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public EnrichmentAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class EnrichmentBeforeInsertHandler implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<Id> accountIdsToSet = new List<Id>();

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Integer repointIndex = 0;

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
            return this.newDeclaration;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));

            if (this.accountIdsToSet.isEmpty()) {
                return;
            }

            record.put(Contact.AccountId, this.accountIdsToSet[Math.min(this.repointIndex, this.accountIdsToSet.size() - 1)]);
            this.repointIndex++;
        }
    }

    private class EnrichmentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.ParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenNewOwners = new List<SObject>();

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            this.seenNewOwners.add(record.getNewParent('Owner'));
        }
    }

    private class EnrichmentBeforeUpdateHandler implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public List<Id> accountIdsToSet = new List<Id>();

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Integer repointIndex = 0;

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
            return this.oldDeclaration;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            this.seenOldParents.add(record.getOldParent('Account'));

            if (this.accountIdsToSet.isEmpty()) {
                return;
            }

            record.put(Contact.AccountId, this.accountIdsToSet[Math.min(this.repointIndex, this.accountIdsToSet.size() - 1)]);
            this.repointIndex++;
        }
    }

    private class EnrichmentAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public List<Id> accountIdsToSet = new List<Id>();

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Integer repointIndex = 0;

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
            return this.oldDeclaration;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            this.seenOldParents.add(record.getOldParent('Account'));

            if (this.accountIdsToSet.isEmpty()) {
                return;
            }

            record.put(Contact.AccountId, this.accountIdsToSet[Math.min(this.repointIndex, this.accountIdsToSet.size() - 1)]);
            this.repointIndex++;
        }
    }

    private class BypassFinalizeCountingLogger implements TriggerOrchestrator.Logger {
        public Integer finalizeCount = 0;
        public Integer logCount = 0;

        public void log(TriggerOrchestrator.Error error) {
            this.logCount++;
        }

        public void finalize() {
            this.finalizeCount++;
        }
    }

    private class BypassNestedRunHandler implements AfterInsert.Handler {
        public Integer finalizeCountAfterNestedRun = -1;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;

            List<SObject> nestedRecords = new List<Account>{ new Account(Id = TriggerHandler.IdGenerator.get(Account.SObjectType), Name = 'Nested') };

            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new BypassNestedAccountOrchestrator());
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner2.context.newRecords = nestedRecords;
            orchestratorRunner2.run();

            this.finalizeCountAfterNestedRun = ((BypassFinalizeCountingLogger) TriggerOrchestrator.triggerLogger.logger).finalizeCount;
        }
    }

    private class BypassNestedAccountOrchestrator implements TriggerOrchestrator.AfterInsert {
        public List<AfterInsert.Handler> afterInsertHandlers() {
            return new List<AfterInsert.Handler>();
        }
    }

    private class BypassBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public Boolean areHandlersRequested = false;
        private List<BeforeInsert.Handler> handlers;

        public BypassBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        public Boolean areHandlersRequested = false;
        private List<AfterInsert.Handler> handlers;

        public BypassAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        public Boolean areHandlersRequested = false;
        private List<BeforeUpdate.Handler> handlers;

        public BypassBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public Boolean areHandlersRequested = false;
        private List<AfterUpdate.Handler> handlers;

        public BypassAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        public Boolean areHandlersRequested = false;
        private List<BeforeDelete.Handler> handlers;

        public BypassBeforeDeleteOrchestrator(List<BeforeDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        public Boolean areHandlersRequested = false;
        private List<AfterDelete.Handler> handlers;

        public BypassAfterDeleteOrchestrator(List<AfterDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        public Boolean areHandlersRequested = false;
        private List<AfterUndelete.Handler> handlers;

        public BypassAfterUndeleteOrchestrator(List<AfterUndelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            this.areHandlersRequested = true;
            return this.handlers;
        }
    }

    private class BypassBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnBeforeInsertWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
            record.put(Contact.Title, 'Populated');
        }
    }

    private class BypassBeforeInsertValidator implements BeforeInsert.Validator, BeforeInsert.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean bypassOnBeforeInsertWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.messageCount++;
            return 'Before insert validation failed';
        }
    }

    private class BypassAfterInsertHandler implements AfterInsert.Handler, AfterInsert.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnAfterInsertWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class BypassBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnBeforeUpdateWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            record.put(Contact.Title, 'Populated');
        }
    }

    private class BypassBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean bypassOnBeforeUpdateWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.messageCount++;
            return 'Before update validation failed';
        }
    }

    private class BypassAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnAfterUpdateWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class BypassBeforeDeleteHandler implements BeforeDelete.Handler, BeforeDelete.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnBeforeDeleteWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
        }
    }

    private class BypassAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnAfterDeleteWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
        }
    }

    private class BypassAfterUndeleteHandler implements AfterUndelete.Handler, AfterUndelete.Bypassable {
        public Boolean isBypassed = false;
        public Boolean isQualified = true;
        public Integer bypassCheckCount = 0;
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnAfterUndeleteWhen() {
            this.bypassCheckCount++;
            return this.isBypassed;
        }

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            this.qualifyCount++;
            return this.isQualified;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.runCount++;
        }
    }

    private class BypassPlainAfterInsertHandler implements AfterInsert.Handler {
        public Integer runCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class BypassMetadataHandler implements AfterInsert.Handler, AfterInsert.Bypassable {
        public Integer bypassCheckCount = 0;
        public Integer runCount = 0;

        public Boolean bypassOnAfterInsertWhen() {
            this.bypassCheckCount++;
            return false;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class BypassMetadataPopulator implements BeforeInsert.Populator {
        public Integer runCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class BypassEnrichmentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.Bypassable, AfterInsert.ParentQuery {
        public Boolean isBypassed = false;
        public Integer runCount = 0;

        public Boolean bypassOnAfterInsertWhen() {
            return this.isBypassed;
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
            return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class BypassRelatedReaderAfterInsertHandler implements AfterInsert.Handler {
        public SObject relatedAccount;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
            this.relatedAccount = record.getNewParent('Account');
        }
    }

    private class BypassLastNameAfterInsertHandler implements AfterInsert.Handler {
        public List<Id> processedRecordIds = new List<Id>();

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return record.equals(Contact.LastName, 'Qualified');
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.processedRecordIds.add(record.getId());
        }
    }

    private class BypassTitlePopulator implements BeforeInsert.Populator {
        public Integer runCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return record.isBlank(Contact.Title);
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
            record.put(Contact.Title, 'Hot');
        }
    }

    private class BypassTitleReaderPopulator implements BeforeInsert.Populator {
        public Integer runCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return record.equals(Contact.Title, 'Hot');
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
            record.put(Contact.Department, 'Priority');
        }
    }

    private class RecursionBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public RecursionBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class RecursionAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public RecursionAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class RecursionBothUpdatesOrchestrator implements TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
        private RecursionBothUpdatesHandler handler;

        public RecursionBothUpdatesOrchestrator(RecursionBothUpdatesHandler handler) {
            this.handler = handler;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return new List<BeforeUpdate.Handler>{ this.handler };
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return new List<AfterUpdate.Handler>{ this.handler };
        }
    }

    private class RecursionAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public RecursionAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class RecursionBeforeUpdateHandler implements BeforeUpdate.Populator {
        public Integer runCount = 0;
        public Map<Id, Integer> runCountByRecordId = new Map<Id, Integer>();

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RecursionSecondBeforeUpdateHandler implements BeforeUpdate.Populator {
        public Integer runCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class RecursionGuardedBeforeUpdateHandler implements BeforeUpdate.Populator, BeforeUpdate.RecursionGuard {
        public Integer runCount = 0;
        public Map<Id, Integer> runCountByRecordId = new Map<Id, Integer>();

        private Integer maxRecursionDepth;

        public RecursionGuardedBeforeUpdateHandler(Integer maxRecursionDepth) {
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepthOnBeforeUpdate() {
            return this.maxRecursionDepth;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RecursionSelectiveBeforeUpdateHandler implements BeforeUpdate.Populator {
        public Integer qualificationCount = 0;
        public Map<Id, Integer> runCountByRecordId = new Map<Id, Integer>();

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualificationCount++;
            return record.equals(Contact.LastName, 'Qualified');
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RecursionBeforeUpdateValidator implements BeforeUpdate.Validator {
        public Integer runCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            return 'Contact is not valid.';
        }
    }

    private class RecursionGuardedBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.RecursionGuard {
        public Integer runCount = 0;

        private Integer maxRecursionDepth;

        public RecursionGuardedBeforeUpdateValidator(Integer maxRecursionDepth) {
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepthOnBeforeUpdate() {
            return this.maxRecursionDepth;
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            return 'Contact is not valid.';
        }
    }

    private class RecursionAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer runCount = 0;
        public Map<Id, Integer> runCountByRecordId = new Map<Id, Integer>();

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RecursionSecondAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer runCount = 0;

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class RecursionGuardedAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.RecursionGuard {
        public Integer runCount = 0;
        public Map<Id, Integer> runCountByRecordId = new Map<Id, Integer>();

        private Integer maxRecursionDepth;

        public RecursionGuardedAfterUpdateHandler(Integer maxRecursionDepth) {
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepthOnAfterUpdate() {
            return this.maxRecursionDepth;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RecursionSelectiveAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer qualificationCount = 0;
        public Map<Id, Integer> runCountByRecordId = new Map<Id, Integer>();

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualificationCount++;
            return record.equals(Contact.LastName, 'Qualified');
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCountByRecordId.put(record.getId(), (this.runCountByRecordId.get(record.getId()) ?? 0) + 1);
        }
    }

    private class RecursionFinalizingAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.RecursionGuard, AfterUpdate.Finalizer {
        public Integer runCount = 0;
        public Integer finalizeCount = 0;

        private Integer maxRecursionDepth;

        public RecursionFinalizingAfterUpdateHandler(Integer maxRecursionDepth) {
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepthOnAfterUpdate() {
            return this.maxRecursionDepth;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }

        public void finalizeAfterUpdate() {
            this.finalizeCount++;
        }
    }

    private class RecursionBothUpdatesHandler implements BeforeUpdate.Populator, AfterUpdate.Handler {
        public Integer beforeUpdateRunCount = 0;
        public Integer afterUpdateRunCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.beforeUpdateRunCount++;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.afterUpdateRunCount++;
        }
    }

    private class RecursionAfterInsertHandler implements AfterInsert.Handler {
        public Integer runCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class RecursionLogger implements TriggerOrchestrator.Logger {
        public List<TriggerOrchestrator.Error> loggedErrors = new List<TriggerOrchestrator.Error>();
        public Integer finalizeCount = 0;

        public void log(TriggerOrchestrator.Error error) {
            this.loggedErrors.add(error);
        }

        public void finalize() {
            this.finalizeCount++;
        }
    }

    private class ErrorsLoggingException extends Exception {
    }

    private class ErrorsLoggingLogger implements TriggerOrchestrator.Logger {
        public List<TriggerOrchestrator.Error> errors = new List<TriggerOrchestrator.Error>();
        public List<Integer> finalizeCountWhenLogged = new List<Integer>();
        public Integer finalizeCount = 0;

        public void log(TriggerOrchestrator.Error error) {
            this.errors.add(error);
            this.finalizeCountWhenLogged.add(this.finalizeCount);
        }

        public void finalize() {
            this.finalizeCount++;
        }
    }

    private class ErrorsLoggingNoInterfaceOrchestrator {
    }

    private class ErrorsLoggingAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public ErrorsLoggingAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class ErrorsLoggingAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public ErrorsLoggingAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class ErrorsLoggingAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        public ErrorsLoggingAfterDeleteOrchestrator(List<AfterDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class ErrorsLoggingBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public ErrorsLoggingBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class ErrorsLoggingCountingHandler implements AfterInsert.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
        }
    }

    private class ErrorsLoggingFailingHandler implements AfterInsert.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new ErrorsLoggingException('Handler failed on purpose.');
        }
    }

    private class ErrorsLoggingMutedFailingHandler implements AfterInsert.Handler, AfterInsert.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new ErrorsLoggingException('Handler failed on purpose.');
        }
    }

    private class ErrorsLoggingFailingQualifierHandler implements AfterInsert.Handler {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            throw new ErrorsLoggingException('Qualification failed on purpose.');
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
        }
    }

    private class ErrorsLoggingFailingFinalizerHandler implements AfterInsert.Handler, AfterInsert.Finalizer {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
        }

        public void finalizeAfterInsert() {
            throw new ErrorsLoggingException('Finalizer failed on purpose.');
        }
    }

    private class ErrorsLoggingMutedRecordApiHandler implements AfterInsert.Handler, AfterInsert.ContinueOnError {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            throw new TriggerHandler.TriggerHandlerException('Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.');
        }
    }

    private class ErrorsLoggingBadCastHandler implements AfterInsert.Handler {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            Object text = 'Not a number';
            Integer castValue = (Integer) text;

            Assert.isNotNull(castValue, 'It should never be reached, because the cast above throws a TypeException.');
        }
    }

    private class ErrorsLoggingMutedBadCastHandler implements AfterInsert.Handler, AfterInsert.ContinueOnError {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            Object text = 'Not a number';
            Integer castValue = (Integer) text;

            Assert.isNotNull(castValue, 'It should never be reached, because the cast above throws a TypeException.');
        }
    }

    private class ErrorsLoggingNullDereferenceHandler implements AfterInsert.Handler {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            String missing = null;

            Assert.isNotNull(missing.length(), 'It should never be reached, because the dereference above throws a NullPointerException.');
        }
    }

    private class ErrorsLoggingNestedRunHandler implements AfterInsert.Handler {
        public Integer executionCount = 0;
        public Integer finalizeCountAfterNestedRun;

        private Object nestedOrchestrator;
        private ErrorsLoggingLogger logger;

        public ErrorsLoggingNestedRunHandler(Object nestedOrchestrator, ErrorsLoggingLogger logger) {
            this.nestedOrchestrator = nestedOrchestrator;
            this.logger = logger;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;

            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(this.nestedOrchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner2.context.newRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Nested') };
            orchestratorRunner2.run();

            this.finalizeCountAfterNestedRun = this.logger.finalizeCount;
        }
    }

    private class ErrorsLoggingMutedFailingAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.ContinueOnError {
        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            throw new ErrorsLoggingException('Handler failed on purpose.');
        }
    }

    private class ErrorsLoggingMutedFailingAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.ContinueOnError {
        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            throw new ErrorsLoggingException('Handler failed on purpose.');
        }
    }

    private class ErrorsLoggingCountingPopulator implements BeforeInsert.Populator {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
        }
    }

    private class ErrorsLoggingFailingPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            throw new ErrorsLoggingException('Populator failed on purpose.');
        }
    }

    private class ErrorsLoggingMutedDmlPopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            insert new Case(Subject = 'Errors logging guard');
        }
    }

    private class ErrorsLoggingMutedNestedRunPopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        private Object nestedOrchestrator;

        public ErrorsLoggingMutedNestedRunPopulator(Object nestedOrchestrator) {
            this.nestedOrchestrator = nestedOrchestrator;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            TriggerOrchestrator orchestratorRunner3 = new TriggerOrchestrator(this.nestedOrchestrator);
            orchestratorRunner3.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner3.context.newRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
            orchestratorRunner3.run();
        }
    }

    private class ErrorsLoggingMutedRecordApiPopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            throw new TriggerHandler.TriggerHandlerException('Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.');
        }
    }

    private class DmlGuardBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        private DmlGuardBeforeInsertOrchestrator(BeforeInsert.Handler handler) {
            this.handlers = new List<BeforeInsert.Handler>{ handler };
        }

        private DmlGuardBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        private DmlGuardBeforeUpdateOrchestrator(BeforeUpdate.Handler handler) {
            this.handlers = new List<BeforeUpdate.Handler>{ handler };
        }

        private DmlGuardBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        private DmlGuardAfterInsertOrchestrator(AfterInsert.Handler handler) {
            this.handlers = new List<AfterInsert.Handler>{ handler };
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        private DmlGuardAfterUpdateOrchestrator(AfterUpdate.Handler handler) {
            this.handlers = new List<AfterUpdate.Handler>{ handler };
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        private List<BeforeDelete.Handler> handlers;

        private DmlGuardBeforeDeleteOrchestrator(BeforeDelete.Handler handler) {
            this.handlers = new List<BeforeDelete.Handler>{ handler };
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        private DmlGuardAfterDeleteOrchestrator(AfterDelete.Handler handler) {
            this.handlers = new List<AfterDelete.Handler>{ handler };
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        private List<AfterUndelete.Handler> handlers;

        private DmlGuardAfterUndeleteOrchestrator(AfterUndelete.Handler handler) {
            this.handlers = new List<AfterUndelete.Handler>{ handler };
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlers;
        }
    }

    private class DmlGuardService {
        private void insertGuardAccount() {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardInsertPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardInsertValidator implements BeforeInsert.Validator {
        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            insert new Account(Name = 'Guard');
            return 'Contact is not allowed.';
        }
    }

    private class DmlGuardInsertFinalizer implements BeforeInsert.Populator, BeforeInsert.Finalizer {
        public Boolean isFinalized = false;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            record.put(Contact.Department, 'Guard');
        }

        public void finalizeBeforeInsert() {
            this.isFinalized = true;
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardInsertQualifier implements BeforeInsert.Populator {
        public Integer populateCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            insert new Account(Name = 'Guard');
            return false;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.populateCount++;
        }
    }

    private class DmlGuardInsertServicePopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            new DmlGuardService().insertGuardAccount();
        }
    }

    private class DmlGuardInsertSilentPopulator implements BeforeInsert.Populator {
        public Integer populateCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.populateCount++;
            record.put(Contact.Department, 'Guard');
        }
    }

    private class DmlGuardInsertContinuePopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardInsertContinueThrowingPopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            insert new Account(Name = 'Guard');
            throw new DmlGuardHandlerException('Handler failed.');
        }
    }

    private class DmlGuardInsertContinueFailingPopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Boolean hasThrown = false;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.hasThrown = true;
            throw new DmlGuardHandlerException('Handler failed.');
        }
    }

    private class DmlGuardUpdatePopulator implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardUpdateValidator implements BeforeUpdate.Validator {
        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            insert new Account(Name = 'Guard');
            return 'Contact is not allowed.';
        }
    }

    private class DmlGuardUpdateFinalizer implements BeforeUpdate.Populator, BeforeUpdate.Finalizer {
        public Boolean isFinalized = false;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            record.put(Contact.Department, 'Guard');
        }

        public void finalizeBeforeUpdate() {
            this.isFinalized = true;
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardUpdateQualifier implements BeforeUpdate.Populator {
        public Integer populateCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            insert new Account(Name = 'Guard');
            return false;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.populateCount++;
        }
    }

    private class DmlGuardUpdateStatementPopulator implements BeforeUpdate.Populator {
        private Account accountToUpdate;

        private DmlGuardUpdateStatementPopulator(Account accountToUpdate) {
            this.accountToUpdate = accountToUpdate;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.accountToUpdate.Rating = 'Warm';
            update this.accountToUpdate;
        }
    }

    private class DmlGuardUpdateSilentPopulator implements BeforeUpdate.Populator {
        public Integer populateCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.populateCount++;
            record.put(Contact.Department, 'Guard');
        }
    }

    private class DmlGuardUpdateContinuePopulator implements BeforeUpdate.Populator, BeforeUpdate.ContinueOnError {
        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardUpdateContinueThrowingPopulator implements BeforeUpdate.Populator, BeforeUpdate.ContinueOnError {
        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            insert new Account(Name = 'Guard');
            throw new DmlGuardHandlerException('Handler failed.');
        }
    }

    private class DmlGuardUpdateContinueFailingPopulator implements BeforeUpdate.Populator, BeforeUpdate.ContinueOnError {
        public Boolean hasThrown = false;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.hasThrown = true;
            throw new DmlGuardHandlerException('Handler failed.');
        }
    }

    private class DmlGuardAfterInsertHandler implements AfterInsert.Handler {
        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardAfterInsertFinalizer implements AfterInsert.Handler, AfterInsert.Finalizer {
        public Boolean isFinalized = false;
        public Integer handledCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.handledCount++;
        }

        public void finalizeAfterInsert() {
            this.isFinalized = true;
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardAfterUpdateHandler implements AfterUpdate.Handler {
        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardAfterDeleteHandler implements AfterDelete.Handler {
        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardAfterUndeleteHandler implements AfterUndelete.Handler {
        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardBeforeDeleteHandler implements BeforeDelete.Handler {
        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            insert new Account(Name = 'Guard');
        }
    }

    private class DmlGuardHandlerException extends Exception {
    }

    private class ShapesFakeIds {
        private final String keyPrefix = Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix();
        private Integer counter = 0;

        public Id next() {
            this.counter++;
            return Id.valueOf(this.keyPrefix + String.valueOf(this.counter).leftPad(12, '0'));
        }
    }

    private class ShapesSharedState {
        public List<String> events = new List<String>();
        public Set<Id> processedIds = new Set<Id>();
        public Integer processedCount = 0;
        public Integer finalizeCount = 0;
    }

    private class ShapesBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public ShapesBeforeInsertOrchestrator(BeforeInsert.Handler handler) {
            this.handlers = new List<BeforeInsert.Handler>{ handler };
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class ShapesAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public ShapesAfterInsertOrchestrator(AfterInsert.Handler handler) {
            this.handlers = new List<AfterInsert.Handler>{ handler };
        }

        public ShapesAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class ShapesBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public ShapesBeforeUpdateOrchestrator(BeforeUpdate.Handler handler) {
            this.handlers = new List<BeforeUpdate.Handler>{ handler };
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class ShapesAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public ShapesAfterUpdateOrchestrator(AfterUpdate.Handler handler) {
            this.handlers = new List<AfterUpdate.Handler>{ handler };
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class ShapesBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        private List<BeforeDelete.Handler> handlers;

        public ShapesBeforeDeleteOrchestrator(BeforeDelete.Handler handler) {
            this.handlers = new List<BeforeDelete.Handler>{ handler };
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlers;
        }
    }

    private class ShapesAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        public ShapesAfterDeleteOrchestrator(AfterDelete.Handler handler) {
            this.handlers = new List<AfterDelete.Handler>{ handler };
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class ShapesAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        private List<AfterUndelete.Handler> handlers;

        public ShapesAfterUndeleteOrchestrator(AfterUndelete.Handler handler) {
            this.handlers = new List<AfterUndelete.Handler>{ handler };
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlers;
        }
    }

    private class ShapesBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.Finalizer {
        public Boolean qualifies = true;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;
        public List<Id> recordIds = new List<Id>();
        public List<SObject> newRecords = new List<SObject>();
        public List<SObject> oldRecords = new List<SObject>();

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.qualifies;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.actionCount++;
            this.recordIds.add(record.getId());
            this.newRecords.add(record.getNewSObject());
            this.oldRecords.add(((TriggerHandler.UpdateRecord) record).getOldSObject());
            record.put(Contact.Description, 'Populated');
        }

        public void finalizeBeforeInsert() {
            this.finalizeCount++;
        }
    }

    private class ShapesBeforeInsertValidator implements BeforeInsert.Validator, BeforeInsert.Finalizer {
        public Boolean qualifies = true;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return this.qualifies;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.actionCount++;
            return 'Record is not allowed.';
        }

        public void finalizeBeforeInsert() {
            this.finalizeCount++;
        }
    }

    private class ShapesAfterInsertHandler implements AfterInsert.Handler, AfterInsert.Finalizer {
        public Boolean qualifies = true;
        public String qualifyingLeadSource = null;
        public Integer qualifyCount = 0;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;
        public List<String> events = new List<String>();
        public List<Id> recordIds = new List<Id>();
        public List<SObject> newRecords = new List<SObject>();
        public List<SObject> oldRecords = new List<SObject>();

        private String name;
        private ShapesSharedState state;

        public ShapesAfterInsertHandler() {
            this.name = 'Handler';
            this.state = new ShapesSharedState();
        }

        public ShapesAfterInsertHandler(String name, ShapesSharedState state) {
            this.name = name;
            this.state = state;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;

            if (this.qualifyingLeadSource != null) {
                return record.equals(Contact.LeadSource, this.qualifyingLeadSource);
            }

            return this.qualifies;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.actionCount++;
            this.events.add('record');
            this.recordIds.add(record.getId());
            this.newRecords.add(record.getNewSObject());
            this.oldRecords.add(((TriggerHandler.UpdateRecord) record).getOldSObject());

            this.state.processedCount++;
            this.state.processedIds.add(record.getId());
            this.state.events.add(this.name + ' record');
        }

        public void finalizeAfterInsert() {
            this.finalizeCount++;
            this.events.add('finalize');

            this.state.finalizeCount++;
            this.state.events.add(this.name + ' finalize');
        }
    }

    private class ShapesBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.Finalizer {
        public Boolean qualifies = true;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.qualifies;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.actionCount++;
        }

        public void finalizeBeforeUpdate() {
            this.finalizeCount++;
        }
    }

    private class ShapesBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.Finalizer {
        public Boolean qualifies = true;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.qualifies;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.actionCount++;
            return 'Record is not allowed.';
        }

        public void finalizeBeforeUpdate() {
            this.finalizeCount++;
        }
    }

    private class ShapesGuardedBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.Finalizer, BeforeUpdate.RecursionGuard {
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;

        private Integer maxRecursionDepth;

        public ShapesGuardedBeforeUpdatePopulator(Integer maxRecursionDepth) {
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepthOnBeforeUpdate() {
            return this.maxRecursionDepth;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.actionCount++;
        }

        public void finalizeBeforeUpdate() {
            this.finalizeCount++;
        }
    }

    private class ShapesAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.Finalizer {
        public Boolean qualifies = true;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;
        public List<Id> recordIds = new List<Id>();
        public List<SObject> newRecords = new List<SObject>();
        public List<SObject> oldRecords = new List<SObject>();

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return this.qualifies;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.actionCount++;
            this.recordIds.add(record.getId());
            this.newRecords.add(record.getNewSObject());
            this.oldRecords.add(record.getOldSObject());
        }

        public void finalizeAfterUpdate() {
            this.finalizeCount++;
        }
    }

    private class ShapesBeforeDeleteHandler implements BeforeDelete.Handler, BeforeDelete.Finalizer {
        public Boolean qualifies = true;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;
        public List<SObject> newRecords = new List<SObject>();
        public List<SObject> oldRecords = new List<SObject>();

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return this.qualifies;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.actionCount++;
            this.newRecords.add(((TriggerHandler.UpdateRecord) record).getNewSObject());
            this.oldRecords.add(record.getOldSObject());
        }

        public void finalizeBeforeDelete() {
            this.finalizeCount++;
        }
    }

    private class ShapesAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.Finalizer {
        public Boolean qualifies = true;
        public String qualifyingLeadSource = null;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;
        public List<Id> recordIds = new List<Id>();
        public List<SObject> newRecords = new List<SObject>();
        public List<SObject> oldRecords = new List<SObject>();

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            if (this.qualifyingLeadSource != null) {
                return record.equals(Contact.LeadSource, this.qualifyingLeadSource);
            }

            return this.qualifies;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.actionCount++;
            this.recordIds.add(record.getId());
            this.newRecords.add(((TriggerHandler.UpdateRecord) record).getNewSObject());
            this.oldRecords.add(record.getOldSObject());
        }

        public void finalizeAfterDelete() {
            this.finalizeCount++;
        }
    }

    private class ShapesAfterUndeleteHandler implements AfterUndelete.Handler, AfterUndelete.Finalizer {
        public Boolean qualifies = true;
        public String qualifyingLeadSource = null;
        public Integer actionCount = 0;
        public Integer finalizeCount = 0;
        public List<Id> recordIds = new List<Id>();
        public List<SObject> newRecords = new List<SObject>();
        public List<SObject> oldRecords = new List<SObject>();

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            if (this.qualifyingLeadSource != null) {
                return record.equals(Contact.LeadSource, this.qualifyingLeadSource);
            }

            return this.qualifies;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.actionCount++;
            this.recordIds.add(record.getId());
            this.newRecords.add(record.getNewSObject());
            this.oldRecords.add(((TriggerHandler.UpdateRecord) record).getOldSObject());
        }

        public void finalizeAfterUndelete() {
            this.finalizeCount++;
        }
    }

    private class ShapesPuttingAfterDeleteHandler implements AfterDelete.Handler {
        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            ((TriggerHandler.UpdateRecord) record).put(Contact.Description, 'Written after delete');
        }
    }

    private class ShapesPuttingBeforeDeleteHandler implements BeforeDelete.Handler {
        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            ((TriggerHandler.UpdateRecord) record).put(Contact.Description, 'Written before delete');
        }
    }

    private class GapMetadataBypassBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public GapMetadataBypassBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public GapMetadataBypassAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public GapMetadataBypassBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public GapMetadataBypassAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        private List<BeforeDelete.Handler> handlers;

        public GapMetadataBypassBeforeDeleteOrchestrator(List<BeforeDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        public GapMetadataBypassAfterDeleteOrchestrator(List<AfterDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        private List<AfterUndelete.Handler> handlers;

        public GapMetadataBypassAfterUndeleteOrchestrator(List<AfterUndelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapMetadataBypassMutedInsertPopulator implements BeforeInsert.Populator {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveInsertPopulator implements BeforeInsert.Populator {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassMutedInsertValidator implements BeforeInsert.Validator {
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.messageCount++;
            return 'Muted before insert validation';
        }
    }

    private class GapMetadataBypassLiveInsertValidator implements BeforeInsert.Validator {
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.messageCount++;
            return 'Live before insert validation';
        }
    }

    private class GapMetadataBypassMutedAfterInsertHandler implements AfterInsert.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveAfterInsertHandler implements AfterInsert.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassMutedUpdatePopulator implements BeforeUpdate.Populator {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveUpdatePopulator implements BeforeUpdate.Populator {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassMutedUpdateValidator implements BeforeUpdate.Validator {
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.messageCount++;
            return 'Muted before update validation';
        }
    }

    private class GapMetadataBypassLiveUpdateValidator implements BeforeUpdate.Validator {
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.messageCount++;
            return 'Live before update validation';
        }
    }

    private class GapMetadataBypassDottedNameValidator implements BeforeUpdate.Validator {
        public Integer qualifyCount = 0;
        public Integer messageCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.messageCount++;
            return 'Dotted name before update validation';
        }
    }

    private class GapMetadataBypassMutedAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassMutedBeforeDeleteHandler implements BeforeDelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveBeforeDeleteHandler implements BeforeDelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassMutedAfterDeleteHandler implements AfterDelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveAfterDeleteHandler implements AfterDelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassMutedAfterUndeleteHandler implements AfterUndelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.runCount++;
        }
    }

    private class GapMetadataBypassLiveAfterUndeleteHandler implements AfterUndelete.Handler {
        public Integer qualifyCount = 0;
        public Integer runCount = 0;

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            this.qualifyCount++;
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.runCount++;
        }
    }

    private class GapEnrichmentBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public GapEnrichmentBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public GapEnrichmentAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public GapEnrichmentBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public GapEnrichmentAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        private List<BeforeDelete.Handler> handlers;

        public GapEnrichmentBeforeDeleteOrchestrator(List<BeforeDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        public GapEnrichmentAfterDeleteOrchestrator(List<AfterDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        private List<AfterUndelete.Handler> handlers;

        public GapEnrichmentAfterUndeleteOrchestrator(List<AfterUndelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapEnrichmentBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            Account parent = (Account) record.getNewParent('Account');

            this.seenNewParents.add(parent);
            record.put(Contact.Department, parent?.Name);
        }
    }

    private class GapEnrichmentBeforeInsertValidator implements BeforeInsert.Validator, BeforeInsert.ParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            Account parent = (Account) record.getNewParent('Account');

            return 'Account ' + parent?.Name + ' does not accept new contacts.';
        }
    }

    private class GapEnrichmentBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            this.seenOldParents.add(record.getOldParent('Account'));
        }
    }

    private class GapEnrichmentBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            this.seenOldParents.add(record.getOldParent('Account'));
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            Account parent = (Account) record.getNewParent('Account');

            return 'Account ' + parent?.Name + ' is locked.';
        }
    }

    private class GapEnrichmentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.ParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
        }
    }

    private class GapEnrichmentAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();
        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
            this.seenOldParents.add(record.getOldParent('Account'));
        }
    }

    private class GapEnrichmentBeforeDeleteHandler implements BeforeDelete.Handler, BeforeDelete.PriorParentQuery {
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeDelete() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.seenOldParents.add(record.getOldParent('Account'));
        }
    }

    private class GapEnrichmentAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.PriorParentQuery {
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> oldDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareOld(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterDelete() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.seenOldParents.add(record.getOldParent('Account'));
        }
    }

    private class GapEnrichmentAfterUndeleteHandler implements AfterUndelete.Handler, AfterUndelete.ParentQuery {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUndelete() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.seenNewParents.add(record.getNewParent('Account'));
        }
    }

    private class GapContinueOnErrorException extends Exception {
    }

    private class GapContinueOnErrorBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public GapContinueOnErrorBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public GapContinueOnErrorAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public GapContinueOnErrorBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public GapContinueOnErrorAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        private List<BeforeDelete.Handler> handlers;

        public GapContinueOnErrorBeforeDeleteOrchestrator(List<BeforeDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        public GapContinueOnErrorAfterDeleteOrchestrator(List<AfterDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        private List<AfterUndelete.Handler> handlers;

        public GapContinueOnErrorAfterUndeleteOrchestrator(List<AfterUndelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlers;
        }
    }

    private class GapContinueOnErrorMutedBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before insert populator failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingBeforeInsertPopulator implements BeforeInsert.Populator {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before insert populator failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingBeforeInsertPopulator implements BeforeInsert.Populator {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
        }
    }

    private class GapContinueOnErrorMutedBeforeInsertValidator implements BeforeInsert.Validator, BeforeInsert.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before insert validator failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingBeforeInsertValidator implements BeforeInsert.Validator {
        public Integer executionCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before insert validator failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingBeforeInsertValidator implements BeforeInsert.Validator {
        public Integer executionCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            return 'Record is not allowed.';
        }
    }

    private class GapContinueOnErrorMutedAfterInsertHandler implements AfterInsert.Handler, AfterInsert.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After insert handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingAfterInsertHandler implements AfterInsert.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After insert handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingAfterInsertHandler implements AfterInsert.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.executionCount++;
        }
    }

    private class GapContinueOnErrorMutedBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before update populator failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingBeforeUpdatePopulator implements BeforeUpdate.Populator {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before update populator failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingBeforeUpdatePopulator implements BeforeUpdate.Populator {
        public Integer executionCount = 0;

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
        }
    }

    private class GapContinueOnErrorMutedBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before update validator failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingBeforeUpdateValidator implements BeforeUpdate.Validator {
        public Integer executionCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before update validator failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingBeforeUpdateValidator implements BeforeUpdate.Validator {
        public Integer executionCount = 0;

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            return 'Record is not allowed.';
        }
    }

    private class GapContinueOnErrorMutedAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After update handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After update handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingAfterUpdateHandler implements AfterUpdate.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.executionCount++;
        }
    }

    private class GapContinueOnErrorMutedBeforeDeleteHandler implements BeforeDelete.Handler, BeforeDelete.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before delete handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingBeforeDeleteHandler implements BeforeDelete.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('Before delete handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingBeforeDeleteHandler implements BeforeDelete.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.executionCount++;
        }
    }

    private class GapContinueOnErrorMutedAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After delete handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingAfterDeleteHandler implements AfterDelete.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After delete handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingAfterDeleteHandler implements AfterDelete.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.executionCount++;
        }
    }

    private class GapContinueOnErrorMutedAfterUndeleteHandler implements AfterUndelete.Handler, AfterUndelete.ContinueOnError {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After undelete handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorFailingAfterUndeleteHandler implements AfterUndelete.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.executionCount++;
            throw new GapContinueOnErrorException('After undelete handler failed on purpose.');
        }
    }

    private class GapContinueOnErrorCountingAfterUndeleteHandler implements AfterUndelete.Handler {
        public Integer executionCount = 0;

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.executionCount++;
        }
    }

    private class DispatchNonOrchestrator {
    }

    private class LazySilentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.ParentQuery {
        public Integer runCount = 0;
        public Boolean readsParent = false;
        public SObject seenParent;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.runCount++;

            if (this.readsParent) {
                this.seenParent = record.getNewParent('Account');
            }
        }
    }

    private class LazySilentBeforeUpdateHandler implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery {
        public String relationshipToRead;
        public SObject seenParent;

        private Map<SObjectField, TriggerHandler.ParentFields> newDeclaration = new Map<SObjectField, TriggerHandler.ParentFields>();

        public void declareNew(SObjectField parentField, TriggerHandler.ParentFields fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate() {
            return this.newDeclaration;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.seenParent = record.getNewParent(this.relationshipToRead);
            return false;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        }
    }

    private static Integer relatedPooledQueries = 0;

    private class RelatedPooledProvider implements BeforeInsert.RecordsProvider {
        private String label;

        public RelatedPooledProvider(String label) {
            this.label = label;
        }

        public List<SObject> query(TriggerHandler.InsertRecords records) {
            TriggerOrchestratorTest.relatedPooledQueries++;
            return new List<SObject>{ new Contact(LastName = this.label) };
        }

        public String keyOf(SObject record) {
            return (String) record.get('LastName');
        }
    }

    private class RelatedException extends Exception {
    }

    private class RelatedBeforeInsertOrchestrator implements TriggerOrchestrator.BeforeInsert {
        private List<BeforeInsert.Handler> handlers;

        public RelatedBeforeInsertOrchestrator(List<BeforeInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.handlers;
        }
    }

    private class RelatedAfterInsertOrchestrator implements TriggerOrchestrator.AfterInsert {
        private List<AfterInsert.Handler> handlers;

        public RelatedAfterInsertOrchestrator(List<AfterInsert.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterInsert.Handler> afterInsertHandlers() {
            return this.handlers;
        }
    }

    private class RelatedBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        private List<BeforeUpdate.Handler> handlers;

        public RelatedBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.handlers;
        }
    }

    private class RelatedAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate {
        private List<AfterUpdate.Handler> handlers;

        public RelatedAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return this.handlers;
        }
    }

    private class RelatedBeforeDeleteOrchestrator implements TriggerOrchestrator.BeforeDelete {
        private List<BeforeDelete.Handler> handlers;

        public RelatedBeforeDeleteOrchestrator(List<BeforeDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<BeforeDelete.Handler> beforeDeleteHandlers() {
            return this.handlers;
        }
    }

    private class RelatedAfterDeleteOrchestrator implements TriggerOrchestrator.AfterDelete {
        private List<AfterDelete.Handler> handlers;

        public RelatedAfterDeleteOrchestrator(List<AfterDelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.handlers;
        }
    }

    private class RelatedAfterUndeleteOrchestrator implements TriggerOrchestrator.AfterUndelete {
        private List<AfterUndelete.Handler> handlers;

        public RelatedAfterUndeleteOrchestrator(List<AfterUndelete.Handler> handlers) {
            this.handlers = handlers;
        }

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.handlers;
        }
    }

    private class RelatedCountingProvider implements BeforeInsert.RecordsProvider, AfterInsert.RecordsProvider, BeforeUpdate.RecordsProvider, AfterUpdate.RecordsProvider, BeforeDelete.RecordsProvider, AfterDelete.RecordsProvider, AfterUndelete.RecordsProvider {
        public Integer loadCount = 0;
        public Integer lastRecordCount = 0;
        public List<Integer> recordCounts = new List<Integer>();
        private List<SObject> recordsToReturn;

        public RelatedCountingProvider(List<SObject> recordsToReturn) {
            this.recordsToReturn = recordsToReturn;
        }

        public List<SObject> query(TriggerHandler.InsertRecords records) {
            return this.queried(records.size());
        }

        public List<SObject> query(TriggerHandler.UpdateRecords records) {
            return this.queried(records.size());
        }

        public List<SObject> query(TriggerHandler.DeleteRecords records) {
            return this.queried(records.size());
        }

        public List<SObject> query(TriggerHandler.UndeleteRecords records) {
            return this.queried(records.size());
        }

        public String keyOf(SObject record) {
            return (String) record.get('LastName');
        }

        private List<SObject> queried(Integer recordCount) {
            this.loadCount++;
            this.lastRecordCount = recordCount;
            this.recordCounts.add(recordCount);
            return this.recordsToReturn;
        }
    }

    private class RelatedFailingProvider implements BeforeInsert.RecordsProvider {
        public List<SObject> query(TriggerHandler.InsertRecords records) {
            throw new RelatedException('Provider failed on purpose.');
        }

        public String keyOf(SObject record) {
            return record.Id;
        }
    }

    private class RelatedDmlProvider implements BeforeInsert.RecordsProvider {
        public List<SObject> query(TriggerHandler.InsertRecords records) {
            insert new Account(Name = 'Guard');
            return new List<SObject>();
        }

        public String keyOf(SObject record) {
            return record.Id;
        }
    }

    private class RelatedTwoHopProvider implements BeforeInsert.RecordsProvider {
        private Set<Id> accountIds;

        public RelatedTwoHopProvider(Set<Id> accountIds) {
            this.accountIds = accountIds;
        }

        public List<SObject> query(TriggerHandler.InsertRecords records) {
            Set<Id> foundAccountIds = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :this.accountIds]).keySet();
            return [SELECT Id, AccountId FROM Contact WHERE AccountId IN :foundAccountIds];
        }

        public String keyOf(SObject record) {
            return ((Contact) record).AccountId;
        }
    }

    private class RelatedPeekingProvider implements BeforeInsert.RecordsProvider {
        private RelatedPeekingBeforeInsertPopulator owner;

        public RelatedPeekingProvider(RelatedPeekingBeforeInsertPopulator owner) {
            this.owner = owner;
        }

        public List<SObject> query(TriggerHandler.InsertRecords records) {
            try {
                records.getRecords()[0].getRelated('related');
            } catch (TriggerHandler.TriggerHandlerException e) {
                this.owner.previousProviderReachableInQuery = false;
            }

            return new List<SObject>();
        }

        public String keyOf(SObject record) {
            return record.Id;
        }
    }

    private class RelatedEnrichedProvider implements BeforeInsert.RecordsProvider {
        private RelatedEnrichedBeforeInsertPopulator owner;

        public RelatedEnrichedProvider(RelatedEnrichedBeforeInsertPopulator owner) {
            this.owner = owner;
        }

        public List<SObject> query(TriggerHandler.InsertRecords records) {
            this.owner.parentNamesSeenInQuery = records.getValuesOf('Account', Account.Name);
            return new List<SObject>();
        }

        public String keyOf(SObject record) {
            return record.Id;
        }
    }

    private class RelatedBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.RelatedQuery, BeforeInsert.Finalizer, BeforeInsert.Bypassable {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        public Boolean bypass = false;
        public Boolean qualify = true;
        public Boolean returnNull = false;
        public Boolean throwInHook = false;
        public Boolean readProviders = true;
        private RelatedCountingProvider countingProvider;
        private BeforeInsert.RecordsProvider provider;
        private TriggerHandler.InsertRecord lastRecord;

        public RelatedBeforeInsertPopulator(BeforeInsert.RecordsProvider provider) {
            this.provider = provider;
            if (provider instanceof RelatedCountingProvider) {
                this.countingProvider = (RelatedCountingProvider) provider;
            }
        }

        public Boolean bypassOnBeforeInsertWhen() {
            return this.bypass;
        }

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            this.hookCount++;

            if (this.throwInHook) {
                throw new RelatedException('Hook failed on purpose.');
            }

            if (this.returnNull) {
                return null;
            }

            return new Map<String, BeforeInsert.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            if (this.loadCountAtFirstPredicate == null && this.countingProvider != null) {
                this.loadCountAtFirstPredicate = this.countingProvider.loadCount;
            }

            if (this.readProviders) {
                record.getRelated('related').getRecords();
                this.predicateReads++;
            }

            this.lastRecord = record;
            return this.qualify;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            if (this.readProviders) {
                record.getRelated('related').getRecords();
                this.actionReads++;
            }
        }

        public void finalizeBeforeInsert() {
            if (this.readProviders) {
                this.lastRecord.getRelated('related').getRecords();
                this.finalizerReads++;
            }
        }
    }

    private class RelatedMutedBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.RelatedQuery, BeforeInsert.ContinueOnError {
        public Integer predicateReads = 0;
        private BeforeInsert.RecordsProvider provider;

        public RelatedMutedBeforeInsertPopulator(BeforeInsert.RecordsProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.predicateReads++;
            record.getRelated('related').getRecords();
            return false;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        }
    }

    private class RelatedReaderBeforeInsertPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            record.getRelated('related');
            return false;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        }
    }

    private class RelatedPeekingBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.RelatedQuery {
        public Boolean previousProviderReachableInQuery = true;
        public Boolean previousProviderReachableInPredicate = true;
        public Boolean ownProviderReachableInPredicate = false;

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'own' => new RelatedPeekingProvider(this) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            try {
                record.getRelated('related');
            } catch (TriggerHandler.TriggerHandlerException e) {
                this.previousProviderReachableInPredicate = false;
            }

            this.ownProviderReachableInPredicate = record.getRelated('own').getRecords() != null;
            return false;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        }
    }

    private class RelatedEnrichedBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery, BeforeInsert.RelatedQuery {
        public Set<String> parentNamesSeenInQuery = new Set<String>();

        public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert() {
            return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
        }

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'parents' => new RelatedEnrichedProvider(this) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            record.getRelated('parents').getRecords();
            return false;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        }
    }

    private class RelatedGuardedBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.RelatedQuery, BeforeUpdate.RecursionGuard {
        public Integer hookCount = 0;
        public Integer actionCount = 0;
        private BeforeUpdate.RecordsProvider provider;

        public RelatedGuardedBeforeUpdatePopulator(BeforeUpdate.RecordsProvider provider) {
            this.provider = provider;
        }

        public Integer maxRecursionDepthOnBeforeUpdate() {
            return 1;
        }

        public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
            this.hookCount++;
            return new Map<String, BeforeUpdate.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            record.getRelated('related').getRecords();
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.actionCount++;
        }
    }

    private class RelatedBeforeInsertValidator implements BeforeInsert.Validator, BeforeInsert.RelatedQuery, BeforeInsert.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.InsertRecord lastRecord;

        public RelatedBeforeInsertValidator(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            this.hookCount++;
            return new Map<String, BeforeInsert.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
            return 'blocked';
        }

        public void finalizeBeforeInsert() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedAfterInsertHandler implements AfterInsert.Handler, AfterInsert.RelatedQuery, AfterInsert.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.InsertRecord lastRecord;

        public RelatedAfterInsertHandler(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert() {
            this.hookCount++;
            return new Map<String, AfterInsert.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
        }

        public void finalizeAfterInsert() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.RelatedQuery, BeforeUpdate.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.UpdateRecord lastRecord;

        public RelatedBeforeUpdatePopulator(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
            this.hookCount++;
            return new Map<String, BeforeUpdate.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
        }

        public void finalizeBeforeUpdate() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.RelatedQuery, BeforeUpdate.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.UpdateRecord lastRecord;

        public RelatedBeforeUpdateValidator(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
            this.hookCount++;
            return new Map<String, BeforeUpdate.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
            return 'blocked';
        }

        public void finalizeBeforeUpdate() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.RelatedQuery, AfterUpdate.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.UpdateRecord lastRecord;

        public RelatedAfterUpdateHandler(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
            this.hookCount++;
            return new Map<String, AfterUpdate.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
        }

        public void finalizeAfterUpdate() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedBeforeDeleteHandler implements BeforeDelete.Handler, BeforeDelete.RelatedQuery, BeforeDelete.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.DeleteRecord lastRecord;

        public RelatedBeforeDeleteHandler(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
            this.hookCount++;
            return new Map<String, BeforeDelete.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
        }

        public void finalizeBeforeDelete() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.RelatedQuery, AfterDelete.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.DeleteRecord lastRecord;

        public RelatedAfterDeleteHandler(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete() {
            this.hookCount++;
            return new Map<String, AfterDelete.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
        }

        public void finalizeAfterDelete() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }

    private class RelatedAfterUndeleteHandler implements AfterUndelete.Handler, AfterUndelete.RelatedQuery, AfterUndelete.Finalizer {
        public Integer hookCount = 0;
        public Integer loadCountAtFirstPredicate;
        public Integer predicateReads = 0;
        public Integer actionReads = 0;
        public Integer finalizerReads = 0;
        private RelatedCountingProvider provider;
        private TriggerHandler.UndeleteRecord lastRecord;

        public RelatedAfterUndeleteHandler(RelatedCountingProvider provider) {
            this.provider = provider;
        }

        public Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete() {
            this.hookCount++;
            return new Map<String, AfterUndelete.RecordsProvider>{ 'related' => this.provider };
        }

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            if (this.loadCountAtFirstPredicate == null) {
                this.loadCountAtFirstPredicate = this.provider.loadCount;
            }

            record.getRelated('related').getRecords();
            this.predicateReads++;
            this.lastRecord = record;
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            record.getRelated('related').getRecords();
            this.actionReads++;
        }

        public void finalizeAfterUndelete() {
            this.lastRecord.getRelated('related').getRecords();
            this.finalizerReads++;
        }
    }
}
