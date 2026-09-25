/**
 * @description Tests for the BeforeInsert context of the TriggerOrchestrator class.
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
@IsTest(IsParallel=true testFor='ApexClass:BeforeInsert, ApexClass:TriggerOrchestrator')
private class BeforeInsertTest {
    @IsTest
    static void populatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void validatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DoeValidator());

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should reject the record.');
    }

    @IsTest
    static void populatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithBypassable.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithBypassable());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void populatorWithBypassableWhenBypassIsOff() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithBypassableOff.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithBypassableOff());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void populatorWithBypassableWhenManyRecords() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TitlePopulatorWithBypassCounter populator = new TitlePopulatorWithBypassCounter();

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithBypassCounter.class).with(new List<Contact>{ new Contact(LastName = 'Doe'), new Contact(LastName = 'Roe') });

        // Test
        TriggerOrchestrator.runTestFor(populator);

        // Verify
        Assert.areEqual(1, populator.bypassChecks, 'The bypass should be checked once per run.');
    }

    @IsTest
    static void parentQueryWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new AccountNamePopulatorWithBypassable());
        handlers.beforeInsert.add(new AccountNamePopulatorWithoutParentQuery());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.isNull(doe.Department, 'The parent should not be queried.');
    }

    @IsTest
    static void validatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidatorWithBypassable.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DoeValidatorWithBypassable());

        // Verify
        Assert.isTrue(doe.getErrors().isEmpty(), 'The handler should not run.');
    }

    @IsTest
    static void populator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void populatorWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(roe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(roe.Title, 'The populator should not set the title.');
    }

    @IsTest
    static void validator() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DoeValidator());

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should reject the record.');
    }

    @IsTest
    static void validatorWhenRecordDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidator.class).with(roe);

        // Test
        TriggerOrchestrator.runTestFor(new DoeValidator());

        // Verify
        Assert.isTrue(roe.getErrors().isEmpty(), 'The validator should not reject the record.');
    }

    @IsTest
    static void validatorWithFieldError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(DoeFieldValidator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DoeFieldValidator());

        // Verify
        Assert.areEqual(new List<String>{ 'Email' }, doe.getErrors()[0].getFields(), 'The error should be attached to the field.');
    }

    @IsTest
    static void validatorWithRecordError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DoeValidator());

        // Verify
        Assert.isTrue(doe.getErrors()[0].getFields().isEmpty(), 'The error should not be attached to a field.');
    }

    @IsTest
    static void validatorWithTwoErrors() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(DoubleDoeValidator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new DoubleDoeValidator());

        // Verify
        Assert.areEqual(2, doe.getErrors().size(), 'Both errors should be attached.');
    }

    @IsTest
    static void validatorWhenNoErrorIsAttached() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(SilentValidator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new SilentValidator());
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
    static void populatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithFinalizer.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(populator);

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe' }, populator.finalizedNames, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void validatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidatorWithFinalizer.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(validator);

        // Verify
        Assert.areEqual(new Set<String>{ 'Doe' }, validator.finalizedNames, 'The finalizer should receive the qualified records.');
    }

    @IsTest
    static void populatorWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithFinalizer.class).with(roe);

        // Test
        TriggerOrchestrator.runTestFor(populator);

        // Verify
        Assert.isNull(populator.finalizedNames, 'The finalizer should not run.');
    }

    @IsTest
    static void validatorWithFinalizerWhenNoRecordQualifies() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact roe = new Contact(LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TriggerOrchestrator.mock().beforeInsertFor(DoeValidatorWithFinalizer.class).with(roe);

        // Test
        TriggerOrchestrator.runTestFor(validator);

        // Verify
        Assert.isNull(validator.finalizedNames, 'The finalizer should not run.');
    }

    @IsTest
    static void populatorWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingPopulator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The populator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void validatorWhenHandlerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(FailingValidator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingValidator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The validator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void populatorWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnError());

        // Verify
        Assert.areEqual('The populator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void validatorWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(FailingValidatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingValidatorWithContinueOnError());

        // Verify
        Assert.areEqual('The validator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void populatorWithContinueOnErrorWhenFailingRecordIsNotLast() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');
        Contact roe = new Contact(LastName = 'Roe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorFailingOnDoeWithContinueOnError.class).with(new List<Contact>{ doe, roe });

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorFailingOnDoeWithContinueOnError());

        // Verify
        Assert.isNull(roe.Title, 'The populator should stop at the failing record.');
    }

    @IsTest
    static void finalizerWhenHandlerFailsWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(FailingPopulatorWithContinueOnErrorAndFinalizer.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new FailingPopulatorWithContinueOnErrorAndFinalizer());

        // Verify
        Assert.isNull(doe.Description, 'The finalizer should not run.');
    }

    @IsTest
    static void populatorWhenPreviousHandlerFailsWithContinueOnError() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(LastName = 'Doe');

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeInsert.add(new FailingPopulatorWithContinueOnError());
        handlers.beforeInsert.add(new TitlePopulator());

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void populatorWithContinueOnErrorWhenQualificationFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(PopulatorFailingOnQualificationWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new PopulatorFailingOnQualificationWithContinueOnError());

        // Verify
        Assert.areEqual('The qualification failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void populatorWithContinueOnErrorWhenFinalizerFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorFailingOnFinalizeWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorFailingOnFinalizeWithContinueOnError());

        // Verify
        Assert.areEqual('The finalizer failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void populatorWithContinueOnErrorWhenRelatedProviderIsNotRegistered() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(UnregisteredProviderReaderWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new UnregisteredProviderReaderWithContinueOnError());
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
    static void populatorWithContinueOnErrorWhenNestedRunFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(NestedRunPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new NestedRunPopulatorWithContinueOnError());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('Called outside of a trigger context.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void populatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(DmlPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlPopulator());
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
    static void validatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(DmlValidator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlValidator());
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
    static void populatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(DmlPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlPopulator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(expectedException, logger.errors[0].getException(), 'The guard should log the exception it throws.');
    }

    @IsTest
    static void validatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        TriggerOrchestrator.mock().beforeInsertFor(DmlValidator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlValidator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(expectedException, logger.errors[0].getException(), 'The guard should log the exception it throws.');
    }

    @IsTest
    static void populatorWhenQualificationPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(DmlQualificationPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlQualificationPopulator());
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
    static void populatorWhenFinalizerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithDmlFinalizer.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new TitlePopulatorWithDmlFinalizer());
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
    static void populatorWhenRelatedQueryPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulatorWithDmlRelatedQuery.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new TitlePopulatorWithDmlRelatedQuery());
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
    static void populatorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(FailingDmlPopulator.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDmlPopulator());
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('The populator failed.', expectedException?.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void populatorWhenDmlIsPerformedBeforeRun() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Database.setSavepoint();

        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitlePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void populatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(FailingDmlPopulatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDmlPopulatorWithContinueOnError());
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
    static void validatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TriggerOrchestrator.mock().beforeInsertFor(FailingDmlValidatorWithContinueOnError.class).with(new Contact(LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDmlValidatorWithContinueOnError());
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
    static void parentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(AccountNamePopulator.class).with(doe).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the account name.');
    }

    @IsTest
    static void parentQueryWhenLookupIsRepointed() {
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

        TriggerOrchestrator.mock().beforeInsertFor(TestOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(handlers);

        // Verify
        Assert.areEqual('Globex', doe.Department, 'The populator should copy the new account name.');
    }

    @IsTest
    static void relatedQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        SOQL.mock(Account.SObjectType).thenReturn(acme);

        Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeInsertFor(RelatedAccountNamePopulator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new RelatedAccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the related account name.');
    }

    @IsTest
    static void mockWith() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithList() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(new List<Contact>{ doe });

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithTwice() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe).with(new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_INSERT', doe.Description, 'The first row should still run.');
    }

    @IsTest
    static void mockWithParent() {
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
    static void mockWithParentList() {
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
    static void mockWithoutId() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(OperationStamper.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.isNull(doe.Id, 'The row should keep no Id.');
    }

    @IsTest
    static void mockOrchestrator() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeInsertFor(TitleOrchestrator.class).with(doe);

        // Test
        TriggerOrchestrator.runTestFor(new TitleOrchestrator());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The mocked orchestrator should run.');
    }

    private class OperationStamper implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.getNewSObject().put(Contact.Description, 'BEFORE_INSERT');
        }
    }

    private class TitlePopulatorWithBypassable extends TitlePopulator implements BeforeInsert.Bypassable {
        public Boolean bypassOnBeforeInsertWhen() {
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

    private class DoeValidatorWithBypassable extends DoeValidator implements BeforeInsert.Bypassable {
        public Boolean bypassOnBeforeInsertWhen() {
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

    private class TitlePopulatorWithFinalizer extends TitlePopulator implements BeforeInsert.Finalizer {
        public Set<String> finalizedNames;

        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }
    }

    private class DoeValidatorWithFinalizer extends DoeValidator implements BeforeInsert.Finalizer {
        public Set<String> finalizedNames;

        public void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }
    }

    private virtual class FailingValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            throw new TestException('The validator failed.');
        }
    }

    private class FailingValidatorWithContinueOnError extends FailingValidator implements BeforeInsert.ContinueOnError {
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

    private class DmlPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            Database.setSavepoint();
        }
    }

    private class DmlValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
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

    private virtual class FailingDmlPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            Database.setSavepoint();
            throw new TestException('The populator failed.');
        }
    }

    private class FailingDmlPopulatorWithContinueOnError extends FailingDmlPopulator implements BeforeInsert.ContinueOnError {
    }

    private virtual class FailingDmlValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            Database.setSavepoint();
            throw new TestException('The validator failed.');
        }
    }

    private class FailingDmlValidatorWithContinueOnError extends FailingDmlValidator implements BeforeInsert.ContinueOnError {
    }

    private class AccountRepointingPopulator implements BeforeInsert.Populator {
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
    }

    private class RelatedAccountProvider implements BeforeInsert.RecordsProvider {
        public List<SObject> query(TriggerTypes.InsertRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNamePopulator implements BeforeInsert.Populator, BeforeInsert.RelatedQuery {
        public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
            return new Map<String, BeforeInsert.RecordsProvider>{ 'accounts' => new RelatedAccountProvider() };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getRelated('accounts').getFirstWhereKeyEquals(record.getNewSObject().get(Contact.AccountId))?.get(Account.Name));
        }
    }

    private class TitleOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return new List<BeforeInsert.Handler>{ new TitlePopulator() };
        }
    }

    private class TestOrchestrator implements TriggerOrchestrator.BeforeInsert {
        public List<BeforeInsert.Handler> beforeInsert = new List<BeforeInsert.Handler>();

        public List<BeforeInsert.Handler> beforeInsertHandlers() {
            return this.beforeInsert;
        }
    }

    private virtual class TitlePopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private virtual class DoeValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            record.addError('Doe is not allowed.');
        }
    }

    private class DoeFieldValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            record.addError(Contact.Email, 'Doe is not allowed.');
        }
    }

    private class DoubleDoeValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
            record.addError('Doe is not allowed.');
            record.addError(Contact.Email, 'Doe is not allowed.');
        }
    }

    private class SilentValidator implements BeforeInsert.Validator {
        public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        }
    }

    private virtual class AccountNamePopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
        public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
            return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
        }

        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            record.put(Contact.Department, record.getNewParent('Account')?.get(Account.Name));
        }
    }

    private virtual class FailingPopulator implements BeforeInsert.Populator {
        public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
            throw new TestException('The populator failed.');
        }
    }

    private class FailingPopulatorWithContinueOnError extends FailingPopulator implements BeforeInsert.ContinueOnError {
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
