/**
 * @description Tests for the TriggerHandler class.
 * Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
 * Licensed under the MIT License (https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE)
 *
 * v0.0.1
 *
 * PMD False Positives:
 * - CyclomaticComplexity: It is a library and we tried to put everything into ONE test class
 * - CognitiveComplexity: It is a library and we tried to put everything into ONE test class
 * - NcssTypeCount: It is a library and we tried to put everything into ONE test class
 * - ApexUnitTestClassShouldHaveRunAs: The lib does not branch on the running user, so running as one proves nothing
 **/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount,PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest(IsParallel=true)
private class TriggerHandlerTest {
    @IsTest
    static void isChangedWhenValueDiffers() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChanged(Contact.LastName);

        // Verify
        Assert.isTrue(result, 'It should be changed, because the new value differs from the old one.');
    }

    @IsTest
    static void isChangedWhenValueIsTheSame() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Same'), new Contact(LastName = 'Same'));

        // Test
        Boolean result = record.isChanged(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'It should not be changed, because the new and old values compare equal.');
    }

    @IsTest
    static void isChangedWhenValueWasSetFromNull() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChanged(Contact.Title);

        // Verify
        Assert.isTrue(result, 'It should be changed, because null takes part in the comparison and differs from a populated value.');
    }

    @IsTest
    static void isChangedWhenValueWasClearedToNull() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = null), new Contact(LastName = 'New', Title = 'Manager'));

        // Test
        Boolean result = record.isChanged(Contact.Title);

        // Verify
        Assert.isTrue(result, 'It should be changed, because a populated old value differs from a null new value in the same comparison.');
    }

    @IsTest
    static void isChangedWhenBothValuesAreNull() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = null), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChanged(Contact.Title);

        // Verify
        Assert.isFalse(result, 'It should not be changed, because null equals null, so the comparison finds no difference.');
    }

    @IsTest
    static void isChangedWhenBooleanWasFlipped() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', DoNotCall = true), new Contact(LastName = 'New', DoNotCall = false));

        // Test
        Boolean result = record.isChanged(Contact.DoNotCall);

        // Verify
        Assert.isTrue(result, 'It should be changed, because true and false are different values to the Object comparison.');
    }

    @IsTest
    static void isChangedWhenNumberDiffers() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Account(Name = 'Test', NumberOfEmployees = 10),
            new Account(Name = 'Test', NumberOfEmployees = 5)
        );

        // Test
        Boolean result = record.isChanged(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be changed, because the Object comparison compares the numeric values themselves.');
    }

    @IsTest
    static void isChangedWhenDateDiffers() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', Birthdate = Date.newInstance(2026, 1, 1)),
            new Contact(LastName = 'New', Birthdate = Date.newInstance(2025, 1, 1))
        );

        // Test
        Boolean result = record.isChanged(Contact.Birthdate);

        // Verify
        Assert.isTrue(result, 'It should be changed, because the Object comparison compares the date values themselves.');
    }

    @IsTest
    static void isChangedToWhenNewValueMatchesAndOldDiffers() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedTo(Contact.LastName, 'New');

        // Verify
        Assert.isTrue(result, 'It should be changed to the given value, because the new value equals it while the old value does not.');
    }

    @IsTest
    static void isChangedToWhenNewValueDoesNotMatch() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Other'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedTo(Contact.LastName, 'New');

        // Verify
        Assert.isFalse(result, 'It should not be changed to the given value, because the new value does not equal it and both halves of the rule must hold.');
    }

    @IsTest
    static void isChangedToWhenOldValueAlreadyMatched() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'New'));

        // Test
        Boolean result = record.isChangedTo(Contact.LastName, 'New');

        // Verify
        Assert.isFalse(result, 'It should not be changed to the given value, because the old value already equalled it, so no transition into that value happened.');
    }

    @IsTest
    static void isChangedToWhenValueWasSetFromNull() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChangedTo(Contact.Title, 'Manager');

        // Verify
        Assert.isTrue(result, 'It should be changed to the given value, because a null old value does not equal it while the new value does.');
    }

    @IsTest
    static void isChangedToNullWhenValueWasCleared() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = null), new Contact(LastName = 'New', Title = 'Manager'));

        // Test
        Boolean result = record.isChangedTo(Contact.Title, null);

        // Verify
        Assert.isTrue(result, 'It should be changed to null, because null is compared like any other target value on both sides.');
    }

    @IsTest
    static void isChangedFromWhenOldValueMatchesAndNewDiffers() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFrom(Contact.LastName, 'Old');

        // Verify
        Assert.isTrue(result, 'It should be changed from the given value, because the old value equals it while the new value does not.');
    }

    @IsTest
    static void isChangedFromWhenOldValueDoesNotMatch() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Other'));

        // Test
        Boolean result = record.isChangedFrom(Contact.LastName, 'Old');

        // Verify
        Assert.isFalse(result, 'It should not be changed from the given value, because the old value never equalled it and both halves of the rule must hold.');
    }

    @IsTest
    static void isChangedFromWhenNewValueStillMatches() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Old'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFrom(Contact.LastName, 'Old');

        // Verify
        Assert.isFalse(result, 'It should not be changed from the given value, because the new value still equals it, so nothing moved away from it.');
    }

    @IsTest
    static void isChangedFromNullWhenValueWasSet() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChangedFrom(Contact.Title, null);

        // Verify
        Assert.isTrue(result, 'It should be changed from null, because null is compared like any other prior value and the new value differs from it.');
    }

    @IsTest
    static void isChangedFromToWhenBothValuesMatch() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Old', 'New');

        // Verify
        Assert.isTrue(result, 'It should be reported as a from-to match, because the old value equals the from value and the new value equals the to value.');
    }

    @IsTest
    static void isChangedFromToWhenOldValueDoesNotMatch() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Other'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Old', 'New');

        // Verify
        Assert.isFalse(result, 'It should not be reported as a from-to match, because the old value does not equal the from value and both sides must match.');
    }

    @IsTest
    static void isChangedFromToWhenNewValueDoesNotMatch() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Other'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Old', 'New');

        // Verify
        Assert.isFalse(result, 'It should not be reported as a from-to match, because the new value does not equal the to value and both sides must match.');
    }

    @IsTest
    static void isChangedFromToWhenFromAndToAreTheSame() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Same'), new Contact(LastName = 'Same'));

        // Test
        Boolean result = record.isChangedFromTo(Contact.LastName, 'Same', 'Same');

        // Verify
        Assert.isTrue(result, 'It should be reported as a from-to match, because each side is only compared to the given value and no actual change is required.');
    }

    @IsTest
    static void isChangedFromToWhenValueWasSetFromNull() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Manager'), new Contact(LastName = 'New', Title = null));

        // Test
        Boolean result = record.isChangedFromTo(Contact.Title, null, 'Manager');

        // Verify
        Assert.isTrue(result, 'It should be reported as a from-to match, because null is accepted as the from value and compared like any other value.');
    }

    @IsTest
    static void isAnyChangedWithTwoFieldsWhenOneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Same', FirstName = 'New'), new Contact(LastName = 'Same', FirstName = 'Old'));

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isTrue(result, 'It should be reported as changed, because the scan stops as soon as one field differs.');
    }

    @IsTest
    static void isAnyChangedWithTwoFieldsWhenNoneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same'),
            new Contact(LastName = 'Same', FirstName = 'Same')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isFalse(result, 'It should not be reported as changed, because the scan covers both fields without finding a difference.');
    }

    @IsTest
    static void isAnyChangedWithThreeFieldsWhenOneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'old@a.co')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isTrue(result, 'It should be reported as changed, because the third field differs and a single differing field is enough.');
    }

    @IsTest
    static void isAnyChangedWithThreeFieldsWhenNoneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isFalse(result, 'It should not be reported as changed, because all three fields compare equal on both sides.');
    }

    @IsTest
    static void isAnyChangedWithFourFieldsWhenOneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'New'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Old')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isTrue(result, 'It should be reported as changed, because the fourth field differs and a single differing field is enough.');
    }

    @IsTest
    static void isAnyChangedWithFourFieldsWhenNoneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isFalse(result, 'It should not be reported as changed, because all four fields compare equal on both sides.');
    }

    @IsTest
    static void isAnyChangedWithFiveFieldsWhenLastChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'New'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'Old')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be reported as changed, because the overload forwards all five fields to the same scan, which reaches the differing last one.');
    }

    @IsTest
    static void isAnyChangedWithFiveFieldsWhenNoneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'Same'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co', Title = 'Same', Description = 'Same')
        );

        // Test
        Boolean result = record.isAnyChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should not be reported as changed, because none of the five fields differs between the old and new values.');
    }

    @IsTest
    static void isAnyChangedWithIterableWhenOneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'old@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.isAnyChanged(fields);

        // Verify
        Assert.isTrue(result, 'It should be reported as changed, because the iterable overload runs the same scan and finds one differing field.');
    }

    @IsTest
    static void isAnyChangedWithIterableWhenNoneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co'),
            new Contact(LastName = 'Same', FirstName = 'Same', Email = 'same@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.isAnyChanged(fields);

        // Verify
        Assert.isFalse(result, 'It should not be reported as changed, because the scan walks every listed field and none differs.');
    }

    @IsTest
    static void isAnyChangedWithEmptyIterable() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));
        Iterable<SObjectField> fields = new List<SObjectField>();

        // Test
        Boolean result = record.isAnyChanged(fields);

        // Verify
        Assert.isFalse(result, 'It should not be reported as changed, because an empty list gives the scan no field to satisfy, so it falls through to false.');
    }

    @IsTest
    static void areAllChangedWithTwoFieldsWhenBothChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isTrue(result, 'It should be reported as fully changed, because every field in the list differs between the old and new values.');
    }

    @IsTest
    static void areAllChangedWithTwoFieldsWhenOnlyOneChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'Same'),
            new Contact(LastName = 'OldLast', FirstName = 'Same')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName);

        // Verify
        Assert.isFalse(result, 'It should not be reported as fully changed, because the scan fails at the first field that compares equal.');
    }

    @IsTest
    static void areAllChangedWithThreeFieldsWhenAllChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isTrue(result, 'It should be reported as fully changed, because all three fields differ and none compares equal.');
    }

    @IsTest
    static void areAllChangedWithThreeFieldsWhenOneDidNotChange() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'Same', Email = 'old@a.co')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isFalse(result, 'It should not be reported as fully changed, because a single equal field is enough to fail the all-changed rule.');
    }

    @IsTest
    static void areAllChangedWithFourFieldsWhenAllChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'NewTitle'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'OldTitle')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isTrue(result, 'It should be reported as fully changed, because all four fields differ between the old and new values.');
    }

    @IsTest
    static void areAllChangedWithFourFieldsWhenOneDidNotChange() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'Same'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'Same')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title);

        // Verify
        Assert.isFalse(result, 'It should not be reported as fully changed, because the equal fourth field fails the all-changed rule.');
    }

    @IsTest
    static void areAllChangedWithFiveFieldsWhenAllChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'NewTitle', Description = 'NewDescription'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'OldTitle', Description = 'OldDescription')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be reported as fully changed, because the overload forwards all five fields to the same scan and each one differs.');
    }

    @IsTest
    static void areAllChangedWithFiveFieldsWhenLastDidNotChange() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co', Title = 'NewTitle', Description = 'Same'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co', Title = 'OldTitle', Description = 'Same')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email, Contact.Title, Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should not be reported as fully changed, because the scan reaches the equal last field and fails there.');
    }

    @IsTest
    static void areAllChangedWithIterableWhenAllChanged() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'old@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.areAllChanged(fields);

        // Verify
        Assert.isTrue(result, 'It should be reported as fully changed, because the iterable overload runs the same scan and every listed field differs.');
    }

    @IsTest
    static void areAllChangedWithIterableWhenOneDidNotChange() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'Same', Email = 'new@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'Same', Email = 'old@a.co')
        );
        Iterable<SObjectField> fields = new List<SObjectField>{ Contact.LastName, Contact.FirstName, Contact.Email };

        // Test
        Boolean result = record.areAllChanged(fields);

        // Verify
        Assert.isFalse(result, 'It should not be reported as fully changed, because one equal field in the list fails the all-changed rule.');
    }

    @IsTest
    static void areAllChangedWithEmptyIterable() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));
        Iterable<SObjectField> fields = new List<SObjectField>();

        // Test
        Boolean result = record.areAllChanged(fields);

        // Verify
        Assert.isTrue(result, 'It should be reported as fully changed, because an empty list gives the scan no equal field to fail on, so it falls through to true.');
    }

    @IsTest
    static void isNullWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be null, because a field that was never assigned has no value on the record.');
    }

    @IsTest
    static void isNullWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should not be null, because the null check tests only for the absence of a value and an empty string is a value.');
    }

    @IsTest
    static void isNullWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should not be null, because the null check does not trim, so a whitespace only string still counts as a value.');
    }
    @IsTest
    static void isNullWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because the raw field value is compared against null and an assigned value is never null.');
    }

    @IsTest
    static void isNullWhenNumberFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'));

        // Test
        Boolean result = record.isNull(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be true, because a numeric field that was never assigned holds no value at all, not a zero.');
    }

    @IsTest
    static void isNullWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0));

        // Test
        Boolean result = record.isNull(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because zero is an assigned value and only an unassigned field reads back as null.');
    }

    @IsTest
    static void isNullWhenBooleanFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isNull(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because false is an assigned value and only an unassigned field reads back as null.');
    }

    @IsTest
    static void isNullWhenNewValueIsNullAndOldValueIsPopulated() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), new Contact(LastName = 'Doe', Description = 'Old'));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the null check reads the new record and the old record is consulted only by the change helpers.');
    }

    @IsTest
    static void isNullOnDeleteRecordReadsOldRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because the delete shape has no new record, so the value falls back to the old one.');
    }

    @IsTest
    static void isNullOnUndeleteRecordReadsNewRecord() {
        TriggerHandler.UndeleteRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Restored'), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because the undelete shape carries only a new record and the value is read from it.');
    }

    @IsTest
    static void isNotNullWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because this check is the plain negation of the null check and an unassigned field is null.');
    }

    @IsTest
    static void isNotNullWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the null check asks only whether a value was assigned, and an empty string is an assigned value.');
    }

    @IsTest
    static void isNotNullWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '));

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because whitespace is an assigned value and the null check never trims.');
    }

    @IsTest
    static void isNotNullWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'));

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because an assigned value makes the negated null check true.');
    }

    @IsTest
    static void isNotNullWhenNumberFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'));

        // Test
        Boolean result = record.isNotNull(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because a numeric field that was never assigned is null and the negation follows that.');
    }

    @IsTest
    static void isNotNullWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0));

        // Test
        Boolean result = record.isNotNull(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be true, because zero is an assigned value and numeric emptiness is never treated as null.');
    }

    @IsTest
    static void isNotNullOnDeleteRecordReadsOldRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the delete shape has no new record, so the value falls back to the old one.');
    }

    @IsTest
    static void isEmptyWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the emptiness check short-circuits on null before it ever inspects text.');
    }

    @IsTest
    static void isEmptyWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a string of zero length is empty once the null short-circuit passes.');
    }

    @IsTest
    static void isEmptyWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because emptiness is measured by length without trimming, so spaces count as content.');
    }

    @IsTest
    static void isEmptyWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a value of non-zero length is not empty.');
    }

    @IsTest
    static void isEmptyWhenNumberFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'));

        // Test
        Boolean result = record.isEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be true, because the null short-circuit answers first and the string conversion is never reached.');
    }

    @IsTest
    static void isEmptyWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0));

        // Test
        Boolean result = record.isEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because a non-null number is converted to text first, and zero converts to a string with length.');
    }

    @IsTest
    static void isEmptyWhenCurrencyFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', AnnualRevenue = 0));

        // Test
        Boolean result = record.isEmpty(Account.AnnualRevenue);

        // Verify
        Assert.isFalse(result, 'It should be false, because a zero currency amount converts to text with length rather than to nothing.');
    }

    @IsTest
    static void isEmptyWhenBooleanFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isEmpty(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a Boolean is converted to the text false, which has length.');
    }

    @IsTest
    static void isEmptyWhenDateFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Birthdate = Date.newInstance(2024, 1, 1)));

        // Test
        Boolean result = record.isEmpty(Contact.Birthdate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a populated date converts to text with length.');
    }

    @IsTest
    static void isEmptyWhenNewValueIsEmptyAndOldValueIsPopulated() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), new Contact(LastName = 'Doe', Description = 'Old'));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the emptiness check reads the new record and ignores what the old record still holds.');
    }

    @IsTest
    static void isEmptyOnDeleteRecordReadsOldRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because the delete shape has no new record, so the value falls back to the old one.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because this check negates one that short-circuits to empty on null.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a string of zero length counts as empty and the negation follows that.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '));

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because emptiness is measured without trimming, so spaces count as content.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'));

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a value of non-zero length is not empty.');
    }

    @IsTest
    static void isNotEmptyWhenNumberFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'));

        // Test
        Boolean result = record.isNotEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null short-circuit makes an unassigned field empty and the negation follows that.');
    }

    @IsTest
    static void isNotEmptyWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0));

        // Test
        Boolean result = record.isNotEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be true, because zero converts to text with length, and only null or a zero length string is empty.');
    }

    @IsTest
    static void isNotEmptyOnDeleteRecordReadsOldRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the delete shape has no new record, so the value falls back to the old one.');
    }

    @IsTest
    static void isBlankWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the blank check short-circuits on null before it ever inspects text.');
    }

    @IsTest
    static void isBlankWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a string of zero length has no non-whitespace content left after trimming.');
    }

    @IsTest
    static void isBlankWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the blank check trims the value first, unlike the emptiness check.');
    }

    @IsTest
    static void isBlankWhenFieldIsTabAndNewLine() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '\t\n'));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because tabs and new lines are whitespace to the blank check, not content.');
    }

    @IsTest
    static void isBlankWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because text that survives trimming is not blank.');
    }

    @IsTest
    static void isBlankWhenFieldHasSurroundingWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   Populated   '));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because trimming removes only the surrounding spaces and leaves real content behind.');
    }

    @IsTest
    static void isBlankWhenNumberFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'));

        // Test
        Boolean result = record.isBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be true, because a field with no value is blank before any text conversion happens.');
    }

    @IsTest
    static void isBlankWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0));

        // Test
        Boolean result = record.isBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because a non-null number is converted to text first, and zero survives trimming.');
    }

    @IsTest
    static void isBlankWhenCurrencyFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', AnnualRevenue = 0));

        // Test
        Boolean result = record.isBlank(Account.AnnualRevenue);

        // Verify
        Assert.isFalse(result, 'It should be false, because a zero currency amount converts to text that is not whitespace.');
    }

    @IsTest
    static void isBlankWhenBooleanFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isBlank(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a Boolean is converted to the text false, which is not whitespace.');
    }

    @IsTest
    static void isBlankWhenDateFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Birthdate = Date.newInstance(2024, 1, 1)));

        // Test
        Boolean result = record.isBlank(Contact.Birthdate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a populated date converts to text that is not whitespace.');
    }

    @IsTest
    static void isBlankWhenNewValueIsWhitespaceAndOldValueIsPopulated() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Doe', Description = '   '),
            new Contact(LastName = 'Doe', Description = 'Old')
        );

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the blank check reads the new record and ignores what the old record still holds.');
    }

    @IsTest
    static void isBlankWhenNewValueIsPopulatedAndOldValueIsBlank() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'Populated'),
            new Contact(LastName = 'Doe', Description = '   ')
        );

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because only the new record decides blankness and the old value takes no part in it.');
    }

    @IsTest
    static void isBlankOnDeleteRecordReadsOldRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because the delete shape has no new record, so the value falls back to the old one.');
    }

    @IsTest
    static void isBlankOnUndeleteRecordReadsNewRecord() {
        TriggerHandler.UndeleteRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the undelete shape carries only a new record and its whitespace value is trimmed away.');
    }
    @IsTest
    static void isNotBlankWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field value short-circuits the blank check to true before any text is inspected.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because an empty string counts as blank for the underlying blank check.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '));

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a string of only whitespace counts as blank for the underlying blank check.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'));

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a non null value with printable characters fails the blank check and the result is negated.');
    }

    @IsTest
    static void isNotBlankWhenNumberFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'));

        // Test
        Boolean result = record.isNotBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because a number field that was never assigned is null, and the null short-circuit reports it as blank.');
    }

    @IsTest
    static void isNotBlankWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0));

        // Test
        Boolean result = record.isNotBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isTrue(result, 'It should be true, because zero is a real value whose text form 0 is not blank, so the numeric zero is never mistaken for an absent value.');
    }

    @IsTest
    static void isNotBlankOnDeleteRecordReadsOldRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Deleted'));

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the new side falls back to the old record when there is no new record, which is the delete shape.');
    }

    @IsTest
    static void equalsWhenValueMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Doe');

        // Verify
        Assert.isTrue(result, 'It should be true, because the new side value and the expected value are the same under Apex Object equality.');
    }

    @IsTest
    static void equalsWhenValueDoesNotMatch() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Smith');

        // Verify
        Assert.isFalse(result, 'It should be false, because Apex Object equality reports two different text values as unequal.');
    }

    @IsTest
    static void equalsIsCaseInsensitiveForText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'DOE');

        // Verify
        Assert.isTrue(result, 'It should be true, because Apex Object equality on String values ignores letter case.');
    }

    @IsTest
    static void equalsWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.equals(Contact.Description, 'Anything');

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field value is never equal to a non null expected value.');
    }

    @IsTest
    static void equalsWhenExpectedValueIsNullAndFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isTrue(result, 'It should be true, because null is compared as a value here, so null matches a null expected value instead of short-circuiting to false.');
    }

    @IsTest
    static void equalsWhenExpectedValueIsNullAndFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Note'));

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'It should be false, because a populated field value is never equal to a null expected value.');
    }

    @IsTest
    static void equalsWhenFieldIsEmptyText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.equals(Contact.Description, '');

        // Verify
        Assert.isTrue(result, 'It should be true, because an empty string is kept as an empty string and matches an empty expected value.');
    }

    @IsTest
    static void equalsWhenFieldIsEmptyTextAndExpectedValueIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'It should be false, because an empty string is a value in its own right and is never coerced to null.');
    }

    @IsTest
    static void equalsWhenBooleanFieldMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.equals(Opportunity.IsPrivate, true);

        // Verify
        Assert.isTrue(result, 'It should be true, because Apex Object equality compares boxed Boolean values by content.');
    }

    @IsTest
    static void equalsWhenNumberFieldMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 1500));

        // Test
        Boolean result = record.equals(Account.NumberOfEmployees, 1500);

        // Verify
        Assert.isTrue(result, 'It should be true, because Apex Object equality compares boxed numeric values by content.');
    }

    @IsTest
    static void equalsWhenDateFieldMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Birthdate = Date.newInstance(2026, 1, 1)));

        // Test
        Boolean result = record.equals(Contact.Birthdate, Date.newInstance(2026, 1, 1));

        // Verify
        Assert.isTrue(result, 'It should be true, because Apex Object equality compares Date values by the day they represent, not by instance.');
    }

    @IsTest
    static void equalsWhenLookupFieldMatches() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', AccountId = accountId));

        // Test
        Boolean result = record.equals(Contact.AccountId, accountId);

        // Verify
        Assert.isTrue(result, 'It should be true, because Apex Object equality compares Id values by the key they hold, not by reference.');
    }

    @IsTest
    static void equalsOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'New');

        // Verify
        Assert.isTrue(result, 'It should be true, because value comparisons read the new side of the record whenever a new record is present.');
    }

    @IsTest
    static void equalsOnUpdateIgnoresOldValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Old');

        // Verify
        Assert.isFalse(result, 'It should be false, because a plain value comparison never reaches the old record, which is reserved for change checks.');
    }

    @IsTest
    static void equalsOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Deleted'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Deleted');

        // Verify
        Assert.isTrue(result, 'It should be true, because the new side falls back to the old record when there is no new record, which is the delete shape.');
    }

    @IsTest
    static void equalsOnUndeleteReadsRestoredValue() {
        TriggerHandler.UndeleteRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Restored'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Restored');

        // Verify
        Assert.isTrue(result, 'It should be true, because an undelete carries only a new record, and that restored record is the one compared.');
    }

    @IsTest
    static void doesNotEqualWhenValueDiffers() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Smith');

        // Verify
        Assert.isTrue(result, 'It should be true, because the comparison is the negation of Object equality, and the two text values are not equal.');
    }

    @IsTest
    static void doesNotEqualWhenValueMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Doe');

        // Verify
        Assert.isFalse(result, 'It should be false, because the negated equality check rejects a value that matches the stored one.');
    }

    @IsTest
    static void doesNotEqualIsCaseInsensitiveForText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'DOE');

        // Verify
        Assert.isFalse(result, 'It should be false, because Apex Object equality on String values ignores letter case, so its negation is false.');
    }

    @IsTest
    static void doesNotEqualWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, 'Anything');

        // Verify
        Assert.isTrue(result, 'It should be true, because a null field value is never equal to a non null expected value, so the negation holds.');
    }

    @IsTest
    static void doesNotEqualWhenExpectedValueIsNullAndFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'It should be false, because null matches a null expected value, so the negation of that match is false.');
    }

    @IsTest
    static void doesNotEqualWhenExpectedValueIsNullAndFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Note'));

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, null);

        // Verify
        Assert.isTrue(result, 'It should be true, because a populated field value is never equal to a null expected value, so the negation holds.');
    }

    @IsTest
    static void doesNotEqualOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Old');

        // Verify
        Assert.isTrue(result, 'It should be true, because the negated comparison reads the new side, where the old value no longer stands.');
    }

    @IsTest
    static void doesNotEqualOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Deleted'));

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Deleted');

        // Verify
        Assert.isFalse(result, 'It should be false, because the new side falls back to the old record in the delete shape, so the deleted value still matches.');
    }

    @IsTest
    static void containsWhenValueIsPresent() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because the value is not null and its text form holds the searched fragment.');
    }

    @IsTest
    static void containsWhenValueIsAbsent() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.contains(Contact.Description, 'Goodbye');

        // Verify
        Assert.isFalse(result, 'It should be false, because the text form of the value does not hold the searched fragment.');
    }

    @IsTest
    static void containsWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because the search is guarded by a not null check, so a null value can never hold a fragment.');
    }

    @IsTest
    static void containsIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.contains(Contact.Description, 'world');

        // Verify
        Assert.isFalse(result, 'It should be false, because the underlying text search compares characters with case respected.');
    }

    @IsTest
    static void containsWhenValueIsTheWholeFieldValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.contains(Contact.Description, 'Hello World');

        // Verify
        Assert.isTrue(result, 'It should be true, because a text value holds itself as a fragment in full.');
    }

    @IsTest
    static void containsWhenFieldIsEmptyText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because an empty string passes the not null guard but carries no characters that could hold the fragment.');
    }

    @IsTest
    static void containsOnNumberFieldUsesTextValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 1500));

        // Test
        Boolean result = record.contains(Account.NumberOfEmployees, '50');

        // Verify
        Assert.isTrue(result, 'It should be true, because a non text value is converted to its text form before the fragment search.');
    }

    @IsTest
    static void containsOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'New note'),
            new Contact(LastName = 'Doe', Description = 'Old note')
        );

        // Test
        Boolean result = record.contains(Contact.Description, 'New');

        // Verify
        Assert.isTrue(result, 'It should be true, because the fragment search reads the new side whenever a new record is present.');
    }

    @IsTest
    static void containsOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Old note'));

        // Test
        Boolean result = record.contains(Contact.Description, 'Old');

        // Verify
        Assert.isTrue(result, 'It should be true, because the new side falls back to the old record when there is no new record, which is the delete shape.');
    }

    @IsTest
    static void doesNotContainWhenValueIsAbsent() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Goodbye');

        // Verify
        Assert.isTrue(result, 'It should be true, because the text form of the value does not hold the searched fragment.');
    }

    @IsTest
    static void doesNotContainWhenValueIsPresent() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because the text form of the value does hold the searched fragment.');
    }

    @IsTest
    static void doesNotContainWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because a null value is answered before the text search runs, and a value that is absent holds nothing.');
    }

    @IsTest
    static void doesNotContainIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'world');

        // Verify
        Assert.isTrue(result, 'It should be true, because the underlying text search respects case, so a differently cased fragment is not found.');
    }

    @IsTest
    static void doesNotContainWhenValueIsTheWholeFieldValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Hello World');

        // Verify
        Assert.isFalse(result, 'It should be false, because a text value holds itself as a fragment in full.');
    }

    @IsTest
    static void doesNotContainWhenFieldIsEmptyText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because an empty string carries no characters that could hold the fragment.');
    }

    @IsTest
    static void doesNotContainOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'New note'),
            new Contact(LastName = 'Doe', Description = 'Old note')
        );

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Old');

        // Verify
        Assert.isTrue(result, 'It should be true, because the fragment search reads the new side, where the old text no longer stands.');
    }
    @IsTest
    static void doesNotContainOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Old note'));

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Old');

        // Verify
        Assert.isFalse(
            result,
            'It should be false, because with no new record the new side falls back to the old record in delete shape, and that old value does contain the text.'
        );
    }

    @IsTest
    static void startsWithWhenPrefixMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value begins with the exact prefix that was supplied.');
    }

    @IsTest
    static void startsWithWhenPrefixDoesNotMatch() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Goodbye');

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value does not begin with the supplied prefix.');
    }

    @IsTest
    static void startsWithWhenValueIsNotAtTheStart() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because startsWith anchors the match at position zero instead of searching anywhere inside the value.');
    }

    @IsTest
    static void startsWithWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isFalse(result, 'It should be false, because the null-field short-circuit returns false before the value is ever dereferenced.');
    }

    @IsTest
    static void startsWithIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'hello');

        // Verify
        Assert.isFalse(result, 'It should be false, because the prefix match is case sensitive.');
    }

    @IsTest
    static void startsWithWhenPrefixIsTheWholeFieldValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello World');

        // Verify
        Assert.isTrue(result, 'It should be true, because a prefix equal to the entire value still matches from position zero.');
    }

    @IsTest
    static void startsWithOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'New note'),
            new Contact(LastName = 'Doe', Description = 'Old note')
        );

        // Test
        Boolean result = record.startsWith(Contact.Description, 'New');

        // Verify
        Assert.isTrue(result, 'It should be true, because on an update the comparison reads the new record rather than the old one.');
    }

    @IsTest
    static void startsWithOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Old note'));

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Old');

        // Verify
        Assert.isTrue(result, 'It should be true, because with no new record the new side falls back to the old record in delete shape.');
    }

    @IsTest
    static void endsWithWhenSuffixMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value terminates with the exact suffix that was supplied.');
    }

    @IsTest
    static void endsWithWhenSuffixDoesNotMatch() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'Goodbye');

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value does not terminate with the supplied suffix.');
    }

    @IsTest
    static void endsWithWhenValueIsNotAtTheEnd() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isFalse(result, 'It should be false, because endsWith anchors the match at the end of the value instead of searching anywhere inside it.');
    }

    @IsTest
    static void endsWithWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because the null-field short-circuit returns false before the value is ever dereferenced.');
    }

    @IsTest
    static void endsWithIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'WORLD');

        // Verify
        Assert.isFalse(result, 'It should be false, because the suffix match is case sensitive.');
    }

    @IsTest
    static void endsWithWhenSuffixIsTheWholeFieldValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'Hello World');

        // Verify
        Assert.isTrue(result, 'It should be true, because a suffix equal to the entire value still matches at the end.');
    }

    @IsTest
    static void endsWithOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Doe', Description = 'Note new'),
            new Contact(LastName = 'Doe', Description = 'Note old')
        );

        // Test
        Boolean result = record.endsWith(Contact.Description, 'new');

        // Verify
        Assert.isTrue(result, 'It should be true, because on an update the comparison reads the new record rather than the old one.');
    }

    @IsTest
    static void endsWithOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Doe', Description = 'Note old'));

        // Test
        Boolean result = record.endsWith(Contact.Description, 'old');

        // Verify
        Assert.isTrue(result, 'It should be true, because with no new record the new side falls back to the old record in delete shape.');
    }

    @IsTest
    static void isTrueWhenFieldIsTrue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored field value is the Boolean true.');
    }

    @IsTest
    static void isTrueWhenFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because isTrue is an equality test against true and false does not satisfy it.');
    }

    @IsTest
    static void isTrueWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal'));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a field that was never assigned holds null, and null does not equal true.');
    }

    @IsTest
    static void isTrueWhenFieldIsText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isTrue(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'It should be false, because the value is compared as an Object and a String can never equal the Boolean true.');
    }

    @IsTest
    static void isTrueOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true), new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because on an update the comparison reads the new record rather than the old one.');
    }

    @IsTest
    static void isTrueOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because with no new record the new side falls back to the old record in delete shape.');
    }

    @IsTest
    static void isFalseWhenFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored field value is the Boolean false.');
    }

    @IsTest
    static void isFalseWhenFieldIsTrue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because isFalse is an equality test against false and true does not satisfy it.');
    }

    @IsTest
    static void isFalseWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal'));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a field that was never assigned holds null, and null does not equal false.');
    }

    @IsTest
    static void isFalseWhenFieldIsText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isFalse(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'It should be false, because the value is compared as an Object and a String can never equal the Boolean false.');
    }

    @IsTest
    static void isFalseOnUpdateReadsNewValue() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), new Opportunity(Name = 'Deal', IsPrivate = true));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because on an update the comparison reads the new record rather than the old one.');
    }

    @IsTest
    static void isFalseOnDeleteReadsOldValue() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Opportunity(Name = 'Deal', IsPrivate = false));

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because with no new record the new side falls back to the old record in delete shape.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is strictly above the compared number.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits below the compared number.');
    }

    @IsTest
    static void greaterThanIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is a strict comparison that excludes equality.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is above the compared number.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits below the compared number, so neither the greater nor the equal branch holds.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isTrue(result, 'It should be true, because greaterThanOrEqualTo admits equality alongside being above.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is strictly below the compared number.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits above the compared number.');
    }

    @IsTest
    static void lessThanIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is a strict comparison that excludes equality.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is below the compared number.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits above the compared number, so neither the less nor the equal branch holds.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isTrue(result, 'It should be true, because lessThanOrEqualTo admits equality alongside being below.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is widened to Decimal and lands strictly above the compared Double.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 7500.75;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value widened to Decimal sits below the compared Double.');
    }
    @IsTest
    static void greaterThanDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 5000.5;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is strict and an equal value is not above the threshold.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field makes every numeric comparison return false instead of attempting a conversion.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Double is converted to a Decimal that sits above the compared value.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 7500.75;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the Double is converted to a Decimal that sits below the compared value.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 5000.5;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts equality as well as being greater.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field returns false even for the or-equal-to form.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Double is converted to a Decimal that sits below the compared value.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 2500.25;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the Double is converted to a Decimal that sits above the compared value.');
    }

    @IsTest
    static void lessThanDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 5000.5;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is strict and an equal value is not below the threshold.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field makes every numeric comparison return false instead of attempting a conversion.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Decimal converted from the Double sits below the compared value.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 2500.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the Decimal converted from the Double sits above the compared value.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5));
        Double value = 5000.5;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts equality as well as being less.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field returns false even for the or-equal-to form.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 2000.25;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void greaterThanDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1500.75;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is strict and equal Decimals are not above each other.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'));
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 2000.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1500.75;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts two Decimals of the same value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'));
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false before the or-equal-to test runs.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1000.50;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void lessThanDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1500.75;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is strict and equal Decimals are not below each other.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'));
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1000.50;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75));
        Decimal value = 1500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts two Decimals of the same value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'));
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false before the or-equal-to test runs.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because a later Birthdate is greater when Dates are compared chronologically.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an earlier Birthdate is not greater when Dates are compared chronologically.');
    }

    @IsTest
    static void greaterThanDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is strict and the same calendar day is not later than itself.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false instead of being cast to a Date.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because a later Birthdate satisfies the or-equal-to Date comparison.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an earlier Birthdate fails both halves of the or-equal-to Date comparison.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts the same calendar day.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false before any Date cast happens.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because an earlier Birthdate is less when Dates are compared chronologically.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a later Birthdate is not less when Dates are compared chronologically.');
    }

    @IsTest
    static void lessThanDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is strict and the same calendar day is not earlier than itself.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false instead of being cast to a Date.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because an earlier Birthdate satisfies the or-equal-to Date comparison.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a later Birthdate fails both halves of the or-equal-to Date comparison.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts the same calendar day.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false before any Date cast happens.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because a DateTime one hour later is greater when instants are compared.');
    }
    @IsTest
    static void greaterThanDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored DateTime falls before the compared one and the comparison is chronological.');
    }

    @IsTest
    static void greaterThanDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is a strict comparison that excludes an identical DateTime.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field short-circuits the DateTime comparison instead of being ordered against the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored DateTime falls after the compared one, which satisfies the greater branch.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an earlier DateTime satisfies neither the greater branch nor the equal branch.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical DateTime still passes.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing DateTime never counts as equal either.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored DateTime falls before the compared one and the comparison is chronological.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored DateTime falls after the compared one, which is the opposite order.');
    }

    @IsTest
    static void lessThanDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is a strict comparison that excludes an identical DateTime.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field short-circuits the DateTime comparison rather than sorting as the earliest possible moment.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored DateTime falls before the compared one, which satisfies the less branch.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a later DateTime satisfies neither the less branch nor the equal branch.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical DateTime still passes.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'));
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing DateTime never counts as equal either.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 50L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Long overload compares both sides as Decimal and the field value outranks the argument.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 150L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value ranks below the argument in the numeric comparison.');
    }

    @IsTest
    static void greaterThanLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 100L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is a strict comparison that excludes an equal number.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Long value = 50L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset numeric field reads as null and the numeric comparison returns false rather than treating null as zero.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 50L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value outranks the argument, which satisfies the greater branch.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 150L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a lower field value satisfies neither the greater branch nor the equal branch.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 100L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical number still passes.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Long value = 50L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing number never counts as equal either.');
    }

    @IsTest
    static void greaterThanLongBeyondDoublePrecisionWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L));
        Long value = 9007199254740992L;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(
            result,
            'It should be true, because the field value is converted to Decimal through its String form, so digits past the Double mantissa survive the comparison.'
        );
    }

    @IsTest
    static void greaterThanLongBeyondDoublePrecisionWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L));
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the argument keeps its exact value in the Decimal comparison instead of being rounded down to the nearest Double.');
    }

    @IsTest
    static void greaterThanOrEqualToLongBeyondDoublePrecisionWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740992L));
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the Decimal comparison keeps the one-unit gap that a Double would have collapsed into equality.');
    }

    @IsTest
    static void greaterThanOrEqualToLongBeyondDoublePrecisionWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L));
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Decimal comparison preserves every digit on both sides, so two identical numbers past the Double limit still match.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 150L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Long widens to the Decimal comparison and the field value ranks below the argument.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 50L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value outranks the argument in the numeric comparison.');
    }

    @IsTest
    static void lessThanLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 100L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is a strict comparison that excludes an equal number.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Long value = 150L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(
            result,
            'It should be false, because an unset numeric field reads as null and the numeric comparison returns false rather than treating null as the smallest value.'
        );
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 150L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value ranks below the argument, which satisfies the less branch.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 50L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a higher field value satisfies neither the less branch nor the equal branch.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100));
        Long value = 100L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical number still passes.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'));
        Long value = 150L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing number never counts as equal either.');
    }

    @IsTest
    static void greaterThanComparesTheNewRecordOnUpdate() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), new Account(NumberOfEmployees = 10));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because every comparison reads the new side of an update, leaving the old value of 10 out of the test.');
    }

    @IsTest
    static void lessThanComparesTheNewRecordOnUpdate() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 10), new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because every comparison reads the new side of an update, leaving the old value of 100 out of the test.');
    }

    @IsTest
    static void greaterThanComparesTheOldRecordOnDelete() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because the new-side lookup falls back to the old record when there is no new record, which is the delete shape.');
    }

    @IsTest
    static void lessThanComparesTheOldRecordOnDelete() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'It should be true, because the new-side lookup falls back to the old record when there is no new record, which is the delete shape.');
    }

    @IsTest
    static void greaterThanDateComparesTheOldRecordOnDelete() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)));
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Date overload reads the same new-side lookup, which falls back to the old record in the delete shape.');
    }

    @IsTest
    static void isRecordTypeEqualWhenSObjectHasNoRecordTypes() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new User());
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(
            handlerException,
            'It should be thrown, because User carries nothing beyond the Master record type and record type checks are refused on such an SObject.'
        );
        Assert.isTrue(
            handlerException instanceof TriggerHandler.TriggerHandlerException,
            'It should be a TriggerHandlerException, because the framework raises its own exception type instead of letting a raw platform error surface.'
        );
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the SObject and the refused method, because the guard builds its message from the resolved SObject type and the call that was blocked.'
        );
    }

    @IsTest
    static void isRecordTypeNotEqualWhenSObjectHasNoRecordTypes() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new User());
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeNotEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(handlerException, 'It should be thrown, because the same record type guard protects the negated check on an SObject with only the Master record type.');
        Assert.isTrue(
            handlerException instanceof TriggerHandler.TriggerHandlerException,
            'It should be a TriggerHandlerException, because the framework raises its own exception type instead of letting a raw platform error surface.'
        );
        Assert.areEqual(
            'User has no record types, so isRecordTypeNotEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the refused method rather than its positive twin, because each guard reports the call that was actually blocked.'
        );
    }

    @IsTest
    static void isRecordTypeEqualOnUpdateRecord() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new User(LastName = 'New'), new User(LastName = 'Old'));
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(
            handlerException,
            'It should be thrown, because the record type guard runs before any value is read, so having both sides of an update does not exempt it.'
        );
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the SObject, because the type behind the message comes from the record pair rather than from the context in use.'
        );
    }

    @IsTest
    static void isRecordTypeNotEqualOnUpdateRecord() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new User(LastName = 'New'), new User(LastName = 'Old'));
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeNotEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(handlerException, 'It should be thrown, because the negated check shares the same guard and rejects an SObject without record types in every context.');
        Assert.areEqual(
            'User has no record types, so isRecordTypeNotEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the refused method, because each guard reports the call that was actually blocked.'
        );
    }

    @IsTest
    static void isRecordTypeEqualOnDeleteRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new User(LastName = 'Old'));
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(
            handlerException,
            'It should be thrown, because the SObject type is taken from the old record when the new record is null, so the guard still applies in delete shape.'
        );
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the SObject, because the deleted row supplies the type that the message is built from.'
        );
    }

    @IsTest
    static void isRecordTypeNotEqualOnDeleteRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new User(LastName = 'Old'));
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeNotEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(handlerException, 'It should be thrown, because the negated check reads the type from the old record as well and hits the same guard.');
        Assert.areEqual(
            'User has no record types, so isRecordTypeNotEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the refused method, because each guard reports the call that was actually blocked.'
        );
    }

    @IsTest
    static void isRecordTypeEqualOnUndeleteRecord() {
        TriggerHandler.UndeleteRecord record = new TriggerHandler.TriggerRecord(new User());
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(handlerException, 'It should be thrown, because the restored record resolves to the same SObject type and the guard rejects it exactly as on insert.');
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the SObject, because the message is built from the resolved type regardless of which context interface exposes the call.'
        );
    }
    @IsTest
    static void isRecordTypeNotEqualOnUndeleteRecord() {
        TriggerHandler.UndeleteRecord record = new TriggerHandler.TriggerRecord(new User());
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeNotEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(handlerException, 'It should be thrown, because User has no record types beyond Master.');
        Assert.areEqual(
            'User has no record types, so isRecordTypeNotEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the SObject, because the framework raises TriggerHandlerException instead of a raw SObjectException.'
        );
    }

    @IsTest
    static void isRecordTypeEqualNamesTheSObjectTypeInTheMessage() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Group());
        Exception handlerException = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            handlerException = e;
        }

        // Verify
        Assert.isNotNull(handlerException, 'It should be thrown, because Group has no record types beyond Master.');
        Assert.areEqual(
            'Group has no record types, so isRecordTypeEqual cannot be used on it.',
            handlerException.getMessage(),
            'It should name the SObject, because the framework raises TriggerHandlerException instead of a raw SObjectException.'
        );
    }

    @IsTest
    static void multipleIsRecordTypeEqualExecutions() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new User());
        Exception firstException = null;
        Exception secondException = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            firstException = e;
        }

        try {
            record.isRecordTypeEqual('Standard');
        } catch (Exception e) {
            secondException = e;
        }

        // Verify
        Assert.isNotNull(firstException, 'It should be thrown on the first call, because User has no record types beyond Master.');
        Assert.isNotNull(secondException, 'It should be thrown on the second call, because the record type guard runs on every call and is never disarmed by an earlier failure.');
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            firstException.getMessage(),
            'It should name the SObject, because the framework raises TriggerHandlerException instead of a raw SObjectException.'
        );
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            secondException.getMessage(),
            'It should be the same message, because the describe is cached per SObjectType and the cached entry yields the same guard outcome.'
        );
    }

    @IsTest
    static void newSObjectIsReturnedWhenBuiltFromASingleRecord() {
        Contact newContact = new Contact(LastName = 'New');
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(newContact);

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(newContact, result, 'It should be the record passed to the constructor, because the single record constructor stores that record as the new side.');
    }

    @IsTest
    static void oldSObjectIsNullWhenBuiltFromASingleRecord() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'));

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.isNull(result, 'It should be null, because the single record constructor leaves the old side unassigned.');
    }

    @IsTest
    static void newSObjectIsReturnedOnInsertShape() {
        Contact newContact = new Contact(LastName = 'New');
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(newContact, null);

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(newContact, result, 'It should be the inserted record, because the insert shape carries the record on the new side and null on the old one.');
    }

    @IsTest
    static void oldSObjectIsNullOnInsertShape() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.isNull(result, 'It should be null, because an inserted record has no prior version to expose.');
    }

    @IsTest
    static void newSObjectIsReturnedOnUpdateShape() {
        Contact newContact = new Contact(LastName = 'New');
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(newContact, new Contact(LastName = 'Old'));

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(newContact, result, 'It should be the updated record, because the update shape keeps the record being saved on the new side.');
    }

    @IsTest
    static void oldSObjectIsReturnedOnUpdateShape() {
        Contact oldContact = new Contact(LastName = 'Old');
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), oldContact);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.areEqual(oldContact, result, 'It should be the record as it was before the update, because the update shape keeps the prior version on the old side.');
    }

    @IsTest
    static void newSObjectIsNullOnDeleteShape() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Old'));

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.isNull(result, 'It should be null, because a deleted record exists only on the old side.');
    }

    @IsTest
    static void oldSObjectIsReturnedOnDeleteShape() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Contact oldContact = new Contact(Id = contactId, LastName = 'Old');
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, oldContact);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.areEqual(oldContact, result, 'It should be the deleted record, because the delete shape carries the row only on the old side.');
    }

    @IsTest
    static void newSidePredicatesReadTheOldRecordOnDeleteShape() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Old'));

        // Test
        Boolean result = record.equals(Contact.LastName, 'Old');

        // Verify
        Assert.isTrue(result, 'It should be true, because the new side predicates fall back to the old record when there is no new record.');
    }

    @IsTest
    static void newSObjectIsReturnedOnUndeleteShape() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Contact restoredContact = new Contact(Id = contactId, LastName = 'Restored');
        TriggerHandler.UndeleteRecord record = new TriggerHandler.TriggerRecord(restoredContact, null);

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(restoredContact, result, 'It should be the restored record, because the undelete shape carries the row only on the new side.');
    }

    @IsTest
    static void oldSObjectIsNullOnUndeleteShape() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'Restored'), null);

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.isNull(result, 'It should be null, because a restored record has no prior version in an after undelete context.');
    }

    @IsTest
    static void newSObjectIsTheInstanceThatWasPassedIn() {
        Contact newContact = new Contact(LastName = 'New');
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(newContact);
        newContact.Title = 'Manager';

        // Test
        SObject result = record.getNewSObject();

        // Verify
        Assert.areEqual(
            'Manager',
            result.get(Contact.Title),
            'It should be Manager, because the record is held by reference rather than cloned, so a later write to the source is visible.'
        );
    }

    @IsTest
    static void oldSObjectIsTheInstanceThatWasPassedIn() {
        Contact oldContact = new Contact(LastName = 'Old');
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), oldContact);
        oldContact.Title = 'Manager';

        // Test
        SObject result = record.getOldSObject();

        // Verify
        Assert.areEqual(
            'Manager',
            result.get(Contact.Title),
            'It should be Manager, because the old record is held by reference rather than cloned, so a later write to the source is visible.'
        );
    }

    @IsTest
    static void getIdReturnsTheNewRecordId() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'New'), null);

        // Test
        Id result = record.getId();

        // Verify
        Assert.areEqual(contactId, String.valueOf(result), 'It should be the new record id, because getId reads the new side first.');
    }

    @IsTest
    static void getIdFallsBackToTheOldRecordIdWhenNewRecordIsNull() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(Id = contactId, LastName = 'Old'));

        // Test
        Id result = record.getId();

        // Verify
        Assert.areEqual(contactId, String.valueOf(result), 'It should be the old record id, because getId falls back to the old record when the new record is null.');
    }

    @IsTest
    static void getIdPrefersTheNewRecordIdOverTheOldOne() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(Id = firstContactId, LastName = 'New'),
            new Contact(Id = secondContactId, LastName = 'Old')
        );

        // Test
        Id result = record.getId();

        // Verify
        Assert.areEqual(
            firstContactId,
            String.valueOf(result),
            'It should be the new record id, because the fallback to the old record applies only when the new record is missing.'
        );
    }

    @IsTest
    static void getIdIsNullWhenTheRecordHasNoId() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        Id result = record.getId();

        // Verify
        Assert.isNull(result, 'It should be null, because a record that has not been saved yet carries no id to read.');
    }

    @IsTest
    static void putSetsTheValueOnTheNewRecord() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Manager', record.getNewSObject().get(Contact.Title), 'It should be Manager, because put writes straight through to the new record.');
    }

    @IsTest
    static void putIsVisibleThroughEquals() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        record.put(Contact.Title, 'Manager');

        // Test
        Boolean result = record.equals(Contact.Title, 'Manager');

        // Verify
        Assert.isTrue(result, 'It should be true, because equals reads the new record live, so a value written by put is seen by later handlers.');
    }

    @IsTest
    static void putIsVisibleOnTheSourceRecord() {
        Contact newContact = new Contact(LastName = 'New');
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(newContact, null);

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Manager', newContact.Title, 'It should be Manager, because put mutates the trigger record itself rather than a copy, so the value is saved.');
    }

    @IsTest
    static void putOverwritesAnExistingValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), null);

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Manager', record.getNewSObject().get(Contact.Title), 'It should be Manager, because put replaces whatever value the field already held.');
    }

    @IsTest
    static void putClearsTheValueWhenNullIsGiven() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), null);

        // Test
        record.put(Contact.Title, null);

        // Verify
        Assert.isNull(record.getNewSObject().get(Contact.Title), 'It should be null, because put passes null through to the field instead of ignoring it.');
    }

    @IsTest
    static void putSetsABooleanValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        record.put(Contact.DoNotCall, true);

        // Verify
        Assert.areEqual(
            true,
            record.getNewSObject().get(Contact.DoNotCall),
            'It should be true, because put writes any Object value, a Boolean included, straight to the new record.'
        );
    }

    @IsTest
    static void putSetsANumericValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'New'), null);

        // Test
        record.put(Account.NumberOfEmployees, 25);

        // Verify
        Assert.areEqual(
            25,
            record.getNewSObject().get(Account.NumberOfEmployees),
            'It should be 25, because put writes any Object value, a number included, straight to the new record.'
        );
    }

    @IsTest
    static void putSetsADateValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        record.put(Contact.Birthdate, Date.newInstance(2020, 1, 1));

        // Verify
        Assert.areEqual(
            Date.newInstance(2020, 1, 1),
            record.getNewSObject().get(Contact.Birthdate),
            'It should be the given date, because put writes any Object value, a Date included, straight to the new record.'
        );
    }

    @IsTest
    static void putDoesNotTouchTheOldRecord() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), new Contact(LastName = 'Old', Title = 'Analyst'));

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Analyst', record.getOldSObject().get(Contact.Title), 'It should stay Analyst, because put writes to the new record only and never reaches the old one.');
    }

    @IsTest
    static void getNewRelatedReturnsTheEnrichedParent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Account parentAccount = new Account(Id = accountId, Name = 'Parent');
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', parentAccount);

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.areEqual(parentAccount, result, 'It should be the enriched parent, because the new side returns the record stored under that relationship name.');
    }

    @IsTest
    static void getNewRelatedExposesTheEnrichedParentFields() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent', Industry = 'IT'));

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.areEqual('IT', result.get(Account.Industry), 'It should be IT, because the enriched parent is handed back whole, so every field declared on it is readable.');
    }

    @IsTest
    static void getNewRelatedUsesTheLookupRelationshipName() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew(Contact.AccountId.getDescribe().getRelationshipName(), new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.areEqual(
            'Parent',
            result.get(Account.Name),
            'It should be Parent, because the parent is keyed by the relationship name of the lookup field, which for AccountId is Account.'
        );
    }

    @IsTest
    static void getOldRelatedReturnsTheEnrichedParent() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Account priorParentAccount = new Account(Id = firstAccountId, Name = 'Prior Parent');
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = secondAccountId),
            new Contact(LastName = 'Old', AccountId = firstAccountId)
        );
        record.enrichOld('Account', priorParentAccount);

        // Test
        SObject result = record.getOldRelated('Account');

        // Verify
        Assert.areEqual(priorParentAccount, result, 'It should be the enriched prior parent, because the old side returns the record stored under that relationship name.');
    }

    @IsTest
    static void getOldRelatedReturnsThePriorParentWhenBothSidesAreEnriched() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );
        record.enrichNew('Account', new Account(Id = firstAccountId, Name = 'Current Parent'));
        record.enrichOld('Account', new Account(Id = secondAccountId, Name = 'Prior Parent'));

        // Test
        SObject result = record.getOldRelated('Account');

        // Verify
        Assert.areEqual(
            'Prior Parent',
            result.get(Account.Name),
            'It should be Prior Parent, because the old side keeps a relationship map of its own, separate from the new side.'
        );
    }

    @IsTest
    static void getNewRelatedReturnsTheCurrentParentWhenBothSidesAreEnriched() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );
        record.enrichNew('Account', new Account(Id = firstAccountId, Name = 'Current Parent'));
        record.enrichOld('Account', new Account(Id = secondAccountId, Name = 'Prior Parent'));

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.areEqual(
            'Current Parent',
            result.get(Account.Name),
            'It should be Current Parent, because the new side keeps a relationship map of its own, separate from the old side.'
        );
    }

    @IsTest
    static void getOldRelatedReturnsTheEnrichedParentOnDeleteShape() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Account parentAccount = new Account(Id = accountId, Name = 'Parent');
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(null, new Contact(Id = contactId, LastName = 'Old', AccountId = accountId));
        record.enrichOld('Account', parentAccount);

        // Test
        SObject result = record.getOldRelated('Account');

        // Verify
        Assert.areEqual(parentAccount, result, 'It should be the enriched parent, because the old side relationship map is filled even when there is no new record.');
    }

    @IsTest
    static void getNewRelatedIsNullWhenNothingWasEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because the new side relationship map has no entry for a name that was never enriched.');
    }

    @IsTest
    static void getOldRelatedIsNullWhenNothingWasEnriched() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );

        // Test
        SObject result = record.getOldRelated('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because the old side relationship map has no entry for a name that was never enriched.');
    }

    @IsTest
    static void getNewRelatedIsNullForARelationshipThatWasNotEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewRelated('ReportsTo');

        // Verify
        Assert.isNull(result, 'It should be null, because only the enriched relationship names are stored, so every other name misses the map.');
    }

    @IsTest
    static void getOldRelatedIsNullForARelationshipThatWasNotEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.enrichOld('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getOldRelated('ReportsTo');

        // Verify
        Assert.isNull(result, 'It should be null, because only the enriched relationship names are stored on the old side, so every other name misses the map.');
    }

    @IsTest
    static void getOldRelatedIsNullWhenOnlyTheNewSideWasEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getOldRelated('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because enrichNew writes to the new side map only and leaves the old side map empty.');
    }

    @IsTest
    static void getNewRelatedIsNullWhenOnlyTheOldSideWasEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.enrichOld('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because enrichOld writes to the old side map only and leaves the new side map empty.');
    }

    @IsTest
    static void getNewRelatedIsNullWhenTheLookupIsUnset() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        record.enrichNew('Account', null);

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because an unset lookup resolves to no parent, so the stored null is what the new side hands back.');
    }

    @IsTest
    static void getNewRelatedIsCaseSensitive() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewRelated('account');

        // Verify
        Assert.isNull(result, 'It should be null, because the relationship map is keyed by String and a Map lookup on a String key is case sensitive.');
    }

    @IsTest
    static void enrichNewOverwritesThePreviouslyEnrichedParent() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = firstAccountId), null);
        record.enrichNew('Account', new Account(Id = firstAccountId, Name = 'Original Parent'));
        record.enrichNew('Account', new Account(Id = secondAccountId, Name = 'Re-pointed Parent'));

        // Test
        SObject result = record.getNewRelated('Account');

        // Verify
        Assert.areEqual(
            'Re-pointed Parent',
            result.get(Account.Name),
            'It should be Re-pointed Parent, because a second enrichment under the same relationship name replaces the earlier entry.'
        );
    }

    @IsTest
    static void enrichNewKeepsRelationshipsIndependent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));
        record.enrichNew('ReportsTo', new Contact(Id = contactId, LastName = 'Manager'));

        // Test
        SObject result = record.getNewRelated('ReportsTo');

        // Verify
        Assert.areEqual(
            'Manager',
            result.get(Contact.LastName),
            'It should be Manager, because each relationship is stored under its own name, so enriching one does not disturb another.'
        );
    }

    @IsTest
    static void getIdentifierReturnsTheRecordId() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'New'), null);

        // Test
        String result = record.getIdentifier();

        // Verify
        Assert.areEqual(contactId, result, 'It should be the record id, because the identifier falls back to a generated UUID only when the record has no id.');
    }
    @IsTest
    static void getIdentifierFallsBackToTheOldRecordIdWhenNewRecordIsNull() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(null, new Contact(Id = contactId, LastName = 'Old'));

        // Test
        String result = record.getIdentifier();

        // Verify
        Assert.areEqual(
            contactId,
            result,
            'It should be the id of the old record, because the identifier falls back to the old record when there is no new record, as in delete shape.'
        );
    }

    @IsTest
    static void getIdentifierPrefersTheNewRecordId() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(Id = firstContactId, LastName = 'New'),
            new Contact(Id = secondContactId, LastName = 'Old')
        );

        // Test
        String result = record.getIdentifier();

        // Verify
        Assert.areEqual(
            firstContactId,
            result,
            'It should be the id of the new record, because the identifier reads the new record first and only falls back to the old one when the new record is null.'
        );
    }

    @IsTest
    static void getIdentifierIsNotNullWhenTheRecordHasNoId() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);

        // Test
        String result = record.getIdentifier();

        // Verify
        Assert.isNotNull(result, 'It should be not null, because a record with no id is given a random UUID as its identifier.');
    }

    @IsTest
    static void getIdentifierIsUniquePerRecordWithoutAnId() {
        TriggerHandler.TriggerRecord firstRecord = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        TriggerHandler.TriggerRecord secondRecord = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        String secondIdentifier = secondRecord.getIdentifier();

        // Test
        String result = firstRecord.getIdentifier();

        // Verify
        Assert.areNotEqual(secondIdentifier, result, 'It should differ from the other identifier, because every record without an id gets its own random UUID.');
    }

    @IsTest
    static void getIdentifierIsSharedByTwoRecordsWrappingTheSameRow() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord firstRecord = new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'New'), null);
        TriggerHandler.TriggerRecord secondRecord = new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'New'), null);
        String secondIdentifier = secondRecord.getIdentifier();

        // Test
        String result = firstRecord.getIdentifier();

        // Verify
        Assert.areEqual(secondIdentifier, result, 'It should be the same identifier, because the record id is used as the identifier whenever the wrapped row has one.');
    }

    @IsTest
    static void getIdentifierIsStableAcrossCalls() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        String firstIdentifier = record.getIdentifier();

        // Test
        String result = record.getIdentifier();

        // Verify
        Assert.areEqual(
            firstIdentifier,
            result,
            'It should be the identifier returned by the first call, because the identifier is computed once in the constructor and stored on the record.'
        );
    }

    @IsTest
    static void getIdentifierIsNotChangedByPut() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        String identifierBeforePut = record.getIdentifier();
        record.put(Contact.Title, 'Manager');

        // Test
        String result = record.getIdentifier();

        // Verify
        Assert.areEqual(
            identifierBeforePut,
            result,
            'It should be the identifier taken before the write, because the identifier is fixed at construction time and put only writes to the wrapped SObject.'
        );
    }

    @IsTest
    static void withOneField() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name).getFields();

        // Verify
        Assert.areEqual(new List<String>{ 'Name' }, fields, 'It should contain only Name, because with() appends each requested field in order.');
    }

    @IsTest
    static void withTwoFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Account.Industry).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry' },
            fields,
            'It should contain Name and Industry, because the two-field overload appends both arguments in the order they were passed.'
        );
    }

    @IsTest
    static void withThreeFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Account.Industry, Account.Description).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Description' },
            fields,
            'It should contain Name, Industry and Description, because the three-field overload appends every argument in the order it was passed.'
        );
    }

    @IsTest
    static void withFourFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Account.Industry, Account.Description, Account.Website).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Description', 'Website' },
            fields,
            'It should contain Name, Industry, Description and Website, because the four-field overload appends every argument in the order it was passed.'
        );
    }

    @IsTest
    static void withFiveFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Account.Industry, Account.Description, Account.Website, Account.NumberOfEmployees).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Description', 'Website', 'NumberOfEmployees' },
            fields,
            'It should contain Name, Industry, Description, Website and NumberOfEmployees, because the five-field overload appends every argument in the order it was passed.'
        );
    }

    @IsTest
    static void withIterableOfFields() {
        List<SObjectField> fieldsToSelect = new List<SObjectField>{
            Account.Name,
            Account.Industry,
            Account.Description,
            Account.Website,
            Account.NumberOfEmployees,
            Account.AnnualRevenue
        };

        // Test
        List<String> fields = TriggerHandler.ParentFields.with(fieldsToSelect).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Description', 'Website', 'NumberOfEmployees', 'AnnualRevenue' },
            fields,
            'It should contain all six fields in iteration order, because the iterable overload appends one entry per element as it iterates.'
        );
    }

    @IsTest
    static void withEmptyIterableOfFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(new List<SObjectField>()).getFields();

        // Verify
        Assert.areEqual(new List<String>(), fields, 'It should be empty, because the iterable overload appends one entry per element and an empty iterable yields none.');
    }

    @IsTest
    static void withRelationshipAndOneField() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name' },
            fields,
            'It should contain Parent.Name, because the relationship overload joins the relationship name and the field name with a dot.'
        );
    }

    @IsTest
    static void withRelationshipAndTwoFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', Account.Name, Account.Industry).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry' },
            fields,
            'It should contain Parent.Name and Parent.Industry, because the relationship overload prefixes every field argument with the same relationship name.'
        );
    }

    @IsTest
    static void withRelationshipAndThreeFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', Account.Name, Account.Industry, Account.Description).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description' },
            fields,
            'It should contain the three fields prefixed with Parent, because the relationship overload prefixes every field argument with the same relationship name.'
        );
    }

    @IsTest
    static void withRelationshipAndFourFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', Account.Name, Account.Industry, Account.Description, Account.Website).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description', 'Parent.Website' },
            fields,
            'It should contain the four fields prefixed with Parent, because the relationship overload prefixes every field argument with the same relationship name.'
        );
    }

    @IsTest
    static void withRelationshipAndFiveFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields
            .with('Parent', Account.Name, Account.Industry, Account.Description, Account.Website, Account.NumberOfEmployees)
            .getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description', 'Parent.Website', 'Parent.NumberOfEmployees' },
            fields,
            'It should contain the five fields prefixed with Parent, because the relationship overload prefixes every field argument with the same relationship name.'
        );
    }

    @IsTest
    static void withRelationshipAndIterableOfFields() {
        List<SObjectField> fieldsToSelect = new List<SObjectField>{
            Account.Name,
            Account.Industry,
            Account.Description,
            Account.Website,
            Account.NumberOfEmployees,
            Account.AnnualRevenue
        };

        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', fieldsToSelect).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Industry', 'Parent.Description', 'Parent.Website', 'Parent.NumberOfEmployees', 'Parent.AnnualRevenue' },
            fields,
            'It should contain all six fields prefixed with Parent in iteration order, because the relationship iterable overload prefixes each element as it iterates.'
        );
    }

    @IsTest
    static void withRelationshipAndEmptyIterableOfFields() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', new List<SObjectField>()).getFields();

        // Verify
        Assert.areEqual(
            new List<String>(),
            fields,
            'It should be empty, because the relationship iterable overload appends one entry per element and an empty iterable yields none.'
        );
    }

    @IsTest
    static void withCustomRelationshipName() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Custom_Lookup__r', Account.Name, Account.Industry).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Custom_Lookup__r.Name', 'Custom_Lookup__r.Industry' },
            fields,
            'It should contain Custom_Lookup__r.Name and Custom_Lookup__r.Industry, because the relationship name is concatenated verbatim and never resolved against the schema.'
        );
    }

    @IsTest
    static void withMultiLevelRelationshipName() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent.Parent', Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Parent.Name' },
            fields,
            'It should contain Parent.Parent.Name, because the relationship name is concatenated verbatim, so any number of levels passes through untouched.'
        );
    }

    @IsTest
    static void withEmptyRelationshipName() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('', Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ '.Name' },
            fields,
            'It should contain .Name, because the relationship name is concatenated verbatim and the selection never validates it.'
        );
    }

    @IsTest
    static void withPlainAndRelationshipFieldsChained() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Account.Industry).with('Parent', Account.Name).with(Account.Website).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Parent.Name', 'Website' },
            fields,
            'It should contain the four entries in call order, because every with() overload appends to the same backing list.'
        );
    }

    @IsTest
    static void withDifferentRelationshipsChained() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Account', Account.Name).with('ReportsTo', Contact.Email).with('Account', Account.Industry).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Account.Name', 'ReportsTo.Email', 'Account.Industry' },
            fields,
            'It should keep every entry with its own prefix and position, because each call appends to the same backing list and no grouping by relationship happens.'
        );
    }

    @IsTest
    static void withEveryOverloadChained() {
        // Test
        List<String> fields = TriggerHandler.ParentFields
            .with(Account.Name)
            .with(Account.Industry, Account.Description)
            .with(Account.Website, Account.NumberOfEmployees, Account.AnnualRevenue)
            .with(Account.Name, Account.Industry, Account.Description, Account.Website)
            .with(Account.Name, Account.Industry, Account.Description, Account.Website, Account.NumberOfEmployees)
            .with(new List<SObjectField>{ Account.AnnualRevenue })
            .with('Parent', Account.Name)
            .with('Parent', Account.Industry, Account.Description)
            .with('Parent', Account.Website, Account.NumberOfEmployees, Account.AnnualRevenue)
            .with('Parent', Account.Name, Account.Industry, Account.Description, Account.Website)
            .with('Parent', Account.Name, Account.Industry, Account.Description, Account.Website, Account.NumberOfEmployees)
            .with('Parent', new List<SObjectField>{ Account.AnnualRevenue })
            .getFields();

        // Verify
        Assert.areEqual(
            new List<String>{
                'Name',
                'Industry',
                'Description',
                'Website',
                'NumberOfEmployees',
                'AnnualRevenue',
                'Name',
                'Industry',
                'Description',
                'Website',
                'Name',
                'Industry',
                'Description',
                'Website',
                'NumberOfEmployees',
                'AnnualRevenue',
                'Parent.Name',
                'Parent.Industry',
                'Parent.Description',
                'Parent.Website',
                'Parent.NumberOfEmployees',
                'Parent.AnnualRevenue',
                'Parent.Name',
                'Parent.Industry',
                'Parent.Description',
                'Parent.Website',
                'Parent.Name',
                'Parent.Industry',
                'Parent.Description',
                'Parent.Website',
                'Parent.NumberOfEmployees',
                'Parent.AnnualRevenue'
            },
            fields,
            'It should contain every appended field in call order, because all twelve overloads append to the same backing list and none of them de-duplicates.'
        );
    }

    @IsTest
    static void withReturnsTheSameSelection() {
        TriggerHandler.ParentFields selection = TriggerHandler.ParentFields.with(Account.Name);

        // Test
        TriggerHandler.ParentFields chainedSelection = selection.with(Account.Industry);

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry' },
            chainedSelection.getFields(),
            'It should contain Name and Industry, because with() returns this, so the chained reference is the very same selection.'
        );
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry' },
            selection.getFields(),
            'It should contain Name and Industry, because with() mutates the selection in place instead of returning a new one.'
        );
    }

    @IsTest
    static void withRelationshipReturnsTheSameSelection() {
        TriggerHandler.ParentFields selection = TriggerHandler.ParentFields.with(Account.Name);

        // Test
        TriggerHandler.ParentFields chainedSelection = selection.with('Parent', Account.Industry);

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Parent.Industry' },
            chainedSelection.getFields(),
            'It should contain Name and Parent.Industry, because the relationship overload also returns this, so the chained reference is the very same selection.'
        );
        Assert.areEqual(
            new List<String>{ 'Name', 'Parent.Industry' },
            selection.getFields(),
            'It should contain Name and Parent.Industry, because the relationship overload mutates the selection in place instead of returning a new one.'
        );
    }

    @IsTest
    static void withAccumulatesAcrossSeparateStatements() {
        TriggerHandler.ParentFields selection = TriggerHandler.ParentFields;

        selection.with(Account.Name);
        selection.with('Parent', Account.Industry);

        // Test
        List<String> fields = selection.with(new List<SObjectField>{ Account.Website }).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Parent.Industry', 'Website' },
            fields,
            'It should contain the fields of all three calls in call order, because the selection keeps one backing list that every with() call appends to.'
        );
    }

    @IsTest
    static void fieldSelectionPropertyStartsEmpty() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.getFields();

        // Verify
        Assert.areEqual(new List<String>(), fields, 'It should be empty, because the property getter returns a brand new FieldSelector whose backing list starts out empty.');
    }

    @IsTest
    static void fieldSelectionPropertyReturnsNewSelectionOnEveryRead() {
        TriggerHandler.ParentFields firstSelection = TriggerHandler.ParentFields.with(Account.Name);
        TriggerHandler.ParentFields secondSelection = TriggerHandler.ParentFields.with(Account.Industry);

        // Test
        firstSelection.with(Account.Website);

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Website' },
            firstSelection.getFields(),
            'It should contain only Name and Website, because each read of the property builds a separate FieldSelector with its own backing list.'
        );
        Assert.areEqual(
            new List<String>{ 'Industry' },
            secondSelection.getFields(),
            'It should contain only Industry, because the two selections came from two reads of the property and share no state.'
        );
    }

    @IsTest
    static void fieldSelectionPropertyDoesNotShareFieldsBetweenReads() {
        TriggerHandler.ParentFields.with(Account.Name, Account.Industry);

        // Test
        List<String> fields = TriggerHandler.ParentFields.getFields();

        // Verify
        Assert.areEqual(
            new List<String>(),
            fields,
            'It should be empty, because the property getter returns a new FieldSelector on every read, so fields added through an earlier read are not visible.'
        );
    }

    @IsTest
    static void getFieldsPreservesInsertionOrder() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Website).with(Account.Name).with(Account.Industry, Account.Description).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Website', 'Name', 'Industry', 'Description' },
            fields,
            'It should be returned in selection order, because getFields returns the backing list, which is only appended to and never sorted.'
        );
    }

    @IsTest
    static void getFieldsDoesNotDeduplicateRepeatedField() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name).with(Account.Industry).with(Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Name' },
            fields,
            'It should contain Name twice, because each with() call appends without checking whether the field is already selected.'
        );
    }

    @IsTest
    static void getFieldsDoesNotDeduplicateRepeatedFieldInSingleCall() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Account.Name, Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Name', 'Name' },
            fields,
            'It should contain Name three times, because the overload appends one entry per argument without de-duplication.'
        );
    }

    @IsTest
    static void getFieldsDoesNotDeduplicateRepeatedRelationshipField() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with('Parent', Account.Name).with('Parent', Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Parent.Name', 'Parent.Name' },
            fields,
            'It should contain Parent.Name twice, because relationship entries are appended without de-duplication as well.'
        );
    }

    @IsTest
    static void getFieldsKeepsPlainAndRelationshipFieldApart() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name).with('Parent', Account.Name).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Parent.Name' },
            fields,
            'It should contain both Name and Parent.Name, because the relationship prefix makes the two entries different strings.'
        );
    }

    @IsTest
    static void getFieldsReturnsTheSelectionsOwnList() {
        TriggerHandler.ParentFields selection = TriggerHandler.ParentFields.with(Account.Name);
        List<String> fields = selection.getFields();

        // Test
        fields.add('Industry');

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry' },
            selection.getFields(),
            'It should contain Name and Industry, because getFields hands back the backing list itself, so a change made to that list is visible on the selection.'
        );
    }

    @IsTest
    static void withFieldsFromDifferentSObjects() {
        // Test
        List<String> fields = TriggerHandler.ParentFields.with(Account.Name, Contact.LastName, Opportunity.Amount).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'LastName', 'Amount' },
            fields,
            'It should contain Name, LastName and Amount, because each field is appended as its own token and the selection never validates the SObject it belongs to.'
        );
    }

    @IsTest
    static void fieldSelectionAsEnrichmentDeclaration() {
        Map<SObjectField, TriggerHandler.ParentFields> fieldsToEnrich = new Map<SObjectField, TriggerHandler.ParentFields>{
            Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name, Account.Industry).with('Parent', Account.Name)
        };

        // Test
        List<String> fields = fieldsToEnrich.get(Contact.AccountId).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name', 'Industry', 'Parent.Name' },
            fields,
            'It should contain Name, Industry and Parent.Name, because the selection stored in the map keeps the fields of every chained call in declaration order.'
        );
    }

    @IsTest
    static void fieldSelectionsInOneEnrichmentDeclarationAreIndependent() {
        Map<SObjectField, TriggerHandler.ParentFields> fieldsToEnrich = new Map<SObjectField, TriggerHandler.ParentFields>{
            Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name),
            Contact.ReportsToId => TriggerHandler.ParentFields.with(Contact.LastName)
        };

        // Test
        List<String> accountFields = fieldsToEnrich.get(Contact.AccountId).getFields();

        // Verify
        Assert.areEqual(
            new List<String>{ 'Name' },
            accountFields,
            'It should contain only Name, because each read of the property creates a separate selection, so the two lookups share no backing list.'
        );
        Assert.areEqual(
            new List<String>{ 'LastName' },
            fieldsToEnrich.get(Contact.ReportsToId).getFields(),
            'It should contain only LastName, because every value in the map came from its own read of the property.'
        );
    }
}
