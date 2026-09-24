/**
 * @description Tests for the AfterDelete context of the TriggerOrchestrator class.
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
private class AfterDeleteTest {
    @IsTest
    static void writerWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriter.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcher.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriterWithBypassable.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcherWithBypassable.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriter.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriter.class).with(roe);

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

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcher.class).with(new List<Contact>{ doe, roe });

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

        TriggerOrchestrator.mock().afterDeleteFor(BatchDispatcher.class).with(roe);

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

        TriggerOrchestrator.mock().afterDeleteFor(BatchDispatcher.class).with(new List<Contact>{ johnDoe, janeDoe });

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

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcherWithFinalizerSnapshot.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriterWithFinalizer.class).with(new List<Contact>{ doe, roe });

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

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcherWithFinalizer.class).with(new List<Contact>{ doe, roe });

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

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriterWithFinalizer.class).with(roe);

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

        TriggerOrchestrator.mock().afterDeleteFor(IdDispatcherWithFinalizer.class).with(roe);

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

        TriggerOrchestrator.mock().afterDeleteFor(FailingWriter.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(FailingDispatcher.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(FailingWriterWithContinueOnError.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(FailingDispatcherWithContinueOnError.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new FailingDispatcherWithContinueOnError());

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void priorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterDeleteFor(PriorAccountNameWriter.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new PriorAccountNameWriter());

        // Verify
        Assert.areEqual('Acme', DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0].get(Task.Subject), 'The writer should copy the prior account name.');
    }

    @IsTest
    static void relatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterDeleteFor(RelatedAccountNameWriter.class).with(doe).withParent(Contact.AccountId, acme);

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
        handlers.afterDelete.add(new AccountWriter());
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator.mock().afterDeleteFor(TestOrchestrator.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(AccountWriterWithOwnUnitOfWork.class).with(doe);

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
        handlers.afterDelete.add(new AccountWriterWithContinueOnError());
        handlers.afterDelete.add(dispatcher);

        TriggerOrchestrator.mock().afterDeleteFor(TestOrchestrator.class).with(doe);

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

        TriggerOrchestrator.mock().afterDeleteFor(FailingAccountWriterWithContinueOnError.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new FailingAccountWriterWithContinueOnError());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void mockWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterDeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_DELETE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithParent() {
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

    private class OperationStamper implements AfterDelete.Writer {
        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getOldSObject().put(Contact.Description, 'AFTER_DELETE');
        }
    }

    private class AccountWriterWithBypassable extends AccountWriter implements AfterDelete.Bypassable {
        public Boolean bypassOnAfterDeleteWhen() {
            return true;
        }
    }

    private class IdDispatcherWithBypassable extends IdDispatcher implements AfterDelete.Bypassable {
        public Boolean bypassOnAfterDeleteWhen() {
            return true;
        }
    }

    private class BatchDispatcher implements AfterDelete.Dispatcher {
        public List<Set<Id>> dispatchedBatches = new List<Set<Id>>();

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }
    }

    private class IdDispatcherWithFinalizerSnapshot extends IdDispatcher implements AfterDelete.Finalizer {
        public List<Id> dispatchedIdsWhenFinalized;

        public void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }
    }

    private class AccountWriterWithFinalizer extends AccountWriter implements AfterDelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private class IdDispatcherWithFinalizer extends IdDispatcher implements AfterDelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private virtual class FailingWriter implements AfterDelete.Writer {
        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }
    }

    private class FailingWriterWithContinueOnError extends FailingWriter implements AfterDelete.ContinueOnError {
    }

    private virtual class FailingDispatcher implements AfterDelete.Dispatcher {
        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            throw new TestException('The dispatcher failed.');
        }
    }

    private class FailingDispatcherWithContinueOnError extends FailingDispatcher implements AfterDelete.ContinueOnError {
    }

    private class PriorAccountNameWriter implements AfterDelete.Writer, AfterDelete.PriorParentQuery {
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

    private class RelatedAccountProvider implements AfterDelete.RecordsProvider {
        public List<SObject> query(TriggerTypes.DeleteRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNameWriter implements AfterDelete.Writer, AfterDelete.RelatedQuery {
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
    }

    private class CommitCountingDispatcher implements AfterDelete.Dispatcher {
        public Integer committedAccounts;

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }
    }

    private virtual class AccountWriterWithOwnUnitOfWork extends AccountWriter implements AfterDelete.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnAfterDelete() {
            return new DML().identifier('ownUnit');
        }
    }

    private class AccountWriterWithContinueOnError extends AccountWriter implements AfterDelete.ContinueOnError {
    }

    private class FailingAccountWriterWithContinueOnError implements AfterDelete.Writer, AfterDelete.ContinueOnError {
        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }
    }

    private class TestOrchestrator implements TriggerOrchestrator.AfterDelete {
        public List<AfterDelete.Handler> afterDelete = new List<AfterDelete.Handler>();

        public List<AfterDelete.Handler> afterDeleteHandlers() {
            return this.afterDelete;
        }
    }

    private virtual class AccountWriter implements AfterDelete.Writer {
        public Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
        }
    }

    private virtual class IdDispatcher implements AfterDelete.Dispatcher {
        public List<Id> dispatchedIds = new List<Id>();

        public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
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
