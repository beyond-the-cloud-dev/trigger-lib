/**
 * @description Tests for the BeforeDelete context of the TriggerOrchestrator class.
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
@IsTest(IsParallel=true testFor='ApexClass:BeforeDelete, ApexClass:TriggerOrchestrator')
private class BeforeDeleteTest {
    @IsTest
    static void handlerWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(DeletionBlocker.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DeletionBlocker());

        // Verify
        Assert.areEqual('Doe cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void handlerWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(DeletionBlockerWithBypassable.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DeletionBlockerWithBypassable());

        // Verify
        Assert.isTrue(doe.getErrors().isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void handler() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(DeletionBlocker.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DeletionBlocker());

        // Verify
        Assert.areEqual('Doe cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void handlerWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TriggerOrchestrator.mock().beforeDeleteFor(DeletionBlocker.class).with(roe);

        // Test
        TriggerOrchestrator.runTestFor(new DeletionBlocker());

        // Verify
        Assert.isTrue(roe.getErrors().isEmpty(), 'The handler should not block the deletion.');
    }

    @IsTest
    static void validatorWhenNoErrorIsAttached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeDeleteFor(SilentValidator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new SilentValidator());
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
    static void writer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().beforeDeleteFor(AccountWriter.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriter());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The writer should register the account.');
    }

    @IsTest
    static void writerWithOwnUnitOfWork() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('ownUnit').allDmls();

        TriggerOrchestrator.mock().beforeDeleteFor(AccountWriterWithOwnUnitOfWork.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new AccountWriterWithOwnUnitOfWork());

        // Verify
        Assert.areEqual('Doe', DML.retrieveResultFor('ownUnit').insertsOf(Account.SObjectType).records()[0].get(Account.Name), 'The own unit of work should commit the account.');
    }

    @IsTest
    static void writerWithContinueOnErrorWhenWriteFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
        DML.mock('triggerUow').allDmls();

        TriggerOrchestrator.mock().beforeDeleteFor(FailingAccountWriterWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingAccountWriterWithContinueOnError());

        // Verify
        Assert.areEqual(0, DML.retrieveResultFor('triggerUow').insertsOf(Account.SObjectType).records().size(), 'The automatic unit of work should not commit.');
    }

    @IsTest
    static void handlerWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        DeletionBlockerWithFinalizer blocker = new DeletionBlockerWithFinalizer();

        TriggerOrchestrator.mock().beforeDeleteFor(DeletionBlockerWithFinalizer.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(blocker);

        // Verify
        Assert.areEqual(new Set<Id>{ doe.Id }, blocker.finalizedIds, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void handlerWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        DeletionBlockerWithFinalizer blocker = new DeletionBlockerWithFinalizer();

        TriggerOrchestrator.mock().beforeDeleteFor(DeletionBlockerWithFinalizer.class).with(new Contact(LastName = 'Roe'));

        // Test
        TriggerOrchestrator.runTestFor(blocker);

        // Verify
        Assert.isNull(blocker.finalizedIds, 'The finalizer should not run.');
    }

    @IsTest
    static void handlerWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeDeleteFor(FailingDeleteHandler.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDeleteHandler());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The handler failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void handlerWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeDeleteFor(FailingDeleteHandlerWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingDeleteHandlerWithContinueOnError());

        // Verify
        Assert.areEqual('The handler failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void handlerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(DmlDeletionBlocker.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DmlDeletionBlocker());

        // Verify
        Assert.areEqual('Doe cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void priorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeDeleteFor(PriorAccountDeletionBlocker.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new PriorAccountDeletionBlocker());

        // Verify
        Assert.areEqual('Contacts of Acme cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void relatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeDeleteFor(RelatedAccountDeletionBlocker.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new RelatedAccountDeletionBlocker());

        // Verify
        Assert.areEqual('Contacts of Acme cannot be deleted.', doe.getErrors()[0].getMessage(), 'The handler should block the deletion.');
    }

    @IsTest
    static void mockWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_DELETE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithParent() {
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
    static void mockWithFakeId() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeDeleteFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.isNotNull(doe.Id, 'The row should get a fake Id.');
    }

    private class OperationStamper implements BeforeDelete.Writer {
        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            record.getOldSObject().put(Contact.Description, 'BEFORE_DELETE');
        }
    }

    private class DeletionBlockerWithBypassable extends DeletionBlocker implements BeforeDelete.Bypassable {
        public Boolean bypassOnBeforeDeleteWhen() {
            return true;
        }
    }

    private class DeletionBlockerWithFinalizer extends DeletionBlocker implements BeforeDelete.Finalizer {
        public Set<Id> finalizedIds;

        public void finalizeOnBeforeDelete(TriggerTypes.DeleteRecords records) {
            this.finalizedIds = records.getIds();
        }
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

    private class DmlDeletionBlocker implements BeforeDelete.Validator {
        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
            Database.setSavepoint();
            record.addError('Doe cannot be deleted.');
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
            record.addError('Contacts of ' + (String) record.getOldParent(Contact.AccountId)?.get(Account.Name) + ' cannot be deleted.');
        }
    }

    private class RelatedAccountProvider implements BeforeDelete.RecordsProvider {
        public List<SObject> query(TriggerTypes.DeleteRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
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

    private virtual class AccountWriterWithOwnUnitOfWork extends AccountWriter implements BeforeDelete.OwnUnitOfWork {
        public DML.Committable ownUnitOfWorkOnBeforeDelete() {
            return new DML().identifier('ownUnit');
        }
    }

    private class FailingAccountWriterWithContinueOnError implements BeforeDelete.Writer, BeforeDelete.ContinueOnError {
        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
            throw new TestException('The writer failed.');
        }
    }

    private class SilentValidator implements BeforeDelete.Validator {
        public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
        }
    }

    private virtual class AccountWriter implements BeforeDelete.Writer {
        public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
            unitOfWork.toInsert(new Account(Name = (String) record.getOldSObject().get(Contact.LastName)));
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
