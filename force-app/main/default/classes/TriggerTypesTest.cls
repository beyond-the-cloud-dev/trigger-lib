/**
 * @description Tests for the TriggerTypes class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.4
 *
 * PMD False Positives:
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true testFor='ApexClass:TriggerTypes')
private class TriggerTypesTest {
    @IsTest
    static void isChangedWhenValueDiffers() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChanged(Contact.LastName);

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed.');
    }

    @IsTest
    static void isChangedWhenValueIsTheSame() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Same'), new Contact(LastName = 'Same'));

        // Test
        Boolean result = record.isChanged(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed.');
    }

    @IsTest
    static void isChangedWhenValueWasSetFromNull() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChanged(Contact.Title);

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed.');
    }

    @IsTest
    static void isChangedWhenValueWasClearedToNull() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = null), new Contact(LastName = 'New', Title = 'Manager'));

        // Test
        Boolean result = record.isChanged(Contact.Title);

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed.');
    }

    @IsTest
    static void isChangedWhenBothValuesAreNull() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = null), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChanged(Contact.Title);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed.');
    }

    @IsTest
    static void isChangedWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'DOE'), new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isChanged(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed.');
    }

    @IsTest
    static void isChangedToWhenNewValueMatchesAndOldDiffers() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedTo(Contact.LastName, 'New');

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed to the value.');
    }

    @IsTest
    static void isChangedToWhenNewValueDoesNotMatch() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Other'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedTo(Contact.LastName, 'New');

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed to the value.');
    }

    @IsTest
    static void isChangedToWhenOldValueAlreadyMatched() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'New'));

        // Test
        Boolean result = record.isChangedTo(Contact.LastName, 'New');

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed to the value.');
    }

    @IsTest
    static void isChangedToWhenValueWasSetFromNull() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChangedTo(Contact.Title, 'Manager');

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed to the value.');
    }

    @IsTest
    static void isChangedToNullWhenValueWasCleared() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = null), new Contact(LastName = 'New', Title = 'Manager'));

        // Test
        Boolean result = record.isChangedTo(Contact.Title, null);

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed to the value.');
    }

    @IsTest
    static void isChangedFromWhenOldValueMatchesAndNewDiffers() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFrom(Contact.LastName, 'Old');

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed from the value.');
    }

    @IsTest
    static void isChangedFromWhenOldValueDoesNotMatch() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Other'));

        // Test
        Boolean result = record.isChangedFrom(Contact.LastName, 'Old');

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed from the value.');
    }

    @IsTest
    static void isChangedFromWhenNewValueStillMatches() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Old'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFrom(Contact.LastName, 'Old');

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed from the value.');
    }

    @IsTest
    static void isChangedFromNullWhenValueWasSet() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChangedFrom(Contact.Title, null);

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed from the value.');
    }

    @IsTest
    static void isChangedFromToWhenBothValuesMatch() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Old', 'New');

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed from and to the values.');
    }

    @IsTest
    static void isChangedFromToWhenOldValueDoesNotMatch() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Other'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Old', 'New');

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed from and to the values.');
    }

    @IsTest
    static void isChangedFromToWhenNewValueDoesNotMatch() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Other'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Old', 'New');

        // Verify
        Assert.isFalse(result, 'The field should not be reported as changed from and to the values.');
    }

    @IsTest
    static void isChangedFromToWhenFromAndToAreTheSame() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Same'), new Contact(LastName = 'Same'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Same', 'Same');

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed from and to the values.');
    }

    @IsTest
    static void isChangedFromToWhenValueWasSetFromNull() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChangedFromTo(Contact.Title, null, 'Manager');

        // Verify
        Assert.isTrue(result, 'The field should be reported as changed from and to the values.');
    }

    @IsTest
    static void isAnyChangedWithTwoFieldsWhenOneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Same', FirstName = 'New'), new Contact(LastName = 'Same', FirstName = 'Old'));

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isTrue(result, 'A field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithTwoFieldsWhenNoneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Same', FirstName = 'Same'), new Contact(LastName = 'Same', FirstName = 'Same'));

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isFalse(result, 'No field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithThreeFieldsWhenOneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'old@a.co')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isTrue(result, 'A field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithThreeFieldsWhenNoneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isFalse(result, 'No field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithFourFieldsWhenOneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'New'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Old')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isTrue(result, 'A field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithFourFieldsWhenNoneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isFalse(result, 'No field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithFiveFieldsWhenLastChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'New'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'Old')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isTrue(result, 'A field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithFiveFieldsWhenNoneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'Same'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'Same')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isFalse(result, 'No field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithIterableWhenOneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'old@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.isAnyChanged(fields);

        // Verify
        Assert.isTrue(result, 'A field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithIterableWhenNoneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.isAnyChanged(fields);

        // Verify
        Assert.isFalse(result, 'No field should be reported as changed.');
    }

    @IsTest
    static void isAnyChangedWithEmptyIterable() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));
        Iterable<SObjectField> fields = new List<SObjectField>();

        // Test
        Boolean result = record.isAnyChanged(fields);

        // Verify
        Assert.isFalse(result, 'No field should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithTwoFieldsWhenBothChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isTrue(result, 'All fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithTwoFieldsWhenOnlyOneChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'Same'),
            new Contact(LastName = 'OldLast', FirstName = 'Same')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isFalse(result, 'Not all fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithThreeFieldsWhenAllChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isTrue(result, 'All fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithThreeFieldsWhenLastDidNotChange() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'same@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'same@a.co')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isFalse(result, 'Not all fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithFourFieldsWhenAllChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'NewTitle'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'OldTitle')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isTrue(result, 'All fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithFourFieldsWhenOneDidNotChange() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'Same'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'Same')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isFalse(result, 'Not all fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithFiveFieldsWhenAllChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'NewTitle', Description = 'NewDescription'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'OldTitle', Description = 'OldDescription')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isTrue(result, 'All fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithFiveFieldsWhenLastDidNotChange() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'NewTitle', Description = 'Same'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'OldTitle', Description = 'Same')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isFalse(result, 'Not all fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithIterableWhenAllChanged() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.areAllChanged(fields);

        // Verify
        Assert.isTrue(result, 'All fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithIterableWhenOneDidNotChange() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'Same', Email = 'old@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.areAllChanged(fields);

        // Verify
        Assert.isFalse(result, 'Not all fields should be reported as changed.');
    }

    @IsTest
    static void areAllChangedWithEmptyIterable() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));
        Iterable<SObjectField> fields = new List<SObjectField>();

        // Test
        Boolean result = record.areAllChanged(fields);

        // Verify
        Assert.isTrue(result, 'All fields should be reported as changed.');
    }

    @IsTest
    static void isNullWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as null.');
    }

    @IsTest
    static void isNullWhenFieldIsEmptyString() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as null.');
    }

    @IsTest
    static void isNullWhenFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as null.');
    }

    @IsTest
    static void isNullWhenNumberFieldIsZero() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isNull(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as null.');
    }

    @IsTest
    static void isNullWhenBooleanFieldIsFalse() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isNull(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as null.');
    }

    @IsTest
    static void isNullWhenNewValueIsNullAndOldValueIsPopulated() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), new Contact(LastName = 'Doe', Description = 'Old'));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as null.');
    }

    @IsTest
    static void isNullOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as null.');
    }

    @IsTest
    static void isNotNullWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should be reported as null.');
    }

    @IsTest
    static void isNotNullWhenFieldIsEmptyString() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not null.');
    }

    @IsTest
    static void isNotNullWhenFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not null.');
    }

    @IsTest
    static void isNotNullWhenNumberFieldIsZero() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isNotNull(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not null.');
    }

    @IsTest
    static void isNotNullOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not null.');
    }

    @IsTest
    static void isEmptyWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as empty.');
    }

    @IsTest
    static void isEmptyWhenFieldIsEmptyString() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as empty.');
    }

    @IsTest
    static void isEmptyWhenFieldIsWhitespace() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as empty.');
    }

    @IsTest
    static void isEmptyWhenFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as empty.');
    }

    @IsTest
    static void isEmptyWhenNumberFieldIsZero() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as empty.');
    }

    @IsTest
    static void isEmptyWhenBooleanFieldIsFalse() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isEmpty(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as empty.');
    }

    @IsTest
    static void isEmptyWhenNewValueIsEmptyAndOldValueIsPopulated() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), new Contact(LastName = 'Doe', Description = 'Old'));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as empty.');
    }

    @IsTest
    static void isEmptyOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as empty.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should be reported as empty.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsEmptyString() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should be reported as empty.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsWhitespace() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not empty.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not empty.');
    }

    @IsTest
    static void isNotEmptyWhenNumberFieldIsZero() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isNotEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not empty.');
    }

    @IsTest
    static void isNotEmptyOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not empty.');
    }

    @IsTest
    static void isBlankWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isBlankWhenFieldIsEmptyString() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isBlankWhenFieldIsWhitespace() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isBlankWhenFieldIsTabAndNewLine() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '\t\n'), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isBlankWhenFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as blank.');
    }

    @IsTest
    static void isBlankWhenFieldHasSurroundingWhitespace() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '   Populated   '), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as blank.');
    }

    @IsTest
    static void isBlankWhenNumberFieldIsZero() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as blank.');
    }

    @IsTest
    static void isBlankWhenBooleanFieldIsFalse() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isBlank(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as blank.');
    }

    @IsTest
    static void isBlankWhenNewValueIsWhitespaceAndOldValueIsPopulated() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), new Contact(LastName = 'Doe', Description = 'Old'));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isBlankWhenNewValueIsPopulatedAndOldValueIsBlank() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'Populated'),
            new Contact(LastName = 'Doe', Description = '   ')
        );

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as blank.');
    }

    @IsTest
    static void isBlankOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as blank.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsEmptyString() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsWhitespace() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'The field should be reported as blank.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not blank.');
    }

    @IsTest
    static void isNotBlankWhenNumberFieldIsZero() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isNotBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not blank.');
    }

    @IsTest
    static void isNotBlankOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'The field should be reported as not blank.');
    }

    @IsTest
    static void equalsWhenValueMatches() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.LastName, 'Doe');

        // Verify
        Assert.isTrue(result, 'The field should equal the value.');
    }

    @IsTest
    static void equalsWhenValueDoesNotMatch() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.LastName, 'Smith');

        // Verify
        Assert.isFalse(result, 'The field should not equal the value.');
    }

    @IsTest
    static void equalsWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.LastName, 'DOE');

        // Verify
        Assert.isTrue(result, 'The field should equal the value.');
    }

    @IsTest
    static void equalsWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.Description, 'Anything');

        // Verify
        Assert.isFalse(result, 'The field should not equal the value.');
    }

    @IsTest
    static void equalsWhenExpectedValueIsNullAndFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isTrue(result, 'The field should equal the value.');
    }

    @IsTest
    static void equalsWhenExpectedValueIsNullAndFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Note'), null);

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'The field should not equal the value.');
    }

    @IsTest
    static void equalsWhenFieldIsEmptyText() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.equals(Contact.Description, '');

        // Verify
        Assert.isTrue(result, 'The field should equal the value.');
    }

    @IsTest
    static void equalsWhenFieldIsEmptyTextAndExpectedValueIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'The field should not equal the value.');
    }

    @IsTest
    static void equalsOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'New');

        // Verify
        Assert.isTrue(result, 'The field should equal the value.');
    }

    @IsTest
    static void equalsOnUpdateRecordWhenOldValueMatches() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Old');

        // Verify
        Assert.isFalse(result, 'The field should not equal the value.');
    }

    @IsTest
    static void equalsOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Deleted'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Deleted');

        // Verify
        Assert.isTrue(result, 'The field should equal the value.');
    }

    @IsTest
    static void doesNotEqualWhenValueDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Smith');

        // Verify
        Assert.isTrue(result, 'The field should not equal the value.');
    }

    @IsTest
    static void doesNotEqualWhenValueMatches() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Doe');

        // Verify
        Assert.isFalse(result, 'The field should equal the value.');
    }

    @IsTest
    static void doesNotEqualWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'DOE');

        // Verify
        Assert.isFalse(result, 'The field should equal the value.');
    }

    @IsTest
    static void doesNotEqualWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, 'Anything');

        // Verify
        Assert.isTrue(result, 'The field should not equal the value.');
    }

    @IsTest
    static void doesNotEqualWhenExpectedValueIsNullAndFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'The field should equal the value.');
    }

    @IsTest
    static void doesNotEqualWhenExpectedValueIsNullAndFieldIsPopulated() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Note'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, null);

        // Verify
        Assert.isTrue(result, 'The field should not equal the value.');
    }

    @IsTest
    static void doesNotEqualOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Old');

        // Verify
        Assert.isTrue(result, 'The field should not equal the value.');
    }

    @IsTest
    static void doesNotEqualOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Deleted'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Deleted');

        // Verify
        Assert.isFalse(result, 'The field should equal the value.');
    }

    @IsTest
    static void containsWhenValueIsPresent() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'The field should contain the value.');
    }

    @IsTest
    static void containsWhenValueIsAbsent() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'Goodbye');

        // Verify
        Assert.isFalse(result, 'The field should not contain the value.');
    }

    @IsTest
    static void containsWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'The field should not contain the value.');
    }

    @IsTest
    static void containsWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'world');

        // Verify
        Assert.isFalse(result, 'The field should not contain the value.');
    }

    @IsTest
    static void containsWithNumberField() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 1500), null);

        // Test
        Boolean result = record.contains(Account.NumberOfEmployees, '50');

        // Verify
        Assert.isTrue(result, 'The field should contain the value.');
    }

    @IsTest
    static void containsOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'New note'),
            new Contact(LastName = 'Doe', Description = 'Old note')
        );

        // Test
        Boolean result = record.contains(Contact.Description, 'New');

        // Verify
        Assert.isTrue(result, 'The field should contain the value.');
    }

    @IsTest
    static void containsOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Old note'));

        // Test
        Boolean result = record.contains(Contact.Description, 'Old');

        // Verify
        Assert.isTrue(result, 'The field should contain the value.');
    }

    @IsTest
    static void doesNotContainWhenValueIsAbsent() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Goodbye');

        // Verify
        Assert.isTrue(result, 'The field should not contain the value.');
    }

    @IsTest
    static void doesNotContainWhenValueIsPresent() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'The field should contain the value.');
    }

    @IsTest
    static void doesNotContainWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'The field should not contain the value.');
    }

    @IsTest
    static void doesNotContainWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'world');

        // Verify
        Assert.isTrue(result, 'The field should not contain the value.');
    }

    @IsTest
    static void doesNotContainOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'New note'),
            new Contact(LastName = 'Doe', Description = 'Old note')
        );

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Old');

        // Verify
        Assert.isTrue(result, 'The field should not contain the value.');
    }

    @IsTest
    static void doesNotContainOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Old note'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Old');

        // Verify
        Assert.isFalse(result, 'The field should contain the value.');
    }

    @IsTest
    static void startsWithWhenPrefixMatches() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isTrue(result, 'The field should start with the value.');
    }

    @IsTest
    static void startsWithWhenValueIsNotAtTheStart() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'The field should not start with the value.');
    }

    @IsTest
    static void startsWithWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isFalse(result, 'The field should not start with the value.');
    }

    @IsTest
    static void startsWithWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'hello');

        // Verify
        Assert.isFalse(result, 'The field should not start with the value.');
    }

    @IsTest
    static void startsWithOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'New note'),
            new Contact(LastName = 'Doe', Description = 'Old note')
        );

        // Test
        Boolean result = record.startsWith(Contact.Description, 'New');

        // Verify
        Assert.isTrue(result, 'The field should start with the value.');
    }

    @IsTest
    static void startsWithOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Old note'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Old');

        // Verify
        Assert.isTrue(result, 'The field should start with the value.');
    }

    @IsTest
    static void endsWithWhenSuffixMatches() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'The field should end with the value.');
    }

    @IsTest
    static void endsWithWhenValueIsNotAtTheEnd() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isFalse(result, 'The field should not end with the value.');
    }

    @IsTest
    static void endsWithWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'The field should not end with the value.');
    }

    @IsTest
    static void endsWithWhenOnlyLetterCaseDiffers() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'WORLD');

        // Verify
        Assert.isFalse(result, 'The field should not end with the value.');
    }

    @IsTest
    static void endsWithOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'Note new'),
            new Contact(LastName = 'Doe', Description = 'Note old')
        );

        // Test
        Boolean result = record.endsWith(Contact.Description, 'new');

        // Verify
        Assert.isTrue(result, 'The field should end with the value.');
    }

    @IsTest
    static void endsWithOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Note old'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'old');

        // Verify
        Assert.isTrue(result, 'The field should end with the value.');
    }

    @IsTest
    static void isTrueWhenFieldIsTrue() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true), null);

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'The field should be reported as true.');
    }

    @IsTest
    static void isTrueWhenFieldIsFalse() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as true.');
    }

    @IsTest
    static void isTrueWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal'), null);

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as true.');
    }

    @IsTest
    static void isTrueWhenFieldIsText() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'true'), null);

        // Test
        Boolean result = record.isTrue(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as true.');
    }

    @IsTest
    static void isTrueOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true), new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'The field should be reported as true.');
    }

    @IsTest
    static void isTrueOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'The field should be reported as true.');
    }

    @IsTest
    static void isFalseWhenFieldIsFalse() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'The field should be reported as false.');
    }

    @IsTest
    static void isFalseWhenFieldIsTrue() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true), null);

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as false.');
    }

    @IsTest
    static void isFalseWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal'), null);

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as false.');
    }

    @IsTest
    static void isFalseWhenFieldIsText() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isFalse(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'The field should not be reported as false.');
    }

    @IsTest
    static void isFalseOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'The field should be reported as false.');
    }

    @IsTest
    static void isFalseOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'The field should be reported as false.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanIntegerWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'The field should be less than the value.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanIntegerWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDoubleWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than the value.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDoubleWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDecimalWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than the value.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDecimalWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDateWhenDatesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenDatesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than the value.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDateWhenDatesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenDatesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDateTimeWhenDateTimesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenDateTimesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than the value.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDateTimeWhenDateTimesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsEarlier() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsLater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenDateTimesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanLongWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanLongBeyondDoublePrecisionWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L), null);
        Long value = 9007199254740992L;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than the value.');
    }

    @IsTest
    static void greaterThanLongBeyondDoublePrecisionWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L), null);
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than the value.');
    }

    @IsTest
    static void greaterThanOrEqualToLongBeyondDoublePrecisionWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 9007199254740992L), null);
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'The field should not be greater than or equal to the value.');
    }

    @IsTest
    static void greaterThanOrEqualToLongBeyondDoublePrecisionWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L), null);
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'The field should be greater than or equal to the value.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than the value.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanLongWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Long value = 150L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than the value.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsLower() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsGreater() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenValuesAreEqual() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'The field should be less than or equal to the value.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsNull() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Name = 'Test'), null);
        Long value = 150L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'The field should not be less than or equal to the value.');
    }

    @IsTest
    static void greaterThanOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Account(NumberOfEmployees = 100), new Account(NumberOfEmployees = 10));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'The comparison should read the new record.');
    }

    @IsTest
    static void greaterThanOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'The comparison should read the old record.');
    }

    @IsTest
    static void isRecordTypeWhenSObjectHasNoRecordTypes() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new User(), null);
        Exception expectedException = null;

        // Test
        try {
            record.isRecordType('Standard');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('User has no record types, so isRecordType cannot be used on it.', expectedException.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void isNotRecordTypeWhenSObjectHasNoRecordTypes() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new User(), null);
        Exception expectedException = null;

        // Test
        try {
            record.isNotRecordType('Standard');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'User has no record types, so isNotRecordType cannot be used on it.',
            expectedException.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void isRecordTypeOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new User(LastName = 'Old'));
        Exception expectedException = null;

        // Test
        try {
            record.isRecordType('Standard');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('User has no record types, so isRecordType cannot be used on it.', expectedException.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void isNotRecordTypeOnDeleteRecord() {
        // Setup
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new User(LastName = 'Old'));
        Exception expectedException = null;

        // Test
        try {
            record.isNotRecordType('Standard');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'User has no record types, so isNotRecordType cannot be used on it.',
            expectedException.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void isRecordTypeWhenGroupHasNoRecordTypes() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Group(), null);
        Exception expectedException = null;

        // Test
        try {
            record.isRecordType('Standard');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual('Group has no record types, so isRecordType cannot be used on it.', expectedException.getMessage(), 'The exception message should match the expected one.');
    }

    @IsTest
    static void getNewSObjectOnInsertRecord() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(newContact, null);

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(newContact, result, 'The new record should be returned.');
    }

    @IsTest
    static void getOldSObjectOnInsertRecord() {
        // Setup
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.isNull(result, 'The old record should be null.');
    }

    @IsTest
    static void getNewSObjectOnUpdateRecord() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(newContact, new Contact(LastName = 'Old'));

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(newContact, result, 'The new record should be returned.');
    }

    @IsTest
    static void getOldSObjectOnUpdateRecord() {
        // Setup
        Contact oldContact = new Contact(LastName = 'Old');
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), oldContact);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.areEqual(oldContact, result, 'The old record should be returned.');
    }

    @IsTest
    static void getNewSObjectOnDeleteRecord() {
        // Setup
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Old'));

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.isNull(result, 'The new record should be null.');
    }

    @IsTest
    static void getOldSObjectOnDeleteRecord() {
        // Setup
        Id contactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        Contact oldContact = new Contact(Id = contactId, LastName = 'Old');
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, oldContact);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.areEqual(oldContact, result, 'The old record should be returned.');
    }

    @IsTest
    static void getNewSObjectWhenSourceRecordChanges() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(newContact, null);
        newContact.Title = 'Manager';

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual('Manager', result.get(Contact.Title), 'The change on the source record should be visible.');
    }

    @IsTest
    static void getOldSObjectWhenSourceRecordChanges() {
        // Setup
        Contact oldContact = new Contact(LastName = 'Old');
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), oldContact);
        oldContact.Title = 'Manager';

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.areEqual('Manager', result.get(Contact.Title), 'The change on the source record should be visible.');
    }

    @IsTest
    static void getIdOnDeleteRecord() {
        // Setup
        Id contactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.DeleteRecord record = new TriggerTypes.TriggerRecord(null, new Contact(Id = contactId, LastName = 'Old'));

        // Test
        Id result = record.getId();

        // Verify
        Assert.areEqual(contactId, result, 'The old record Id should be returned.');
    }

    @IsTest
    static void getIdWhenNewAndOldIdsDiffer() {
        // Setup
        Id firstContactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        Id secondContactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(Id = firstContactId, LastName = 'New'), new Contact(Id = secondContactId, LastName = 'Old'));

        // Test
        Id result = record.getId();

        // Verify
        Assert.areEqual(firstContactId, result, 'The new record Id should be returned.');
    }

    @IsTest
    static void equalsAfterPut() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), null);
        record.put(Contact.Title, 'Manager');

        // Test
        Boolean result = record.equals(Contact.Title, 'Manager');

        // Verify
        Assert.isTrue(result, 'The field should equal the put value.');
    }

    @IsTest
    static void put() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(newContact, null);

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Manager', newContact.Title, 'The field should be set on the source record.');
    }

    @IsTest
    static void putWhenFieldHasValue() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), null);

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Manager', record.getNewSObject().get(Contact.Title), 'The field should be overwritten.');
    }

    @IsTest
    static void putWithNullValue() {
        // Setup
        TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), null);

        // Test
        record.put(Contact.Title, null);

        // Verify
        Assert.isNull(record.getNewSObject().get(Contact.Title), 'The field should be cleared.');
    }

    @IsTest
    static void putOnUpdateRecord() {
        // Setup
        TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), new Contact(LastName = 'Old', Title = 'Analyst'));

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Analyst', record.getOldSObject().get(Contact.Title), 'The old record should not change.');
    }

    @IsTest
    static void addErrorOnRejectableInsertRecord() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.RejectableInsertRecord record = new TriggerTypes.TriggerRecord(newContact, null);

        // Test
        record.addError('The record is not allowed.');

        // Verify
        Assert.areEqual('The record is not allowed.', newContact.getErrors()[0].getMessage(), 'The error should be attached to the record.');
    }

    @IsTest
    static void addErrorWithFieldOnRejectableInsertRecord() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.RejectableInsertRecord record = new TriggerTypes.TriggerRecord(newContact, null);

        // Test
        record.addError(Contact.Email, 'The email is not allowed.');

        // Verify
        Assert.areEqual(new List<String>{ 'Email' }, newContact.getErrors()[0].getFields(), 'The error should be attached to the field.');
    }

    @IsTest
    static void addErrorOnRejectableUpdateRecord() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.RejectableUpdateRecord record = new TriggerTypes.TriggerRecord(newContact, new Contact(LastName = 'Old'));

        // Test
        record.addError('The record is not allowed.');

        // Verify
        Assert.areEqual('The record is not allowed.', newContact.getErrors()[0].getMessage(), 'The error should be attached to the new record.');
    }

    @IsTest
    static void addErrorWithFieldOnRejectableUpdateRecord() {
        // Setup
        Contact newContact = new Contact(LastName = 'New');
        TriggerTypes.RejectableUpdateRecord record = new TriggerTypes.TriggerRecord(newContact, new Contact(LastName = 'Old'));

        // Test
        record.addError(Contact.Email, 'The email is not allowed.');

        // Verify
        Assert.areEqual(new List<String>{ 'Email' }, newContact.getErrors()[0].getFields(), 'The error should be attached to the field.');
    }

    @IsTest
    static void addErrorOnRejectableDeleteRecord() {
        // Setup
        Contact oldContact = new Contact(LastName = 'Old');
        TriggerTypes.RejectableDeleteRecord record = new TriggerTypes.TriggerRecord(null, oldContact);

        // Test
        record.addError('The record is not allowed.');

        // Verify
        Assert.areEqual('The record is not allowed.', oldContact.getErrors()[0].getMessage(), 'The error should be attached to the old record.');
    }

    @IsTest
    static void addErrorWithFieldOnRejectableDeleteRecord() {
        // Setup
        Contact oldContact = new Contact(LastName = 'Old');
        TriggerTypes.RejectableDeleteRecord record = new TriggerTypes.TriggerRecord(null, oldContact);

        // Test
        record.addError(Contact.Email, 'The email is not allowed.');

        // Verify
        Assert.areEqual(new List<String>{ 'Email' }, oldContact.getErrors()[0].getFields(), 'The error should be attached to the field.');
    }

    @IsTest
    static void getNewParent() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Account parentAccount = new Account(Id = accountId, Name = 'Parent');
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.setNewParent('Account', parentAccount);

        // Test
        SObject result = record.getNewParent(Contact.AccountId);

        // Verify
        Assert.areEqual(parentAccount, result, 'The enriched parent should be returned.');
    }

    @IsTest
    static void getOldParent() {
        // Setup
        Id firstAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id secondAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Account priorParentAccount = new Account(Id = firstAccountId, Name = 'Prior Parent');
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'New', AccountId = secondAccountId),
            new Contact(LastName = 'Old', AccountId = firstAccountId)
        );
        record.setOldParent('Account', priorParentAccount);

        // Test
        SObject result = record.getOldParent(Contact.AccountId);

        // Verify
        Assert.areEqual(priorParentAccount, result, 'The enriched parent should be returned.');
    }

    @IsTest
    static void getOldParentWhenBothSidesAreEnriched() {
        // Setup
        Id firstAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id secondAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );
        record.setOldParent('Account', new Account(Id = secondAccountId, Name = 'Prior Parent'));
        record.setNewParent('Account', new Account(Id = firstAccountId, Name = 'Current Parent'));

        // Test
        SObject result = record.getOldParent(Contact.AccountId);

        // Verify
        Assert.areEqual('Prior Parent', result.get(Account.Name), 'The old parent should be returned.');
    }

    @IsTest
    static void getNewParentWhenBothSidesAreEnriched() {
        // Setup
        Id firstAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id secondAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );
        record.setNewParent('Account', new Account(Id = firstAccountId, Name = 'Current Parent'));
        record.setOldParent('Account', new Account(Id = secondAccountId, Name = 'Prior Parent'));

        // Test
        SObject result = record.getNewParent(Contact.AccountId);

        // Verify
        Assert.areEqual('Current Parent', result.get(Account.Name), 'The new parent should be returned.');
    }

    @IsTest
    static void getNewParentWhenLookupIsNotEnriched() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.setNewParent('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewParent(Contact.ReportsToId);

        // Verify
        Assert.isNull(result, 'The parent should be null.');
    }

    @IsTest
    static void getOldParentWhenLookupIsNotEnriched() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.setOldParent('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getOldParent(Contact.ReportsToId);

        // Verify
        Assert.isNull(result, 'The parent should be null.');
    }

    @IsTest
    static void getOldParentWhenOnlyNewSideIsEnriched() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.setNewParent('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getOldParent(Contact.AccountId);

        // Verify
        Assert.isNull(result, 'The parent should be null.');
    }

    @IsTest
    static void getNewParentWhenOnlyOldSideIsEnriched() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.setOldParent('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewParent(Contact.AccountId);

        // Verify
        Assert.isNull(result, 'The parent should be null.');
    }

    @IsTest
    static void getNewParentWhenOtherLookupPointsToSameObject() {
        // Setup
        Id managerId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', ReportsToId = managerId), null);
        record.setNewParent('ReportsTo', new Contact(Id = managerId, LastName = 'Manager'));

        // Test
        SObject result = record.getNewParent(Contact.MasterRecordId);

        // Verify
        Assert.isNull(result, 'The parent should be null.');
    }

    @IsTest
    static void enrichNewWhenRelationshipIsAlreadyEnriched() {
        // Setup
        Id firstAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id secondAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', AccountId = firstAccountId), null);
        record.setNewParent('Account', new Account(Id = firstAccountId, Name = 'Original Parent'));
        record.setNewParent('Account', new Account(Id = secondAccountId, Name = 'Re-pointed Parent'));

        // Test
        SObject result = record.getNewParent(Contact.AccountId);

        // Verify
        Assert.areEqual('Re-pointed Parent', result.get(Account.Name), 'The parent should be replaced.');
    }

    @IsTest
    static void enrichNewWithTwoRelationships() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id contactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.setNewParent('Account', new Account(Id = accountId, Name = 'Parent'));
        record.setNewParent('ReportsTo', new Contact(Id = contactId, LastName = 'Manager'));

        // Test
        SObject result = record.getNewParent(Contact.AccountId);

        // Verify
        Assert.areEqual('Parent', result.get(Account.Name), 'The first parent should be kept.');
    }

    @IsTest
    static void withOneField() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withTwoFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name, Account.Industry).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Industry' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withThreeFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name, Account.Industry, Account.Description).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Industry', 'Description' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withFourFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name, Account.Industry, Account.Description, Account.Website).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Industry', 'Description', 'Website' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withFiveFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name, Account.Industry, Account.Description, Account.Website, Account.NumberOfEmployees).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Industry', 'Description', 'Website', 'NumberOfEmployees' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withIterableOfFields() {
        // Setup
        List<SObjectField> fieldsToSelect = new List<SObjectField>{
            Account.Name,
            Account.Industry,
            Account.Description,
            Account.Website,
            Account.NumberOfEmployees,
            Account.AnnualRevenue
        };

        // Test
        List<String> fields = TriggerTypes.ParentFields.with(fieldsToSelect).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Description', 'Website', 'NumberOfEmployees', 'AnnualRevenue' },
            fields,
            'The selected fields should match the expected ones.'
        );
    }

    @IsTest
    static void withRelationshipAndOneField() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', Account.Name).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Parent.Name' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withRelationshipAndTwoFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', Account.Name, Account.Industry).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Parent.Name', 'Parent.Industry' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withRelationshipAndThreeFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', Account.Name, Account.Industry, Account.Description).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withRelationshipAndFourFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', Account.Name, Account.Industry, Account.Description, Account.Website).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description', 'Parent.Website' },
            fields,
            'The selected fields should match the expected ones.'
        );
    }

    @IsTest
    static void withRelationshipAndFiveFields() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', Account.Name, Account.Industry, Account.Description, Account.Website, Account.NumberOfEmployees).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description', 'Parent.Website', 'Parent.NumberOfEmployees' },
            fields,
            'The selected fields should match the expected ones.'
        );
    }

    @IsTest
    static void withRelationshipAndIterableOfFields() {
        // Setup
        List<SObjectField> fieldsToSelect = new List<SObjectField>{
            Account.Name,
            Account.Industry,
            Account.Description,
            Account.Website,
            Account.NumberOfEmployees,
            Account.AnnualRevenue
        };

        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', fieldsToSelect).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description', 'Parent.Website', 'Parent.NumberOfEmployees', 'Parent.AnnualRevenue' },
            fields,
            'The selected fields should match the expected ones.'
        );
    }

    @IsTest
    static void withPlainAndRelationshipFieldsChained() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name, Account.Industry).with('Parent', Account.Name).with(Account.Website).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Industry', 'Parent.Name', 'Website' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withDifferentRelationshipsChained() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Account', Account.Name).with('ReportsTo', Contact.Email).with('Account', Account.Industry).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Account.Name', 'ReportsTo.Email', 'Account.Industry' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void withChaining() {
        // Setup
        TriggerTypes.ParentFields selection = TriggerTypes.ParentFields.with(Account.Name);

        // Test
        TriggerTypes.ParentFields chainedSelection = selection.with(Account.Industry);

        // Verify
        Assert.isTrue(chainedSelection === selection, 'The same selection should be returned.');
    }

    @IsTest
    static void withRelationshipChaining() {
        // Setup
        TriggerTypes.ParentFields selection = TriggerTypes.ParentFields.with(Account.Name);

        // Test
        TriggerTypes.ParentFields chainedSelection = selection.with('Parent', Account.Industry);

        // Verify
        Assert.isTrue(chainedSelection === selection, 'The same selection should be returned.');
    }

    @IsTest
    static void withInSeparateStatements() {
        // Setup
        TriggerTypes.ParentFields selection = TriggerTypes.ParentFields;

        selection.with(Account.Name);
        selection.with('Parent', Account.Industry);

        // Test
        List<String> fields = selection.with(new List<SObjectField>{ Account.Website }).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Parent.Industry', 'Website' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void parentFieldsWhenReadTwice() {
        // Setup
        TriggerTypes.ParentFields.with(Account.Name, Account.Industry);

        // Test
        List<String> fields = TriggerTypes.ParentFields.getFields();

        // Verify
        Assert.areEqual(new List<String>(), fields, 'The selected fields should be empty.');
    }

    @IsTest
    static void getFieldsWithRepeatedField() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name).with(Account.Industry).with(Account.Name).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Industry', 'Name' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void getFieldsWithRepeatedFieldInSingleCall() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with(Account.Name, Account.Name, Account.Name).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name', 'Name', 'Name' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void getFieldsWithRepeatedRelationshipField() {
        // Test
        List<String> fields = TriggerTypes.ParentFields.with('Parent', Account.Name).with('Parent', Account.Name).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Parent.Name', 'Parent.Name' }, fields, 'The selected fields should match the expected ones.');
    }

    @IsTest
    static void providedRecordsGetFirstWhereKeyEquals() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Opportunity firstOpportunity = new Opportunity(Name = 'First', AccountId = accountId);
        Opportunity secondOpportunity = new Opportunity(Name = 'Second', AccountId = accountId);
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ firstOpportunity, secondOpportunity });
        related.groupUnderKey(accountId, firstOpportunity);
        related.groupUnderKey(accountId, secondOpportunity);

        // Test
        SObject result = related.getFirstWhereKeyEquals(accountId);

        // Verify
        Assert.areEqual(firstOpportunity, result, 'The first grouped record should be returned.');
    }

    @IsTest
    static void providedRecordsGetAllWhereKeyEquals() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Opportunity firstOpportunity = new Opportunity(Name = 'First', AccountId = accountId);
        Opportunity secondOpportunity = new Opportunity(Name = 'Second', AccountId = accountId);
        Opportunity otherOpportunity = new Opportunity(Name = 'Other', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ firstOpportunity, secondOpportunity, otherOpportunity });
        related.groupUnderKey(accountId, firstOpportunity);
        related.groupUnderKey(accountId, secondOpportunity);
        related.groupUnderKey(otherOpportunity.AccountId, otherOpportunity);

        // Test
        List<SObject> result = related.getAllWhereKeyEquals(accountId);

        // Verify
        Assert.areEqual(new List<SObject>{ firstOpportunity, secondOpportunity }, result, 'The grouped records should be returned.');
    }

    @IsTest
    static void providedRecordsGetAllWhereKeyEqualsWhenKeyIsUnknown() {
        // Setup
        Opportunity deal = new Opportunity(Name = 'First', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ deal });
        related.groupUnderKey(deal.AccountId, deal);

        // Test
        List<SObject> result = related.getAllWhereKeyEquals(new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        // Verify
        Assert.areEqual(new List<SObject>(), result, 'An empty list should be returned.');
    }

    @IsTest
    static void providedRecordsGetFirstWhereKeyEqualsWhenKeyIsUnknown() {
        // Setup
        Opportunity deal = new Opportunity(Name = 'First', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ deal });
        related.groupUnderKey(deal.AccountId, deal);

        // Test
        SObject result = related.getFirstWhereKeyEquals(new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

        // Verify
        Assert.isNull(result, 'The record should be null.');
    }

    @IsTest
    static void providedRecordsGetFirstWhereKeyEqualsWithNumericKey() {
        // Setup
        Opportunity deal = new Opportunity(Name = 'First');
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ deal });
        related.groupUnderKey('42', deal);

        // Test
        SObject result = related.getFirstWhereKeyEquals(42);

        // Verify
        Assert.areEqual(deal, result, 'The record grouped under the text key should be returned.');
    }

    @IsTest
    static void providedRecordsGroupUnderKeyWithNullKey() {
        // Setup
        Opportunity orphan = new Opportunity(Name = 'Orphan');
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ orphan });
        related.groupUnderKey(null, orphan);

        // Test
        List<SObject> result = related.getAllWhereKeyEquals(null);

        // Verify
        Assert.areEqual(new List<SObject>(), result, 'The record should not be grouped.');
    }

    @IsTest
    static void providedRecordsGetRecordsWithUngroupedRecord() {
        // Setup
        Opportunity orphan = new Opportunity(Name = 'Orphan');
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ orphan });
        related.groupUnderKey(null, orphan);

        // Test
        List<SObject> result = related.getRecords();

        // Verify
        Assert.areEqual(new List<Opportunity>{ orphan }, result, 'The ungrouped record should be returned.');
    }

    @IsTest
    static void providedRecordsIsEmptyWithUngroupedRecord() {
        // Setup
        Opportunity orphan = new Opportunity(Name = 'Orphan');
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ orphan });
        related.groupUnderKey(null, orphan);

        // Test
        Boolean result = related.isEmpty();

        // Verify
        Assert.isFalse(result, 'The records should not be empty.');
    }

    @IsTest
    static void providedRecordsGetRecordsWhenBuiltFromNull() {
        // Setup
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(null);

        // Test
        List<SObject> result = related.getRecords();

        // Verify
        Assert.areEqual(new List<SObject>(), result, 'An empty list should be returned.');
    }

    @IsTest
    static void getRelated() {
        // Setup
        TriggerTypes.ProvidedRecords openOpportunities = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ new Opportunity(Name = 'Open') });
        TriggerTypes.ProvidedRecords closedOpportunities = new TriggerTypes.ProvidedRecords(new List<Opportunity>{ new Opportunity(Name = 'Closed') });
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), null);
        record.setRelated(new Map<String, TriggerTypes.RelatedRecords>{ 'openOpportunities' => openOpportunities, 'closedOpportunities' => closedOpportunities });

        // Test
        TriggerTypes.RelatedRecords result = record.getRelated('openOpportunities');

        // Verify
        Assert.areEqual(openOpportunities, result, 'The related records should be returned.');
    }

    @IsTest
    static void getRelatedWhenNameIsUnknown() {
        // Setup
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), null);
        record.setRelated(new Map<String, TriggerTypes.RelatedRecords>{ 'openOpportunities' => new TriggerTypes.ProvidedRecords(new List<Opportunity>()) });
        Exception expectedException = null;

        // Test
        try {
            record.getRelated('missing');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'No related records provider named missing is declared. Return it from the queryRelatedOn method of the handler first.',
            expectedException.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void getRelatedWhenNoProvidersAreSet() {
        // Setup
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), null);
        Exception expectedException = null;

        // Test
        try {
            record.getRelated('openOpportunities');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'No related records provider named openOpportunities is declared. Return it from the queryRelatedOn method of the handler first.',
            expectedException.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void setRelatedWhenAlreadySet() {
        // Setup
        TriggerTypes.ProvidedRecords related = new TriggerTypes.ProvidedRecords(new List<Opportunity>());
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'New'), null);
        record.setRelated(new Map<String, TriggerTypes.RelatedRecords>{ 'first' => related });
        record.setRelated(new Map<String, TriggerTypes.RelatedRecords>{ 'second' => related });
        Exception expectedException = null;

        // Test
        try {
            record.getRelated('first');
        } catch (Exception e) {
            expectedException = e;
        }

        // Verify
        Assert.areEqual(
            'No related records provider named first is declared. Return it from the queryRelatedOn method of the handler first.',
            expectedException.getMessage(),
            'The exception message should match the expected one.'
        );
    }

    @IsTest
    static void updateRecordsGetIdsWhenRecordHasNoId() {
        // Setup
        Id contactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(Id = contactId, LastName = 'Saved'), new Contact(Id = contactId, LastName = 'Old')),
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'Unsaved'), null)
            }
        );

        // Test
        Set<Id> ids = records.getIds();

        // Verify
        Assert.areEqual(new Set<Id>{ contactId }, ids, 'The record without an Id should be skipped.');
    }

    @IsTest
    static void updateRecordsSizeWhenRecordHasNoId() {
        // Setup
        Id contactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(Id = contactId, LastName = 'Saved'), new Contact(Id = contactId, LastName = 'Old')),
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'Unsaved'), null)
            }
        );

        // Test
        Integer result = records.size();

        // Verify
        Assert.areEqual(2, result, 'The size should include every record.');
    }

    @IsTest
    static void updateRecordsGetIdsOf() {
        // Setup
        Id oldAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id newAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = newAccountId), new Contact(LastName = 'A', AccountId = oldAccountId))
            }
        );

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ newAccountId }, ids, 'The new Ids should be returned.');
    }

    @IsTest
    static void updateRecordsGetIdsOfWhenValueIsNull() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), new Contact(LastName = 'A', AccountId = accountId)),
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'B'), new Contact(LastName = 'B'))
            }
        );

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ accountId }, ids, 'The null value should be skipped.');
    }

    @IsTest
    static void updateRecordsGetOldIdsOf() {
        // Setup
        Id oldAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id newAccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = newAccountId), new Contact(LastName = 'A', AccountId = oldAccountId))
            }
        );

        // Test
        Set<Id> oldIds = records.getOldIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ oldAccountId }, oldIds, 'The old Ids should be returned.');
    }

    @IsTest
    static void updateRecordsGetOldValuesOf() {
        // Setup
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{ new TriggerTypes.TriggerRecord(new Contact(LastName = 'Current'), new Contact(LastName = 'Previous')) }
        );

        // Test
        Set<String> oldValues = records.getOldValuesOf(Contact.LastName);

        // Verify
        Assert.areEqual(new Set<String>{ 'Previous' }, oldValues, 'The old values should be returned.');
    }

    @IsTest
    static void deleteRecordsGetIdsOf() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.DeleteRecords records = new TriggerTypes.DeleteTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{ new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'Gone', AccountId = accountId)) }
        );

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ accountId }, ids, 'The old Ids should be returned.');
    }

    @IsTest
    static void undeleteRecordsGetValuesOfWithNumberField() {
        // Setup
        TriggerTypes.UndeleteRecords records = new TriggerTypes.UndeleteTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{ new TriggerTypes.TriggerRecord(new Opportunity(Name = 'One', Amount = 100), null) }
        );

        // Test
        Set<String> amounts = records.getValuesOf(Opportunity.Amount);

        // Verify
        Assert.areEqual(new Set<String>{ '100' }, amounts, 'The value should be returned as text.');
    }

    @IsTest
    static void undeleteRecordsGetValuesOfWhenValueIsNull() {
        // Setup
        TriggerTypes.UndeleteRecords records = new TriggerTypes.UndeleteTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', Title = 'Manager'), null),
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'B'), null)
            }
        );

        // Test
        Set<String> titles = records.getValuesOf(Contact.Title);

        // Verify
        Assert.areEqual(new Set<String>{ 'Manager' }, titles, 'The null value should be skipped.');
    }

    @IsTest
    static void insertRecordsGetIdsOfWithRelationship() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id ownerId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType);
        TriggerTypes.TriggerRecord enriched = new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), null);
        enriched.setNewParent('Account', new Account(Id = accountId, OwnerId = ownerId));
        TriggerTypes.InsertRecords records = new TriggerTypes.InsertTriggerRecords(new List<TriggerTypes.TriggerRecord>{ enriched });

        // Test
        Set<Id> ownerIds = records.getIdsOf('Account', Account.OwnerId);

        // Verify
        Assert.areEqual(new Set<Id>{ ownerId }, ownerIds, 'The parent Ids should be returned.');
    }

    @IsTest
    static void updateRecordsGetValuesOfWithDottedRelationship() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Account parentAccount = new Account(Id = accountId, Name = 'Child Corp');
        parentAccount.putSObject('Parent', new Account(Name = 'Holding Corp'));
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), new Contact(LastName = 'A', AccountId = accountId));
        record.setNewParent('Account', parentAccount);
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(new List<TriggerTypes.TriggerRecord>{ record });

        // Test
        Set<String> names = records.getValuesOf('Account.Parent', Account.Name);

        // Verify
        Assert.areEqual(new Set<String>{ 'Holding Corp' }, names, 'The grandparent values should be returned.');
    }

    @IsTest
    static void updateRecordsGetOldValuesOfWithRelationship() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), new Contact(LastName = 'A', AccountId = accountId));
        record.setNewParent('Account', new Account(Id = accountId, Name = 'Current'));
        record.setOldParent('Account', new Account(Id = accountId, Name = 'Previous'));
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(new List<TriggerTypes.TriggerRecord>{ record });

        // Test
        Set<String> oldNames = records.getOldValuesOf('Account', Account.Name);

        // Verify
        Assert.areEqual(new Set<String>{ 'Previous' }, oldNames, 'The old parent values should be returned.');
    }

    @IsTest
    static void updateRecordsGetOldIdsOfWithRelationship() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        Id currentOwnerId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType);
        Id previousOwnerId = new TriggerTypes.RandomIdGenerator().get(User.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), new Contact(LastName = 'A', AccountId = accountId));
        record.setNewParent('Account', new Account(Id = accountId, OwnerId = currentOwnerId));
        record.setOldParent('Account', new Account(Id = accountId, OwnerId = previousOwnerId));
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(new List<TriggerTypes.TriggerRecord>{ record });

        // Test
        Set<Id> oldOwnerIds = records.getOldIdsOf('Account', Account.OwnerId);

        // Verify
        Assert.areEqual(new Set<Id>{ previousOwnerId }, oldOwnerIds, 'The old parent Ids should be returned.');
    }

    @IsTest
    static void deleteRecordsGetValuesOfWithRelationship() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.TriggerRecord record = new TriggerTypes.TriggerRecord(null, new Contact(LastName = 'A', AccountId = accountId));
        record.setOldParent('Account', new Account(Id = accountId, Name = 'Previous'));
        TriggerTypes.DeleteRecords records = new TriggerTypes.DeleteTriggerRecords(new List<TriggerTypes.TriggerRecord>{ record });

        // Test
        Set<String> names = records.getValuesOf('Account', Account.Name);

        // Verify
        Assert.areEqual(new Set<String>{ 'Previous' }, names, 'The old parent values should be returned.');
    }

    @IsTest
    static void insertRecordsGetIdsOfWhenRelationshipIsNotEnriched() {
        // Setup
        TriggerTypes.InsertRecords records = new TriggerTypes.InsertTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{
                new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType)), null)
            }
        );

        // Test
        Set<Id> ids = records.getIdsOf('Account', Account.OwnerId);

        // Verify
        Assert.areEqual(new Set<Id>(), ids, 'No Ids should be returned.');
    }

    @IsTest
    static void insertRecordsGetIdsOfWhenPreviousResultIsCleared() {
        // Setup
        Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
        TriggerTypes.InsertRecords records = new TriggerTypes.InsertTriggerRecords(
            new List<TriggerTypes.TriggerRecord>{ new TriggerTypes.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), null) }
        );
        records.getIdsOf(Contact.AccountId).clear();

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ accountId }, ids, 'A new set should be returned.');
    }

    @IsTest
    static void insertRecordsGetRecords() {
        // Setup
        TriggerTypes.TriggerRecord firstRecord = new TriggerTypes.TriggerRecord(new Contact(LastName = 'A'), null);
        TriggerTypes.TriggerRecord secondRecord = new TriggerTypes.TriggerRecord(new Contact(LastName = 'B'), null);
        TriggerTypes.InsertRecords records = new TriggerTypes.InsertTriggerRecords(new List<TriggerTypes.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerTypes.InsertRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerTypes.InsertRecord>{ firstRecord, secondRecord }, result, 'The records should be returned in trigger order.');
    }

    @IsTest
    static void updateRecordsGetRecords() {
        // Setup
        Id firstContactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        Id secondContactId = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType);
        TriggerTypes.TriggerRecord firstRecord = new TriggerTypes.TriggerRecord(new Contact(Id = firstContactId, LastName = 'A'), new Contact(Id = firstContactId, LastName = 'A'));
        TriggerTypes.TriggerRecord secondRecord = new TriggerTypes.TriggerRecord(
            new Contact(Id = secondContactId, LastName = 'B'),
            new Contact(Id = secondContactId, LastName = 'B')
        );
        TriggerTypes.UpdateRecords records = new TriggerTypes.UpdateTriggerRecords(new List<TriggerTypes.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerTypes.UpdateRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerTypes.UpdateRecord>{ firstRecord, secondRecord }, result, 'The records should be returned in trigger order.');
    }

    @IsTest
    static void deleteRecordsGetRecords() {
        // Setup
        TriggerTypes.TriggerRecord firstRecord = new TriggerTypes.TriggerRecord(
            null,
            new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'A')
        );
        TriggerTypes.TriggerRecord secondRecord = new TriggerTypes.TriggerRecord(
            null,
            new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'B')
        );
        TriggerTypes.DeleteRecords records = new TriggerTypes.DeleteTriggerRecords(new List<TriggerTypes.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerTypes.DeleteRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerTypes.DeleteRecord>{ firstRecord, secondRecord }, result, 'The records should be returned in trigger order.');
    }

    @IsTest
    static void undeleteRecordsGetRecords() {
        // Setup
        TriggerTypes.TriggerRecord firstRecord = new TriggerTypes.TriggerRecord(
            new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'A'),
            null
        );
        TriggerTypes.TriggerRecord secondRecord = new TriggerTypes.TriggerRecord(
            new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType), LastName = 'B'),
            null
        );
        TriggerTypes.UndeleteRecords records = new TriggerTypes.UndeleteTriggerRecords(new List<TriggerTypes.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerTypes.UndeleteRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerTypes.UndeleteRecord>{ firstRecord, secondRecord }, result, 'The records should be returned in trigger order.');
    }

    @IsTest
    static void toTriggerRecords() {
        // Setup
        List<Contact> newContacts = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        List<Contact> oldContacts = new List<Contact>{ new Contact(LastName = 'First Before'), new Contact(LastName = 'Second Before') };

        // Test
        List<TriggerTypes.TriggerRecord> records = TriggerTypes.toTriggerRecords(newContacts, oldContacts);

        // Verify
        Assert.isTrue(records[1].isChangedFromTo(Contact.LastName, 'Second Before', 'Second'), 'The new and old records should be paired by position.');
    }
}
