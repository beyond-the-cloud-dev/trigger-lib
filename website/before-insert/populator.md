---
template: role
context: BeforeInsert
interface: Populator
description: Set, default, derive or normalize fields on records before insert with record.put, with no DML and no second save.
---

# BeforeInsert.Populator

A Populator sets, defaults, derives or normalizes (stamps) fields on records in **before insert**, with `record.put`, so the values save with the record: no DML, no second save. It can read parent (lookup) fields and other records declared through add-ons, and can be skipped or bypassed on a condition.

<!--@include: @/_parts/generated/before-insert/populator/available-in.md-->

## When to Use {#when-to-use}

- Default a field when it is blank, such as a close date or a lead source.
- Derive a field from other fields of the same record, such as a rating from annual revenue.
- Normalize input, such as trimming and lowercasing an email.
- Copy values from the parent record, with a [ParentQuery](/before-insert/add-ons/parent-query).

Use a [Validator](/before-insert/validator) instead to reject a record, and an [AfterInsert.Writer](/after-insert/writer) to change other records or when you need the new record's Id.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/populator/signature.md-->

<!--@include: @/_parts/generated/before-insert/populator/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/populator/skeleton.md-->

<<< @/../examples/main/default/classes/contact/before-insert/populator/ContactEmailNormalizationPopulator.cls [Minimal]

<<< @/../examples/main/default/classes/account/before-insert/populator/AccountRatingPopulator.cls [Derive from a number]

<<< @/../examples/main/default/classes/opportunity/before-insert/populator/OpportunityCloseDatePopulator.cls [Default when blank]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/populator.md-->

## Register {#register}

<!--@include: @/_parts/generated/before-insert/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/before-insert/accessors.md-->

`getId()` is null here, so key nothing by the record Id.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/populator/works-with.md-->

## Gotchas {#gotchas}

- **An exception fails the whole chunk, unless you opt out.** Without ContinueOnError, an exception in the predicate or the action fails every record in the chunk and, with all-or-none DML (the default for `insert`), the whole statement, so values already put on earlier records never save. With [ContinueOnError](/before-insert/add-ons/continue-on-error), the exception is logged and swallowed, the handler skips its remaining records, the values already put stay, and the save goes on. To fail only one record, catch the exception and call `record.getNewSObject().addError(…)` on it. See [one record, not the whole save](/guide/error-handling#one-record).
- **The row's relationship fields are empty.** `((Contact) record.getNewSObject()).Account.Name` throws a `NullPointerException` in before insert, because the row carries only `AccountId`. Declare a [ParentQuery](/before-insert/add-ons/parent-query) and read `record.getNewParent('Account')`.

<!--@include: @/_parts/roles/dml-guard.md-->

<!--@include: @/_parts/roles/one-role.md#before-->

## Test It {#test}

Call the predicate and the action directly with a `TriggerHandler.TriggerRecord` built from an in-memory row. Pass `null` as the old row: an insert has none.

::: code-group

```apex [Predicate]
@IsTest
static void populateOnBeforeInsertWhenEmailBlank() {
    // Setup
    TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(Email = ' '), null);

    // Test
    Boolean result = new ContactEmailNormalizationPopulator().populateOnBeforeInsertWhen(record);

    // Verify
    Assert.isFalse(result, 'A blank email should not be normalized.');
}
```

```apex [Action]
@IsTest
static void populateOnBeforeInsertLowercasesEmail() {
    // Setup
    Contact newContact = new Contact(Email = ' Jane.Doe@Example.com ');

    // Test
    new ContactEmailNormalizationPopulator().populateOnBeforeInsert(new TriggerHandler.TriggerRecord(newContact, null));

    // Verify
    Assert.areEqual('jane.doe@example.com', newContact.Email, 'The email should be trimmed and lowercased.');
}
```

:::

No DML and no trigger: `put` writes to the row you passed in. More in [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/populator/other-contexts.md-->

## See Also {#see-also}

- [BeforeInsert](/before-insert/) overview and [Record API in BeforeInsert](/before-insert/record-api).
- [BeforeInsert.Validator](/before-insert/validator) to reject records instead.
- [BeforeUpdate.Populator](/before-update/populator): the same role when records change.
- [Add-ons in BeforeInsert](/before-insert/add-ons/).
