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
    static void isChangedWhenOnlyLetterCaseDiffers() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'DOE'), new Contact(LastName = 'Doe'));

        // Test
        Boolean result = record.isChanged(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'It should not be changed, because the Object comparison ignores letter case for text.');
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
        Assert.isTrue(result, 'It should be reported as changed, because the second field is forwarded to the scan and it differs.');
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
        Assert.isFalse(result, 'It should not be reported as fully changed, because the second field is forwarded to the scan and it compares equal.');
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
    static void areAllChangedWithThreeFieldsWhenLastDidNotChange() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'NewLast', FirstName = 'NewFirst', Email = 'same@a.co'),
            new Contact(LastName = 'OldLast', FirstName = 'OldFirst', Email = 'same@a.co')
        );

        // Test
        Boolean result = record.areAllChanged(Contact.LastName, Contact.FirstName, Contact.Email);

        // Verify
        Assert.isFalse(result, 'It should not be reported as fully changed, because the third field is forwarded to the scan and it compares equal.');
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be null, because a field that was never assigned has no value on the record.');
    }

    @IsTest
    static void isNullWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should not be null, because the null check tests only for the absence of a value and an empty string is a value.');
    }

    @IsTest
    static void isNullWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because the raw field value is compared against null and an assigned value is never null.');
    }

    @IsTest
    static void isNullWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isNull(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because zero is an assigned value and only an unassigned field reads back as null.');
    }

    @IsTest
    static void isNullWhenBooleanFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

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
    static void isNotNullWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because this check is the plain negation of the null check and an unassigned field is null.');
    }

    @IsTest
    static void isNotNullWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the null check asks only whether a value was assigned, and an empty string is an assigned value.');
    }

    @IsTest
    static void isNotNullWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNotNull(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because an assigned value makes the negated null check true.');
    }

    @IsTest
    static void isNotNullWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the emptiness check short-circuits on null before it ever inspects text.');
    }

    @IsTest
    static void isEmptyWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a string of zero length is empty once the null short-circuit passes.');
    }

    @IsTest
    static void isEmptyWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because emptiness is measured by length without trimming, so spaces count as content.');
    }

    @IsTest
    static void isEmptyWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a value of non-zero length is not empty.');
    }

    @IsTest
    static void isEmptyWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isEmpty(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because a non-null number is converted to text first, and zero converts to a string with length.');
    }

    @IsTest
    static void isEmptyWhenBooleanFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isEmpty(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a Boolean is converted to the text false, which has length.');
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because this check negates one that short-circuits to empty on null.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a string of zero length counts as empty and the negation follows that.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because emptiness is measured without trimming, so spaces count as content.');
    }

    @IsTest
    static void isNotEmptyWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNotEmpty(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a value of non-zero length is not empty.');
    }

    @IsTest
    static void isNotEmptyWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the blank check short-circuits on null before it ever inspects text.');
    }

    @IsTest
    static void isBlankWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a string of zero length has no non-whitespace content left after trimming.');
    }

    @IsTest
    static void isBlankWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because the blank check trims the value first, unlike the emptiness check.');
    }

    @IsTest
    static void isBlankWhenFieldIsTabAndNewLine() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '\t\n'), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because tabs and new lines are whitespace to the blank check, not content.');
    }

    @IsTest
    static void isBlankWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because text that survives trimming is not blank.');
    }

    @IsTest
    static void isBlankWhenFieldHasSurroundingWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   Populated   '), null);

        // Test
        Boolean result = record.isBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because trimming removes only the surrounding spaces and leaves real content behind.');
    }

    @IsTest
    static void isBlankWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

        // Test
        Boolean result = record.isBlank(Account.NumberOfEmployees);

        // Verify
        Assert.isFalse(result, 'It should be false, because a non-null number is converted to text first, and zero survives trimming.');
    }

    @IsTest
    static void isBlankWhenBooleanFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isBlank(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a Boolean is converted to the text false, which is not whitespace.');
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
    static void isNotBlankWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field value short-circuits the blank check to true before any text is inspected.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsEmptyString() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because an empty string counts as blank for the underlying blank check.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsWhitespace() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = '   '), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isFalse(result, 'It should be false, because a string of only whitespace counts as blank for the underlying blank check.');
    }

    @IsTest
    static void isNotBlankWhenFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Populated'), null);

        // Test
        Boolean result = record.isNotBlank(Contact.Description);

        // Verify
        Assert.isTrue(result, 'It should be true, because a non null value with printable characters fails the blank check and the result is negated.');
    }

    @IsTest
    static void isNotBlankWhenNumberFieldIsZero() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 0), null);

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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.LastName, 'Doe');

        // Verify
        Assert.isTrue(result, 'It should be true, because the new side value and the expected value are the same under Apex Object equality.');
    }

    @IsTest
    static void equalsWhenValueDoesNotMatch() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.LastName, 'Smith');

        // Verify
        Assert.isFalse(result, 'It should be false, because Apex Object equality reports two different text values as unequal.');
    }

    @IsTest
    static void equalsIsCaseInsensitiveForText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.LastName, 'DOE');

        // Verify
        Assert.isTrue(result, 'It should be true, because Apex Object equality on String values ignores letter case.');
    }

    @IsTest
    static void equalsWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.Description, 'Anything');

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field value is never equal to a non null expected value.');
    }

    @IsTest
    static void equalsWhenExpectedValueIsNullAndFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isTrue(result, 'It should be true, because null is compared as a value here, so null matches a null expected value instead of short-circuiting to false.');
    }

    @IsTest
    static void equalsWhenExpectedValueIsNullAndFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Note'), null);

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'It should be false, because a populated field value is never equal to a null expected value.');
    }

    @IsTest
    static void equalsWhenFieldIsEmptyText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.equals(Contact.Description, '');

        // Verify
        Assert.isTrue(result, 'It should be true, because an empty string is kept as an empty string and matches an empty expected value.');
    }

    @IsTest
    static void equalsWhenFieldIsEmptyTextAndExpectedValueIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = ''), null);

        // Test
        Boolean result = record.equals(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'It should be false, because an empty string is a value in its own right and is never coerced to null.');
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
    static void doesNotEqualWhenValueDiffers() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Smith');

        // Verify
        Assert.isTrue(result, 'It should be true, because the comparison is the negation of Object equality, and the two text values are not equal.');
    }

    @IsTest
    static void doesNotEqualWhenValueMatches() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'Doe');

        // Verify
        Assert.isFalse(result, 'It should be false, because the negated equality check rejects a value that matches the stored one.');
    }

    @IsTest
    static void doesNotEqualIsCaseInsensitiveForText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.LastName, 'DOE');

        // Verify
        Assert.isFalse(result, 'It should be false, because Apex Object equality on String values ignores letter case, so its negation is false.');
    }

    @IsTest
    static void doesNotEqualWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, 'Anything');

        // Verify
        Assert.isTrue(result, 'It should be true, because a null field value is never equal to a non null expected value, so the negation holds.');
    }

    @IsTest
    static void doesNotEqualWhenExpectedValueIsNullAndFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotEqual(Contact.Description, null);

        // Verify
        Assert.isFalse(result, 'It should be false, because null matches a null expected value, so the negation of that match is false.');
    }

    @IsTest
    static void doesNotEqualWhenExpectedValueIsNullAndFieldIsPopulated() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Note'), null);

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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because the value is not null and its text form holds the searched fragment.');
    }

    @IsTest
    static void containsWhenValueIsAbsent() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'Goodbye');

        // Verify
        Assert.isFalse(result, 'It should be false, because the text form of the value does not hold the searched fragment.');
    }

    @IsTest
    static void containsWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because the search is guarded by a not null check, so a null value can never hold a fragment.');
    }

    @IsTest
    static void containsIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.contains(Contact.Description, 'world');

        // Verify
        Assert.isFalse(result, 'It should be false, because the underlying text search compares characters with case respected.');
    }

    @IsTest
    static void containsOnNumberFieldUsesTextValue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme', NumberOfEmployees = 1500), null);

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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'Goodbye');

        // Verify
        Assert.isTrue(result, 'It should be true, because the text form of the value does not hold the searched fragment.');
    }

    @IsTest
    static void doesNotContainWhenValueIsPresent() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because the text form of the value does hold the searched fragment.');
    }

    @IsTest
    static void doesNotContainWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because a null value is answered before the text search runs, and a value that is absent holds nothing.');
    }

    @IsTest
    static void doesNotContainIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.doesNotContain(Contact.Description, 'world');

        // Verify
        Assert.isTrue(result, 'It should be true, because the underlying text search respects case, so a differently cased fragment is not found.');
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value begins with the exact prefix that was supplied.');
    }

    @IsTest
    static void startsWithWhenValueIsNotAtTheStart() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because startsWith anchors the match at position zero instead of searching anywhere inside the value.');
    }

    @IsTest
    static void startsWithWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isFalse(result, 'It should be false, because the null-field short-circuit returns false before the value is ever dereferenced.');
    }

    @IsTest
    static void startsWithIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.startsWith(Contact.Description, 'hello');

        // Verify
        Assert.isFalse(result, 'It should be false, because the prefix match is case sensitive.');
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'World');

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value terminates with the exact suffix that was supplied.');
    }

    @IsTest
    static void endsWithWhenValueIsNotAtTheEnd() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'Hello');

        // Verify
        Assert.isFalse(result, 'It should be false, because endsWith anchors the match at the end of the value instead of searching anywhere inside it.');
    }

    @IsTest
    static void endsWithWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'World');

        // Verify
        Assert.isFalse(result, 'It should be false, because the null-field short-circuit returns false before the value is ever dereferenced.');
    }

    @IsTest
    static void endsWithIsCaseSensitive() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe', Description = 'Hello World'), null);

        // Test
        Boolean result = record.endsWith(Contact.Description, 'WORLD');

        // Verify
        Assert.isFalse(result, 'It should be false, because the suffix match is case sensitive.');
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true), null);

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored field value is the Boolean true.');
    }

    @IsTest
    static void isTrueWhenFieldIsFalse() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because isTrue is an equality test against true and false does not satisfy it.');
    }

    @IsTest
    static void isTrueWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal'), null);

        // Test
        Boolean result = record.isTrue(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a field that was never assigned holds null, and null does not equal true.');
    }

    @IsTest
    static void isTrueWhenFieldIsText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'true'), null);

        // Test
        Boolean result = record.isTrue(Contact.LastName);

        // Verify
        Assert.isFalse(result, 'It should be false, because the value is compared as an Object, so even the text true never equals the Boolean true.');
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = false), null);

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored field value is the Boolean false.');
    }

    @IsTest
    static void isFalseWhenFieldIsTrue() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal', IsPrivate = true), null);

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because isFalse is an equality test against false and true does not satisfy it.');
    }

    @IsTest
    static void isFalseWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Deal'), null);

        // Test
        Boolean result = record.isFalse(Opportunity.IsPrivate);

        // Verify
        Assert.isFalse(result, 'It should be false, because a field that was never assigned holds null, and null does not equal false.');
    }

    @IsTest
    static void isFalseWhenFieldIsText() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is strictly above the compared number.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits below the compared number.');
    }

    @IsTest
    static void greaterThanIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is a strict comparison that excludes equality.');
    }

    @IsTest
    static void greaterThanIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is above the compared number.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits below the compared number, so neither the greater nor the equal branch holds.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isTrue(result, 'It should be true, because greaterThanOrEqualTo admits equality alongside being above.');
    }

    @IsTest
    static void greaterThanOrEqualToIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is strictly below the compared number.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits above the compared number.');
    }

    @IsTest
    static void lessThanIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is a strict comparison that excludes equality.');
    }

    @IsTest
    static void lessThanIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is below the compared number.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits above the compared number, so neither the less nor the equal branch holds.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 100);

        // Verify
        Assert.isTrue(result, 'It should be true, because lessThanOrEqualTo admits equality alongside being below.');
    }

    @IsTest
    static void lessThanOrEqualToIntegerWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, 150);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null numeric field makes every comparison return false instead of throwing.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value is widened to Decimal and lands strictly above the compared Double.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value widened to Decimal sits below the compared Double.');
    }

    @IsTest
    static void greaterThanDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is strict and an equal value is not above the threshold.');
    }

    @IsTest
    static void greaterThanDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field makes every numeric comparison return false instead of attempting a conversion.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value sits above the compared Double.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits below the compared Double.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts equality as well as being greater.');
    }

    @IsTest
    static void greaterThanOrEqualToDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field returns false even for the or-equal-to form.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value sits strictly below the compared Double.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits above the compared Double.');
    }

    @IsTest
    static void lessThanDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is strict and an equal value is not below the threshold.');
    }

    @IsTest
    static void lessThanDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field makes every numeric comparison return false instead of attempting a conversion.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value sits below the compared Double.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 2500.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value sits above the compared Double.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 5000.5), null);
        Double value = 5000.5;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts equality as well as being less.');
    }

    @IsTest
    static void lessThanOrEqualToDoubleWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
        Double value = 7500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field returns false even for the or-equal-to form.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void greaterThanDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is strict and equal Decimals are not above each other.');
    }

    @IsTest
    static void greaterThanDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts two Decimals of the same value.');
    }

    @IsTest
    static void greaterThanOrEqualToDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false before the or-equal-to test runs.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void lessThanDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is strict and equal Decimals are not below each other.');
    }

    @IsTest
    static void lessThanDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThan(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored Decimal Amount is below the compared value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1000.50;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored Decimal Amount is above the compared value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = 1500.75), null);
        Decimal value = 1500.75;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts two Decimals of the same value.');
    }

    @IsTest
    static void lessThanOrEqualToDecimalWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Name = 'Test'), null);
        Decimal value = 2000.25;

        // Test
        Boolean result = record.lessThanOrEqualTo(Opportunity.Amount, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset Amount short-circuits the comparison to false before the or-equal-to test runs.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because a later Birthdate is greater when Dates are compared chronologically.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an earlier Birthdate is not greater when Dates are compared chronologically.');
    }

    @IsTest
    static void greaterThanDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is strict and the same calendar day is not later than itself.');
    }

    @IsTest
    static void greaterThanDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false instead of being cast to a Date.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because a later Birthdate satisfies the or-equal-to Date comparison.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an earlier Birthdate fails both halves of the or-equal-to Date comparison.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts the same calendar day.');
    }

    @IsTest
    static void greaterThanOrEqualToDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false before any Date cast happens.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because an earlier Birthdate is less when Dates are compared chronologically.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a later Birthdate is not less when Dates are compared chronologically.');
    }

    @IsTest
    static void lessThanDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is strict and the same calendar day is not earlier than itself.');
    }

    @IsTest
    static void lessThanDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThan(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false instead of being cast to a Date.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because an earlier Birthdate satisfies the or-equal-to Date comparison.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1989, 12, 31);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a later Birthdate fails both halves of the or-equal-to Date comparison.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenDatesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test', Birthdate = Date.newInstance(1990, 1, 1)), null);
        Date value = Date.newInstance(1990, 1, 1);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the or-equal-to form accepts the same calendar day.');
    }

    @IsTest
    static void lessThanOrEqualToDateWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        Date value = Date.newInstance(1990, 1, 2);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.Birthdate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null Birthdate returns false before any Date cast happens.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because a DateTime one hour later is greater when instants are compared.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored DateTime falls before the compared one and the comparison is chronological.');
    }

    @IsTest
    static void greaterThanDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is a strict comparison that excludes an identical DateTime.');
    }

    @IsTest
    static void greaterThanDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field short-circuits the DateTime comparison instead of being ordered against the value.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored DateTime falls after the compared one, which satisfies the greater branch.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an earlier DateTime satisfies neither the greater branch nor the equal branch.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical DateTime still passes.');
    }

    @IsTest
    static void greaterThanOrEqualToDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.greaterThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing DateTime never counts as equal either.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored DateTime falls before the compared one and the comparison is chronological.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the stored DateTime falls after the compared one, which is the opposite order.');
    }

    @IsTest
    static void lessThanDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is a strict comparison that excludes an identical DateTime.');
    }

    @IsTest
    static void lessThanDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThan(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a null field short-circuits the DateTime comparison rather than sorting as the earliest possible moment.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsEarlier() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the stored DateTime falls before the compared one, which satisfies the less branch.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsLater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 11, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a later DateTime satisfies neither the less branch nor the equal branch.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenDateTimesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'Test', EmailBouncedDate = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0)),
            null
        );
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 12, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical DateTime still passes.');
    }

    @IsTest
    static void lessThanOrEqualToDateTimeWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Test'), null);
        DateTime value = DateTime.newInstanceGmt(2024, 1, 1, 13, 0, 0);

        // Test
        Boolean result = record.lessThanOrEqualTo(Contact.EmailBouncedDate, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing DateTime never counts as equal either.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Long overload compares both sides as Decimal and the field value outranks the argument.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value ranks below the argument in the numeric comparison.');
    }

    @IsTest
    static void greaterThanLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because greaterThan is a strict comparison that excludes an equal number.');
    }

    @IsTest
    static void greaterThanLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because an unset numeric field reads as null and the numeric comparison returns false rather than treating null as zero.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value outranks the argument, which satisfies the greater branch.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a lower field value satisfies neither the greater branch nor the equal branch.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical number still passes.');
    }

    @IsTest
    static void greaterThanOrEqualToLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
        Long value = 50L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the null check runs ahead of the inclusive comparison, so a missing number never counts as equal either.');
    }

    @IsTest
    static void greaterThanLongBeyondDoublePrecisionWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L), null);
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L), null);
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThan(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the argument keeps its exact value in the Decimal comparison instead of being rounded down to the nearest Double.');
    }

    @IsTest
    static void greaterThanOrEqualToLongBeyondDoublePrecisionWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740992L), null);
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the Decimal comparison keeps the one-unit gap that a Double would have collapsed into equality.');
    }

    @IsTest
    static void greaterThanOrEqualToLongBeyondDoublePrecisionWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(AnnualRevenue = 9007199254740993L), null);
        Long value = 9007199254740993L;

        // Test
        Boolean result = record.greaterThanOrEqualTo(Account.AnnualRevenue, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Decimal comparison preserves every digit on both sides, so two identical numbers past the Double limit still match.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsLower() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the Long widens to the Decimal comparison and the field value ranks below the argument.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because the field value outranks the argument in the numeric comparison.');
    }

    @IsTest
    static void lessThanLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.lessThan(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because lessThan is a strict comparison that excludes an equal number.');
    }

    @IsTest
    static void lessThanLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
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
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 150L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the field value ranks below the argument, which satisfies the less branch.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsGreater() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 50L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isFalse(result, 'It should be false, because a higher field value satisfies neither the less branch nor the equal branch.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenValuesAreEqual() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(NumberOfEmployees = 100), null);
        Long value = 100L;

        // Test
        Boolean result = record.lessThanOrEqualTo(Account.NumberOfEmployees, value);

        // Verify
        Assert.isTrue(result, 'It should be true, because the inclusive comparison admits equality, so an identical number still passes.');
    }

    @IsTest
    static void lessThanOrEqualToLongWhenFieldIsNull() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Test'), null);
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
    static void greaterThanComparesTheOldRecordOnDelete() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Account(NumberOfEmployees = 100));

        // Test
        Boolean result = record.greaterThan(Account.NumberOfEmployees, 50);

        // Verify
        Assert.isTrue(result, 'It should be true, because the new-side lookup falls back to the old record when there is no new record, which is the delete shape.');
    }

    @IsTest
    static void isRecordTypeEqualWhenSObjectHasNoRecordTypes() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new User(), null);
        String errorMessage = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (TriggerHandler.TriggerHandlerException e) {
            errorMessage = e.getMessage();
        }

        // Verify
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            errorMessage,
            'It should be refused with a TriggerHandlerException, because User carries nothing beyond the Master record type.'
        );
    }

    @IsTest
    static void isRecordTypeNotEqualWhenSObjectHasNoRecordTypes() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new User(), null);
        String errorMessage = null;

        // Test
        try {
            record.isRecordTypeNotEqual('Standard');
        } catch (TriggerHandler.TriggerHandlerException e) {
            errorMessage = e.getMessage();
        }

        // Verify
        Assert.areEqual(
            'User has no record types, so isRecordTypeNotEqual cannot be used on it.',
            errorMessage,
            'It should be refused with a TriggerHandlerException naming the negated check, because the same guard protects both checks.'
        );
    }

    @IsTest
    static void isRecordTypeEqualOnDeleteRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new User(LastName = 'Old'));
        String errorMessage = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (TriggerHandler.TriggerHandlerException e) {
            errorMessage = e.getMessage();
        }

        // Verify
        Assert.areEqual(
            'User has no record types, so isRecordTypeEqual cannot be used on it.',
            errorMessage,
            'It should be refused, because the SObject type is taken from the old record when the new record is null, so the guard still applies in delete shape.'
        );
    }

    @IsTest
    static void isRecordTypeNotEqualOnDeleteRecord() {
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new User(LastName = 'Old'));
        String errorMessage = null;

        // Test
        try {
            record.isRecordTypeNotEqual('Standard');
        } catch (TriggerHandler.TriggerHandlerException e) {
            errorMessage = e.getMessage();
        }

        // Verify
        Assert.areEqual(
            'User has no record types, so isRecordTypeNotEqual cannot be used on it.',
            errorMessage,
            'It should be refused, because the negated check reads the SObject type from the old record as well.'
        );
    }

    @IsTest
    static void isRecordTypeEqualNamesTheSObjectTypeInTheMessage() {
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Group(), null);
        String errorMessage = null;

        // Test
        try {
            record.isRecordTypeEqual('Standard');
        } catch (TriggerHandler.TriggerHandlerException e) {
            errorMessage = e.getMessage();
        }

        // Verify
        Assert.areEqual(
            'Group has no record types, so isRecordTypeEqual cannot be used on it.',
            errorMessage,
            'It should name Group, because the message is built from the SObject type of the record.'
        );
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
    static void newSObjectIsTheInstanceThatWasPassedIn() {
        Contact newContact = new Contact(LastName = 'New');
        TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(newContact, null);
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
    static void getIdFallsBackToTheOldRecordIdWhenNewRecordIsNull() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.DeleteRecord record = new TriggerHandler.TriggerRecord(null, new Contact(Id = contactId, LastName = 'Old'));

        // Test
        Id result = record.getId();

        // Verify
        Assert.areEqual(contactId, result, 'It should be the old record id, because getId falls back to the old record when the new record is null.');
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
        Assert.areEqual(firstContactId, result, 'It should be the new record id, because the fallback to the old record applies only when the new record is missing.');
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
    static void putDoesNotTouchTheOldRecord() {
        TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', Title = 'Analyst'), new Contact(LastName = 'Old', Title = 'Analyst'));

        // Test
        record.put(Contact.Title, 'Manager');

        // Verify
        Assert.areEqual('Analyst', record.getOldSObject().get(Contact.Title), 'It should stay Analyst, because put writes to the new record only and never reaches the old one.');
    }

    @IsTest
    static void getNewParentReturnsTheEnrichedParent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Account parentAccount = new Account(Id = accountId, Name = 'Parent');
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', parentAccount);

        // Test
        SObject result = record.getNewParent('Account');

        // Verify
        Assert.areEqual(parentAccount, result, 'It should be the enriched parent, because the new side returns the record stored under that relationship name.');
    }

    @IsTest
    static void getOldParentReturnsTheEnrichedParent() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Account priorParentAccount = new Account(Id = firstAccountId, Name = 'Prior Parent');
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = secondAccountId),
            new Contact(LastName = 'Old', AccountId = firstAccountId)
        );
        record.enrichOld('Account', priorParentAccount);

        // Test
        SObject result = record.getOldParent('Account');

        // Verify
        Assert.areEqual(priorParentAccount, result, 'It should be the enriched prior parent, because the old side returns the record stored under that relationship name.');
    }

    @IsTest
    static void getOldParentReturnsThePriorParentWhenBothSidesAreEnriched() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );
        record.enrichOld('Account', new Account(Id = secondAccountId, Name = 'Prior Parent'));
        record.enrichNew('Account', new Account(Id = firstAccountId, Name = 'Current Parent'));

        // Test
        SObject result = record.getOldParent('Account');

        // Verify
        Assert.areEqual(
            'Prior Parent',
            result.get(Account.Name),
            'It should be Prior Parent, because the old side keeps a relationship map of its own, separate from the new side.'
        );
    }

    @IsTest
    static void getNewParentReturnsTheCurrentParentWhenBothSidesAreEnriched() {
        Id firstAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id secondAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = firstAccountId),
            new Contact(LastName = 'Old', AccountId = secondAccountId)
        );
        record.enrichNew('Account', new Account(Id = firstAccountId, Name = 'Current Parent'));
        record.enrichOld('Account', new Account(Id = secondAccountId, Name = 'Prior Parent'));

        // Test
        SObject result = record.getNewParent('Account');

        // Verify
        Assert.areEqual(
            'Current Parent',
            result.get(Account.Name),
            'It should be Current Parent, because the new side keeps a relationship map of its own, separate from the old side.'
        );
    }

    @IsTest
    static void getNewParentIsNullForARelationshipThatWasNotEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewParent('ReportsTo');

        // Verify
        Assert.isNull(result, 'It should be null, because only the enriched relationship names are stored, so every other name misses the map.');
    }

    @IsTest
    static void getOldParentIsNullForARelationshipThatWasNotEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.enrichOld('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getOldParent('ReportsTo');

        // Verify
        Assert.isNull(result, 'It should be null, because only the enriched relationship names are stored on the old side, so every other name misses the map.');
    }

    @IsTest
    static void getOldParentIsNullWhenOnlyTheNewSideWasEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getOldParent('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because enrichNew writes to the new side map only and leaves the old side map empty.');
    }

    @IsTest
    static void getNewParentIsNullWhenOnlyTheOldSideWasEnriched() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'New', AccountId = accountId),
            new Contact(LastName = 'Old', AccountId = accountId)
        );
        record.enrichOld('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewParent('Account');

        // Verify
        Assert.isNull(result, 'It should be null, because enrichOld writes to the old side map only and leaves the new side map empty.');
    }

    @IsTest
    static void getNewParentIsCaseSensitive() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New', AccountId = accountId), null);
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Parent'));

        // Test
        SObject result = record.getNewParent('account');

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
        SObject result = record.getNewParent('Account');

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
        SObject result = record.getNewParent('Account');

        // Verify
        Assert.areEqual(
            'Parent',
            result.get(Account.Name),
            'It should be Parent, because each relationship is stored under its own name, so enriching another one later does not disturb it.'
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
    static void withReturnsTheSameSelection() {
        TriggerHandler.ParentFields selection = TriggerHandler.ParentFields.with(Account.Name);

        // Test
        TriggerHandler.ParentFields chainedSelection = selection.with(Account.Industry);

        // Verify
        Assert.isTrue(chainedSelection === selection, 'It should be the same selection, because with() mutates the selection in place and returns this.');
    }

    @IsTest
    static void withRelationshipReturnsTheSameSelection() {
        TriggerHandler.ParentFields selection = TriggerHandler.ParentFields.with(Account.Name);

        // Test
        TriggerHandler.ParentFields chainedSelection = selection.with('Parent', Account.Industry);

        // Verify
        Assert.isTrue(chainedSelection === selection, 'It should be the same selection, because the relationship overload also mutates the selection in place and returns this.');
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
    static void fieldSelectionPropertyDoesNotShareFieldsBetweenReads() {
        TriggerHandler.ParentFields.with(Account.Name, Account.Industry);

        // Test
        List<String> fields = TriggerHandler.ParentFields.getFields();

        // Verify
        Assert.areEqual(
            new List<String>(),
            fields,
            'It should be empty, because the property getter returns a new selection on every read, so fields added through an earlier read are not visible.'
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
    static void providedRecordsGetFirstReturnsTheFirstRecordGroupedUnderTheKey() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Opportunity firstOpportunity = new Opportunity(Name = 'First', AccountId = accountId);
        Opportunity secondOpportunity = new Opportunity(Name = 'Second', AccountId = accountId);
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ firstOpportunity, secondOpportunity });
        related.groupUnderKey(accountId, firstOpportunity);
        related.groupUnderKey(accountId, secondOpportunity);

        // Test
        SObject result = related.getFirstWhereKeyEquals(accountId);

        // Verify
        Assert.areEqual(firstOpportunity, result, 'It should be First, because getFirstWhereKeyEquals returns the record grouped first under the key.');
    }

    @IsTest
    static void providedRecordsGetAllReturnsEveryRecordGroupedUnderTheKey() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Opportunity firstOpportunity = new Opportunity(Name = 'First', AccountId = accountId);
        Opportunity secondOpportunity = new Opportunity(Name = 'Second', AccountId = accountId);
        Opportunity otherOpportunity = new Opportunity(Name = 'Other', AccountId = TriggerHandler.IdGenerator.get(Account.SObjectType));
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ firstOpportunity, secondOpportunity, otherOpportunity });
        related.groupUnderKey(accountId, firstOpportunity);
        related.groupUnderKey(accountId, secondOpportunity);
        related.groupUnderKey(otherOpportunity.AccountId, otherOpportunity);

        // Test
        List<SObject> result = related.getAllWhereKeyEquals(accountId);

        // Verify
        Assert.areEqual(
            new List<SObject>{ firstOpportunity, secondOpportunity },
            result,
            'It should hold First and Second in grouping order, because only the records grouped under that key are returned.'
        );
    }

    @IsTest
    static void providedRecordsGetAllForAnUnknownKeyIsEmpty() {
        Opportunity opportunity = new Opportunity(Name = 'First', AccountId = TriggerHandler.IdGenerator.get(Account.SObjectType));
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ opportunity });
        related.groupUnderKey(opportunity.AccountId, opportunity);

        // Test
        List<SObject> result = related.getAllWhereKeyEquals(TriggerHandler.IdGenerator.get(Account.SObjectType));

        // Verify
        Assert.areEqual(new List<SObject>(), result, 'It should be an empty list rather than null, because no record is grouped under that key.');
    }

    @IsTest
    static void providedRecordsGetFirstForAnUnknownKeyIsNull() {
        Opportunity opportunity = new Opportunity(Name = 'First', AccountId = TriggerHandler.IdGenerator.get(Account.SObjectType));
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ opportunity });
        related.groupUnderKey(opportunity.AccountId, opportunity);

        // Test
        SObject result = related.getFirstWhereKeyEquals(TriggerHandler.IdGenerator.get(Account.SObjectType));

        // Verify
        Assert.isNull(result, 'It should be null, because no record is grouped under that key.');
    }

    @IsTest
    static void providedRecordsMatchesANumericKeyAgainstItsTextForm() {
        Opportunity opportunity = new Opportunity(Name = 'First');
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ opportunity });
        related.groupUnderKey('42', opportunity);

        // Test
        SObject result = related.getFirstWhereKeyEquals(42);

        // Verify
        Assert.areEqual(opportunity, result, 'It should be the record grouped under 42, because the lookup key is turned into text with String.valueOf before it is matched.');
    }

    @IsTest
    static void providedRecordsNullKeyIsNotGrouped() {
        Opportunity orphan = new Opportunity(Name = 'Orphan');
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ orphan });
        related.groupUnderKey(null, orphan);

        // Test
        List<SObject> result = related.getAllWhereKeyEquals(null);

        // Verify
        Assert.areEqual(new List<SObject>(), result, 'It should be empty, because a record with a null key is left out of the key groups.');
    }

    @IsTest
    static void providedRecordsGetRecordsKeepsUngroupedRecords() {
        Opportunity orphan = new Opportunity(Name = 'Orphan');
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ orphan });
        related.groupUnderKey(null, orphan);

        // Test
        List<SObject> result = related.getRecords();

        // Verify
        Assert.areEqual(new List<Opportunity>{ orphan }, result, 'It should hold the orphan, because getRecords returns every record it was built from, grouped or not.');
    }

    @IsTest
    static void providedRecordsWithOnlyUngroupedRecordsIsNotEmpty() {
        Opportunity orphan = new Opportunity(Name = 'Orphan');
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ orphan });
        related.groupUnderKey(null, orphan);

        // Test
        Boolean result = related.isEmpty();

        // Verify
        Assert.isFalse(result, 'It should not be empty, because isEmpty counts every record it was built from, grouped or not.');
    }

    @IsTest
    static void providedRecordsBuiltFromANullListReturnsAnEmptyList() {
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(null);

        // Test
        List<SObject> result = related.getRecords();

        // Verify
        Assert.areEqual(new List<SObject>(), result, 'It should be an empty list rather than null, because a null query result is replaced with an empty list.');
    }

    @IsTest
    static void getRelatedReturnsTheRecordsRegisteredUnderTheName() {
        TriggerHandler.ProvidedRecords openOpportunities = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ new Opportunity(Name = 'Open') });
        TriggerHandler.ProvidedRecords closedOpportunities = new TriggerHandler.ProvidedRecords(new List<Opportunity>{ new Opportunity(Name = 'Closed') });
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ 'openOpportunities' => openOpportunities, 'closedOpportunities' => closedOpportunities });

        // Test
        TriggerHandler.RelatedRecords result = record.getRelated('openOpportunities');

        // Verify
        Assert.areEqual(openOpportunities, result, 'It should be the related records registered under that name.');
    }

    @IsTest
    static void getRelatedThrowsForAnUnknownName() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>());
        String errorMessage = null;

        // Test
        try {
            record.getRelated('missing');
        } catch (TriggerHandler.TriggerHandlerException e) {
            errorMessage = e.getMessage();
        }

        // Verify
        Assert.areEqual(
            'No related records provider is registered under missing. Return it from the RelatedQuery method of the context first.',
            errorMessage,
            'It should be refused with a TriggerHandlerException naming the missing provider, because a wrong provider name is a contract violation.'
        );
    }

    @IsTest
    static void getRelatedThrowsBeforeAnyProviderMapWasSet() {
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        TriggerHandler.TriggerHandlerException thrown = null;

        // Test
        try {
            record.getRelated('openOpportunities');
        } catch (TriggerHandler.TriggerHandlerException e) {
            thrown = e;
        }

        // Verify
        Assert.isNotNull(thrown, 'It should be thrown, because a fresh record carries an empty provider map.');
    }

    @IsTest
    static void setProvidedRecordsReplacesThePreviousMap() {
        TriggerHandler.ProvidedRecords related = new TriggerHandler.ProvidedRecords(new List<Opportunity>());
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'New'), null);
        record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ 'first' => related });
        record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ 'second' => related });
        TriggerHandler.TriggerHandlerException thrown = null;

        // Test
        try {
            record.getRelated('first');
        } catch (TriggerHandler.TriggerHandlerException e) {
            thrown = e;
        }

        // Verify
        Assert.isNotNull(thrown, 'It should be thrown, because setProvidedRecords replaces the whole map, so a name from the earlier map is gone.');
    }

    @IsTest
    static void updateRecordsGetIdsSkipsRecordsWithoutAnId() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'Saved'), new Contact(Id = contactId, LastName = 'Old')),
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'Unsaved'), null)
            }
        );

        // Test
        Set<Id> ids = records.getIds();

        // Verify
        Assert.areEqual(new Set<Id>{ contactId }, ids, 'It should hold the saved id only, because nulls are dropped.');
    }

    @IsTest
    static void updateRecordsSizeCountsEveryRecord() {
        Id contactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(Id = contactId, LastName = 'Saved'), new Contact(Id = contactId, LastName = 'Old')),
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'Unsaved'), null)
            }
        );

        // Test
        Integer result = records.size();

        // Verify
        Assert.areEqual(2, result, 'It should be 2, because size counts every trigger row, including one without an id.');
    }

    @IsTest
    static void updateRecordsGetIdsOfReadsTheNewRow() {
        Id oldAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id newAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', AccountId = newAccountId), new Contact(LastName = 'A', AccountId = oldAccountId))
            }
        );

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ newAccountId }, ids, 'It should hold the new account id, because getIdsOf reads the new row.');
    }

    @IsTest
    static void updateRecordsGetIdsOfDropsNulls() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), new Contact(LastName = 'A', AccountId = accountId)),
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'B'), new Contact(LastName = 'B'))
            }
        );

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ accountId }, ids, 'It should hold only the set account id, because a row without a value contributes nothing.');
    }

    @IsTest
    static void updateRecordsGetOldIdsOfReadsTheOldRow() {
        Id oldAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id newAccountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', AccountId = newAccountId), new Contact(LastName = 'A', AccountId = oldAccountId))
            }
        );

        // Test
        Set<Id> oldIds = records.getOldIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ oldAccountId }, oldIds, 'It should hold the old account id, because getOldIdsOf reads the old row.');
    }

    @IsTest
    static void updateRecordsGetOldValuesOfReadsTheOldRow() {
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(new Contact(LastName = 'Current'), new Contact(LastName = 'Previous')) }
        );

        // Test
        Set<String> oldValues = records.getOldValuesOf(Contact.LastName);

        // Verify
        Assert.areEqual(new Set<String>{ 'Previous' }, oldValues, 'It should hold Previous, because getOldValuesOf reads the old row.');
    }

    @IsTest
    static void deleteRecordsGetIdsOfReadsTheOldRow() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.DeleteRecords records = new TriggerHandler.DeleteTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'Gone', AccountId = accountId)) }
        );

        // Test
        Set<Id> ids = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ accountId }, ids, 'It should hold the account id, because delete collections read the old row.');
    }

    @IsTest
    static void undeleteRecordsGetValuesOfStringifiesNonStringValues() {
        TriggerHandler.UndeleteRecords records = new TriggerHandler.UndeleteTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(new Opportunity(Name = 'One', Amount = 100), null) }
        );

        // Test
        Set<String> amounts = records.getValuesOf(Opportunity.Amount);

        // Verify
        Assert.areEqual(new Set<String>{ '100' }, amounts, 'It should hold 100 as text, because values go through String.valueOf.');
    }

    @IsTest
    static void undeleteRecordsGetValuesOfDropsNulls() {
        TriggerHandler.UndeleteRecords records = new TriggerHandler.UndeleteTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', Title = 'Manager'), null),
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'B'), null)
            }
        );

        // Test
        Set<String> titles = records.getValuesOf(Contact.Title);

        // Verify
        Assert.areEqual(new Set<String>{ 'Manager' }, titles, 'It should hold only Manager, because a row without a value contributes nothing.');
    }

    @IsTest
    static void insertRecordsGetIdsOfRelationshipReadsTheEnrichedParent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id ownerId = TriggerHandler.IdGenerator.get(User.SObjectType);
        TriggerHandler.TriggerRecord enriched = new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), null);
        enriched.enrichNew('Account', new Account(Id = accountId, OwnerId = ownerId));
        TriggerHandler.InsertRecords records = new TriggerHandler.InsertTriggerRecords(new List<TriggerHandler.TriggerRecord>{ enriched });

        // Test
        Set<Id> ownerIds = records.getIdsOf('Account', Account.OwnerId);

        // Verify
        Assert.areEqual(new Set<Id>{ ownerId }, ownerIds, 'It should hold the owner id of the enriched parent, because the relationship name is the one getNewParent takes.');
    }

    @IsTest
    static void updateRecordsGetValuesOfRelationshipWalksADottedPath() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Account parentAccount = new Account(Id = accountId, Name = 'Child Corp');
        parentAccount.putSObject('Parent', new Account(Name = 'Holding Corp'));
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'A', AccountId = accountId),
            new Contact(LastName = 'A', AccountId = accountId)
        );
        record.enrichNew('Account', parentAccount);
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(new List<TriggerHandler.TriggerRecord>{ record });

        // Test
        Set<String> names = records.getValuesOf('Account.Parent', Account.Name);

        // Verify
        Assert.areEqual(new Set<String>{ 'Holding Corp' }, names, 'It should hold the grandparent name, because segments after the first are read with getSObject.');
    }

    @IsTest
    static void updateRecordsGetOldValuesOfRelationshipReadsTheOldParent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'A', AccountId = accountId),
            new Contact(LastName = 'A', AccountId = accountId)
        );
        record.enrichNew('Account', new Account(Id = accountId, Name = 'Current'));
        record.enrichOld('Account', new Account(Id = accountId, Name = 'Previous'));
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(new List<TriggerHandler.TriggerRecord>{ record });

        // Test
        Set<String> oldNames = records.getOldValuesOf('Account', Account.Name);

        // Verify
        Assert.areEqual(new Set<String>{ 'Previous' }, oldNames, 'It should hold Previous, because getOldValuesOf reads the old related record.');
    }

    @IsTest
    static void updateRecordsGetOldIdsOfRelationshipReadsTheOldParent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        Id currentOwnerId = TriggerHandler.IdGenerator.get(User.SObjectType);
        Id previousOwnerId = TriggerHandler.IdGenerator.get(User.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
            new Contact(LastName = 'A', AccountId = accountId),
            new Contact(LastName = 'A', AccountId = accountId)
        );
        record.enrichNew('Account', new Account(Id = accountId, OwnerId = currentOwnerId));
        record.enrichOld('Account', new Account(Id = accountId, OwnerId = previousOwnerId));
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(new List<TriggerHandler.TriggerRecord>{ record });

        // Test
        Set<Id> oldOwnerIds = records.getOldIdsOf('Account', Account.OwnerId);

        // Verify
        Assert.areEqual(new Set<Id>{ previousOwnerId }, oldOwnerIds, 'It should hold the previous owner id, because getOldIdsOf with a relationship reads the old parent.');
    }

    @IsTest
    static void deleteRecordsGetValuesOfRelationshipReadsTheOldParent() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(null, new Contact(LastName = 'A', AccountId = accountId));
        record.enrichOld('Account', new Account(Id = accountId, Name = 'Previous'));
        TriggerHandler.DeleteRecords records = new TriggerHandler.DeleteTriggerRecords(new List<TriggerHandler.TriggerRecord>{ record });

        // Test
        Set<String> names = records.getValuesOf('Account', Account.Name);

        // Verify
        Assert.areEqual(new Set<String>{ 'Previous' }, names, 'It should hold Previous, because delete collections read the old related record.');
    }

    @IsTest
    static void insertRecordsUndeclaredRelationshipYieldsAnEmptySet() {
        TriggerHandler.InsertRecords records = new TriggerHandler.InsertTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{
                new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', AccountId = TriggerHandler.IdGenerator.get(Account.SObjectType)), null)
            }
        );

        // Test
        Set<Id> ids = records.getIdsOf('Account', Account.OwnerId);

        // Verify
        Assert.isTrue(ids.isEmpty(), 'It should be empty, because a relationship that was not enriched contributes nothing.');
    }

    @IsTest
    static void collectionsReturnFreshSets() {
        Id accountId = TriggerHandler.IdGenerator.get(Account.SObjectType);
        TriggerHandler.InsertRecords records = new TriggerHandler.InsertTriggerRecords(
            new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(new Contact(LastName = 'A', AccountId = accountId), null) }
        );

        // Test
        Set<Id> first = records.getIdsOf(Contact.AccountId);
        first.clear();
        Set<Id> second = records.getIdsOf(Contact.AccountId);

        // Verify
        Assert.areEqual(new Set<Id>{ accountId }, second, 'It should still hold the account id, because every call builds a new set.');
    }

    @IsTest
    static void insertRecordsGetRecordsReturnsTheRecordsInTriggerOrder() {
        TriggerHandler.TriggerRecord firstRecord = new TriggerHandler.TriggerRecord(new Contact(LastName = 'A'), null);
        TriggerHandler.TriggerRecord secondRecord = new TriggerHandler.TriggerRecord(new Contact(LastName = 'B'), null);
        TriggerHandler.InsertRecords records = new TriggerHandler.InsertTriggerRecords(new List<TriggerHandler.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerHandler.InsertRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerHandler.InsertRecord>{ firstRecord, secondRecord }, result, 'It should hold both records in trigger order.');
    }

    @IsTest
    static void updateRecordsGetRecordsReturnsTheRecordsInTriggerOrder() {
        Id firstContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        Id secondContactId = TriggerHandler.IdGenerator.get(Contact.SObjectType);
        TriggerHandler.TriggerRecord firstRecord = new TriggerHandler.TriggerRecord(
            new Contact(Id = firstContactId, LastName = 'A'),
            new Contact(Id = firstContactId, LastName = 'A')
        );
        TriggerHandler.TriggerRecord secondRecord = new TriggerHandler.TriggerRecord(
            new Contact(Id = secondContactId, LastName = 'B'),
            new Contact(Id = secondContactId, LastName = 'B')
        );
        TriggerHandler.UpdateRecords records = new TriggerHandler.UpdateTriggerRecords(new List<TriggerHandler.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerHandler.UpdateRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerHandler.UpdateRecord>{ firstRecord, secondRecord }, result, 'It should hold both records in trigger order.');
    }

    @IsTest
    static void deleteRecordsGetRecordsReturnsTheRecordsInTriggerOrder() {
        TriggerHandler.TriggerRecord firstRecord = new TriggerHandler.TriggerRecord(null, new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'A'));
        TriggerHandler.TriggerRecord secondRecord = new TriggerHandler.TriggerRecord(null, new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'B'));
        TriggerHandler.DeleteRecords records = new TriggerHandler.DeleteTriggerRecords(new List<TriggerHandler.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerHandler.DeleteRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerHandler.DeleteRecord>{ firstRecord, secondRecord }, result, 'It should hold both records in trigger order.');
    }

    @IsTest
    static void undeleteRecordsGetRecordsReturnsTheRecordsInTriggerOrder() {
        TriggerHandler.TriggerRecord firstRecord = new TriggerHandler.TriggerRecord(new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'A'), null);
        TriggerHandler.TriggerRecord secondRecord = new TriggerHandler.TriggerRecord(new Contact(Id = TriggerHandler.IdGenerator.get(Contact.SObjectType), LastName = 'B'), null);
        TriggerHandler.UndeleteRecords records = new TriggerHandler.UndeleteTriggerRecords(new List<TriggerHandler.TriggerRecord>{ firstRecord, secondRecord });

        // Test
        List<TriggerHandler.UndeleteRecord> result = records.getRecords();

        // Verify
        Assert.areEqual(new List<TriggerHandler.UndeleteRecord>{ firstRecord, secondRecord }, result, 'It should hold both records in trigger order.');
    }

    @IsTest
    static void getTriggerRecordsFromPairsTheNewAndOldRecordAtTheSamePosition() {
        List<Contact> newContacts = new List<Contact>{ new Contact(LastName = 'First'), new Contact(LastName = 'Second') };
        List<Contact> oldContacts = new List<Contact>{ new Contact(LastName = 'First Before'), new Contact(LastName = 'Second Before') };

        // Test
        List<TriggerHandler.TriggerRecord> records = TriggerHandler.getTriggerRecordsFrom(newContacts, oldContacts);

        // Verify
        Assert.isTrue(
            records[1].isChangedFromTo(Contact.LastName, 'Second Before', 'Second'),
            'It should pair Second with Second Before, because each trigger record joins the new and the old record at the same position.'
        );
    }
}
