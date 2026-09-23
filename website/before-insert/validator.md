---
template: role
context: BeforeInsert
interface: Validator
description: Reject records before insert with a record-level or field-level error message, like a validation rule written in Apex.
---

# BeforeInsert.Validator

A Validator rejects records in **before insert** with an error message, on the record or on a field, like a validation rule written in Apex. It can check parent (lookup) fields and other records declared through add-ons, such as a duplicate check, and can be skipped or bypassed on a condition.

<!--@include: @/_parts/generated/before-insert/validator/available-in.md-->

## When to Use {#when-to-use}

- Block a save when a field is missing or out of range, such as a negative amount or a birthdate in the future.
- Block a save based on the parent record, with a [ParentQuery](/before-insert/add-ons/parent-query).
- Block a save based on records already in the database, such as an existing contact with the same email, with a [RelatedQuery](/before-insert/add-ons/related-query).

Use a [Populator](/before-insert/populator) instead to fix a value rather than reject it, and a Populator with a [Finalizer](/before-insert/add-ons/finalizer) to compare records of the same save with each other.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/validator/signature.md-->

<!--@include: @/_parts/generated/before-insert/validator/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/validator/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-insert/validator/OpportunityAmountValidator.cls [Minimal]

<<< @/../examples/main/default/classes/account/before-insert/validator/AccountCustomerDataValidator.cls [Two field errors]

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactBirthdateValidator.cls [Dates]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/validator.md-->

## Register {#register}

<!--@include: @/_parts/generated/before-insert/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/before-insert/accessors.md-->

- The predicate receives an `InsertRecord` and the error method a `RejectableInsertRecord`. Both wrap the same `Trigger.new` row, so the error lands on the record being inserted.
- With all-or-none DML (the default for `insert`), one rejected record fails the whole statement. With `Database.insert(records, false)`, only the rejected records fail and the others are saved.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/validator/works-with.md-->

## Gotchas {#gotchas}

- **Field-level errors.** `record.addError(Opportunity.Amount, message)` in `addErrorOnBeforeInsert` shows the message next to the field. The `[Two field errors]` example also calls `record.addError(Account.BillingCountry, …)`: Billing Country is part of the compound billing address, where this form loses the field attribution (tested on Billing Street and Billing City), so that message shows at record level. To keep it on the field, call `((Account) record.getNewSObject()).BillingCountry.addError(…)` in the error method instead.
- **Keep the predicate and the error method in step.** A branch of `addErrorOnBeforeInsert` that returns without calling `addError` fails the whole chunk, ContinueOnError or not (see [How It Runs](#how-it-runs)). The `[Two field errors]` example checks the same two fields in both methods, so every qualified record gets at least one error.
- **Translated messages.** Pass a custom label: `record.addError(Opportunity.Amount, System.Label.AmountMustBePositive)`.

<!--@include: @/_parts/roles/dml-guard.md-->

<!--@include: @/_parts/roles/one-role.md#before-->

## Test It {#test}

Call both methods directly with a `TriggerHandler.TriggerRecord` built from an in-memory row, and pass `null` as the old row. An error added in a test stays on the row, where `getErrors()` reads it.

::: code-group

```apex [Predicate]
@IsTest
static void errorShouldBeAttachedOnBeforeInsertWhenAmountNegative() {
    // Setup
    TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Amount = -100), null);

    // Test
    Boolean result = new OpportunityAmountValidator().errorShouldBeAttachedOnBeforeInsertWhen(record);

    // Verify
    Assert.isTrue(result, 'A negative amount should be rejected.');
}
```

```apex [Error method]
@IsTest
static void addErrorOnBeforeInsertOnAmount() {
    // Setup
    Opportunity newOpportunity = new Opportunity(Amount = -100);

    // Test
    new OpportunityAmountValidator().addErrorOnBeforeInsert(new TriggerHandler.TriggerRecord(newOpportunity, null));

    // Verify
    Assert.areEqual(new List<String>{ 'Amount' }, newOpportunity.getErrors()[0].getFields(), 'The error should be attached to Amount.');
}
```

:::

More in [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/validator/other-contexts.md-->

## See Also {#see-also}

- [BeforeInsert](/before-insert/) overview and [Record API in BeforeInsert](/before-insert/record-api).
- [BeforeInsert.Populator](/before-insert/populator) to fix values instead.
- [BeforeUpdate.Validator](/before-update/validator): the same role when records change.
- [Errors & Logging](/guide/error-handling).
