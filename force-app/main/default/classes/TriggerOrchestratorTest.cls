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

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Contact firstHandledNewRecord = (Contact) orchestrator.beforeInsertHandler.handledNewRecords[0];
        Contact secondHandledNewRecord = (Contact) orchestrator.beforeInsertHandler.handledNewRecords[1];
        Assert.areEqual(
            new List<String>{ 'beforeInsertHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be beforeInsertHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.beforeInsertHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.beforeInsertHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual('Doe', firstHandledNewRecord.LastName, 'It should be Doe, because records reach the handler in the order the trigger set holds them.');
        Assert.areEqual('Legal', secondHandledNewRecord.Department, 'It should be Legal, because getNewSObject() exposes the record being inserted with the values it carries.');
        Assert.isNull(
            orchestrator.beforeInsertHandler.handledIds[0],
            'It should be null, because an insert context has no old side and the new record has no id before it is saved.'
        );
    }

    @IsTest
    static void dispatchAfterInsertRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Doe'), new Contact(Id = secondContactId, LastName = 'Roe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'afterInsertHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be afterInsertHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.afterInsertHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.afterInsertHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual(
            'Doe',
            ((Contact) orchestrator.afterInsertHandler.handledNewRecords[0]).LastName,
            'It should be Doe, because an insert context dispatches the inserted row as the new side of the trigger record.'
        );
        Assert.areEqual(
            newRecords[1].Id,
            orchestrator.afterInsertHandler.handledIds[1],
            'It should be the id of the second inserted record, because getId() reads the new side once the record has been saved.'
        );
    }

    @IsTest
    static void dispatchBeforeUpdateRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'New One'), new Contact(Id = secondContactId, LastName = 'New Two') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Old One'), new Contact(Id = secondContactId, LastName = 'Old Two') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Contact firstHandledNewRecord = (Contact) orchestrator.beforeUpdateHandler.handledNewRecords[0];
        Contact firstHandledOldRecord = (Contact) orchestrator.beforeUpdateHandler.handledOldRecords[0];
        Contact secondHandledOldRecord = (Contact) orchestrator.beforeUpdateHandler.handledOldRecords[1];
        Assert.areEqual(
            new List<String>{ 'beforeUpdateHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be beforeUpdateHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.beforeUpdateHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.beforeUpdateHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual('New One', firstHandledNewRecord.LastName, 'It should be New One, because an update context dispatches the incoming version as the new side.');
        Assert.areEqual(
            'Old One',
            firstHandledOldRecord.LastName,
            'It should be Old One, because an update context pairs each new record with the stored version at the same index.'
        );
        Assert.areEqual('Old Two', secondHandledOldRecord.LastName, 'It should be Old Two, because the pairing of the new and old sides follows the trigger record order.');
    }

    @IsTest
    static void dispatchAfterUpdateRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'New One'), new Contact(Id = secondContactId, LastName = 'New Two') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Old One'), new Contact(Id = secondContactId, LastName = 'Old Two') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'afterUpdateHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be afterUpdateHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.afterUpdateHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.afterUpdateHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual(
            'New Two',
            ((Contact) orchestrator.afterUpdateHandler.handledNewRecords[1]).LastName,
            'It should be New Two, because an update context dispatches the saved version as the new side.'
        );
        Assert.areEqual(
            'Old Two',
            ((Contact) orchestrator.afterUpdateHandler.handledOldRecords[1]).LastName,
            'It should be Old Two, because an update context pairs each new record with the stored version at the same index.'
        );
        Assert.areEqual(
            newRecords[1].Id,
            orchestrator.afterUpdateHandler.handledIds[1],
            'It should be the id of the second updated record, because getId() reads the new side of the trigger record.'
        );
    }

    @IsTest
    static void dispatchBeforeDeleteRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'Deleted One', Department = 'Sales'),
            new Contact(Id = secondContactId, LastName = 'Deleted Two', Department = 'Legal')
        };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Contact firstHandledOldRecord = (Contact) orchestrator.beforeDeleteHandler.handledOldRecords[0];
        Contact secondHandledOldRecord = (Contact) orchestrator.beforeDeleteHandler.handledOldRecords[1];
        Assert.areEqual(
            new List<String>{ 'beforeDeleteHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be beforeDeleteHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.beforeDeleteHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.beforeDeleteHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual('Deleted One', firstHandledOldRecord.LastName, 'It should be Deleted One, because a delete context builds the trigger record from the deleted row alone.');
        Assert.areEqual('Legal', secondHandledOldRecord.Department, 'It should be Legal, because getOldSObject() exposes the row about to be deleted with the values it holds.');
        Assert.areEqual(
            oldRecords[1].Id,
            orchestrator.beforeDeleteHandler.handledIds[1],
            'It should be the id of the second deleted record, because getId() falls back to the old side when there is no new record.'
        );
    }

    @IsTest
    static void dispatchAfterDeleteRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'Deleted One', Department = 'Sales'),
            new Contact(Id = secondContactId, LastName = 'Deleted Two', Department = 'Legal')
        };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Contact secondHandledOldRecord = (Contact) orchestrator.afterDeleteHandler.handledOldRecords[1];
        Contact firstHandledOldRecord = (Contact) orchestrator.afterDeleteHandler.handledOldRecords[0];
        Assert.areEqual(
            new List<String>{ 'afterDeleteHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be afterDeleteHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.afterDeleteHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.afterDeleteHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual('Deleted Two', secondHandledOldRecord.LastName, 'It should be Deleted Two, because a delete context dispatches the deleted rows in trigger order.');
        Assert.areEqual('Sales', firstHandledOldRecord.Department, 'It should be Sales, because getOldSObject() exposes the deleted row with the values it held.');
        Assert.areEqual(
            oldRecords[0].Id,
            orchestrator.afterDeleteHandler.handledIds[0],
            'It should be the id of the first deleted record, because getId() falls back to the old side when there is no new record.'
        );
    }

    @IsTest
    static void dispatchAfterUndeleteRunsTheHandlersOfItsOwnList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Restored One'), new Contact(Id = secondContactId, LastName = 'Restored Two') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'afterUndeleteHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be afterUndeleteHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
        Assert.areEqual(2, orchestrator.afterUndeleteHandler.qualifyCount, 'It should be 2, because qualification is evaluated once per trigger record.');
        Assert.areEqual(2, orchestrator.afterUndeleteHandler.runCount, 'It should be 2, because the action runs once for every qualified trigger record.');
        Assert.areEqual(2, orchestrator.totalRunCount(), 'It should be 2, because one invocation resolves exactly one context, so the six other handler lists contribute nothing.');
        Assert.areEqual(
            'Restored One',
            ((Contact) orchestrator.afterUndeleteHandler.handledNewRecords[0]).LastName,
            'It should be Restored One, because an undelete context dispatches the restored row as the new side of the trigger record.'
        );
        Assert.areEqual(
            newRecords[1].Id,
            orchestrator.afterUndeleteHandler.handledIds[1],
            'It should be the id of the second restored record, because a restored row keeps the id it had before it was deleted.'
        );
    }

    @IsTest
    static void dispatchRunsEveryHandlerReturnedByTheList() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Doe'), new Contact(Id = secondContactId, LastName = 'Roe') };
        DispatchTwoHandlersOrchestrator orchestrator = new DispatchTwoHandlersOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, orchestrator.firstHandler.runCount, 'It should be 2, because every handler of the list takes its own full turn over all trigger records.');
        Assert.areEqual(2, orchestrator.secondHandler.runCount, 'It should be 2, because the whole handler list is dispatched, not only its first entry.');
    }

    @IsTest
    static void dispatchUnimplementedAfterInsertContextIsSilentNoOp() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Doe') };
        DispatchPartialOrchestrator orchestrator = new DispatchPartialOrchestrator();
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because a context the orchestrator does not implement is a silent no-op and the DML succeeds.');
        Assert.isTrue(
            orchestrator.requestedHandlerLists.isEmpty(),
            'It should be true, because the context is selected before handlers are collected, so an unimplemented context never reaches the orchestrator.'
        );
        Assert.areEqual(
            0,
            orchestrator.beforeInsertHandler.runCount + orchestrator.afterUpdateHandler.runCount,
            'It should be 0, because the contexts the orchestrator does implement must not run for a different operation type.'
        );
    }

    @IsTest
    static void dispatchUnimplementedBeforeDeleteContextIsSilentNoOp() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted One') };
        DispatchPartialOrchestrator orchestrator = new DispatchPartialOrchestrator();
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because a delete context the orchestrator does not implement is a silent no-op and the DML succeeds.');
        Assert.isTrue(
            orchestrator.requestedHandlerLists.isEmpty(),
            'It should be true, because the context is selected before handlers are collected, so an unimplemented context never reaches the orchestrator.'
        );
    }

    @IsTest
    static void dispatchImplementedContextStillRunsWhenOtherContextsAreNotImplemented() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchPartialOrchestrator orchestrator = new DispatchPartialOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            orchestrator.beforeInsertHandler.runCount,
            'It should be 1, because implementing only some of the seven interfaces is a supported setup and the implemented contexts keep working.'
        );
        Assert.areEqual(
            new List<String>{ 'beforeInsertHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be beforeInsertHandlers alone, because the orchestrator is asked only for the context that is firing.'
        );
    }

    @IsTest
    static void dispatchOrchestratorWithoutContextInterfacesIsSilentNoOp() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DispatchNoInterfacesOrchestrator());
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because an orchestrator that implements no context interface resolves to no context, which is a silent no-op.');
    }

    @IsTest
    static void dispatchNonOrchestratorArgumentIsSilentNoOpInTriggerContext() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator('Not an orchestrator');
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because run() takes an Object and context selection only tests instanceof, so a value that matches no context is a no-op.'
        );
    }

    @IsTest
    static void dispatchNullOrchestratorIsSilentNoOpInTriggerContext() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(null);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because null is instanceof nothing, so context selection falls through to the same no-op as an unimplemented context.'
        );
    }

    @IsTest
    static void dispatchRunOutsideTriggerContextThrows() {
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because run() is only valid inside a trigger.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message, because there is no operation type to resolve a context from.'
        );
        Assert.isTrue(
            orchestratorException.getTypeName().endsWith('TriggerOrchestratorException'),
            'It should be true, because every contract violation the framework detects is raised as a TriggerOrchestratorException, never as a bare platform exception.'
        );
        Assert.isTrue(
            orchestrator.requestedHandlerLists.isEmpty(),
            'It should be true, because the trigger context guard is the first step of the pipeline, before any handler list is collected.'
        );
    }

    @IsTest
    static void dispatchRunOutsideTriggerContextWithNullArgumentThrows() {
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(null);
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the missing trigger context is checked before the argument is looked at.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message, because the guard does not depend on what was passed to run().'
        );
    }

    @IsTest
    static void dispatchRunOutsideTriggerContextWithNonOrchestratorArgumentThrows() {
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator('Not an orchestrator');
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the missing trigger context is checked before the argument is looked at.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message, because the guard does not depend on what was passed to run().'
        );
    }

    @IsTest
    static void dispatchRunWithRecordsButWithoutOperationTypeThrows() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the operation type alone decides whether there is a trigger context.');
        Assert.areEqual(
            'Called outside of a trigger context, or the trigger operation is not supported.',
            orchestratorException.getMessage(),
            'It should be the outside-of-trigger message, because records without an operation type are not a trigger invocation.'
        );
    }

    @IsTest
    static void dispatchEmptyHandlerListRunsNothingOnBeforeInsert() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
        DispatchEmptyListOrchestrator orchestrator = new DispatchEmptyListOrchestrator();
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because an empty handler list is a valid answer and the DML succeeds.');
        Assert.areEqual(
            new List<String>{ 'beforeInsertHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be beforeInsertHandlers alone, because the context is implemented, so handlers are collected before the list turns out to be empty.'
        );
    }

    @IsTest
    static void dispatchEmptyHandlerListRunsNothingOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New One') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old One') };
        DispatchEmptyListOrchestrator orchestrator = new DispatchEmptyListOrchestrator();
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because an empty handler list behaves exactly like an unimplemented context and the DML succeeds.');
        Assert.areEqual(
            new List<String>{ 'afterUpdateHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be afterUpdateHandlers alone, because run() asks only the orchestrator interface that matches the firing operation type.'
        );
    }

    @IsTest
    static void dispatchEmptyTriggerRecordListLeavesHandlersUnused() {
        List<SObject> newRecords = new List<Contact>();
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'beforeInsertHandlers' },
            orchestrator.requestedHandlerLists,
            'It should be beforeInsertHandlers alone, because the context is selected from the operation type, not from how many records the trigger carries.'
        );
        Assert.areEqual(
            0,
            orchestrator.beforeInsertHandler.qualifyCount,
            'It should be 0, because qualification is asked once per trigger record and there is no record to ask about.'
        );
        Assert.areEqual(0, orchestrator.totalRunCount(), 'It should be 0, because a handler action only ever runs for a qualified trigger record.');
    }

    @IsTest
    static void dispatchObjectBypassedInMetadataRunsNoHandler() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        TriggerOrchestrator.MetadataSettings bypassedContact = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = true));
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => bypassedContact };

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because a bypassed object stops the framework silently and the DML succeeds.');
        Assert.areEqual(0, orchestrator.totalRunCount(), 'It should be 0, because TriggerObject__mdt with Bypass__c checked switches off every handler of that object.');
        Assert.isTrue(
            orchestrator.requestedHandlerLists.isEmpty(),
            'It should be true, because the object bypass is read before the context is selected, so the orchestrator is never asked for handlers.'
        );
    }

    @IsTest
    static void dispatchObjectBypassedInMetadataAppliesInAfterContexts() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New One') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old One') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        TriggerOrchestrator.MetadataSettings bypassedContact = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = true));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => bypassedContact };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, orchestrator.totalRunCount(), 'It should be 0, because an object bypass switches off every context of that object, not only the before ones.');
        Assert.isTrue(
            orchestrator.requestedHandlerLists.isEmpty(),
            'It should be true, because the object bypass is read before the context is selected, so the orchestrator is never asked for handlers.'
        );
    }

    @IsTest
    static void dispatchObjectBypassOfAnotherSObjectDoesNotStopDispatch() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        TriggerOrchestrator.MetadataSettings bypassedAccount = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = true));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'account' => bypassedAccount };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            orchestrator.beforeInsertHandler.runCount,
            'It should be 1, because a bypass is looked up by the SObject of the trigger records and only switches off that object.'
        );
    }

    @IsTest
    static void dispatchObjectNotBypassedInMetadataRunsHandlers() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchAllContextsOrchestrator orchestrator = new DispatchAllContextsOrchestrator();
        TriggerOrchestrator.MetadataSettings activeContact = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = false));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => activeContact };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            orchestrator.beforeInsertHandler.runCount,
            'It should be 1, because a TriggerObject__mdt record only ever switches handlers off, and this one has the bypass unchecked.'
        );
    }

    @IsTest
    static void dispatchUnimplementedContextInANestedRunLeavesTheOuterInvocationAlone() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Doe') };
        DispatchFinalizeCountingLogger logger = new DispatchFinalizeCountingLogger();
        DispatchNestedRunOrchestrator orchestrator = new DispatchNestedRunOrchestrator();

        orchestrator.handler.logger = logger;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            orchestrator.handler.finalizeCountDuringHandler,
            'It should be 0, because a nested run that resolves to no context is a silent no-op, so it must not finalize the logger of the outer invocation that is still running.'
        );
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because finalize runs once per top level invocation and a nested invocation never calls it.');
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
            orchestratorRunner2.context.triggerNewRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
            orchestratorRunner2.run();
            this.finalizeCountDuringHandler = this.logger.finalizeCount;
        }
    }

    private class DispatchNestedUnimplementedContextOrchestrator implements TriggerOrchestrator.AfterUpdate {
        public List<AfterUpdate.Handler> afterUpdateHandlers() {
            return new List<AfterUpdate.Handler>();
        }
    }

    @IsTest
    static void beforeInsertPopulatorWritesFieldOnQualifiedRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertPopulator handler = new RolesInsertPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'Populated',
            ((Contact) records[0]).Title,
            'It should be Populated, because a populator writes onto the new SObject of the trigger record, which is the version the platform saves.'
        );
        Assert.areEqual(1, handler.populateCount, 'It should be 1, because the populator action runs once for every qualified record.');
    }

    @IsTest
    static void beforeInsertPopulatorRunsOncePerQualifiedRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B') };
        RolesInsertPopulator handler = new RolesInsertPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Contact firstRecord = (Contact) records[0];
        Contact secondRecord = (Contact) records[1];
        Assert.areEqual(2, handler.qualificationCount, 'It should be 2, because the qualification predicate is evaluated once for every trigger record.');
        Assert.areEqual(2, handler.populateCount, 'It should be 2, because the populator action is called once per qualified record, never once per invocation.');
        Assert.areEqual('Populated', firstRecord.Title, 'It should be Populated, because the action runs per record and the first record passed the predicate.');
        Assert.areEqual('Populated', secondRecord.Title, 'It should be Populated, because the action runs per record and the second record passed the predicate as well.');
    }

    @IsTest
    static void beforeInsertPopulatorActionIsSkippedWhenQualificationReturnsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertPopulator handler = new RolesInsertPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.qualifies = false;
        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.qualificationCount, 'It should be 1, because the predicate is still evaluated for the record before it is dropped.');
        Assert.areEqual(0, handler.populateCount, 'It should be 0, because populateOnBeforeInsert is never called for a record the predicate rejected.');
        Assert.isNull(((Contact) records[0]).Title, 'It should be null, because an unqualified record never reaches the populator action that would write it.');
    }

    @IsTest
    static void beforeInsertPopulatorActionRunsOnlyForQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B', Title = 'Existing') };
        RolesBlankTitlePopulator handler = new RolesBlankTitlePopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Contact firstRecord = (Contact) records[0];
        Contact secondRecord = (Contact) records[1];
        Assert.areEqual(1, handler.populateCount, 'It should be 1, because qualification is decided per record and only one record satisfied the predicate.');
        Assert.areEqual('Populated', firstRecord.Title, 'It should be Populated, because the predicate is evaluated per record and the blank Title satisfied it.');
        Assert.areEqual('Existing', secondRecord.Title, 'It should be Existing, because an unqualified record is left exactly as the caller sent it.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'Populated',
            ((Contact) newRecords[0]).Department,
            'It should be Populated, because a before update populator writes onto the new SObject, which is the version the platform saves.'
        );
        Assert.areEqual(1, handler.populateCount, 'It should be 1, because the populator action runs once for every qualified record.');
        Assert.isNull(((Contact) oldRecords[0]).Department, 'It should be null, because put targets the new record only and the old record is the immutable stored version.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.qualificationCount, 'It should be 1, because the predicate is still evaluated for the record before it is dropped.');
        Assert.areEqual(0, handler.populateCount, 'It should be 0, because populateOnBeforeUpdate is never called for a record the predicate rejected.');
        Assert.isNull(((Contact) newRecords[0]).Department, 'It should be null, because an unqualified record never reaches the populator action that would write it.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Contact firstNewRecord = (Contact) newRecords[0];
        Contact secondNewRecord = (Contact) newRecords[1];
        Assert.areEqual(1, handler.populateCount, 'It should be 1, because qualification is decided per record and only one record changed its Title.');
        Assert.areEqual('Populated', firstNewRecord.Department, 'It should be Populated, because the predicate is evaluated per record and the changed Title satisfied it.');
        Assert.isNull(secondNewRecord.Department, 'It should be null, because the record with an unchanged Title never reached the populator action.');
    }

    @IsTest
    static void beforeInsertValidatorAttachesErrorWhenPredicateReturnsTrue() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertValidator handler = new RolesInsertValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            records[0].getErrors().size(),
            'It should be 1, because a validator has no action method and the framework itself calls addError on the new SObject of every qualified record.'
        );
        Assert.areEqual(
            'Title is required on new contacts.',
            records[0].getErrors()[0].getMessage(),
            'It should be the validator message, because the blocked record carries the string the validator supplied.'
        );
    }

    @IsTest
    static void beforeInsertValidatorUsesValidationMessageMethodAsErrorMessage() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        RolesInsertValidator handler = new RolesInsertValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        handler.validationMessage = 'Contacts from this source are not allowed.';
        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.messageCount, 'It should be 1, because beforeInsertValidationMessage is asked once for every qualified record.');
        Assert.areEqual(
            'Contacts from this source are not allowed.',
            records[0].getErrors()[0].getMessage(),
            'It should be the exact string returned by beforeInsertValidationMessage, because the framework attaches it verbatim.'
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.isTrue(records[0].getErrors().isEmpty(), 'It should be empty, because a record the validator predicate rejected saves untouched.');
        Assert.areEqual(0, handler.messageCount, 'It should be 0, because the message method is only asked for records that must be blocked.');
        Assert.areEqual('Existing', ((Contact) records[0]).Title, 'It should be Existing, because a validator has no action method and never writes on the record.');
    }

    @IsTest
    static void beforeInsertValidatorAttachesErrorOnlyToQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B', Title = 'Existing') };
        RolesBlankTitleValidator handler = new RolesBlankTitleValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1, because the predicate is evaluated per record and this record is the one it qualified.');
        Assert.isTrue(records[1].getErrors().isEmpty(), 'It should be empty, because the validator predicate is evaluated per record and this record passed.');
    }

    @IsTest
    static void beforeUpdateValidatorAttachesErrorWhenPredicateReturnsTrue() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesUpdateValidator handler = new RolesUpdateValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            newRecords[0].getErrors().size(),
            'It should be 1, because a validator has no action method and the framework itself calls addError on the new SObject of every qualified record.'
        );
        Assert.areEqual(
            'Title cannot be changed.',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be the validator message, because the blocked record carries the string the validator supplied.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorAttachesErrorToTheNewRecordSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesUpdateValidator handler = new RolesUpdateValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1, because addError is called on getNewSObject, the record the DML is saving.');
        Assert.isTrue(oldRecords[0].getErrors().isEmpty(), 'It should be empty, because the old record is the stored version and never carries a validation error.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.messageCount, 'It should be 1, because beforeUpdateValidationMessage is asked once for every qualified record.');
        Assert.areEqual(
            'Closed contacts cannot be edited.',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be the exact string returned by beforeUpdateValidationMessage, because the framework attaches it verbatim.'
        );
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.isTrue(newRecords[0].getErrors().isEmpty(), 'It should be empty, because a record the validator predicate rejected saves untouched.');
        Assert.areEqual(0, handler.messageCount, 'It should be 0, because the message method is only asked for records that must be blocked.');
        Assert.areEqual('New', ((Contact) newRecords[0]).Title, 'It should be New, because a validator has no action method and never writes on the record.');
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
        RolesChangedTitleValidator handler = new RolesChangedTitleValidator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.updateHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1, because the predicate is evaluated per record and the changed Title qualified this one.');
        Assert.isTrue(newRecords[1].getErrors().isEmpty(), 'It should be empty, because the validator predicate is evaluated per record and this record passed.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'First qualify A,First populate A,Second qualify A,Second message A,Third qualify A,Third populate A',
            String.join(executionLog, ','),
            'It should be the registration order, because handlers run in the order the orchestrator list returns them and a validator between two populators does not reorder anything.'
        );
        Assert.areEqual(
            1,
            records[0].getErrors().size(),
            'It should be 1, because a validator blocking a record does not stop the handlers registered after it from running on that record.'
        );
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'First qualify A,First message A,Second qualify A,Second populate A',
            String.join(executionLog, ','),
            'It should be the registration order, because the role never reorders the list and a validator registered first runs before a populator registered after it.'
        );
    }

    @IsTest
    static void beforeInsertHandlerProcessesEveryRecordBeforeTheNextHandlerStarts() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A'), new Contact(LastName = 'B') };
        List<String> executionLog = new List<String>();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(new RolesLoggingInsertPopulator('First', executionLog));
        orchestrator.insertHandlers.add(new RolesLoggingInsertPopulator('Second', executionLog));

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'First qualify A,First populate A,First qualify B,First populate B,Second qualify A,Second populate A,Second qualify B,Second populate B',
            String.join(executionLog, ','),
            'It should be handler by handler, because each handler is run over the whole record list before the next one starts, there is no shared qualification pass.'
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.beforeInsertPopulateCount, 'It should be 1, because the one-role rule is per context and the class holds a valid role in before insert.');
        Assert.areEqual(0, handler.beforeUpdatePopulateCount, 'It should be 0, because each context calls only its own pair of methods.');
        Assert.areEqual('Insert', ((Contact) records[0]).Title, 'It should be Insert, because the before insert action is the one the running context selected.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.beforeUpdatePopulateCount, 'It should be 1, because the one-role rule is per context and the class holds a valid role in before update too.');
        Assert.areEqual(0, handler.beforeInsertPopulateCount, 'It should be 0, because the before insert methods belong to a context that is not running.');
        Assert.areEqual('Update', ((Contact) newRecords[0]).Title, 'It should be Update, because the before update action is the one the running context selected.');
    }

    @IsTest
    static void oneClassWithARoleInTwoContextsFiresEachContextFinalizerOnce() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'A') };
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'A', Title = 'Old') };
        RolesDualContextPopulator handler = new RolesDualContextPopulator();
        RolesOrchestrator orchestrator = new RolesOrchestrator();

        orchestrator.insertHandlers.add(handler);
        orchestrator.updateHandlers.add(handler);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner2.context.triggerNewRecords = newRecords;
        orchestratorRunner2.context.triggerOldRecords = oldRecords;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(1, handler.beforeInsertFinalizeCount, 'It should be 1, because a finalizer fires once per handler execution and only for the context it belongs to.');
        Assert.areEqual(1, handler.beforeUpdateFinalizeCount, 'It should be 1, because the before update finalizer is a separate callback that its own context fires once.');
        Assert.areEqual(1, handler.beforeInsertPopulateCount, 'It should be 1, because the before insert invocation processed its single qualified record.');
        Assert.areEqual(1, handler.beforeUpdatePopulateCount, 'It should be 1, because the before update invocation processed its single qualified record.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner2.context.triggerNewRecords = newRecords;
        orchestratorRunner2.context.triggerOldRecords = oldRecords;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(
            'Populated',
            ((Contact) records[0]).Title,
            'It should be Populated, because the role is resolved per context and the class is a populator in before insert.'
        );
        Assert.isTrue(records[0].getErrors().isEmpty(), 'It should be empty, because a populator has no validation message and the before insert turn writes instead of blocking.');
        Assert.areEqual(
            1,
            newRecords[0].getErrors().size(),
            'It should be 1, because the same class is a validator in before update, which is a different context with its own role.'
        );
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

    @IsTest
    static void enrichmentAttachesParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Umbrella Corp', Industry = 'Technology');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.seenNewParents.size(),
            'It should be 1, because enrichment attaches a parent to every trigger record of the invocation before the handler runs.'
        );
        Assert.areEqual(
            parentAccount.Id,
            handler.seenNewParents[0].Id,
            'It should be the inserted account id, because the parent is fetched by the value held in the declared lookup field.'
        );
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because getNewRelated returns the parent carrying the declared fields.'
        );
    }

    @IsTest
    static void enrichmentAttachesParentOnOldSide() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        Id contactId = new EnrichmentIdFactory().next(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        EnrichmentAfterUpdateHandler handler = new EnrichmentAfterUpdateHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because getOldRelated returns the parent the old record points at, never the one the new record moved to.'
        );
        Assert.isNull(handler.seenNewParents[0], 'It should be null, because the two sides are declared independently and only the old side was declared.');
    }

    @IsTest
    static void enrichmentUndeclaredRelationshipReturnsNullWithoutQuery() {
        Account parentAccount = new Account(Name = 'Never Queried');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.isNull(handler.seenNewParents[0], 'It should be null, because a relationship no active handler declared is never attached, even when the lookup holds a real id.');
        Assert.areEqual(0, queriesAfter - queriesBefore, 'It should be 0, because no query is issued for an undeclared relationship.');
    }

    @IsTest
    static void enrichmentUnsetLookupAttachesNoParent() {
        Account parentAccount = new Account(Name = 'Umbrella Corp');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'With Parent', AccountId = parentAccount.Id), new Contact(LastName = 'Without Parent') };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because a record holding a value in the declared lookup still gets its parent.'
        );
        Assert.isNull(handler.seenNewParents[1], 'It should be null, because an unset lookup fetches nothing for that record and raises no error.');
        Assert.areEqual(
            1,
            queriesAfter - queriesBefore,
            'It should be 1, because the record with no lookup value contributes no id and the declared field is still resolved in a single query.'
        );
    }

    @IsTest
    static void enrichmentUnsetLookupOnEveryRecordIssuesNoQuery() {
        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(0, queriesAfter - queriesBefore, 'It should be 0, because a lookup with no populated value on any record of the invocation is not queried at all.');
        Assert.isNull(handler.seenNewParents[0], 'It should be null, because an unset lookup attaches no parent.');
        Assert.isNull(handler.seenNewParents[1], 'It should be null, because an unset lookup attaches no parent.');
    }

    @IsTest
    static void enrichmentSeveralHandlersDeclaringTheSameParentFieldCostOneQuery() {
        Account parentAccount = new Account(Name = 'Umbrella Corp', Industry = 'Technology', BillingCountry = 'Poland');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'First', AccountId = parentAccount.Id),
            new Contact(LastName = 'Second', AccountId = parentAccount.Id)
        };

        EnrichmentAfterInsertHandler nameHandler = new EnrichmentAfterInsertHandler();
        nameHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        EnrichmentAfterInsertHandler industryHandler = new EnrichmentAfterInsertHandler();
        industryHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Industry));

        EnrichmentAfterInsertHandler countryHandler = new EnrichmentAfterInsertHandler();
        countryHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.BillingCountry));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ nameHandler, industryHandler, countryHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(
            1,
            queriesAfter - queriesBefore,
            'It should be 1, because the cost is one query per declared lookup field per invocation, whatever the number of handlers or records.'
        );
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
    static void enrichmentTwoDeclaredLookupsCostOneQueryEach() {
        Account parentAccount = new Account(Name = 'Umbrella Corp');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{
            new Contact(LastName = 'First', AccountId = parentAccount.Id, OwnerId = UserInfo.getUserId()),
            new Contact(LastName = 'Second', AccountId = parentAccount.Id, OwnerId = UserInfo.getUserId())
        };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
        handler.declareNew(Contact.OwnerId, TriggerHandler.FieldSelection.with(User.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(2, queriesAfter - queriesBefore, 'It should be 2, because the cost is one query per declared lookup field, and two lookup fields were declared.');
        Assert.areEqual(
            'Umbrella Corp',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Umbrella Corp, because each declared lookup is attached under its own relationship name.'
        );
        Assert.areEqual(
            UserInfo.getUserId(),
            handler.seenNewOwners[0].Id,
            'It should be the running user id, because Contact.OwnerId is resolved separately and read through the Owner relationship name.'
        );
    }

    @IsTest
    static void enrichmentLookupPointingAtMissingParentAttachesNull() {
        Id missingAccountId = new EnrichmentIdFactory().next(Account.SObjectType);

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = missingAccountId) };

        EnrichmentAfterInsertHandler handler = new EnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
        repointingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
        repointingHandler.accountIdsToSet = new List<Id>{ accounts[1].Id };

        EnrichmentBeforeUpdateHandler readingHandler = new EnrichmentBeforeUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ populatingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
            lastHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
            handlers.add(lastHandler);
        }

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentBeforeInsertOrchestrator(handlers));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
        readingHandler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new EnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ repointingHandler, readingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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

        Id contactId = new EnrichmentIdFactory().next(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = accounts[0].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = accounts[0].Id) };

        EnrichmentAfterUpdateHandler repointingHandler = new EnrichmentAfterUpdateHandler();
        repointingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
        repointingHandler.accountIdsToSet = new List<Id>{ accounts[1].Id };

        EnrichmentAfterUpdateHandler readingHandler = new EnrichmentAfterUpdateHandler();
        readingHandler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ repointingHandler, readingHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(
            'First Parent',
            ((Account) readingHandler.seenNewParents[0]).Name,
            'It should be First Parent, because after update resolves parents once and never re-checks between handlers.'
        );
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because no re-check is performed in a context where no handler can change a record.');
    }

    @IsTest
    static void enrichmentResolvesBothSidesInOneQuery() {
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        Id contactId = new EnrichmentIdFactory().next(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        EnrichmentAfterUpdateHandler handler = new EnrichmentAfterUpdateHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new EnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because getOldRelated returns the parent the record pointed at before the change.'
        );
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because getNewRelated returns the parent the record points at now.'
        );
        Assert.areEqual(1, queriesAfter - queriesBefore, 'It should be 1, because both sides of the same lookup field are gathered into a single query for the invocation.');
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

    private class EnrichmentBeforeInsertHandler implements BeforeInsert.Populator, BeforeInsert.NewRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<Id> accountIdsToSet = new List<Id>();

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Integer repointIndex = 0;

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert() {
            return this.newDeclaration;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));

            if (this.accountIdsToSet.isEmpty()) {
                return;
            }

            record.put(Contact.AccountId, this.accountIdsToSet[Math.min(this.repointIndex, this.accountIdsToSet.size() - 1)]);
            this.repointIndex++;
        }
    }

    private class EnrichmentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.NewRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenNewOwners = new List<SObject>();

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert() {
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            this.seenNewOwners.add(record.getNewRelated('Owner'));
        }
    }

    private class EnrichmentBeforeUpdateHandler implements BeforeUpdate.Populator, BeforeUpdate.NewRecordEnrichment, BeforeUpdate.OldRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public List<Id> accountIdsToSet = new List<Id>();

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Integer repointIndex = 0;

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeUpdate() {
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeUpdate() {
            return this.oldDeclaration;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            this.seenOldParents.add(record.getOldRelated('Account'));

            if (this.accountIdsToSet.isEmpty()) {
                return;
            }

            record.put(Contact.AccountId, this.accountIdsToSet[Math.min(this.repointIndex, this.accountIdsToSet.size() - 1)]);
            this.repointIndex++;
        }
    }

    private class EnrichmentAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.OldRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public List<Id> accountIdsToSet = new List<Id>();

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Integer repointIndex = 0;

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnAfterUpdate() {
            return this.oldDeclaration;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            this.seenOldParents.add(record.getOldRelated('Account'));

            if (this.accountIdsToSet.isEmpty()) {
                return;
            }

            record.put(Contact.AccountId, this.accountIdsToSet[Math.min(this.repointIndex, this.accountIdsToSet.size() - 1)]);
            this.repointIndex++;
        }
    }

    @IsTest
    static void bypassableHandlerSkippedOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertPopulator bypassedHandler = new BypassBeforeInsertPopulator();
        BypassBeforeInsertPopulator activeHandler = new BypassBeforeInsertPopulator();
        bypassedHandler.isBypassed = true;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a before insert populator whose bypassOnBeforeInsertWhen returns true is dropped from the invocation before any record reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnBeforeInsertWhenBypassIsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertPopulator handler = new BypassBeforeInsertPopulator();
        handler.isBypassed = false;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnBeforeInsertWhen returning false leaves the handler in the invocation.');
        Assert.areEqual('Populated', ((Contact) records[0]).Title, 'It should be Populated, because a handler that is not bypassed populates the trigger record in place.');
    }

    @IsTest
    static void bypassableValidatorSkippedOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertValidator bypassedValidator = new BypassBeforeInsertValidator();
        BypassBeforeInsertPopulator activeHandler = new BypassBeforeInsertPopulator();
        bypassedValidator.isBypassed = true;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ bypassedValidator, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedValidator.messageCount,
            'It should be 0, because the validator adapter answers the same Bypassable interface as the populator adapter, so a bypassed validator never reaches a record.'
        );
        Assert.areEqual(0, records[0].getErrors().size(), 'It should be 0, because a bypassed validator attaches no error and the record stays saveable.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableValidatorRunsOnBeforeInsertWhenBypassIsFalse() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassBeforeInsertValidator validator = new BypassBeforeInsertValidator();
        validator.isBypassed = false;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ validator });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            records[0].getErrors().size(),
            'It should be 1, because bypassOnBeforeInsertWhen returning false leaves the validator in the invocation and it marks every qualified record.'
        );
        Assert.areEqual(
            'Before insert validation failed',
            records[0].getErrors()[0].getMessage(),
            'It should be Before insert validation failed, because the adapter attaches the exact string returned by beforeInsertValidationMessage.'
        );
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterInsert() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassAfterInsertHandler bypassedHandler = new BypassAfterInsertHandler();
        BypassAfterInsertHandler activeHandler = new BypassAfterInsertHandler();
        bypassedHandler.isBypassed = true;

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a handler whose bypassOnAfterInsertWhen returns true is dropped from the invocation before any record reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterInsertWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isBypassed = false;

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnAfterInsertWhen returning false leaves the handler in the invocation.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator bypassedHandler = new BypassBeforeUpdatePopulator();
        BypassBeforeUpdatePopulator activeHandler = new BypassBeforeUpdatePopulator();
        bypassedHandler.isBypassed = true;

        BypassBeforeUpdateOrchestrator orchestrator = new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a before update populator whose bypassOnBeforeUpdateWhen returns true is dropped from the invocation before any record reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnBeforeUpdateWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator handler = new BypassBeforeUpdatePopulator();
        handler.isBypassed = false;

        BypassBeforeUpdateOrchestrator orchestrator = new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnBeforeUpdateWhen returning false leaves the handler in the invocation.');
        Assert.areEqual(
            'Populated',
            ((Contact) newRecords[0]).Title,
            'It should be Populated, because put writes to the new version of the record, which is the one the platform saves.'
        );
    }

    @IsTest
    static void bypassableValidatorSkippedOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdateValidator bypassedValidator = new BypassBeforeUpdateValidator();
        BypassBeforeUpdatePopulator activeHandler = new BypassBeforeUpdatePopulator();
        bypassedValidator.isBypassed = true;

        BypassBeforeUpdateOrchestrator orchestrator = new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ bypassedValidator, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedValidator.messageCount,
            'It should be 0, because the validator adapter answers the same Bypassable interface as the populator adapter, so a bypassed validator never reaches a record.'
        );
        Assert.areEqual(0, newRecords[0].getErrors().size(), 'It should be 0, because a bypassed validator attaches no error and the record stays saveable.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableValidatorRunsOnBeforeUpdateWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdateValidator validator = new BypassBeforeUpdateValidator();
        validator.isBypassed = false;

        BypassBeforeUpdateOrchestrator orchestrator = new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ validator });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            newRecords[0].getErrors().size(),
            'It should be 1, because bypassOnBeforeUpdateWhen returning false leaves the validator in the invocation and it marks every qualified record.'
        );
        Assert.areEqual(
            'Before update validation failed',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be Before update validation failed, because the adapter attaches the exact string returned by beforeUpdateValidationMessage.'
        );
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler bypassedHandler = new BypassAfterUpdateHandler();
        BypassAfterUpdateHandler activeHandler = new BypassAfterUpdateHandler();
        bypassedHandler.isBypassed = true;

        BypassAfterUpdateOrchestrator orchestrator = new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a handler whose bypassOnAfterUpdateWhen returns true is dropped from the invocation before any record reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterUpdateWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler handler = new BypassAfterUpdateHandler();
        handler.isBypassed = false;

        BypassAfterUpdateOrchestrator orchestrator = new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnAfterUpdateWhen returning false leaves the handler in the invocation.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnBeforeDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassBeforeDeleteHandler bypassedHandler = new BypassBeforeDeleteHandler();
        BypassBeforeDeleteHandler activeHandler = new BypassBeforeDeleteHandler();
        bypassedHandler.isBypassed = true;

        BypassBeforeDeleteOrchestrator orchestrator = new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a handler whose bypassOnBeforeDeleteWhen returns true is dropped from the invocation before any deleted row reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnBeforeDeleteWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassBeforeDeleteHandler handler = new BypassBeforeDeleteHandler();
        handler.isBypassed = false;

        BypassBeforeDeleteOrchestrator orchestrator = new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnBeforeDeleteWhen returning false leaves the handler in the invocation.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassAfterDeleteHandler bypassedHandler = new BypassAfterDeleteHandler();
        BypassAfterDeleteHandler activeHandler = new BypassAfterDeleteHandler();
        bypassedHandler.isBypassed = true;

        BypassAfterDeleteOrchestrator orchestrator = new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a handler whose bypassOnAfterDeleteWhen returns true is dropped from the invocation before any deleted row reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterDeleteWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassAfterDeleteHandler handler = new BypassAfterDeleteHandler();
        handler.isBypassed = false;

        BypassAfterDeleteOrchestrator orchestrator = new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnAfterDeleteWhen returning false leaves the handler in the invocation.');
    }

    @IsTest
    static void bypassableHandlerSkippedOnAfterUndelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored') };
        BypassAfterUndeleteHandler bypassedHandler = new BypassAfterUndeleteHandler();
        BypassAfterUndeleteHandler activeHandler = new BypassAfterUndeleteHandler();
        bypassedHandler.isBypassed = true;

        BypassAfterUndeleteOrchestrator orchestrator = new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            bypassedHandler.runCount,
            'It should be 0, because a handler whose bypassOnAfterUndeleteWhen returns true is dropped from the invocation before any restored record reaches it.'
        );
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a bypass switches off only the handler that declares it, never the rest of the context.');
    }

    @IsTest
    static void bypassableHandlerRunsOnAfterUndeleteWhenBypassIsFalse() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored') };
        BypassAfterUndeleteHandler handler = new BypassAfterUndeleteHandler();
        handler.isBypassed = false;

        BypassAfterUndeleteOrchestrator orchestrator = new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because bypassOnAfterUndeleteWhen returning false leaves the handler in the invocation.');
    }

    @IsTest
    static void bypassIsAskedOncePerInvocation() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id thirdContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'One'),
            new Contact(Id = secondContactId, LastName = 'Two'),
            new Contact(Id = thirdContactId, LastName = 'Three')
        };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.bypassCheckCount,
            'It should be 1, because bypassOn...When takes no record and is asked once per invocation for the handler as a whole, while per record decisions belong to qualification.'
        );
        Assert.areEqual(3, handler.runCount, 'It should be 3, because one bypass answer covers every record of the invocation.');
    }

    @IsTest
    static void bypassedHandlerQualificationIsNeverEvaluated() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'One'), new Contact(Id = secondContactId, LastName = 'Two') };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isBypassed = true;

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.qualifyCount, 'It should be 0, because the bypass step runs before any predicate, so a bypassed handler never has its qualification called.');
        Assert.areEqual(0, handler.runCount, 'It should be 0, because a handler that was never qualified is never executed either.');
    }

    @IsTest
    static void handlerWithoutBypassableInterfaceAlwaysRuns() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassPlainAfterInsertHandler handler = new BypassPlainAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because the adapter falls through to false when the handler implements neither the metadata bypass nor Bypassable.');
    }

    @IsTest
    static void bypassedHandlerContributesNoEnrichmentFields() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass', AccountId = accountId) };
        BypassEnrichmentAfterInsertHandler bypassedHandler = new BypassEnrichmentAfterInsertHandler();
        BypassRelatedReaderAfterInsertHandler readerHandler = new BypassRelatedReaderAfterInsertHandler();
        bypassedHandler.isBypassed = true;

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, readerHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            Limits.getQueries() - queriesBefore,
            'It should be 0, because parent fields are declared from the surviving handlers only, so a bypassed handler contributes nothing to query.'
        );
        Assert.areEqual(1, readerHandler.runCount, 'It should be 1, because the reader itself is not bypassed and still receives the record.');
        Assert.isNull(readerHandler.relatedAccount, 'It should be null, because getNewRelated returns null for a relationship no surviving handler declared.');
    }

    @IsTest
    static void bypassWholeContextWithEmptyHandlerList() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>());
        Exception orchestratorException = null;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because an orchestrator returning an empty list bypasses the whole context and the invocation completes normally.'
        );
        Assert.isTrue(
            orchestrator.areHandlersRequested,
            'It should be true, because an implemented context is always dispatched, so the orchestrator is asked for its list even when the list turns out to be empty.'
        );
    }

    @IsTest
    static void metadataBypassedHandlerIsSkipped() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler bypassedHandler = new BypassMetadataHandler();
        BypassAfterInsertHandler activeHandler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = false));
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0, because a TriggerHandler__mdt record naming the class with Bypass__c checked switches that handler off.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because a metadata handler bypass switches off only the named class, never the whole object.');
    }

    @IsTest
    static void metadataBypassedHandlerIsNeverAskedForItsCodeBypass() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler handler = new BypassMetadataHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            handler.bypassCheckCount,
            'It should be 0, because metadata is checked first and short circuits, so a handler bypassed in metadata never has its bypassOn...When called.'
        );
        Assert.areEqual(0, handler.runCount, 'It should be 0, because the metadata bypass alone is enough to drop the handler from the invocation.');
    }

    @IsTest
    static void metadataBypassedPopulatorIsSkippedOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Bypass') };
        BypassMetadataPopulator bypassedHandler = new BypassMetadataPopulator();
        BypassBeforeInsertPopulator activeHandler = new BypassBeforeInsertPopulator();

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'bypassmetadatapopulator' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0, because the metadata bypass is keyed by class name alone, so it applies in every context the class runs in.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because the other handlers of the object keep running.');
    }

    @IsTest
    static void metadataObjectBypassSkipsEveryHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassAfterInsertHandler firstHandler = new BypassAfterInsertHandler();
        BypassAfterInsertHandler secondHandler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ firstHandler, secondHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = true));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because an object bypass returns silently and the DML is left to succeed.');
        Assert.areEqual(0, firstHandler.runCount, 'It should be 0, because no handler of a bypassed object runs, in any context.');
        Assert.areEqual(0, secondHandler.runCount, 'It should be 0, because no handler of a bypassed object runs, in any context.');
        Assert.isFalse(
            orchestrator.areHandlersRequested,
            'It should be false, because the object bypass is the first check of the invocation and happens before the orchestrator is asked for its handler list.'
        );
    }

    @IsTest
    static void metadataObjectBypassAppliesOnlyToTheNamedObject() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings accountSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = true));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'account' => accountSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.runCount,
            'It should be 1, because the object bypass is looked up by the API name of the object the trigger fired on, and Contact has no record.'
        );
    }

    @IsTest
    static void metadataObjectRecordWithoutBypassLetsHandlersRun() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = false));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because metadata records only ever turn things off and an unchecked Bypass__c changes nothing.');
    }

    @IsTest
    static void metadataInnerClassQualifiedNameBypassesHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler handler = new BypassMetadataHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{
            'triggerorchestratortest.bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true),
            'bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true)
        };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            handler.runCount,
            'It should be 0, because ApexClassName__c spelled Outer.Inner is stored in both spellings by the loader, so an inner class handler is bypassed by the qualified name too.'
        );
    }

    @IsTest
    static void metadataInnerClassSimpleNameBypassesHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler handler = new BypassMetadataHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            handler.runCount,
            'It should be 0, because the name compared at runtime is the lowercased simple class name, so the bare Inner spelling matches an inner class handler.'
        );
    }

    @IsTest
    static void metadataQualifiedNameAloneDoesNotBypassInnerClass() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler handler = new BypassMetadataHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'triggerorchestratortest.bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.runCount,
            'It should be 1, because an inner class reports only its simple name at runtime, which is why the loader has to store the unqualified tail of a dotted name as well.'
        );
    }

    @IsTest
    static void metadataNameOfAnotherOuterClassBypassesTheSameSimpleName() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler handler = new BypassMetadataHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{
            'someotherouterclass.bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true),
            'bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true)
        };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            handler.runCount,
            'It should be 0, because the record names a different outer class yet its unqualified tail is the same simple name, so inner classes sharing a simple name are bypassed together.'
        );
    }

    @IsTest
    static void zeroMetadataRecordsRunEveryHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler firstHandler = new BypassMetadataHandler();
        BypassAfterInsertHandler secondHandler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ firstHandler, secondHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            firstHandler.runCount,
            'It should be 1, because an empty settings cache resolves to no settings for the object and metadata records only ever turn things off.'
        );
        Assert.areEqual(
            1,
            secondHandler.runCount,
            'It should be 1, because an empty settings cache resolves to no settings for the object and metadata records only ever turn things off.'
        );
    }

    @IsTest
    static void zeroMetadataRecordsAreLoadedWithoutConsumingSoql() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler handler = new BypassMetadataHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        Map<String, TriggerOrchestrator.MetadataSettings> eagerlyLoadedSettings = TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName;

        Integer queriesBefore = Limits.getQueries();
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = TriggerOrchestrator.TriggerSettings.resolveMetadataSettings();
        Integer queriesAfterLoad = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            queriesAfterLoad - queriesBefore,
            'It should be 0, because the settings come from a custom metadata query and custom metadata queries never count against the SOQL governor limit.'
        );
        Assert.areEqual(
            0,
            Limits.getQueries() - queriesAfterLoad,
            'It should be 0, because the loader ran once when the class was initialized and the invocation only reads the cached map.'
        );
        Assert.isNotNull(eagerlyLoadedSettings, 'It should be not null, because the loader runs when the class is initialized and caches whatever it finds, even nothing.');
        Assert.isNull(
            TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName.get('contact'),
            'It should be null, because no TriggerObject__mdt record exists for Contact, so the object resolves to no settings at all.'
        );
        Assert.areEqual(1, handler.runCount, 'It should be 1, because with no metadata records every handler runs and nothing about the behaviour changes.');
    }

    @IsTest
    static void metadataReadConsumesNoSoqlWhenCacheIsPopulated() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Bypass') };
        BypassMetadataHandler bypassedHandler = new BypassMetadataHandler();
        BypassAfterInsertHandler activeHandler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ bypassedHandler, activeHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'bypassmetadatahandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            Limits.getQueries() - queriesBefore,
            'It should be 0, because the settings are read once per transaction and every later lookup, one per handler plus the object check, comes from the cache.'
        );
        Assert.areEqual(0, bypassedHandler.runCount, 'It should be 0, because the cached settings still bypass the named handler.');
        Assert.areEqual(1, activeHandler.runCount, 'It should be 1, because the cached settings leave the other handlers running.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterInsert() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Qualified') };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isQualified = true;

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because a record whose qualify method returns true is passed on to the handler action.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterInsert() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Skipped') };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();
        handler.isQualified = false;

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because a record whose qualify method returns false never reaches the handler action.');
        Assert.areEqual(1, handler.qualifyCount, 'It should be 1, because the predicate is evaluated for every record of the invocation, qualified or not.');
    }

    @IsTest
    static void qualificationIsEvaluatedPerRecord() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id thirdContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'Skipped'),
            new Contact(Id = secondContactId, LastName = 'Qualified'),
            new Contact(Id = thirdContactId, LastName = 'Skipped')
        };
        BypassLastNameAfterInsertHandler handler = new BypassLastNameAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.processedRecordIds.size(), 'It should be 1, because qualification is a per record predicate and only one record of the three matched it.');
        Assert.areEqual(
            secondContactId,
            String.valueOf(handler.processedRecordIds[0]).left(15),
            'It should be the second record, because the action runs only for the records whose own predicate returned true.'
        );
    }

    @IsTest
    static void qualificationPredicateRunsOncePerRecord() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id thirdContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{
            new Contact(Id = firstContactId, LastName = 'One'),
            new Contact(Id = secondContactId, LastName = 'Two'),
            new Contact(Id = thirdContactId, LastName = 'Three')
        };
        BypassAfterInsertHandler handler = new BypassAfterInsertHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(3, handler.qualifyCount, 'It should be 3, because at a handler turn the framework walks the records and asks the predicate exactly once for each of them.');
        Assert.areEqual(3, handler.runCount, 'It should be 3, because every record that qualified is then passed to the handler action.');
    }

    @IsTest
    static void qualifiedRecordRunsPopulatorOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Qualified') };
        BypassBeforeInsertPopulator handler = new BypassBeforeInsertPopulator();
        handler.isQualified = true;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because populateOnBeforeInsertWhen returning true hands the record to populateOnBeforeInsert.');
        Assert.areEqual(
            'Populated',
            ((Contact) records[0]).Title,
            'It should be Populated, because a before insert populator writes straight onto the record the platform is about to save.'
        );
    }

    @IsTest
    static void unqualifiedRecordSkipsPopulatorOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Skipped') };
        BypassBeforeInsertPopulator handler = new BypassBeforeInsertPopulator();
        handler.isQualified = false;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because populateOnBeforeInsert is never called for a record the predicate rejected.');
        Assert.isNull(((Contact) records[0]).Title, 'It should be null, because an unqualified record is left exactly as the caller supplied it.');
    }

    @IsTest
    static void qualifiedRecordAttachesValidatorMessageOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Qualified') };
        BypassBeforeInsertValidator validator = new BypassBeforeInsertValidator();
        validator.isQualified = true;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ validator });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            records[0].getErrors().size(),
            'It should be 1, because a validator predicate is worded the other way round and returning true marks the record as the one that must carry the error.'
        );
        Assert.areEqual(
            'Before insert validation failed',
            records[0].getErrors()[0].getMessage(),
            'It should be Before insert validation failed, because the adapter attaches the exact string returned by beforeInsertValidationMessage.'
        );
    }

    @IsTest
    static void unqualifiedRecordSkipsValidatorOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Skipped') };
        BypassBeforeInsertValidator validator = new BypassBeforeInsertValidator();
        validator.isQualified = false;

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ validator });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, records[0].getErrors().size(), 'It should be 0, because a validator predicate returning false leaves the record to save untouched.');
        Assert.areEqual(0, validator.messageCount, 'It should be 0, because the validation message is asked for inside the action, which runs only for records that qualified.');
    }

    @IsTest
    static void qualifiedRecordRunsPopulatorOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator handler = new BypassBeforeUpdatePopulator();
        handler.isQualified = true;

        BypassBeforeUpdateOrchestrator orchestrator = new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because populateOnBeforeUpdateWhen returning true hands the record to populateOnBeforeUpdate.');
        Assert.areEqual('Populated', ((Contact) newRecords[0]).Title, 'It should be Populated, because a before update populator writes onto the new version of the record.');
    }

    @IsTest
    static void unqualifiedRecordSkipsPopulatorOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassBeforeUpdatePopulator handler = new BypassBeforeUpdatePopulator();
        handler.isQualified = false;

        BypassBeforeUpdateOrchestrator orchestrator = new BypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because populateOnBeforeUpdate is never called for a record the predicate rejected.');
        Assert.isNull(((Contact) newRecords[0]).Title, 'It should be null, because an unqualified record is left exactly as the caller supplied it.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler handler = new BypassAfterUpdateHandler();
        handler.isQualified = true;

        BypassAfterUpdateOrchestrator orchestrator = new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because qualifiesForAfterUpdateWhen returning true hands the record to onAfterUpdate.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        BypassAfterUpdateHandler handler = new BypassAfterUpdateHandler();
        handler.isQualified = false;

        BypassAfterUpdateOrchestrator orchestrator = new BypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because onAfterUpdate is never called for a record the predicate rejected.');
        Assert.areEqual(1, handler.qualifyCount, 'It should be 1, because the predicate is still evaluated once for the record before it is dropped.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnBeforeDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassBeforeDeleteHandler handler = new BypassBeforeDeleteHandler();
        handler.isQualified = true;

        BypassBeforeDeleteOrchestrator orchestrator = new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because a delete context qualifies on the deleted row and the predicate returned true for it.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnBeforeDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassBeforeDeleteHandler handler = new BypassBeforeDeleteHandler();
        handler.isQualified = false;

        BypassBeforeDeleteOrchestrator orchestrator = new BypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because onBeforeDelete is never called for a record the predicate rejected.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassAfterDeleteHandler handler = new BypassAfterDeleteHandler();
        handler.isQualified = true;

        BypassAfterDeleteOrchestrator orchestrator = new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because a delete context qualifies on the deleted row and the predicate returned true for it.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        BypassAfterDeleteHandler handler = new BypassAfterDeleteHandler();
        handler.isQualified = false;

        BypassAfterDeleteOrchestrator orchestrator = new BypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because onAfterDelete is never called for a record the predicate rejected.');
    }

    @IsTest
    static void qualifiedRecordRunsHandlerOnAfterUndelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored') };
        BypassAfterUndeleteHandler handler = new BypassAfterUndeleteHandler();
        handler.isQualified = true;

        BypassAfterUndeleteOrchestrator orchestrator = new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because an undelete context qualifies on the restored record and the predicate returned true for it.');
    }

    @IsTest
    static void unqualifiedRecordSkipsHandlerOnAfterUndelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored') };
        BypassAfterUndeleteHandler handler = new BypassAfterUndeleteHandler();
        handler.isQualified = false;

        BypassAfterUndeleteOrchestrator orchestrator = new BypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.runCount, 'It should be 0, because onAfterUndelete is never called for a record the predicate rejected.');
    }

    @IsTest
    static void qualificationReadsValuesWrittenByEarlierHandler() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Pipeline') };
        BypassTitlePopulator firstHandler = new BypassTitlePopulator();
        BypassTitleReaderPopulator secondHandler = new BypassTitleReaderPopulator();

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ firstHandler, secondHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, firstHandler.runCount, 'It should be 1, because the first handler qualified the record on the blank title it arrived with.');
        Assert.areEqual(
            1,
            secondHandler.runCount,
            'It should be 1, because each predicate is evaluated at its own turn, after every handler above it has finished, so it reads the record as the earlier handler left it.'
        );
        Assert.areEqual(
            'Priority',
            ((Contact) records[0]).Department,
            'It should be Priority, because the second populator qualified on the title the first one wrote and then ran its own action.'
        );
    }

    @IsTest
    static void predicateDoesNotSeeWritesOfHandlersBelowItInTheList() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Pipeline') };
        BypassTitleReaderPopulator firstHandler = new BypassTitleReaderPopulator();
        BypassTitlePopulator secondHandler = new BypassTitlePopulator();

        BypassBeforeInsertOrchestrator orchestrator = new BypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ firstHandler, secondHandler });

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            firstHandler.runCount,
            'It should be 0, because registration order is part of the behaviour and a predicate sees only the writes of the handlers registered above it in the list.'
        );
        Assert.areEqual(
            1,
            secondHandler.runCount,
            'It should be 1, because the handler below still runs at its own turn and writes the value the earlier predicate could not see.'
        );
        Assert.isNull(((Contact) records[0]).Department, 'It should be null, because the reader never qualified, so its populate method never wrote the field.');
    }

    @IsTest
    static void objectBypassInNestedInvocationDoesNotFinalizeLogger() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Outer') };
        BypassFinalizeCountingLogger loggerStub = new BypassFinalizeCountingLogger();
        BypassNestedRunHandler handler = new BypassNestedRunHandler();

        BypassAfterInsertOrchestrator orchestrator = new BypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        TriggerOrchestrator.MetadataSettings accountSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt(Bypass__c = true));

        TriggerOrchestrator.TriggerSettings.logger = loggerStub;
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'account' => accountSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because the outer invocation is not bypassed and its handler is the one that fires the nested trigger.');
        Assert.areEqual(
            0,
            handler.finalizeCountAfterNestedRun,
            'It should be 0, because a nested invocation stopped by an object bypass must leave the outer invocation on the execution stack and never finalize the logger.'
        );
        Assert.areEqual(1, loggerStub.finalizeCount, 'It should be 1, because finalize runs once per top level invocation and a nested invocation never calls it.');
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
            orchestratorRunner2.context.triggerNewRecords = nestedRecords;
            orchestratorRunner2.run();

            this.finalizeCountAfterNestedRun = ((BypassFinalizeCountingLogger) TriggerOrchestrator.TriggerSettings.logger).finalizeCount;
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

    private class BypassEnrichmentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.Bypassable, AfterInsert.NewRecordEnrichment {
        public Boolean isBypassed = false;
        public Integer runCount = 0;

        public Boolean bypassOnAfterInsertWhen() {
            return this.isBypassed;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert() {
            return new Map<SObjectField, TriggerHandler.FieldSelection>{ Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name) };
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
            this.relatedAccount = record.getNewRelated('Account');
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

    @IsTest
    static void defaultRecursionDepthStopsBeforeUpdateHandlerAfterThreePasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionBeforeUpdateHandler handler = new RecursionBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            3,
            handler.runCount,
            'It should be 3, because a before update handler without any RecursionGuard stops after the framework default of three passes per record.'
        );
    }

    @IsTest
    static void defaultRecursionDepthStopsAfterUpdateHandlerAfterThreePasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionAfterUpdateHandler handler = new RecursionAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            3,
            handler.runCount,
            'It should be 3, because an after update handler without any RecursionGuard stops after the framework default of three passes per record.'
        );
    }

    @IsTest
    static void handlerRecursionGuardStopsBeforeUpdateHandlerAfterTwoPasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedBeforeUpdateHandler handler = new RecursionGuardedBeforeUpdateHandler(2);
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            2,
            handler.runCount,
            'It should be 2, because BeforeUpdate.RecursionGuard returning two overrides the framework default and caps the handler at two passes per record.'
        );
    }

    @IsTest
    static void handlerRecursionGuardStopsAfterUpdateHandlerAfterTwoPasses() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(2);
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            2,
            handler.runCount,
            'It should be 2, because AfterUpdate.RecursionGuard returning two overrides the framework default and caps the handler at two passes per record.'
        );
    }

    @IsTest
    static void orchestratorRecursionGuardAppliesToEveryBeforeUpdateHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionBeforeUpdateHandler firstHandler = new RecursionBeforeUpdateHandler();
        RecursionSecondBeforeUpdateHandler secondHandler = new RecursionSecondBeforeUpdateHandler();
        RecursionGuardedBeforeUpdateOrchestrator orchestrator = new RecursionGuardedBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ firstHandler, secondHandler }, 5);

        // Test
        for (Integer i = 0; i < 7; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            5,
            firstHandler.runCount,
            'It should be 5, because TriggerOrchestrator.RecursionGuard replaces the framework default of three for every handler the orchestrator returns.'
        );
        Assert.areEqual(
            5,
            secondHandler.runCount,
            'It should be 5, because the orchestrator level depth applies to every handler of that orchestrator, not only to the first one.'
        );
    }

    @IsTest
    static void orchestratorRecursionGuardAppliesToEveryAfterUpdateHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionAfterUpdateHandler firstHandler = new RecursionAfterUpdateHandler();
        RecursionSecondAfterUpdateHandler secondHandler = new RecursionSecondAfterUpdateHandler();
        RecursionGuardedAfterUpdateOrchestrator orchestrator = new RecursionGuardedAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ firstHandler, secondHandler }, 5);

        // Test
        for (Integer i = 0; i < 7; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            5,
            firstHandler.runCount,
            'It should be 5, because TriggerOrchestrator.RecursionGuard replaces the framework default of three for every handler the orchestrator returns.'
        );
        Assert.areEqual(
            5,
            secondHandler.runCount,
            'It should be 5, because the orchestrator level depth applies to every handler of that orchestrator, not only to the first one.'
        );
    }

    @IsTest
    static void handlerRecursionGuardBeatsOrchestratorRecursionGuardOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedBeforeUpdateHandler guardedHandler = new RecursionGuardedBeforeUpdateHandler(2);
        RecursionBeforeUpdateHandler unguardedHandler = new RecursionBeforeUpdateHandler();
        RecursionGuardedBeforeUpdateOrchestrator orchestrator = new RecursionGuardedBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ guardedHandler, unguardedHandler }, 5);

        // Test
        for (Integer i = 0; i < 7; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            2,
            guardedHandler.runCount,
            'It should be 2, because BeforeUpdate.RecursionGuard on the handler is resolved last and always wins over TriggerOrchestrator.RecursionGuard.'
        );
        Assert.areEqual(
            5,
            unguardedHandler.runCount,
            'It should be 5, because a handler that declares no guard keeps the orchestrator level depth when another handler overrides it.'
        );
    }

    @IsTest
    static void handlerRecursionGuardBeatsOrchestratorRecursionGuardOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedAfterUpdateHandler guardedHandler = new RecursionGuardedAfterUpdateHandler(2);
        RecursionAfterUpdateHandler unguardedHandler = new RecursionAfterUpdateHandler();
        RecursionGuardedAfterUpdateOrchestrator orchestrator = new RecursionGuardedAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ guardedHandler, unguardedHandler }, 5);

        // Test
        for (Integer i = 0; i < 7; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            2,
            guardedHandler.runCount,
            'It should be 2, because AfterUpdate.RecursionGuard on the handler is resolved last and always wins over TriggerOrchestrator.RecursionGuard.'
        );
        Assert.areEqual(
            5,
            unguardedHandler.runCount,
            'It should be 5, because a handler that declares no guard keeps the orchestrator level depth when another handler overrides it.'
        );
    }

    @IsTest
    static void noRecursionGuardAnywhereFallsBackToThreePassesOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionBeforeUpdateHandler firstHandler = new RecursionBeforeUpdateHandler();
        RecursionSecondBeforeUpdateHandler secondHandler = new RecursionSecondBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ firstHandler, secondHandler });

        // Test
        for (Integer i = 0; i < 6; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(3, firstHandler.runCount, 'It should be 3, because neither the orchestrator nor the handler declares a RecursionGuard, so the framework default applies.');
        Assert.areEqual(3, secondHandler.runCount, 'It should be 3, because the framework default of three passes per record applies to every unguarded handler.');
    }

    @IsTest
    static void noRecursionGuardAnywhereFallsBackToThreePassesOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionAfterUpdateHandler firstHandler = new RecursionAfterUpdateHandler();
        RecursionSecondAfterUpdateHandler secondHandler = new RecursionSecondAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ firstHandler, secondHandler });

        // Test
        for (Integer i = 0; i < 6; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(3, firstHandler.runCount, 'It should be 3, because neither the orchestrator nor the handler declares a RecursionGuard, so the framework default applies.');
        Assert.areEqual(3, secondHandler.runCount, 'It should be 3, because the framework default of three passes per record applies to every unguarded handler.');
    }

    @IsTest
    static void everyRecordCarriesItsOwnRecursionBudgetOnBeforeUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedBeforeUpdateHandler handler = new RecursionGuardedBeforeUpdateHandler(2);
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(4, handler.runCount, 'It should be 4, because a guard of two passes and two records in one run gives two executions per record, four in total.');
        Assert.areEqual(
            2,
            handler.runCountByRecordId.get(firstContactId),
            'It should be 2, because the counter is keyed by handler class, operation and record id, so the first record carries its own budget.'
        );
        Assert.areEqual(
            2,
            handler.runCountByRecordId.get(secondContactId),
            'It should be 2, because the second record carries its own budget and is never affected by the first one.'
        );
    }

    @IsTest
    static void everyRecordCarriesItsOwnRecursionBudgetOnAfterUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = firstContactId, LastName = 'Ada'), new Contact(Id = secondContactId, LastName = 'Bob') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(2);
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(4, handler.runCount, 'It should be 4, because a guard of two passes and two records in one run gives two executions per record, four in total.');
        Assert.areEqual(
            2,
            handler.runCountByRecordId.get(firstContactId),
            'It should be 2, because the counter is keyed by handler class, operation and record id, so the first record carries its own budget.'
        );
        Assert.areEqual(
            2,
            handler.runCountByRecordId.get(secondContactId),
            'It should be 2, because the second record carries its own budget and is never affected by the first one.'
        );
    }

    @IsTest
    static void exhaustedRecordDoesNotConsumeAnotherRecordBudgetOnAfterUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id exhaustedContactId = firstContactId;
        Id lateContactId = secondContactId;
        Contact exhaustedContact = new Contact(Id = exhaustedContactId, LastName = 'Ada');
        Contact lateContact = new Contact(Id = lateContactId, LastName = 'Bob');
        List<SObject> firstNewRecords = new List<Contact>{ exhaustedContact };
        List<SObject> firstOldRecords = new List<Contact>{ exhaustedContact.clone(true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(2);
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        for (Integer i = 0; i < 3; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = firstNewRecords;
            orchestratorRunner.context.triggerOldRecords = firstOldRecords;
            orchestratorRunner.run();
        }

        List<SObject> secondNewRecords = new List<Contact>{ exhaustedContact, lateContact };
        List<SObject> secondOldRecords = new List<Contact>{ exhaustedContact.clone(true), lateContact.clone(true) };

        // Test
        for (Integer i = 0; i < 3; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner2.context.triggerNewRecords = secondNewRecords;
            orchestratorRunner2.context.triggerOldRecords = secondOldRecords;
            orchestratorRunner2.run();
        }

        // Verify
        Assert.areEqual(
            2,
            handler.runCountByRecordId.get(exhaustedContactId),
            'It should be 2, because the counter lives for the whole transaction, so the record that already spent its two passes gains nothing from a later statement.'
        );
        Assert.areEqual(2, handler.runCountByRecordId.get(lateContactId), 'It should be 2, because one record exhausting its budget never consumes the budget of another record.');
        Assert.areEqual(4, handler.runCount, 'It should be 4, because each of the two records is worth two passes of its own.');
    }

    @IsTest
    static void unqualifiedRecordDoesNotConsumeRecursionBudgetOnBeforeUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id qualifiedContactId = firstContactId;
        Id rejectedContactId = secondContactId;
        Contact qualifiedContact = new Contact(Id = qualifiedContactId, LastName = 'Qualified');
        Contact rejectedContact = new Contact(Id = rejectedContactId, LastName = 'Rejected');
        List<SObject> newRecords = new List<Contact>{ qualifiedContact, rejectedContact };
        List<SObject> oldRecords = new List<Contact>{ qualifiedContact.clone(true), rejectedContact.clone(true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionSelectiveBeforeUpdateHandler handler = new RecursionSelectiveBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        rejectedContact.LastName = 'Qualified';

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner2.context.triggerNewRecords = newRecords;
            orchestratorRunner2.context.triggerOldRecords = oldRecords;
            orchestratorRunner2.run();
        }

        // Verify
        Assert.areEqual(3, handler.runCountByRecordId.get(qualifiedContactId), 'It should be 3, because the qualified record spent the framework default of three passes.');
        Assert.areEqual(
            3,
            handler.runCountByRecordId.get(rejectedContactId),
            'It should be 3, because the counter increments only for qualified records, so the five rejected passes left the whole budget untouched.'
        );
    }

    @IsTest
    static void unqualifiedRecordDoesNotConsumeRecursionBudgetOnAfterUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id qualifiedContactId = firstContactId;
        Id rejectedContactId = secondContactId;
        Contact qualifiedContact = new Contact(Id = qualifiedContactId, LastName = 'Qualified');
        Contact rejectedContact = new Contact(Id = rejectedContactId, LastName = 'Rejected');
        List<SObject> newRecords = new List<Contact>{ qualifiedContact, rejectedContact };
        List<SObject> oldRecords = new List<Contact>{ qualifiedContact.clone(true), rejectedContact.clone(true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionSelectiveAfterUpdateHandler handler = new RecursionSelectiveAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        rejectedContact.LastName = 'Qualified';

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner2.context.triggerNewRecords = newRecords;
            orchestratorRunner2.context.triggerOldRecords = oldRecords;
            orchestratorRunner2.run();
        }

        // Verify
        Assert.areEqual(3, handler.runCountByRecordId.get(qualifiedContactId), 'It should be 3, because the qualified record spent the framework default of three passes.');
        Assert.areEqual(
            3,
            handler.runCountByRecordId.get(rejectedContactId),
            'It should be 3, because the counter increments only for qualified records, so the five rejected passes left the whole budget untouched.'
        );
    }

    @IsTest
    static void exhaustedRecordIsSkippedBeforeItsQualificationRunsOnAfterUpdate() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id qualifiedContactId = firstContactId;
        Id rejectedContactId = secondContactId;
        Contact qualifiedContact = new Contact(Id = qualifiedContactId, LastName = 'Qualified');
        Contact rejectedContact = new Contact(Id = rejectedContactId, LastName = 'Rejected');
        List<SObject> newRecords = new List<Contact>{ qualifiedContact, rejectedContact };
        List<SObject> oldRecords = new List<Contact>{ qualifiedContact.clone(true), rejectedContact.clone(true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionSelectiveAfterUpdateHandler handler = new RecursionSelectiveAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 4; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            7,
            handler.qualificationCount,
            'It should be 7, because a record over its budget is skipped before its predicate is evaluated, while the record that never qualifies is still asked on every pass.'
        );
    }

    @IsTest
    static void recursionBudgetIsIndependentPerHandlerOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedBeforeUpdateHandler guardedHandler = new RecursionGuardedBeforeUpdateHandler(1);
        RecursionBeforeUpdateHandler unguardedHandler = new RecursionBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ guardedHandler, unguardedHandler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(1, guardedHandler.runCount, 'It should be 1, because the counter is keyed by handler class, so this handler spends only its own single pass.');
        Assert.areEqual(
            3,
            unguardedHandler.runCount,
            'It should be 3, because one handler exhausting its budget for a record never consumes another handler budget for the same record.'
        );
    }

    @IsTest
    static void recursionBudgetIsIndependentPerHandlerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedAfterUpdateHandler guardedHandler = new RecursionGuardedAfterUpdateHandler(1);
        RecursionAfterUpdateHandler unguardedHandler = new RecursionAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ guardedHandler, unguardedHandler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(1, guardedHandler.runCount, 'It should be 1, because the counter is keyed by handler class, so this handler spends only its own single pass.');
        Assert.areEqual(
            3,
            unguardedHandler.runCount,
            'It should be 3, because one handler exhausting its budget for a record never consumes another handler budget for the same record.'
        );
    }

    @IsTest
    static void beforeUpdateAndAfterUpdateBudgetsAreIndependentForOneHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionBothUpdatesHandler handler = new RecursionBothUpdatesHandler();
        RecursionBothUpdatesOrchestrator orchestrator = new RecursionBothUpdatesOrchestrator(handler);

        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(orchestrator);
            orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner2.context.triggerNewRecords = newRecords;
            orchestratorRunner2.context.triggerOldRecords = oldRecords;
            orchestratorRunner2.run();
        }

        // Verify
        Assert.areEqual(3, handler.beforeUpdateRunCount, 'It should be 3, because the before update budget of the handler stops at the framework default.');
        Assert.areEqual(
            3,
            handler.afterUpdateRunCount,
            'It should be 3, because the counter key carries the trigger operation, so the after update budget is untouched by the exhausted before update one.'
        );
    }

    @IsTest
    static void recordOverTheRecursionLimitIsSkippedSilentlyOnBeforeUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionLogger logger = new RecursionLogger();

        TriggerOrchestrator.TriggerSettings.logger = logger;

        RecursionGuardedBeforeUpdateHandler handler = new RecursionGuardedBeforeUpdateHandler(1);
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });
        Exception orchestratorException = null;

        // Test
        try {
            for (Integer i = 0; i < 3; i++) {
                TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
                orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
                orchestratorRunner.context.triggerNewRecords = newRecords;
                orchestratorRunner.context.triggerOldRecords = oldRecords;
                orchestratorRunner.run();
            }
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because a record over its recursion budget is skipped silently instead of raising an exception.');
        Assert.areEqual(1, handler.runCount, 'It should be 1, because a guard of one lets each record reach the handler once per transaction and skips every later pass.');
        Assert.areEqual(0, logger.loggedErrors.size(), 'It should be 0, because nothing about a skipped record reaches the Logger.');
        Assert.areEqual(3, logger.finalizeCount, 'It should be 3, because run() finalizes the Logger once per top level invocation even when every record was skipped.');
    }

    @IsTest
    static void recordOverTheRecursionLimitIsSkippedSilentlyOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionLogger logger = new RecursionLogger();

        TriggerOrchestrator.TriggerSettings.logger = logger;

        RecursionGuardedAfterUpdateHandler handler = new RecursionGuardedAfterUpdateHandler(1);
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });
        Exception orchestratorException = null;

        // Test
        try {
            for (Integer i = 0; i < 3; i++) {
                TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
                orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
                orchestratorRunner.context.triggerNewRecords = newRecords;
                orchestratorRunner.context.triggerOldRecords = oldRecords;
                orchestratorRunner.run();
            }
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because a record over its recursion budget is skipped silently instead of raising an exception.');
        Assert.areEqual(1, handler.runCount, 'It should be 1, because a guard of one lets each record reach the handler once per transaction and skips every later pass.');
        Assert.areEqual(0, logger.loggedErrors.size(), 'It should be 0, because nothing about a skipped record reaches the Logger.');
        Assert.areEqual(3, logger.finalizeCount, 'It should be 3, because run() finalizes the Logger once per top level invocation even when every record was skipped.');
    }

    @IsTest
    static void exhaustedRecursionBudgetSkipsTheFinalizerOnAfterUpdate() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionFinalizingAfterUpdateHandler handler = new RecursionFinalizingAfterUpdateHandler(1);
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 3; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(1, handler.runCount, 'It should be 1, because a guard of one lets each record reach the handler once per transaction and skips every later pass.');
        Assert.areEqual(
            1,
            handler.finalizeCount,
            'It should be 1, because a handler whose records are all over the recursion budget qualifies nothing, and a finalizer fires only when at least one record qualified.'
        );
    }

    @IsTest
    static void twoInstancesOfOneHandlerClassShareOneRecursionBudget() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionAfterUpdateHandler firstInstance = new RecursionAfterUpdateHandler();
        RecursionAfterUpdateHandler secondInstance = new RecursionAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ firstInstance, secondInstance });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            3,
            firstInstance.runCount + secondInstance.runCount,
            'It should be 3, because the counter is keyed by handler class name, so two instances of one class share a single budget of three passes per record.'
        );
        Assert.areEqual(
            2,
            firstInstance.runCount,
            'It should be 2, because the instance listed first drains the shared budget on every pass before the second instance is reached.'
        );
        Assert.areEqual(1, secondInstance.runCount, 'It should be 1, because the second instance only gets the passes the first instance left in the shared budget.');
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

        Id firstContactId = newRecords[0].Id;
        Id lastContactId = newRecords[200].Id;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionBeforeUpdateHandler handler = new RecursionBeforeUpdateHandler();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(201, handler.runCount, 'It should be 201, because a batch crossing the chunk boundary is processed record by record exactly once.');
        Assert.areEqual(201, handler.runCountByRecordId.size(), 'It should be 201, because every record of the batch carries its own counter.');
        Assert.areEqual(
            1,
            handler.runCountByRecordId.get(firstContactId),
            'It should be 1, because a record inside the first 200 record chunk spends a single pass of its budget.'
        );
        Assert.areEqual(
            1,
            handler.runCountByRecordId.get(lastContactId),
            'It should be 1, because chunking is not recursion, so the record past the 200 record boundary spends a single pass like every other one.'
        );
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

        Id lastContactId = newRecords[200].Id;

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionAfterUpdateHandler handler = new RecursionAfterUpdateHandler();
        RecursionAfterUpdateOrchestrator orchestrator = new RecursionAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 4; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(603, handler.runCount, 'It should be 603, because each of the 201 records keeps its own budget of three passes.');
        Assert.areEqual(
            3,
            handler.runCountByRecordId.get(lastContactId),
            'It should be 3, because the record past the 200 record boundary is given the same budget as every other record, chunk size does not spend it.'
        );
    }

    @IsTest
    static void recursionGuardDoesNotApplyToAfterInsert() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionAfterInsertHandler handler = new RecursionAfterInsertHandler();
        RecursionAfterInsertOrchestrator orchestrator = new RecursionAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(5, handler.runCount, 'It should be 5, because recursion control covers the update contexts only, so after insert keeps no counter at all.');
    }

    @IsTest
    static void recursionGuardDoesNotApplyToBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionBeforeUpdateValidator handler = new RecursionBeforeUpdateValidator();
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            5,
            handler.runCount,
            'It should be 5, because recursion control covers populators only. A validator that qualifies attaches an error and ends that record\'s save, so it cannot drive re-entry and keeps no counter.'
        );
    }

    @IsTest
    static void handlerRecursionGuardIsInertOnABeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Ada') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        RecursionGuardedBeforeUpdateValidator handler = new RecursionGuardedBeforeUpdateValidator(2);
        RecursionBeforeUpdateOrchestrator orchestrator = new RecursionBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler });

        // Test
        for (Integer i = 0; i < 5; i++) {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        }

        // Verify
        Assert.areEqual(
            5,
            handler.runCount,
            'It should be 5, because BeforeUpdate.RecursionGuard has no effect on a validator. The cap exists for handlers that can be re-entered, and a validator that fires takes its record out of the save.'
        );
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

    private class RecursionGuardedBeforeUpdateOrchestrator implements TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.RecursionGuard {
        private List<BeforeUpdate.Handler> handlers;
        private Integer maxRecursionDepth;

        public RecursionGuardedBeforeUpdateOrchestrator(List<BeforeUpdate.Handler> handlers, Integer maxRecursionDepth) {
            this.handlers = handlers;
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepth() {
            return this.maxRecursionDepth;
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

    private class RecursionGuardedAfterUpdateOrchestrator implements TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursionGuard {
        private List<AfterUpdate.Handler> handlers;
        private Integer maxRecursionDepth;

        public RecursionGuardedAfterUpdateOrchestrator(List<AfterUpdate.Handler> handlers, Integer maxRecursionDepth) {
            this.handlers = handlers;
            this.maxRecursionDepth = maxRecursionDepth;
        }

        public Integer maxRecursionDepth() {
            return this.maxRecursionDepth;
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

    @IsTest
    static void continueOnErrorHandlerFailureLetsTheRunFinish() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Continue') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingMutedFailingHandler failingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because ContinueOnError keeps a handler failure from ending the invocation.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler that fails is still executed before its exception is swallowed.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because handlers registered after a ContinueOnError failure still take their turn.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because a swallowed failure is still reported to the logger.');
    }

    @IsTest
    static void continueOnErrorHandlerStopsAtItsFailingRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingMutedFailingHandler failingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception ends that handler turn, so its remaining records are not processed.');
        Assert.areEqual(2, laterHandler.executionCount, 'It should be 2, because the next handler starts a fresh turn over all records.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the orchestrator catches once per handler turn, not once per record.');
    }

    @IsTest
    static void continueOnErrorLogsEveryFailingHandler() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Continue') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingMutedFailingHandler firstFailingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingMutedBadCastHandler secondFailingHandler = new ErrorsLoggingMutedBadCastHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ firstFailingHandler, secondFailingHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, logger.errors.size(), 'It should be 2, because every handler that fails reaches the logger, and ContinueOnError only stops the exception.');
        Assert.areEqual(
            'ErrorsLoggingMutedFailingHandler',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingMutedFailingHandler, because each error names the handler that raised it.'
        );
        Assert.areEqual(
            'ErrorsLoggingMutedBadCastHandler',
            logger.errors[1].getHandlerName(),
            'It should be ErrorsLoggingMutedBadCastHandler, because each error names the handler that raised it.'
        );
    }

    @IsTest
    static void handlerWithoutContinueOnErrorAbortsTheRun() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingFailingHandler failingHandler = new ErrorsLoggingFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a handler without ContinueOnError ends the invocation.');
        Assert.areEqual(
            'Handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the framework rethrows the handler exception as it is.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception is raised by the handler that actually ran.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because no later handler runs once the invocation is aborted.');
    }

    @IsTest
    static void handlerWithoutContinueOnErrorPropagatesItsOwnExceptionType() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isTrue(orchestratorException instanceof ErrorsLoggingException, 'It should be the handler own exception type, because the framework never wraps a handler failure.');
    }

    @IsTest
    static void loggerReceivesContinueOnErrorFailureWithHandlerNameAndOperation() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Continue') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedFailingHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because a muted failure is still reported to the logger.');
        Assert.areEqual(
            'ErrorsLoggingMutedFailingHandler',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingMutedFailingHandler, because the error names the handler class being processed.'
        );
        Assert.areEqual(
            System.TriggerOperation.AFTER_INSERT,
            logger.errors[0].getOperation(),
            'It should be AFTER_INSERT, because the error carries the operation of the invocation.'
        );
        Assert.areEqual(
            'Handler failed on purpose.',
            logger.errors[0].getException().getMessage(),
            'It should be the handler message, because the error carries the exception that was thrown.'
        );
    }

    @IsTest
    static void loggerReceivesUncaughtErrorBeforeItPropagates() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the handler does not implement ContinueOnError.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because an uncaught handler failure reaches the logger too.');
        Assert.areEqual(
            orchestratorException.getMessage(),
            logger.errors[0].getException().getMessage(),
            'It should be the exception that propagated, because the logger receives that same exception before it leaves the invocation.'
        );
        Assert.areEqual(
            0,
            logger.finalizeCountWhenLogged[0],
            'It should be 0, because the error is logged while the invocation is still running, before finalize and before the exception propagates.'
        );
    }

    @IsTest
    static void loggerErrorCarriesHandlerNameSObjectTypeOperationAndRecordIds() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ new ErrorsLoggingMutedFailingAfterUpdateHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the failing handler turn is reported once.');
        Assert.areEqual(
            'ErrorsLoggingMutedFailingAfterUpdateHandler',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingMutedFailingAfterUpdateHandler, because the error names the handler class being processed.'
        );
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'It should be Contact, because the error carries the SObject type of the trigger records.');
        Assert.areEqual(
            System.TriggerOperation.AFTER_UPDATE,
            logger.errors[0].getOperation(),
            'It should be AFTER_UPDATE, because the error carries the operation of the invocation.'
        );
        Assert.areEqual(
            new Set<Id>{ contactId },
            logger.errors[0].getRecordIds(),
            'It should be the ids of the whole chunk, because the error carries the keys of the new record map, not only the qualified records.'
        );
        Assert.isTrue(
            logger.errors[0].getException() instanceof ErrorsLoggingException,
            'It should be the handler exception, because the error carries the exception that was thrown.'
        );
    }

    @IsTest
    static void loggerErrorCarriesRecordIdsFromTheOldMapInAfterDelete() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ new ErrorsLoggingMutedFailingAfterDeleteHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the failing handler turn is reported once.');
        Assert.areEqual(
            new Set<Id>{ contactId },
            logger.errors[0].getRecordIds(),
            'It should be the ids of the deleted records, because a delete context has no new map and falls back to the old one.'
        );
        Assert.areEqual(Contact.SObjectType, logger.errors[0].getSObjectType(), 'It should be Contact, because a delete context takes the SObject type from the deleted rows.');
        Assert.areEqual(
            System.TriggerOperation.AFTER_DELETE,
            logger.errors[0].getOperation(),
            'It should be AFTER_DELETE, because the error carries the operation of the invocation.'
        );
    }

    @IsTest
    static void loggerErrorCarriesNoRecordIdsInBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Insert') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingFailingPopulator() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the populator has no ContinueOnError.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the populator failure reaches the logger before it propagates.');
        Assert.isTrue(logger.errors[0].getRecordIds().isEmpty(), 'It should be empty, because before insert records have no id yet and there is nothing to report.');
        Assert.areEqual(
            Contact.SObjectType,
            logger.errors[0].getSObjectType(),
            'It should be Contact, because the SObject type comes from the trigger records, not from their ids.'
        );
    }

    @IsTest
    static void loggerReceivesErrorFromQualificationPredicate() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Qualify') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingQualifierHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a failure in the qualification predicate ends the invocation like any other handler failure.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the logger covers the handler qualification predicate too.');
        Assert.areEqual(
            'ErrorsLoggingFailingQualifierHandler',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingFailingQualifierHandler, because the error names the handler whose predicate failed.'
        );
        Assert.areEqual(
            'Qualification failed on purpose.',
            logger.errors[0].getException().getMessage(),
            'It should be the predicate message, because the exception raised in the ...When method is the one reported.'
        );
    }

    @IsTest
    static void loggerReceivesErrorFromFinalizer() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Finalize') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingFinalizerHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the finalizer runs inside the handler turn.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the logger covers the handler finalizer too.');
        Assert.areEqual(
            'ErrorsLoggingFailingFinalizerHandler',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingFailingFinalizerHandler, because the error names the handler whose finalizer failed.'
        );
        Assert.areEqual(
            'Finalizer failed on purpose.',
            logger.errors[0].getException().getMessage(),
            'It should be the finalizer message, because the exception raised after the qualified records is the one reported.'
        );
    }

    @IsTest
    static void loggerReceivesNothingWhenEveryHandlerSucceeds() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Clean') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler handler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.executionCount, 'It should be 1, because the handler qualifies the only record in the chunk.');
        Assert.areEqual(0, logger.errors.size(), 'It should be 0, because log is called only for an exception raised while a handler runs.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because finalize runs once per top level invocation, successful or not.');
    }

    @IsTest
    static void loggerFinalizeRunsOnceOnAFailedInvocation() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the handler does not implement ContinueOnError.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because finalize runs whether the invocation succeeded or failed.');
    }

    @IsTest
    static void loggerFinalizeRunsOncePerInvocation() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Chunk') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingCountingHandler(), new ErrorsLoggingCountingHandler() })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingCountingHandler(), new ErrorsLoggingCountingHandler() })
        );
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.triggerNewRecords = records;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(
            2,
            logger.finalizeCount,
            'It should be 2, because finalize runs once per top level invocation, which means once per trigger phase per chunk, not once per handler and not once per transaction.'
        );
    }

    @IsTest
    static void loggerFinalizeIsSkippedForANestedInvocation() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Nested') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler nestedHandler = new ErrorsLoggingCountingHandler();
        ErrorsLoggingNestedRunHandler outerHandler = new ErrorsLoggingNestedRunHandler(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ nestedHandler }),
            logger
        );

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ outerHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, nestedHandler.executionCount, 'It should be 1, because a nested run dispatches its own handler list over the same chunk.');
        Assert.areEqual(
            0,
            outerHandler.finalizeCountAfterNestedRun,
            'It should be 0, because a nested invocation must not flush the logger while the outer invocation is still running.'
        );
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because a nested invocation does not call finalize, only the outermost one does.');
    }

    @IsTest
    static void loggerFinalizeIsSkippedForANestedInvocationThatDispatchesNothing() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Nested') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingNestedRunHandler outerHandler = new ErrorsLoggingNestedRunHandler(new ErrorsLoggingNoInterfaceOrchestrator(), logger);

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ outerHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            outerHandler.finalizeCountAfterNestedRun,
            'It should be 0, because a nested invocation that dispatches no handler must not flush the logger mid invocation either.'
        );
        Assert.areEqual(
            1,
            logger.finalizeCount,
            'It should be 1, because a nested invocation never calls finalize, not even when the orchestrator does not implement the current context.'
        );
    }

    @IsTest
    static void frameworkExceptionIsRethrownForAContinueOnErrorHandler() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingPopulator laterHandler = new ErrorsLoggingCountingPopulator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingMutedDmlPopulator(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because ContinueOnError covers a handler own exceptions, never a framework contract violation.');
        Assert.areEqual(
            'ErrorsLoggingMutedDmlPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler, because the before context DML guard identifies the class that performed the DML.'
        );
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a framework failure aborts the invocation instead of moving to the next handler.');
    }

    @IsTest
    static void loggerReceivesFrameworkGuardViolationBeforeItPropagates() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingMutedDmlPopulator() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the logger sees the framework exception first and it still propagates.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because a framework exception raised against a handler reaches the logger before it propagates.');
        Assert.areEqual(
            'ErrorsLoggingMutedDmlPopulator',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingMutedDmlPopulator, because the error names the handler the framework raised it against.'
        );
        Assert.areEqual(
            System.TriggerOperation.BEFORE_INSERT,
            logger.errors[0].getOperation(),
            'It should be BEFORE_INSERT, because the error carries the operation of the invocation.'
        );
        Assert.areEqual(
            'ErrorsLoggingMutedDmlPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            logger.errors[0].getException().getMessage(),
            'It should be the guard message, because the logger receives the framework exception itself.'
        );
        Assert.areEqual(0, logger.finalizeCountWhenLogged[0], 'It should be 0, because the guard error is logged while the invocation is still running.');
    }

    @IsTest
    static void frameworkExceptionFromANestedInvocationIsRethrownForAContinueOnErrorHandler() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Nested') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingPopulator laterHandler = new ErrorsLoggingCountingPopulator();
        ErrorsLoggingMutedNestedRunPopulator outerHandler = new ErrorsLoggingMutedNestedRunPopulator(
            new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new ErrorsLoggingMutedRecordApiPopulator() })
        );

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ outerHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because any framework exception raised while a handler runs is rethrown even under ContinueOnError.');
        Assert.areEqual(
            'Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.',
            orchestratorException.getMessage(),
            'It should be the handler exception message, because the nested invocation rethrows it unwrapped.'
        );
        Assert.areEqual(
            2,
            logger.errors.size(),
            'It should be 2, because the nested invocation logs it against its own handler and the outer invocation logs it again against the handler that was running.'
        );
        Assert.areEqual(
            'ErrorsLoggingMutedRecordApiPopulator',
            logger.errors[0].getHandlerName(),
            'It should be ErrorsLoggingMutedRecordApiPopulator, because the nested invocation reports the handler that raised it.'
        );
        Assert.areEqual(
            'ErrorsLoggingMutedNestedRunPopulator',
            logger.errors[1].getHandlerName(),
            'It should be ErrorsLoggingMutedNestedRunPopulator, because the outer invocation reports the handler being processed when it surfaced.'
        );
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a framework failure aborts the invocation.');
    }

    @IsTest
    static void triggerHandlerExceptionIsRethrownForAContinueOnErrorHandler() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Record API') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        TriggerHandler.TriggerHandlerException recordApiException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedRecordApiHandler(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (TriggerHandler.TriggerHandlerException e) {
            recordApiException = e;
        }

        // Verify
        Assert.isNotNull(recordApiException, 'It should be thrown, because a TriggerHandlerException is a framework failure that ContinueOnError never suppresses.');
        Assert.areEqual(
            'Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.',
            recordApiException.getMessage(),
            'It should be the record API message, because the exception is rethrown as it is.'
        );
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because the invocation is aborted instead of moving to the next handler.');
    }

    @IsTest
    static void loggerReceivesTriggerHandlerExceptionBeforeItPropagates() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Record API') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedRecordApiHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a record API failure is logged and then rethrown.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the logger receives the TriggerHandlerException before it propagates.');
        Assert.areEqual(
            'TriggerHandler.TriggerHandlerException',
            logger.errors[0].getException().getTypeName(),
            'It should be TriggerHandler.TriggerHandlerException, because the record API exception reaches the logger unchanged.'
        );
        Assert.areEqual(0, logger.finalizeCountWhenLogged[0], 'It should be 0, because the error is logged while the invocation is still running.');
    }

    @IsTest
    static void platformBadCastPropagatesUnchanged() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Platform') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingBadCastHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a handler without ContinueOnError ends the invocation.');
        Assert.areEqual(
            'System.TypeException',
            orchestratorException.getTypeName(),
            'It should be System.TypeException, because the framework never wraps or translates a platform exception.'
        );
        Assert.areEqual(
            'Invalid conversion from runtime type String to Integer',
            orchestratorException.getMessage(),
            'It should be the original Salesforce message, because the framework rethrows the platform exception as it is.'
        );
    }

    @IsTest
    static void platformNullDereferencePropagatesUnchanged() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Platform') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingNullDereferenceHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.areEqual(
            'System.NullPointerException',
            orchestratorException.getTypeName(),
            'It should be System.NullPointerException, because the original Salesforce type reaches the caller.'
        );
        Assert.areEqual(
            'Attempt to de-reference a null object',
            orchestratorException.getMessage(),
            'It should be the original Salesforce message, because the framework never translates a platform exception.'
        );
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the logger sees a platform exception first, like any other handler failure.');
    }

    @IsTest
    static void platformExceptionIsSwallowedByContinueOnError() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Platform') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
            new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingMutedBadCastHandler(), laterHandler })
        );
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because ContinueOnError applies to a platform exception like any other exception the handler raises.');
        Assert.areEqual(1, logger.errors.size(), 'It should be 1, because the swallowed platform exception is still reported to the logger.');
        Assert.areEqual(
            'System.TypeException',
            logger.errors[0].getException().getTypeName(),
            'It should be System.TypeException, because the platform exception reaches the logger unchanged.'
        );
    }

    @IsTest
    static void emptyHandlerListRunsNothing() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Empty') };
        ErrorsLoggingLogger logger = new ErrorsLoggingLogger();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = logger;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because an orchestrator that returns an empty list runs nothing and lets the DML through.');
        Assert.areEqual(0, logger.errors.size(), 'It should be 0, because no handler ran and nothing failed.');
        Assert.areEqual(1, logger.finalizeCount, 'It should be 1, because finalize runs once per top level invocation even when no handler ran.');
    }

    @IsTest
    static void withoutALoggerAFailureStillPropagates() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'No logger') };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = null;

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ new ErrorsLoggingFailingHandler() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because no Logger implementation means errors are simply rethrown.');
        Assert.areEqual(
            'Handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because nothing else changes when there is no logger.'
        );
    }

    @IsTest
    static void withoutALoggerAContinueOnErrorFailureIsStillSwallowed() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'No logger') };
        ErrorsLoggingMutedFailingHandler failingHandler = new ErrorsLoggingMutedFailingHandler();
        ErrorsLoggingCountingHandler laterHandler = new ErrorsLoggingCountingHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        TriggerOrchestrator.TriggerSettings.logger = null;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ErrorsLoggingAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler that fails is still executed when no logger is implemented.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because ContinueOnError does not depend on a Logger being implemented.');
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
            orchestratorRunner2.context.triggerNewRecords = new List<Contact>{ new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'Nested') };
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
            orchestratorRunner3.context.triggerNewRecords = new List<Contact>{ new Contact(LastName = 'Nested') };
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

    @IsTest
    static void beforeInsertPopulatorPerformingDmlThrows() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertPopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a before insert populator performed DML and the guard has no opt-out.');
        Assert.areEqual(
            'DmlGuardInsertPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the populator, because the DML is attributed to the handler whose measured span the statement counter grew in.'
        );
        Assert.isTrue(
            orchestratorException.getTypeName().endsWith('TriggerOrchestratorException'),
            'It should be a TriggerOrchestratorException, because a framework contract violation is raised as that type and never as a bare platform exception.'
        );
    }

    @IsTest
    static void beforeInsertValidatorPerformingDmlThrows() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertValidator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard applies to a Validator exactly as it applies to a Populator.');
        Assert.areEqual(
            'DmlGuardInsertValidator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the validator, because the validation message method runs inside the measured span like any other handler code.'
        );
    }

    @IsTest
    static void beforeInsertFinalizerPerformingDmlThrows() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardInsertFinalizer handler = new DmlGuardInsertFinalizer();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isTrue(handler.isFinalized, 'It should be true, because a handler that qualified at least one record always gets its finalizer.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the finalizer runs inside the same measured span as the action method.');
        Assert.areEqual(
            'DmlGuardInsertFinalizer performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler, because DML performed by the finalizer is attributed to the handler that owns it.'
        );
    }

    @IsTest
    static void beforeInsertQualificationPerformingDmlThrows() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardInsertQualifier handler = new DmlGuardInsertQualifier();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.areEqual(0, handler.populateCount, 'It should be 0, because a predicate that returns false qualifies no record and the action method never runs.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard spans the handler whole turn, qualification included.');
        Assert.areEqual(
            'DmlGuardInsertQualifier performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler, because DML performed inside the when method is attributed to the handler that declares it.'
        );
    }

    @IsTest
    static void beforeInsertDmlBelowTheHandlerThrows() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertServicePopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the guard counts DML performed anywhere below the handler, including inside a service class it calls.'
        );
        Assert.areEqual(
            'DmlGuardInsertServicePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler and not the service class, because the guard measures a handler span and knows only the handler.'
        );
    }

    @IsTest
    static void beforeInsertWithoutDmlDoesNotThrow() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardInsertSilentPopulator handler = new DmlGuardInsertSilentPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the guard fires only when the DML statement counter increases across the handler span.');
        Assert.areEqual(1, handler.populateCount, 'It should be 1, because a populator that only writes to the trigger record is exactly what a before context is for.');
        Assert.areEqual('Guard', records[0].get(Contact.Department), 'It should be Guard, because put writes straight to the trigger record instead of issuing DML.');
    }

    @IsTest
    static void beforeInsertGuardNamesTheHandlerThatPerformedDml() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardInsertSilentPopulator cleanHandler = new DmlGuardInsertSilentPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new DmlGuardBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ cleanHandler, new DmlGuardInsertPopulator() })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.areEqual(1, cleanHandler.populateCount, 'It should be 1, because handlers run in list order and a handler that performs no DML passes its own span untouched.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because one handler in the list performed DML in a before context.');
        Assert.areEqual(
            'DmlGuardInsertPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the second handler, because each handler is measured over its own span and only the offender is named.'
        );
    }

    @IsTest
    static void beforeInsertContinueOnErrorDoesNotSuppressGuard() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardInsertSilentPopulator laterHandler = new DmlGuardInsertSilentPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new DmlGuardBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ new DmlGuardInsertContinuePopulator(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because ContinueOnError covers a handler own exceptions, never a framework contract violation.');
        Assert.areEqual(
            'DmlGuardInsertContinuePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message, because the guard has no opt-out and ContinueOnError does not suppress it.'
        );
        Assert.areEqual(0, laterHandler.populateCount, 'It should be 0, because a framework contract violation aborts the invocation instead of continuing with the next handler.');
    }

    @IsTest
    static void beforeInsertGuardSurvivesHandlerException() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(new DmlGuardInsertContinueThrowingPopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard runs in a finally, so throwing after the DML is not a way past it.');
        Assert.areEqual(
            'DmlGuardInsertContinueThrowingPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message and not the handler own message, because the exception raised in the finally replaces the one the handler threw.'
        );
    }

    @IsTest
    static void beforeInsertHandlerExceptionWithoutDmlStaysSilent() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardInsertContinueFailingPopulator handler = new DmlGuardInsertContinueFailingPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isTrue(handler.hasThrown, 'It should be true, because ContinueOnError mutes the error afterwards, it does not stop the handler from running.');
        Assert.isNull(
            orchestratorException,
            'It should be null, because a handler that throws without having done DML leaves the guard silent and ContinueOnError swallows its own exception.'
        );
    }

    @IsTest
    static void beforeUpdatePopulatorPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdatePopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard covers before update exactly as it covers before insert.');
        Assert.areEqual(
            'DmlGuardUpdatePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the populator, because the DML is attributed to the handler whose measured span the statement counter grew in.'
        );
    }

    @IsTest
    static void beforeUpdateValidatorPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdateValidator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard applies to a Validator exactly as it applies to a Populator.');
        Assert.areEqual(
            'DmlGuardUpdateValidator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the validator, because the validation message method runs inside the measured span like any other handler code.'
        );
    }

    @IsTest
    static void beforeUpdateFinalizerPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardUpdateFinalizer handler = new DmlGuardUpdateFinalizer();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isTrue(handler.isFinalized, 'It should be true, because a handler that qualified at least one record always gets its finalizer.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the finalizer runs inside the same measured span as the action method.');
        Assert.areEqual(
            'DmlGuardUpdateFinalizer performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler, because DML performed by the finalizer is attributed to the handler that owns it.'
        );
    }

    @IsTest
    static void beforeUpdateQualificationPerformingDmlThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardUpdateQualifier handler = new DmlGuardUpdateQualifier();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.areEqual(0, handler.populateCount, 'It should be 0, because a predicate that returns false qualifies no record and the action method never runs.');
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard spans the handler whole turn, qualification included.');
        Assert.areEqual(
            'DmlGuardUpdateQualifier performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the handler, because DML performed inside the when method is attributed to the handler that declares it.'
        );
    }

    @IsTest
    static void beforeUpdateUpdateStatementThrows() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account existingAccount = new Account(Name = 'Guard');
        insert existingAccount;
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdateStatementPopulator(existingAccount)));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard counts DML statements of every kind, not only inserts.');
        Assert.areEqual(
            'DmlGuardUpdateStatementPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message naming the populator, because any statement raising the DML counter inside the span is attributed to the handler.'
        );
    }

    @IsTest
    static void beforeUpdateWithoutDmlDoesNotThrow() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardUpdateSilentPopulator handler = new DmlGuardUpdateSilentPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the guard fires only when the DML statement counter increases across the handler span.');
        Assert.areEqual(1, handler.populateCount, 'It should be 1, because a populator that only writes to the trigger record is exactly what a before context is for.');
        Assert.areEqual('Guard', newRecords[0].get(Contact.Department), 'It should be Guard, because put writes straight to the trigger record instead of issuing DML.');
    }

    @IsTest
    static void beforeUpdateContinueOnErrorDoesNotSuppressGuard() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardUpdateSilentPopulator laterHandler = new DmlGuardUpdateSilentPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new DmlGuardBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ new DmlGuardUpdateContinuePopulator(), laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because ContinueOnError covers a handler own exceptions, never a framework contract violation.');
        Assert.areEqual(
            'DmlGuardUpdateContinuePopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message, because the guard has no opt-out and ContinueOnError does not suppress it.'
        );
        Assert.areEqual(0, laterHandler.populateCount, 'It should be 0, because a framework contract violation aborts the invocation instead of continuing with the next handler.');
    }

    @IsTest
    static void beforeUpdateGuardSurvivesHandlerException() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(new DmlGuardUpdateContinueThrowingPopulator()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because the guard runs in a finally, so throwing after the DML is not a way past it.');
        Assert.areEqual(
            'DmlGuardUpdateContinueThrowingPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.',
            orchestratorException.getMessage(),
            'It should be the guard message and not the handler own message, because the exception raised in the finally replaces the one the handler threw.'
        );
    }

    @IsTest
    static void beforeUpdateHandlerExceptionWithoutDmlStaysSilent() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardUpdateContinueFailingPopulator handler = new DmlGuardUpdateContinueFailingPopulator();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeUpdateOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isTrue(handler.hasThrown, 'It should be true, because ContinueOnError mutes the error afterwards, it does not stop the handler from running.');
        Assert.isNull(
            orchestratorException,
            'It should be null, because a handler that throws without having done DML leaves the guard silent and ContinueOnError swallows its own exception.'
        );
    }

    @IsTest
    static void afterInsertHandlerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterInsertOrchestrator(new DmlGuardAfterInsertHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the guard covers before insert and before update only, and creating other records is what an after context is for.'
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1, because an after insert handler DML runs to completion instead of being rejected.');
    }

    @IsTest
    static void afterInsertFinalizerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Guard') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        DmlGuardAfterInsertFinalizer handler = new DmlGuardAfterInsertFinalizer();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterInsertOrchestrator(handler));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.areEqual(1, handler.handledCount, 'It should be 1, because the action method runs once for the single qualified record and performs no DML of its own.');
        Assert.isTrue(handler.isFinalized, 'It should be true, because a handler that qualified at least one record always gets its finalizer.');
        Assert.isNull(orchestratorException, 'It should be null, because an after context finalizer is the place the framework tells handlers to put their DML.');
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Account WHERE Name = 'Guard'],
            'It should be 1, because the only DML in the run is the finalizer one and an after context does not guard it.'
        );
    }

    @IsTest
    static void afterUpdateHandlerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterUpdateOrchestrator(new DmlGuardAfterUpdateHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the guard covers before insert and before update only, and DML on other records is allowed after the save.'
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1, because an after update handler DML runs to completion instead of being rejected.');
    }

    @IsTest
    static void afterDeleteHandlerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterDeleteOrchestrator(new DmlGuardAfterDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the guard covers before insert and before update only.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1, because an after delete handler may write to other objects.');
    }

    @IsTest
    static void afterUndeleteHandlerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardAfterUndeleteOrchestrator(new DmlGuardAfterUndeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the guard covers before insert and before update only.');
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1, because an after undelete handler may write to other objects.');
    }

    @IsTest
    static void beforeDeleteHandlerPerformingDmlIsAllowed() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted') };
        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();
        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new DmlGuardBeforeDeleteOrchestrator(new DmlGuardBeforeDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the guard is declared for before insert and before update only, so before delete may cascade cleanup to other objects.'
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Guard'], 'It should be 1, because a before delete handler DML is committed instead of being rejected.');
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

    @IsTest
    static void finalizerFiresOnceOnBeforeInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeInsertValidator() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesBeforeInsertValidator handler = new ShapesBeforeInsertValidator();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because a validator is asked for its message once for every qualified record.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the Finalizer interface fires once per handler in the validator role too.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterInsert() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because a validator is asked for its message once for every qualified record.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnBeforeDelete() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'First'), new Contact(Id = fakeIds.next(), LastName = 'Second') };
        ShapesBeforeDeleteHandler handler = new ShapesBeforeDeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterDelete() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'First'), new Contact(Id = fakeIds.next(), LastName = 'Second') };
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerFiresOnceOnAfterUndelete() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'First'), new Contact(Id = fakeIds.next(), LastName = 'Second') };
        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(2, handler.actionCount, 'It should be 2, because the action method runs once for every qualified record.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires exactly once per handler, not once per record.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeInsertWithoutQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeInsertValidatorWithoutQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesBeforeInsertValidator handler = new ShapesBeforeInsertValidator();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because a validator whose predicate returned false attaches no message.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterInsertWithoutQualifiedRecords() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeUpdateWithoutQualifiedRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id recordId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };
        ShapesBeforeUpdatePopulator handler = new ShapesBeforeUpdatePopulator();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeUpdateValidatorWithoutQualifiedRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id recordId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };
        ShapesBeforeUpdateValidator handler = new ShapesBeforeUpdateValidator();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because a validator whose predicate returned false attaches no message.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterUpdateWithoutQualifiedRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id recordId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };
        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnBeforeDeleteWithoutQualifiedRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted') };
        ShapesBeforeDeleteHandler handler = new ShapesBeforeDeleteHandler();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterDeleteWithoutQualifiedRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted') };
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerDoesNotFireOnAfterUndeleteWithoutQualifiedRecords() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Restored') };
        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();
        handler.qualifies = false;

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.actionCount, 'It should be 0, because the action method never runs for a record the predicate rejected.');
        Assert.areEqual(0, handler.finalizeCount, 'It should be 0, because a handler that qualifies no record is skipped entirely, finalizer included.');
    }

    @IsTest
    static void finalizerRunsAfterTheLastQualifiedRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'record', 'record', 'finalize' },
            handler.events,
            'It should be record, record, finalize, because the finalizer runs only after the action method was called for every qualified record.'
        );
    }

    @IsTest
    static void finalizerRunsBeforeTheNextHandlerStarts() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Only') };

        ShapesSharedState state = new ShapesSharedState();
        ShapesAfterInsertHandler firstHandler = new ShapesAfterInsertHandler('First', state);
        ShapesAfterInsertHandler secondHandler = new ShapesAfterInsertHandler('Second', state);

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(new List<AfterInsert.Handler>{ firstHandler, secondHandler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'First record', 'First finalize', 'Second record', 'Second finalize' },
            state.events,
            'It should be the whole first handler before any of the second, because a finalizer runs after its own handler and before the next handler in the orchestrator list starts.'
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.actionCount, 'It should be 1, because only the record the predicate accepted reaches the action method.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because a single qualified record is enough to fire the finalizer exactly once.');
    }

    @IsTest
    static void finalizerDoesNotFireWhenEveryRecordIsSkippedByTheRecursionGuard() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id recordId = fakeIds.next();

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = recordId, LastName = 'Old') };

        ShapesGuardedBeforeUpdatePopulator firstPass = new ShapesGuardedBeforeUpdatePopulator(1);
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(firstPass));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        ShapesGuardedBeforeUpdatePopulator secondPass = new ShapesGuardedBeforeUpdatePopulator(1);

        // Test
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesBeforeUpdateOrchestrator(secondPass));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner2.context.triggerNewRecords = newRecords;
        orchestratorRunner2.context.triggerOldRecords = oldRecords;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(0, secondPass.actionCount, 'It should be 0, because the record exhausted its recursion budget and is skipped before qualification is even asked.');
        Assert.areEqual(0, secondPass.finalizeCount, 'It should be 0, because records the recursion guard skips never qualify, so nothing is left to finalize.');
        Assert.areEqual(1, firstPass.finalizeCount, 'It should be 1, because the first pass was still inside the budget, so its record qualified and its finalizer fired.');
    }

    @IsTest
    static void finalizerFiresAgainOnASecondInvocationOfTheSameHandlerInstance() {
        List<SObject> firstInvocation = new List<Contact>{ new Contact(LastName = 'First') };
        List<SObject> secondInvocation = new List<Contact>{ new Contact(LastName = 'Second') };
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = firstInvocation;
        orchestratorRunner.run();

        // Test
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.triggerNewRecords = secondInvocation;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(
            new List<String>{ 'record', 'finalize', 'record', 'finalize' },
            handler.events,
            'It should be record, finalize, record, finalize, because the finalizer fires once per invocation and the framework keeps no already-finalized flag on the handler.'
        );
    }

    @IsTest
    static void finalizerDoesNotFireWhenTheRecordListIsEmpty() {
        List<SObject> records = new List<Contact>();
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(0, handler.qualifyCount, 'It should be 0, because an empty invocation has no record to qualify.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(201, handler.actionCount, 'It should be 201, because every record of the invocation reaches the handler, with no internal 200-record cap.');
        Assert.areEqual(201, new Set<Id>(handler.recordIds).size(), 'It should be 201, because each record is processed exactly once per invocation, never twice.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because the finalizer fires once per invocation regardless of how many records it holds.');
    }

    @IsTest
    static void bulkInvocationQualifiesEveryRecordOnce() {
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            String leadSource = Math.mod(i, 2) == 0 ? 'Web' : 'Phone';

            contacts.add(new Contact(LastName = 'Bulk ' + i, LeadSource = leadSource));
        }

        List<SObject> records = contacts;
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();
        handler.qualifyingLeadSource = 'Web';

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(201, handler.qualifyCount, 'It should be 201, because qualification is evaluated once for every record of the invocation.');
        Assert.areEqual(101, handler.actionCount, 'It should be 101, because only the records the predicate accepted reach the action method.');
        Assert.areEqual(1, handler.finalizeCount, 'It should be 1, because a partially qualified chunk still finalizes exactly once.');
    }

    @IsTest
    static void bulkInvocationPopulatesEveryRecordOnBeforeInsert() {
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < 201; i++) {
            contacts.add(new Contact(LastName = 'Bulk ' + i));
        }

        List<SObject> records = contacts;
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(201, handler.actionCount, 'It should be 201, because a before context populates every record of the invocation.');
        Assert.areEqual('Populated', contacts[0].Description, 'It should be Populated, because put writes straight through to the trigger record the orchestrator was given.');
        Assert.areEqual('Populated', contacts[200].Description, 'It should be Populated, because the record past the 200 boundary is populated like every other one.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

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
        List<Contact> secondChunk = new List<Contact>{ new Contact(Id = lastRecordId, LastName = 'Chunk two') };

        ShapesSharedState state = new ShapesSharedState();
        List<SObject> firstRecords = firstChunk;
        List<SObject> secondRecords = secondChunk;

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(new ShapesAfterInsertHandler('Chunk', state)));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = firstRecords;
        orchestratorRunner.run();

        // Test
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(new ShapesAfterInsertHandler('Chunk', state)));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.triggerNewRecords = secondRecords;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(201, state.processedCount, 'It should be 201, because state a handler carries across chunks never makes the framework skip a record.');
        Assert.isTrue(state.processedIds.contains(lastRecordId), 'It should be true, because the record past the 200 boundary is processed by the second chunk.');
        Assert.areEqual(2, state.finalizeCount, 'It should be 2, because each chunk is a separate invocation with its own handler instances and its own finalizer call.');
    }

    @IsTest
    static void partialSaveRetryRunsHandlersAgainForSurvivors() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id survivorId = fakeIds.next();
        Id failingId = fakeIds.next();

        List<SObject> firstAttempt = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Survivor'), new Contact(Id = failingId, LastName = 'Failing') };
        List<SObject> retryAttempt = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Survivor') };

        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = firstAttempt;
        orchestratorRunner.run();

        // Test
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner2.context.triggerNewRecords = retryAttempt;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(
            new List<Id>{ survivorId, failingId, survivorId },
            handler.recordIds,
            'It should be survivor, failing, survivor, because a partial save re-runs the handlers over the surviving records and the framework de-duplicates nothing between attempts.'
        );
        Assert.areEqual(2, handler.finalizeCount, 'It should be 2, because every attempt is its own invocation and fires its own finalizer.');
    }

    @IsTest
    static void partialSaveRetryOnUpdateIsNotSkippedByTheRecursionGuard() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id survivorId = fakeIds.next();
        Id failingId = fakeIds.next();

        List<SObject> firstNewRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'New Survivor'), new Contact(Id = failingId, LastName = 'New Failing') };
        List<SObject> firstOldRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Old Survivor'), new Contact(Id = failingId, LastName = 'Old Failing') };
        List<SObject> retryNewRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'New Survivor') };
        List<SObject> retryOldRecords = new List<Contact>{ new Contact(Id = survivorId, LastName = 'Old Survivor') };

        ShapesAfterUpdateHandler handler = new ShapesAfterUpdateHandler();

        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = firstNewRecords;
        orchestratorRunner.context.triggerOldRecords = firstOldRecords;
        orchestratorRunner.run();

        // Test
        TriggerOrchestrator orchestratorRunner2 = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner2.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner2.context.triggerNewRecords = retryNewRecords;
        orchestratorRunner2.context.triggerOldRecords = retryOldRecords;
        orchestratorRunner2.run();

        // Verify
        Assert.areEqual(
            new List<Id>{ survivorId, failingId, survivorId },
            handler.recordIds,
            'It should be survivor, failing, survivor, because the second pass of a partial save is still within the default budget of three passes per record.'
        );
        Assert.areEqual(2, handler.finalizeCount, 'It should be 2, because every attempt is its own invocation and fires its own finalizer.');
    }

    @IsTest
    static void beforeDeleteRecordShapeHasNoNewRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted', LeadSource = 'Web') };
        ShapesBeforeDeleteHandler handler = new ShapesBeforeDeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.isNull(handler.newRecords[0], 'It should be null, because a delete context has no new record, only the row being deleted.');
        Assert.areEqual('Deleted', handler.oldRecords[0].get(Contact.LastName), 'It should be Deleted, because the old side carries the record as it was before the delete.');
    }

    @IsTest
    static void afterDeleteRecordShapeHasNoNewRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted', LeadSource = 'Web') };
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.isNull(handler.newRecords[0], 'It should be null, because a delete context has no new record, only the row being deleted.');
        Assert.areEqual('Deleted', handler.oldRecords[0].get(Contact.LastName), 'It should be Deleted, because the old side carries the record as it was before the delete.');
    }

    @IsTest
    static void deleteRecordIdComesFromTheOldRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id firstId = fakeIds.next();
        Id secondId = fakeIds.next();

        List<SObject> records = new List<Contact>{ new Contact(Id = firstId, LastName = 'First'), new Contact(Id = secondId, LastName = 'Second') };
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            new List<Id>{ firstId, secondId },
            handler.recordIds,
            'It should be the deleted record ids, because getId falls back to the old record when the context has no new one.'
        );
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.actionCount, 'It should be 1, because a delete context has no new record, so value predicates read the deleted row instead.');
        Assert.areEqual('Web', handler.oldRecords[0].get(Contact.LeadSource), 'It should be Web, because the record that qualified is the deleted row the predicate matched.');
    }

    @IsTest
    static void afterDeleteHandlerReadsTheDeletedFieldValues() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted', Description = 'Gone') };
        ShapesAfterDeleteHandler handler = new ShapesAfterDeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'Gone',
            handler.oldRecords[0].get(Contact.Description),
            'It should be Gone, because getOldSObject is available on DeleteRecord and still exposes every field of the deleted row.'
        );
    }

    @IsTest
    static void putOnAfterDeleteRecordThrowsNullPointerException() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted') };

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterDeleteOrchestrator(new ShapesPuttingAfterDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.triggerOldRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a handler that casts its way past DeleteRecord finds no new record to write to.');
        Assert.areEqual(
            'System.NullPointerException',
            orchestratorException.getTypeName(),
            'It should be System.NullPointerException, because a platform exception a handler causes propagates unchanged instead of being translated by the framework.'
        );
    }

    @IsTest
    static void putOnBeforeDeleteRecordThrowsNullPointerException() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        List<SObject> records = new List<Contact>{ new Contact(Id = fakeIds.next(), LastName = 'Deleted') };

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeDeleteOrchestrator(new ShapesPuttingBeforeDeleteHandler()));
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.triggerOldRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(orchestratorException, 'It should be thrown, because a handler that casts its way past DeleteRecord finds no new record to write to.');
        Assert.areEqual(
            'System.NullPointerException',
            orchestratorException.getTypeName(),
            'It should be System.NullPointerException, because a platform exception a handler causes propagates unchanged instead of being translated by the framework.'
        );
    }

    @IsTest
    static void beforeInsertRecordShapeHasNoOldRecord() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Inserted') };
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'Inserted',
            handler.newRecords[0].get(Contact.LastName),
            'It should be Inserted, because an insert context carries the record being inserted as the new one.'
        );
        Assert.isNull(handler.oldRecords[0], 'It should be null, because an insert context has no prior version of the record.');
    }

    @IsTest
    static void beforeInsertRecordHasNoIdYet() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Inserted') };
        ShapesBeforeInsertPopulator handler = new ShapesBeforeInsertPopulator();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesBeforeInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.isNull(handler.recordIds[0], 'It should be null, because in before insert the record has not been assigned an id yet.');
    }

    @IsTest
    static void afterInsertRecordShapeHasNoOldRecord() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id recordId = fakeIds.next();

        List<SObject> records = new List<Contact>{ new Contact(Id = recordId, LastName = 'Inserted') };
        ShapesAfterInsertHandler handler = new ShapesAfterInsertHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterInsertOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'Inserted',
            handler.newRecords[0].get(Contact.LastName),
            'It should be Inserted, because an insert context carries the record being inserted as the new one.'
        );
        Assert.isNull(handler.oldRecords[0], 'It should be null, because an insert context has no prior version of the record.');
        Assert.areEqual(recordId, handler.recordIds[0], 'It should be the saved id, because after insert the record already carries the id the platform assigned.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUpdateOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            'New First',
            handler.newRecords[0].get(Contact.LastName),
            'It should be New First, because an update context pairs each new record with the old record at the same index.'
        );
        Assert.areEqual(
            'Old First',
            handler.oldRecords[0].get(Contact.LastName),
            'It should be Old First, because an update context pairs each new record with the old record at the same index.'
        );
        Assert.areEqual(
            'New Second',
            handler.newRecords[1].get(Contact.LastName),
            'It should be New Second, because an update context pairs each new record with the old record at the same index.'
        );
        Assert.areEqual(
            'Old Second',
            handler.oldRecords[1].get(Contact.LastName),
            'It should be Old Second, because an update context pairs each new record with the old record at the same index.'
        );
    }

    @IsTest
    static void afterUndeleteRecordShapeHasEmptyOldSide() {
        ShapesFakeIds fakeIds = new ShapesFakeIds();
        Id recordId = fakeIds.next();

        List<SObject> records = new List<Contact>{ new Contact(Id = recordId, LastName = 'Restored') };
        ShapesAfterUndeleteHandler handler = new ShapesAfterUndeleteHandler();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual('Restored', handler.newRecords[0].get(Contact.LastName), 'It should be Restored, because after undelete carries the recycled record as the new one.');
        Assert.isNull(handler.oldRecords[0], 'It should be null, because after undelete runs with an empty old side.');
        Assert.areEqual(recordId, handler.recordIds[0], 'It should be the restored id, because a recycled record keeps the id it had before the delete.');
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
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new ShapesAfterUndeleteOrchestrator(handler));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(1, handler.actionCount, 'It should be 1, because value predicates in after undelete read the restored record on the new side.');
        Assert.areEqual('Web', handler.newRecords[0].get(Contact.LeadSource), 'It should be Web, because the record that qualified is the restored row the predicate matched.');
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

    @IsTest
    static void gapMetadataBypassSkipsBeforeInsertPopulator() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Gap') };
        GapMetadataBypassMutedInsertPopulator mutedPopulator = new GapMetadataBypassMutedInsertPopulator();
        GapMetadataBypassLiveInsertPopulator livePopulator = new GapMetadataBypassLiveInsertPopulator();

        GapMetadataBypassBeforeInsertOrchestrator orchestrator = new GapMetadataBypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ mutedPopulator, livePopulator });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedinsertpopulator' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedPopulator.qualifyCount,
            'It should be 0, because the before insert populator adapter reads the metadata bypass before anything else, so a handler named in TriggerHandler__mdt is dropped from the invocation and is never asked about a record.'
        );
        Assert.areEqual(0, mutedPopulator.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its populate method.');
        Assert.areEqual(
            1,
            livePopulator.runCount,
            'It should be 1, because a metadata handler bypass switches off only the class it names, so the other populators of the same list keep running.'
        );
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeInsertValidator() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Gap') };
        GapMetadataBypassMutedInsertValidator mutedValidator = new GapMetadataBypassMutedInsertValidator();
        GapMetadataBypassLiveInsertValidator liveValidator = new GapMetadataBypassLiveInsertValidator();

        GapMetadataBypassBeforeInsertOrchestrator orchestrator = new GapMetadataBypassBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ mutedValidator, liveValidator });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedinsertvalidator' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedValidator.qualifyCount,
            'It should be 0, because the before insert validator adapter carries its own copy of the metadata bypass check, so a validator named in TriggerHandler__mdt is dropped before qualification.'
        );
        Assert.areEqual(0, mutedValidator.messageCount, 'It should be 0, because a validator dropped by the metadata bypass is never asked for its validation message.');
        Assert.areEqual(1, liveValidator.messageCount, 'It should be 1, because the validator that metadata does not name keeps validating every qualified record.');
        Assert.areEqual(
            1,
            records[0].getErrors().size(),
            'It should be 1, because only the validator left in the invocation attaches an error, so the bypassed one adds nothing to the record.'
        );
        Assert.areEqual(
            'Live before insert validation',
            records[0].getErrors()[0].getMessage(),
            'It should be Live before insert validation, because the adapter attaches the exact string returned by the validator that was not bypassed.'
        );
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterInsertHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Gap') };
        GapMetadataBypassMutedAfterInsertHandler mutedHandler = new GapMetadataBypassMutedAfterInsertHandler();
        GapMetadataBypassLiveAfterInsertHandler liveHandler = new GapMetadataBypassLiveAfterInsertHandler();

        GapMetadataBypassAfterInsertOrchestrator orchestrator = new GapMetadataBypassAfterInsertOrchestrator(new List<AfterInsert.Handler>{ mutedHandler, liveHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedafterinserthandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedHandler.qualifyCount,
            'It should be 0, because the after insert adapter reads the metadata bypass before anything else, so a handler named in TriggerHandler__mdt is dropped from the invocation.'
        );
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names, never the whole context.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeUpdatePopulator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassMutedUpdatePopulator mutedPopulator = new GapMetadataBypassMutedUpdatePopulator();
        GapMetadataBypassLiveUpdatePopulator livePopulator = new GapMetadataBypassLiveUpdatePopulator();

        GapMetadataBypassBeforeUpdateOrchestrator orchestrator = new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ mutedPopulator, livePopulator });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedupdatepopulator' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedPopulator.qualifyCount,
            'It should be 0, because the before update populator adapter carries its own copy of the metadata bypass check and it runs before qualification.'
        );
        Assert.areEqual(0, mutedPopulator.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its populate method.');
        Assert.areEqual(
            1,
            livePopulator.runCount,
            'It should be 1, because a metadata handler bypass switches off only the class it names, so the rest of the before update list keeps running.'
        );
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassMutedUpdateValidator mutedValidator = new GapMetadataBypassMutedUpdateValidator();
        GapMetadataBypassLiveUpdateValidator liveValidator = new GapMetadataBypassLiveUpdateValidator();

        GapMetadataBypassBeforeUpdateOrchestrator orchestrator = new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ mutedValidator, liveValidator });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedupdatevalidator' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedValidator.qualifyCount,
            'It should be 0, because the before update validator adapter checks the metadata bypass first, so a validator named in TriggerHandler__mdt is dropped before qualification.'
        );
        Assert.areEqual(0, mutedValidator.messageCount, 'It should be 0, because a validator dropped by the metadata bypass is never asked for its validation message.');
        Assert.areEqual(1, liveValidator.messageCount, 'It should be 1, because the validator that metadata does not name keeps validating every qualified record.');
        Assert.areEqual(
            1,
            newRecords[0].getErrors().size(),
            'It should be 1, because a before update validator attaches its error to the new side and only the validator left in the invocation attaches one.'
        );
        Assert.areEqual(
            'Live before update validation',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be Live before update validation, because the adapter attaches the exact string returned by the validator that was not bypassed.'
        );
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterUpdateHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassMutedAfterUpdateHandler mutedHandler = new GapMetadataBypassMutedAfterUpdateHandler();
        GapMetadataBypassLiveAfterUpdateHandler liveHandler = new GapMetadataBypassLiveAfterUpdateHandler();

        GapMetadataBypassAfterUpdateOrchestrator orchestrator = new GapMetadataBypassAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ mutedHandler, liveHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedafterupdatehandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedHandler.qualifyCount,
            'It should be 0, because the after update adapter checks the metadata bypass before the recursion budget and before qualification.'
        );
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names, never the whole context.');
    }

    @IsTest
    static void gapMetadataBypassSkipsBeforeDeleteHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Gone') };
        GapMetadataBypassMutedBeforeDeleteHandler mutedHandler = new GapMetadataBypassMutedBeforeDeleteHandler();
        GapMetadataBypassLiveBeforeDeleteHandler liveHandler = new GapMetadataBypassLiveBeforeDeleteHandler();

        GapMetadataBypassBeforeDeleteOrchestrator orchestrator = new GapMetadataBypassBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ mutedHandler, liveHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedbeforedeletehandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedHandler.qualifyCount,
            'It should be 0, because a delete context has no new side, so the settings are looked up by the SObject of the old records and the named handler is dropped before qualification.'
        );
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names, never the whole context.');
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterDeleteHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Gone') };
        GapMetadataBypassMutedAfterDeleteHandler mutedHandler = new GapMetadataBypassMutedAfterDeleteHandler();
        GapMetadataBypassLiveAfterDeleteHandler liveHandler = new GapMetadataBypassLiveAfterDeleteHandler();

        GapMetadataBypassAfterDeleteOrchestrator orchestrator = new GapMetadataBypassAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ mutedHandler, liveHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedafterdeletehandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedHandler.qualifyCount,
            'It should be 0, because the after delete adapter carries its own copy of the metadata bypass check, so the named handler is dropped before qualification.'
        );
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names, never the whole context.');
    }

    @IsTest
    static void gapMetadataBypassSkipsAfterUndeleteHandler() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored') };
        GapMetadataBypassMutedAfterUndeleteHandler mutedHandler = new GapMetadataBypassMutedAfterUndeleteHandler();
        GapMetadataBypassLiveAfterUndeleteHandler liveHandler = new GapMetadataBypassLiveAfterUndeleteHandler();

        GapMetadataBypassAfterUndeleteOrchestrator orchestrator = new GapMetadataBypassAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ mutedHandler, liveHandler });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{ 'gapmetadatabypassmutedafterundeletehandler' => new TriggerHandler__mdt(Bypass__c = true) };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = records;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            mutedHandler.qualifyCount,
            'It should be 0, because the after undelete adapter carries its own copy of the metadata bypass check, so the named handler is dropped before qualification.'
        );
        Assert.areEqual(0, mutedHandler.runCount, 'It should be 0, because a handler dropped by the metadata bypass never reaches its action method.');
        Assert.areEqual(1, liveHandler.runCount, 'It should be 1, because a metadata handler bypass switches off only the class it names, never the whole context.');
    }

    @IsTest
    static void gapMetadataBypassDottedEntryTailSkipsBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassDottedNameValidator dottedValidator = new GapMetadataBypassDottedNameValidator();
        GapMetadataBypassLiveUpdateValidator liveValidator = new GapMetadataBypassLiveUpdateValidator();

        GapMetadataBypassBeforeUpdateOrchestrator orchestrator = new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ dottedValidator, liveValidator });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{
            'triggerorchestratortest.gapmetadatabypassdottednamevalidator' => new TriggerHandler__mdt(Bypass__c = true),
            'gapmetadatabypassdottednamevalidator' => new TriggerHandler__mdt(Bypass__c = true)
        };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            0,
            dottedValidator.messageCount,
            'It should be 0, because an ApexClassName__c spelled Outer.Inner is stored by the loader in both spellings, and the unqualified tail is the one that matches the simple class name an inner class reports at runtime.'
        );
        Assert.areEqual(
            1,
            liveValidator.messageCount,
            'It should be 1, because the two spellings of one metadata entry still name a single class, so the rest of the list is untouched.'
        );
    }

    @IsTest
    static void gapMetadataBypassDottedEntryWithoutTailRunsBeforeUpdateValidator() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old') };
        GapMetadataBypassDottedNameValidator dottedValidator = new GapMetadataBypassDottedNameValidator();

        GapMetadataBypassBeforeUpdateOrchestrator orchestrator = new GapMetadataBypassBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ dottedValidator });

        TriggerOrchestrator.MetadataSettings contactSettings = new TriggerOrchestrator.MetadataSettings(new TriggerObject__mdt());
        contactSettings.settingByHandlerName = new Map<String, TriggerHandler__mdt>{
            'triggerorchestratortest.gapmetadatabypassdottednamevalidator' => new TriggerHandler__mdt(Bypass__c = true)
        };

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>{ 'contact' => contactSettings };

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(orchestrator);
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            dottedValidator.messageCount,
            'It should be 1, because the adapter compares the simple class name an inner class reports at runtime, so the qualified spelling on its own matches nothing and only the tail the loader adds makes the entry bite.'
        );
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

    @IsTest
    static void gapEnrichmentBeforeInsertPopulatorReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Populator Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeInsertPopulator handler = new GapEnrichmentBeforeInsertPopulator();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the before insert populator adapter asks a handler implementing BeforeInsert.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            parentAccount.Id,
            handler.seenNewParents[0].Id,
            'It should be the inserted account id, because the declaration the populator returned names the lookup the enrichment resolves on the new record.'
        );
        Assert.areEqual(
            'Populator Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Populator Parent, because getNewRelated returns the parent carrying the fields the handler selected.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeInsertValidatorReceivesDeclaredParentOnNewSide() {
        Account parentAccount = new Account(Name = 'Validator Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeInsertValidator handler = new GapEnrichmentBeforeInsertValidator();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the before insert validator adapter asks a handler implementing BeforeInsert.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            'Validator Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Validator Parent, because a validator is enriched exactly like a populator and reads its parent through getNewRelated.'
        );
        Assert.areEqual(
            'Account Validator Parent does not accept new contacts.',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be the message naming the enriched parent, because enrichment resolves before the handler runs and the before insert message can read the related record.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeInsertPopulatorAndValidatorShareOneParentQuery() {
        Account parentAccount = new Account(Name = 'Shared Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeInsertPopulator populator = new GapEnrichmentBeforeInsertPopulator();
        populator.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        GapEnrichmentBeforeInsertValidator validator = new GapEnrichmentBeforeInsertValidator();
        validator.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ populator, validator }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

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
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the before update populator adapter asks a handler implementing BeforeUpdate.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because getNewRelated returns the parent the new record points at with the selected fields populated.'
        );
        Assert.isNull(handler.seenOldParents[0], 'It should be null, because the two sides are declared independently and only the new side was declared.');
    }

    @IsTest
    static void gapEnrichmentBeforeUpdatePopulatorReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentBeforeUpdatePopulator handler = new GapEnrichmentBeforeUpdatePopulator();
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.oldDeclarationRequestCount,
            'It should be 1, because the before update populator adapter asks a handler implementing BeforeUpdate.OldRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            accounts[0].Id,
            handler.seenOldParents[0].Id,
            'It should be the previous account id, because the old side of a lookup is resolved from the value the old record holds.'
        );
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because getOldRelated returns the parent the old record points at, never the one the new record moved to.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeUpdatePopulatorReceivesBothDeclaredSidesInOneQuery() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentBeforeUpdatePopulator handler = new GapEnrichmentBeforeUpdatePopulator();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Integer queriesBefore = Limits.getQueries();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        Integer queriesAfter = Limits.getQueries();

        // Verify
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because a handler declaring both sides still reads the new side through getNewRelated.'
        );
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because a handler declaring both sides reads the old side through getOldRelated.'
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
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the before update validator adapter asks a handler implementing BeforeUpdate.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because a validator is enriched exactly like a populator and reads its parent through getNewRelated.'
        );
        Assert.areEqual(
            'Account Current Parent is locked.',
            newRecords[0].getErrors()[0].getMessage(),
            'It should be the message naming the enriched parent, because enrichment resolves before the handler runs and the before update message can read the related record.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeUpdateValidatorReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentBeforeUpdateValidator handler = new GapEnrichmentBeforeUpdateValidator();
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.oldDeclarationRequestCount,
            'It should be 1, because the before update validator adapter asks a handler implementing BeforeUpdate.OldRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because getOldRelated returns the parent the old record points at, never the one the new record moved to.'
        );
        Assert.isNull(handler.seenNewParents[0], 'It should be null, because the two sides are declared independently and only the old side was declared.');
    }

    @IsTest
    static void gapEnrichmentAfterInsertHandlerReceivesDeclaredParentOnNewSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Inserted Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Sanders', AccountId = parentAccount.Id) };

        GapEnrichmentAfterInsertHandler handler = new GapEnrichmentAfterInsertHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterInsertOrchestrator(new List<AfterInsert.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the after insert adapter asks a handler implementing AfterInsert.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            parentAccount.Id,
            handler.seenNewParents[0].Id,
            'It should be the inserted account id, because the parent is fetched by the value held in the declared lookup field.'
        );
        Assert.areEqual(
            'Inserted Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Inserted Parent, because getNewRelated returns the parent carrying the fields the handler selected.'
        );
    }

    @IsTest
    static void gapEnrichmentAfterUpdateHandlerReceivesDeclaredParentOnNewSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Current Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = parentAccount.Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = parentAccount.Id) };

        GapEnrichmentAfterUpdateHandler handler = new GapEnrichmentAfterUpdateHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the after update adapter asks a handler implementing AfterUpdate.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            'Current Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Current Parent, because getNewRelated returns the parent the new record points at with the selected fields populated.'
        );
        Assert.isNull(handler.seenOldParents[0], 'It should be null, because the two sides are declared independently and only the new side was declared.');
    }

    @IsTest
    static void gapEnrichmentAfterUpdateHandlerReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<Account> accounts = new List<Account>{ new Account(Name = 'Previous Parent'), new Account(Name = 'Current Parent') };
        insert accounts;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[1].Id) };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Moved', AccountId = accounts[0].Id) };

        GapEnrichmentAfterUpdateHandler handler = new GapEnrichmentAfterUpdateHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.oldDeclarationRequestCount,
            'It should be 1, because the after update adapter asks a handler implementing AfterUpdate.OldRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            accounts[0].Id,
            handler.seenOldParents[0].Id,
            'It should be the previous account id, because the old side of a lookup is resolved from the value the old record holds.'
        );
        Assert.areEqual(
            'Previous Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Previous Parent, because getOldRelated returns the parent the old record points at, never the one the new record moved to.'
        );
    }

    @IsTest
    static void gapEnrichmentBeforeDeleteHandlerReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Deleted Child Parent');
        insert parentAccount;

        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted', AccountId = parentAccount.Id) };

        GapEnrichmentBeforeDeleteHandler handler = new GapEnrichmentBeforeDeleteHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.oldDeclarationRequestCount,
            'It should be 1, because the before delete adapter asks a handler implementing BeforeDelete.OldRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            parentAccount.Id,
            handler.seenOldParents[0].Id,
            'It should be the inserted account id, because a delete context carries no new record, so the lookup the enrichment reads lives on the deleted row.'
        );
        Assert.areEqual(
            'Deleted Child Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Deleted Child Parent, because getOldRelated returns the parent carrying the fields the handler selected.'
        );
    }

    @IsTest
    static void gapEnrichmentAfterDeleteHandlerReceivesDeclaredParentOnOldSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Removed Child Parent');
        insert parentAccount;

        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Deleted', AccountId = parentAccount.Id) };

        GapEnrichmentAfterDeleteHandler handler = new GapEnrichmentAfterDeleteHandler();
        handler.declareOld(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
        orchestratorRunner.context.triggerOldRecords = oldRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.oldDeclarationRequestCount,
            'It should be 1, because the after delete adapter asks a handler implementing AfterDelete.OldRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            parentAccount.Id,
            handler.seenOldParents[0].Id,
            'It should be the inserted account id, because a delete context carries no new record, so the lookup the enrichment reads lives on the deleted row.'
        );
        Assert.areEqual(
            'Removed Child Parent',
            ((Account) handler.seenOldParents[0]).Name,
            'It should be Removed Child Parent, because getOldRelated returns the parent carrying the fields the handler selected.'
        );
    }

    @IsTest
    static void gapEnrichmentAfterUndeleteHandlerReceivesDeclaredParentOnNewSide() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Name = 'Restored Child Parent');
        insert parentAccount;

        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Restored', AccountId = parentAccount.Id) };

        GapEnrichmentAfterUndeleteHandler handler = new GapEnrichmentAfterUndeleteHandler();
        handler.declareNew(Contact.AccountId, TriggerHandler.FieldSelection.with(Account.Name));

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        // Test
        TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(new GapEnrichmentAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ handler }));
        orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
        orchestratorRunner.context.triggerNewRecords = newRecords;
        orchestratorRunner.run();

        // Verify
        Assert.areEqual(
            1,
            handler.newDeclarationRequestCount,
            'It should be 1, because the after undelete adapter asks a handler implementing AfterUndelete.NewRecordEnrichment for its declaration exactly once per invocation.'
        );
        Assert.areEqual(
            parentAccount.Id,
            handler.seenNewParents[0].Id,
            'It should be the inserted account id, because an undelete context carries only restored records, so the lookup the enrichment reads lives on the new record.'
        );
        Assert.areEqual(
            'Restored Child Parent',
            ((Account) handler.seenNewParents[0]).Name,
            'It should be Restored Child Parent, because getNewRelated returns the parent carrying the fields the handler selected.'
        );
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

    private class GapEnrichmentBeforeInsertPopulator implements BeforeInsert.Populator, BeforeInsert.NewRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
            Account parent = (Account) record.getNewRelated('Account');

            this.seenNewParents.add(parent);
            record.put(Contact.Department, parent?.Name);
        }
    }

    private class GapEnrichmentBeforeInsertValidator implements BeforeInsert.Validator, BeforeInsert.NewRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            return true;
        }

        public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
            Account parent = (Account) record.getNewRelated('Account');

            return 'Account ' + parent?.Name + ' does not accept new contacts.';
        }
    }

    private class GapEnrichmentBeforeUpdatePopulator implements BeforeUpdate.Populator, BeforeUpdate.NewRecordEnrichment, BeforeUpdate.OldRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeUpdate() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeUpdate() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            this.seenOldParents.add(record.getOldRelated('Account'));
        }
    }

    private class GapEnrichmentBeforeUpdateValidator implements BeforeUpdate.Validator, BeforeUpdate.NewRecordEnrichment, BeforeUpdate.OldRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeUpdate() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeUpdate() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            this.seenOldParents.add(record.getOldRelated('Account'));
            return true;
        }

        public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
            Account parent = (Account) record.getNewRelated('Account');

            return 'Account ' + parent?.Name + ' is locked.';
        }
    }

    private class GapEnrichmentAfterInsertHandler implements AfterInsert.Handler, AfterInsert.NewRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
            return true;
        }

        public void onAfterInsert(TriggerHandler.InsertRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
        }
    }

    private class GapEnrichmentAfterUpdateHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.OldRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();
        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnAfterUpdate() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
            return true;
        }

        public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
            this.seenOldParents.add(record.getOldRelated('Account'));
        }
    }

    private class GapEnrichmentBeforeDeleteHandler implements BeforeDelete.Handler, BeforeDelete.OldRecordEnrichment {
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeDelete() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
            this.seenOldParents.add(record.getOldRelated('Account'));
        }
    }

    private class GapEnrichmentAfterDeleteHandler implements AfterDelete.Handler, AfterDelete.OldRecordEnrichment {
        public List<SObject> seenOldParents = new List<SObject>();
        public Integer oldDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> oldDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareOld(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.oldDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnAfterDelete() {
            this.oldDeclarationRequestCount++;
            return this.oldDeclaration;
        }

        public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
            return true;
        }

        public void onAfterDelete(TriggerHandler.DeleteRecord record) {
            this.seenOldParents.add(record.getOldRelated('Account'));
        }
    }

    private class GapEnrichmentAfterUndeleteHandler implements AfterUndelete.Handler, AfterUndelete.NewRecordEnrichment {
        public List<SObject> seenNewParents = new List<SObject>();
        public Integer newDeclarationRequestCount = 0;

        private Map<SObjectField, TriggerHandler.FieldSelection> newDeclaration = new Map<SObjectField, TriggerHandler.FieldSelection>();

        public void declareNew(SObjectField parentField, TriggerHandler.FieldSelection fields) {
            this.newDeclaration.put(parentField, fields);
        }

        public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUndelete() {
            this.newDeclarationRequestCount++;
            return this.newDeclaration;
        }

        public Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
            return true;
        }

        public void onAfterUndelete(TriggerHandler.UndeleteRecord record) {
            this.seenNewParents.add(record.getNewRelated('Account'));
        }
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertPopulatorSwallowsItsFailure() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Continue') };
        GapContinueOnErrorMutedBeforeInsertPopulator failingPopulator = new GapContinueOnErrorMutedBeforeInsertPopulator();
        GapContinueOnErrorCountingBeforeInsertPopulator laterPopulator = new GapContinueOnErrorCountingBeforeInsertPopulator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the before insert populator adapter continues on error for a handler that implements BeforeInsert.ContinueOnError.'
        );
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1, because the populator runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterPopulator.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertPopulatorWithoutOptInPropagatesItsFailure() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        GapContinueOnErrorFailingBeforeInsertPopulator failingPopulator = new GapContinueOnErrorFailingBeforeInsertPopulator();
        GapContinueOnErrorCountingBeforeInsertPopulator laterPopulator = new GapContinueOnErrorCountingBeforeInsertPopulator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the before insert populator adapter continues on error only for a handler that implements BeforeInsert.ContinueOnError.'
        );
        Assert.areEqual(
            'Before insert populator failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1, because the exception is raised by the populator that actually ran.');
        Assert.areEqual(0, laterPopulator.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertValidatorSwallowsItsFailure() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Continue') };
        GapContinueOnErrorMutedBeforeInsertValidator failingValidator = new GapContinueOnErrorMutedBeforeInsertValidator();
        GapContinueOnErrorCountingBeforeInsertValidator laterValidator = new GapContinueOnErrorCountingBeforeInsertValidator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the before insert validator adapter continues on error for a handler that implements BeforeInsert.ContinueOnError.'
        );
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1, because the validation message is asked for and throws before its failure is suppressed.');
        Assert.areEqual(1, laterValidator.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
        Assert.areEqual(1, records[0].getErrors().size(), 'It should be 1, because the validator that follows the suppressed one still attaches its error to the new SObject.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeInsertValidatorWithoutOptInPropagatesItsFailure() {
        List<SObject> records = new List<Contact>{ new Contact(LastName = 'Abort') };
        GapContinueOnErrorFailingBeforeInsertValidator failingValidator = new GapContinueOnErrorFailingBeforeInsertValidator();
        GapContinueOnErrorCountingBeforeInsertValidator laterValidator = new GapContinueOnErrorCountingBeforeInsertValidator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeInsertOrchestrator(new List<BeforeInsert.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the before insert validator adapter continues on error only for a handler that implements BeforeInsert.ContinueOnError.'
        );
        Assert.areEqual(
            'Before insert validator failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1, because the exception is raised by the validator that actually ran.');
        Assert.areEqual(0, laterValidator.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
        Assert.areEqual(0, records[0].getErrors().size(), 'It should be 0, because the failing validator threw instead of returning a message to attach.');
    }

    @IsTest
    static void gapContinueOnErrorAfterInsertHandlerSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Continue') };
        GapContinueOnErrorMutedAfterInsertHandler failingHandler = new GapContinueOnErrorMutedAfterInsertHandler();
        GapContinueOnErrorCountingAfterInsertHandler laterHandler = new GapContinueOnErrorCountingAfterInsertHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the after insert adapter continues on error for a handler that implements AfterInsert.ContinueOnError.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorAfterInsertHandlerWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Abort') };
        GapContinueOnErrorFailingAfterInsertHandler failingHandler = new GapContinueOnErrorFailingAfterInsertHandler();
        GapContinueOnErrorCountingAfterInsertHandler laterHandler = new GapContinueOnErrorCountingAfterInsertHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterInsertOrchestrator(new List<AfterInsert.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_INSERT;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the after insert adapter continues on error only for a handler that implements AfterInsert.ContinueOnError.'
        );
        Assert.areEqual(
            'After insert handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception is raised by the handler that actually ran.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdatePopulatorSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Continue') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Continue') };
        GapContinueOnErrorMutedBeforeUpdatePopulator failingPopulator = new GapContinueOnErrorMutedBeforeUpdatePopulator();
        GapContinueOnErrorCountingBeforeUpdatePopulator laterPopulator = new GapContinueOnErrorCountingBeforeUpdatePopulator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the before update populator adapter continues on error for a handler that implements BeforeUpdate.ContinueOnError.'
        );
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1, because the populator runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterPopulator.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdatePopulatorWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Abort') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Abort') };
        GapContinueOnErrorFailingBeforeUpdatePopulator failingPopulator = new GapContinueOnErrorFailingBeforeUpdatePopulator();
        GapContinueOnErrorCountingBeforeUpdatePopulator laterPopulator = new GapContinueOnErrorCountingBeforeUpdatePopulator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingPopulator, laterPopulator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the before update populator adapter continues on error only for a handler that implements BeforeUpdate.ContinueOnError.'
        );
        Assert.areEqual(
            'Before update populator failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingPopulator.executionCount, 'It should be 1, because the exception is raised by the populator that actually ran.');
        Assert.areEqual(0, laterPopulator.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdateValidatorSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Continue') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Continue') };
        GapContinueOnErrorMutedBeforeUpdateValidator failingValidator = new GapContinueOnErrorMutedBeforeUpdateValidator();
        GapContinueOnErrorCountingBeforeUpdateValidator laterValidator = new GapContinueOnErrorCountingBeforeUpdateValidator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the before update validator adapter continues on error for a handler that implements BeforeUpdate.ContinueOnError.'
        );
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1, because the validation message is asked for and throws before its failure is suppressed.');
        Assert.areEqual(1, laterValidator.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
        Assert.areEqual(1, newRecords[0].getErrors().size(), 'It should be 1, because the validator that follows the suppressed one still attaches its error to the new SObject.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeUpdateValidatorWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Abort') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Abort') };
        GapContinueOnErrorFailingBeforeUpdateValidator failingValidator = new GapContinueOnErrorFailingBeforeUpdateValidator();
        GapContinueOnErrorCountingBeforeUpdateValidator laterValidator = new GapContinueOnErrorCountingBeforeUpdateValidator();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeUpdateOrchestrator(new List<BeforeUpdate.Handler>{ failingValidator, laterValidator })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the before update validator adapter continues on error only for a handler that implements BeforeUpdate.ContinueOnError.'
        );
        Assert.areEqual(
            'Before update validator failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingValidator.executionCount, 'It should be 1, because the exception is raised by the validator that actually ran.');
        Assert.areEqual(0, laterValidator.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
        Assert.areEqual(0, newRecords[0].getErrors().size(), 'It should be 0, because the failing validator threw instead of returning a message to attach.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUpdateHandlerSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Continue') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Continue') };
        GapContinueOnErrorMutedAfterUpdateHandler failingHandler = new GapContinueOnErrorMutedAfterUpdateHandler();
        GapContinueOnErrorCountingAfterUpdateHandler laterHandler = new GapContinueOnErrorCountingAfterUpdateHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the after update adapter continues on error for a handler that implements AfterUpdate.ContinueOnError.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUpdateHandlerWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> newRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'New Abort') };
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Old Abort') };
        GapContinueOnErrorFailingAfterUpdateHandler failingHandler = new GapContinueOnErrorFailingAfterUpdateHandler();
        GapContinueOnErrorCountingAfterUpdateHandler laterHandler = new GapContinueOnErrorCountingAfterUpdateHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUpdateOrchestrator(new List<AfterUpdate.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UPDATE;
            orchestratorRunner.context.triggerNewRecords = newRecords;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the after update adapter continues on error only for a handler that implements AfterUpdate.ContinueOnError.'
        );
        Assert.areEqual(
            'After update handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception is raised by the handler that actually ran.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeDeleteHandlerSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Continue') };
        GapContinueOnErrorMutedBeforeDeleteHandler failingHandler = new GapContinueOnErrorMutedBeforeDeleteHandler();
        GapContinueOnErrorCountingBeforeDeleteHandler laterHandler = new GapContinueOnErrorCountingBeforeDeleteHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the before delete adapter continues on error for a handler that implements BeforeDelete.ContinueOnError.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorBeforeDeleteHandlerWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Abort') };
        GapContinueOnErrorFailingBeforeDeleteHandler failingHandler = new GapContinueOnErrorFailingBeforeDeleteHandler();
        GapContinueOnErrorCountingBeforeDeleteHandler laterHandler = new GapContinueOnErrorCountingBeforeDeleteHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorBeforeDeleteOrchestrator(new List<BeforeDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.BEFORE_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the before delete adapter continues on error only for a handler that implements BeforeDelete.ContinueOnError.'
        );
        Assert.areEqual(
            'Before delete handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception is raised by the handler that actually ran.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
    }

    @IsTest
    static void gapContinueOnErrorAfterDeleteHandlerSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Continue') };
        GapContinueOnErrorMutedAfterDeleteHandler failingHandler = new GapContinueOnErrorMutedAfterDeleteHandler();
        GapContinueOnErrorCountingAfterDeleteHandler laterHandler = new GapContinueOnErrorCountingAfterDeleteHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(orchestratorException, 'It should be null, because the after delete adapter continues on error for a handler that implements AfterDelete.ContinueOnError.');
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorAfterDeleteHandlerWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> oldRecords = new List<Contact>{ new Contact(Id = contactId, LastName = 'Abort') };
        GapContinueOnErrorFailingAfterDeleteHandler failingHandler = new GapContinueOnErrorFailingAfterDeleteHandler();
        GapContinueOnErrorCountingAfterDeleteHandler laterHandler = new GapContinueOnErrorCountingAfterDeleteHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterDeleteOrchestrator(new List<AfterDelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_DELETE;
            orchestratorRunner.context.triggerOldRecords = oldRecords;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the after delete adapter continues on error only for a handler that implements AfterDelete.ContinueOnError.'
        );
        Assert.areEqual(
            'After delete handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception is raised by the handler that actually ran.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUndeleteHandlerSwallowsItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Continue') };
        GapContinueOnErrorMutedAfterUndeleteHandler failingHandler = new GapContinueOnErrorMutedAfterUndeleteHandler();
        GapContinueOnErrorCountingAfterUndeleteHandler laterHandler = new GapContinueOnErrorCountingAfterUndeleteHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNull(
            orchestratorException,
            'It should be null, because the after undelete adapter continues on error for a handler that implements AfterUndelete.ContinueOnError.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the handler runs and throws before its failure is suppressed.');
        Assert.areEqual(1, laterHandler.executionCount, 'It should be 1, because a suppressed failure leaves the handlers registered after it free to take their turn.');
    }

    @IsTest
    static void gapContinueOnErrorAfterUndeleteHandlerWithoutOptInPropagatesItsFailure() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        List<SObject> records = new List<Contact>{ new Contact(Id = contactId, LastName = 'Abort') };
        GapContinueOnErrorFailingAfterUndeleteHandler failingHandler = new GapContinueOnErrorFailingAfterUndeleteHandler();
        GapContinueOnErrorCountingAfterUndeleteHandler laterHandler = new GapContinueOnErrorCountingAfterUndeleteHandler();

        TriggerOrchestrator.TriggerSettings.metadataSettingsByObjectName = new Map<String, TriggerOrchestrator.MetadataSettings>();

        Exception orchestratorException = null;

        // Test
        try {
            TriggerOrchestrator orchestratorRunner = new TriggerOrchestrator(
                new GapContinueOnErrorAfterUndeleteOrchestrator(new List<AfterUndelete.Handler>{ failingHandler, laterHandler })
            );
            orchestratorRunner.context.triggerOperation = System.TriggerOperation.AFTER_UNDELETE;
            orchestratorRunner.context.triggerNewRecords = records;
            orchestratorRunner.run();
        } catch (Exception e) {
            orchestratorException = e;
        }

        // Verify
        Assert.isNotNull(
            orchestratorException,
            'It should be thrown, because the after undelete adapter continues on error only for a handler that implements AfterUndelete.ContinueOnError.'
        );
        Assert.areEqual(
            'After undelete handler failed on purpose.',
            orchestratorException.getMessage(),
            'It should be the handler message, because the orchestrator rethrows the handler exception unwrapped.'
        );
        Assert.areEqual(1, failingHandler.executionCount, 'It should be 1, because the exception is raised by the handler that actually ran.');
        Assert.areEqual(0, laterHandler.executionCount, 'It should be 0, because a rethrown failure ends the invocation before the next handler of the list runs.');
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
}
