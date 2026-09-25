/**
 * @description Tests for the BeforeUpdate context of the TriggerOrchestrator class.
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
@IsTest(IsParallel=true)
private class BeforeUpdateTest {
    @IsTest
    static void populatorWithoutAddOns() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulatorWithBypassable.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithBypassable());

        // Verify
        Assert.isNull(doe.Title, 'The handler should not run.');
    }

    @IsTest
    static void validatorWithBypassable() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidatorWithBypassable.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulator.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidator.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoeFieldValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DoubleDoeValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Id doeId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);

        TriggerOrchestrator.mock().beforeUpdateFor(SilentValidator.class).with(new Contact(Id = doeId, LastName = 'Doe'), new Contact(Id = doeId, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new SilentValidator());
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
    static void populatorWithFinalizer() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TriggerOrchestrator.mock()
            .beforeUpdateFor(TitlePopulatorWithFinalizer.class)
            .with(new List<Contact>{ doe, roe }, new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') });

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');
        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TriggerOrchestrator.mock()
            .beforeUpdateFor(DoeValidatorWithFinalizer.class)
            .with(new List<Contact>{ doe, roe }, new List<Contact>{ new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = roe.Id, LastName = 'Roe') });

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        TitlePopulatorWithFinalizer populator = new TitlePopulatorWithFinalizer();

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulatorWithFinalizer.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact roe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Roe');

        DoeValidatorWithFinalizer validator = new DoeValidatorWithFinalizer();

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidatorWithFinalizer.class).with(roe, new Contact(Id = roe.Id, LastName = 'Roe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingPopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingPopulatorWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingValidatorWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new FailingValidatorWithContinueOnError());

        // Verify
        Assert.areEqual('The validator failed.', logger.errors[0].getException().getMessage(), 'The logged exception message should match the expected one.');
    }

    @IsTest
    static void populatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DmlPopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlPopulator());
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
    static void validatorWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DmlValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new DmlValidator());
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
    static void populatorWithLoggerWhenHandlerPerformsDml() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        TestLogger logger = new TestLogger();
        TriggerOrchestrator.triggerLogger.logger = logger;

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DmlPopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(DmlValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

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
    static void populatorWithDefaultRecursionDepth() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulator.class).with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = doe.Id, LastName = 'Doe'));
        }

        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new TitlePopulator());
        }

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulator());

        // Verify
        Assert.isNull(doe.Title, 'The populator should not run beyond the recursion depth.');
    }

    @IsTest
    static void populatorWithRecursionGuard() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(TitlePopulatorWithRecursionGuard.class)
            .with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = doe.Id, LastName = 'Doe'));
        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulatorWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRecursionGuard());

        // Verify
        Assert.isNull(doe.Title, 'The populator should not run beyond its recursion depth.');
    }

    @IsTest
    static void populatorQualificationWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        QualificationCountingPopulator populator = new QualificationCountingPopulator();

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.mock()
                .beforeUpdateFor(QualificationCountingPopulator.class)
                .with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = doe.Id, LastName = 'Doe'));
        }

        TriggerOrchestrator.mock().beforeUpdateFor(QualificationCountingPopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(populator);
        }

        // Test
        TriggerOrchestrator.runTestFor(populator);

        // Verify
        Assert.areEqual(3, populator.qualificationCalls, 'The qualification should not be asked beyond the recursion depth.');
    }

    @IsTest
    static void populatorWithRecursionGuardWhenEarlierRunDoesNotQualify() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(TitlePopulatorWithRecursionGuard.class)
            .with(new Contact(Id = doe.Id, LastName = 'Roe'), new Contact(Id = doe.Id, LastName = 'Roe'));
        TriggerOrchestrator.mock().beforeUpdateFor(TitlePopulatorWithRecursionGuard.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRecursionGuard());

        // Test
        TriggerOrchestrator.runTestFor(new TitlePopulatorWithRecursionGuard());

        // Verify
        Assert.areEqual('CEO', doe.Title, 'The populator should set the title.');
    }

    @IsTest
    static void validatorWhenRecursionDepthIsExceeded() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.mock().beforeUpdateFor(DoeValidator.class).with(new Contact(Id = doe.Id, LastName = 'Doe'), new Contact(Id = doe.Id, LastName = 'Doe'));
        }

        TriggerOrchestrator.mock().beforeUpdateFor(DoeValidator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        for (Integer run = 0; run < 3; run++) {
            TriggerOrchestrator.runTestFor(new DoeValidator());
        }

        // Test
        TriggerOrchestrator.runTestFor(new DoeValidator());

        // Verify
        Assert.areEqual('Doe is not allowed.', doe.getErrors()[0].getMessage(), 'The validator should not be limited by the recursion depth.');
    }

    @IsTest
    static void populatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingDmlPopulatorWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDmlPopulatorWithContinueOnError());
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
    static void validatorWithContinueOnErrorWhenHandlerPerformsDmlAndFails() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(FailingDmlValidatorWithContinueOnError.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe'));

        Exception expectedException = null;

        // Test
        try {
            TriggerOrchestrator.runTestFor(new FailingDmlValidatorWithContinueOnError());
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
    static void parentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeUpdateFor(AccountNamePopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe')).withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new AccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the account name.');
    }

    @IsTest
    static void priorParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe');

        TriggerOrchestrator.mock()
            .beforeUpdateFor(PriorAccountNamePopulator.class)
            .with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, acme);

        // Test
        TriggerOrchestrator.runTestFor(new PriorAccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the prior account name.');
    }

    @IsTest
    static void priorParentQueryWithParentQuery() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock()
            .beforeUpdateFor(PriorAccountNamePopulatorWithParentQuery.class)
            .with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = globex.Id))
            .withParent(Contact.AccountId, new List<Account>{ acme, globex });

        // Test
        Test.startTest();
        Integer queriesBefore = SOQL.getQueries();
        TriggerOrchestrator.runTestFor(new PriorAccountNamePopulatorWithParentQuery());
        Integer queriesAfter = SOQL.getQueries();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, queriesAfter - queriesBefore, 'The accounts should be queried once.');
    }

    @IsTest
    static void parentQueryWhenLookupIsRepointed() {
        // Setup
        SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
        SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());

        Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
        Account globex = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Globex');
        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TestOrchestrator handlers = new TestOrchestrator();
        handlers.beforeUpdate.add(new AccountRepointingPopulator(globex.Id));
        handlers.beforeUpdate.add(new AccountNamePopulator());

        TriggerOrchestrator.mock()
            .beforeUpdateFor(TestOrchestrator.class)
            .with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id))
            .withParent(Contact.AccountId, new List<Account>{ acme, globex });

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

        Contact doe = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', AccountId = acme.Id);

        TriggerOrchestrator.mock().beforeUpdateFor(RelatedAccountNamePopulator.class).with(doe, new Contact(Id = doe.Id, LastName = 'Doe', AccountId = acme.Id));

        // Test
        TriggerOrchestrator.runTestFor(new RelatedAccountNamePopulator());

        // Verify
        Assert.areEqual('Acme', doe.Department, 'The populator should copy the related account name.');
    }

    @IsTest
    static void mockWithPair() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(OperationStamper.class).with(doe, new Contact(LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_UPDATE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithPairLists() {
        // Setup
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(OperationStamper.class).with(new List<Contact>{ doe }, new List<Contact>{ new Contact(LastName = 'Doe') });

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual('BEFORE_UPDATE', doe.Description, 'The mocked context should run.');
    }

    @IsTest
    static void mockWithPairTwice() {
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
    static void mockWithParent() {
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
    static void mockWithPairSharingOldId() {
        // Setup
        Id doeId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        Contact doe = new Contact(LastName = 'Doe');

        TriggerOrchestrator.mock().beforeUpdateFor(OperationStamper.class).with(doe, new Contact(Id = doeId, LastName = 'Doe'));

        // Test
        TriggerOrchestrator.runTestFor(new OperationStamper());

        // Verify
        Assert.areEqual(doeId, doe.Id, 'The pair should share the old Id.');
    }

    private class OperationStamper implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.getNewSObject().put(Contact.Description, 'BEFORE_UPDATE');
        }
    }

    private class TitlePopulatorWithBypassable extends TitlePopulator implements BeforeUpdate.Bypassable {
        public Boolean bypassOnBeforeUpdateWhen() {
            return true;
        }
    }

    private class DoeValidatorWithBypassable extends DoeValidator implements BeforeUpdate.Bypassable {
        public Boolean bypassOnBeforeUpdateWhen() {
            return true;
        }
    }

    private class TitlePopulatorWithFinalizer extends TitlePopulator implements BeforeUpdate.Finalizer {
        public Set<String> finalizedNames;

        public void finalizeOnBeforeUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }
    }

    private class DoeValidatorWithFinalizer extends DoeValidator implements BeforeUpdate.Finalizer {
        public Set<String> finalizedNames;

        public void finalizeOnBeforeUpdate(TriggerTypes.UpdateRecords records) {
            this.finalizedNames = records.getValuesOf(Contact.LastName);
        }
    }

    private virtual class FailingValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            throw new TestException('The validator failed.');
        }
    }

    private class FailingValidatorWithContinueOnError extends FailingValidator implements BeforeUpdate.ContinueOnError {
    }

    private class DmlPopulator implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            Database.setSavepoint();
        }
    }

    private class DmlValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            Database.setSavepoint();
            record.addError('Doe is not allowed.');
        }
    }

    private virtual class FailingDmlPopulator implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            Database.setSavepoint();
            throw new TestException('The populator failed.');
        }
    }

    private class FailingDmlPopulatorWithContinueOnError extends FailingDmlPopulator implements BeforeUpdate.ContinueOnError {
    }

    private virtual class FailingDmlValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            Database.setSavepoint();
            throw new TestException('The validator failed.');
        }
    }

    private class FailingDmlValidatorWithContinueOnError extends FailingDmlValidator implements BeforeUpdate.ContinueOnError {
    }

    private class TitlePopulatorWithRecursionGuard extends TitlePopulator implements BeforeUpdate.RecursionGuard {
        public Integer maxRunsPerRecordOnBeforeUpdate() {
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

    private class AccountRepointingPopulator implements BeforeUpdate.Populator {
        private Id accountId;

        public AccountRepointingPopulator(Id accountId) {
            this.accountId = accountId;
        }

        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.AccountId, this.accountId);
        }
    }

    private class RelatedAccountProvider implements BeforeUpdate.RecordsProvider {
        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return SOQL.of(Account.SObjectType).with(Account.Name).byIds(records.getIdsOf(Contact.AccountId)).toList();
        }

        public String keyOf(SObject row) {
            return row.Id;
        }
    }

    private class RelatedAccountNamePopulator implements BeforeUpdate.Populator, BeforeUpdate.RelatedQuery {
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

    private class TestOrchestrator implements TriggerOrchestrator.BeforeUpdate {
        public List<BeforeUpdate.Handler> beforeUpdate = new List<BeforeUpdate.Handler>();

        public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
            return this.beforeUpdate;
        }
    }

    private virtual class TitlePopulator implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            record.put(Contact.Title, 'CEO');
        }
    }

    private virtual class DoeValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            record.addError('Doe is not allowed.');
        }
    }

    private class DoeFieldValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            record.addError(Contact.Email, 'Doe is not allowed.');
        }
    }

    private class DoubleDoeValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
            record.addError('Doe is not allowed.');
            record.addError(Contact.Email, 'Doe is not allowed.');
        }
    }

    private class SilentValidator implements BeforeUpdate.Validator {
        public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        }
    }

    private virtual class AccountNamePopulator implements BeforeUpdate.Populator, BeforeUpdate.ParentQuery {
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

    private virtual class FailingPopulator implements BeforeUpdate.Populator {
        public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
            return record.equals(Contact.LastName, 'Doe');
        }

        public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
            throw new TestException('The populator failed.');
        }
    }

    private class FailingPopulatorWithContinueOnError extends FailingPopulator implements BeforeUpdate.ContinueOnError {
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
