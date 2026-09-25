/**
 * @description Tests for the AfterUndelete context of the TriggerOrchestrator class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.4
 *
 * PMD False Positives:
 * - ExcessiveClassLength: It is a library and we tried to put everything into ONE test class
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.ExcessiveClassLength,PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true testFor='ApexClass:AfterUndelete, ApexClass:TriggerOrchestrator')
private class AfterUndeleteTest {
    @IsTest
    static void writerWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriter.class).with(doe);

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

        TriggerOrchestrator.mock().afterUndeleteFor(IdDispatcher.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriterWithBypassable.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        IdDispatcherWithBypassable dispatcher = new IdDispatcherWithBypassable();

        TriggerOrchestrator.mock().afterUndeleteFor(IdDispatcherWithBypassable.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriter.class).with(doe);

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

        Contact roe = new Contact(LastName = 'Roe');

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriter.class).with(roe);

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

        TriggerOrchestrator.mock().afterUndeleteFor(IdDispatcher.class).with(new List<Contact>{ doe, roe });

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

        Contact roe = new Contact(LastName = 'Roe');

        BatchDispatcher dispatcher = new BatchDispatcher();

        TriggerOrchestrator.mock().afterUndeleteFor(BatchDispatcher.class).with(roe);

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

        TriggerOrchestrator.mock().afterUndeleteFor(BatchDispatcher.class).with(new List<Contact>{ johnDoe, janeDoe });

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

        TriggerOrchestrator.mock().afterUndeleteFor(IdDispatcherWithFinalizerSnapshot.class).with(doe);

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

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriterWithFinalizer.class).with(new List<Contact>{ doe, roe });

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

        TriggerOrchestrator.mock().afterUndeleteFor(IdDispatcherWithFinalizer.class).with(new List<Contact>{ doe, roe });

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

        Contact roe = new Contact(LastName = 'Roe');

        AccountWriterWithFinalizer writer = new AccountWriterWithFinalizer();

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriterWithFinalizer.class).with(roe);

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

        Contact roe = new Contact(LastName = 'Roe');

        IdDispatcherWithFinalizer dispatcher = new IdDispatcherWithFinalizer();

        TriggerOrchestrator.mock().afterUndeleteFor(IdDispatcherWithFinalizer.class).with(roe);

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

        TriggerOrchestrator.mock().afterUndeleteFor(FailingWriter.class).with(new Contact(LastName = 'Doe'));

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

        TriggerOrchestrator.mock().afterUndeleteFor(FailingDispatcher.class).with(new Contact(LastName = 'Doe'));

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

        TriggerOrchestrator.mock().afterUndeleteFor(FailingWriterWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

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

        TriggerOrchestrator.mock().afterUndeleteFor(FailingDispatcherWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingDispatcherWithContinueOnError());

        // Verify
        Assert.areEqual('The dispatcher failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void parentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);
        SOQL.mock(Contact.SObjectType).thenReturn(new Contact(Id = doe.Id, Account = acme));

        TriggerOrchestrator.mock().afterUndeleteFor(AccountNameWriter.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().afterUndeleteFor(RelatedAccountNameWriter.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriter());
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator.mock().afterUndeleteFor(TestOrchestrator.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(AccountWriterWithOwnUnitOfWork.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        CommitCountingDispatcher dispatcher = new CommitCountingDispatcher();

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.afterUndelete.add(new AccountWriterWithContinueOnError());
        handlers.afterUndelete.add(dispatcher);

        TriggerOrchestrator.mock().afterUndeleteFor(TestOrchestrator.class).with(doe);

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

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(FailingAccountWriterWithContinueOnError.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new FailingAccountWriterWithContinueOnError());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void mockWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().afterUndeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('AFTER_UNDELETE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithParent() {
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

    private class OperationStamper implements AfterUndelete.Writer {
        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getNewSObject().put(Contact.Description, 'AFTER_UNDELETE');
        }
    }

    private class AccountWriterWithBypassable extends AccountWriter implements AfterUndelete.Bypassable {
        public Boolean bypassOnAfterUndeleteWhen() {
            return true;
        }
    }

    private class IdDispatcherWithBypassable extends IdDispatcher implements AfterUndelete.Bypassable {
        public Boolean bypassOnAfterUndeleteWhen() {
            return true;
        }
    }

    private class BatchDispatcher implements AfterUndelete.Dispatcher {
        public List<Set<Id>> dispatchedBatches = new List<Set<Id>>();

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.dispatchedBatches.add(records.getIds());
        }
    }

    private class IdDispatcherWithFinalizerSnapshot extends IdDispatcher implements AfterUndelete.Finalizer {
        public List<Id> dispatchedIdsWhenFinalized;

        public void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.dispatchedIdsWhenFinalized = this.dispatchedIds.clone();
        }
    }

    private class AccountWriterWithFinalizer extends AccountWriter implements AfterUndelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private class IdDispatcherWithFinalizer extends IdDispatcher implements AfterUndelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
    }

    private virtual class FailingWriter implements AfterUndelete.Writer {
        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            throw new TestException('The writer failed.');
        }
    }

    private class FailingWriterWithContinueOnError extends FailingWriter implements AfterUndelete.ContinueOnError {
    }

    private virtual class FailingDispatcher implements AfterUndelete.Dispatcher {
        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            throw new TestException('The dispatcher failed.');
        }
    }

    private class FailingDispatcherWithContinueOnError extends FailingDispatcher implements AfterUndelete.ContinueOnError {
    }

    private virtual class AccountNameWriter implements AfterUndelete.Writer, AfterUndelete.ParentQuery {
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

    private class RelatedAccountProvider implements AfterUndelete.RecordsProvider {
        public List<SObject> query(TriggerTypes.UndeleteRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNameWriter implements AfterUndelete.Writer, AfterUndelete.RelatedQuery {
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

    private class CommitCountingDispatcher implements AfterUndelete.Dispatcher {
        public Integer committedAccounts;

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
            this.committedAccounts = DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size();
        }
    }

    private virtual class AccountWriterWithOwnUnitOfWork extends AccountWriter implements AfterUndelete.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnAfterUndelete() {
            return new DML().identifier('ownUnit');
        }
    }

    private class AccountWriterWithContinueOnError extends AccountWriter implements AfterUndelete.ContinueOnError {
    }

    private class FailingAccountWriterWithContinueOnError implements AfterUndelete.Writer, AfterUndelete.ContinueOnError {
        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }
    }

    private class TestOrchestrator implements TriggerOrchestrator.AfterUndelete {
        public List<AfterUndelete.Handler> afterUndelete = new List<AfterUndelete.Handler>();

        public List<AfterUndelete.Handler> afterUndeleteHandlers() {
            return this.afterUndelete;
        }
    }

    private virtual class AccountWriter implements AfterUndelete.Writer {
        public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getNewSObject().get(Contact.LastName)));
        }
    }

    private virtual class IdDispatcher implements AfterUndelete.Dispatcher {
        public List<Id> dispatchedIds = new List<Id>();

        public Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records) {
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
