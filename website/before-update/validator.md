---
template: role
context: BeforeUpdate
interface: Validator
description: BeforeUpdate.Validator rejects an update with a record-level or field-level error before it is saved, for example a forbidden transition or a value that must not be cleared.
---

# BeforeUpdate.Validator

Reject (block, prevent, veto, validate) an update with an error message in **before update**, before it is saved: a forbidden stage or type transition, a value that must not be cleared, or a move between parents.

<!--@include: @/_parts/generated/before-update/validator/available-in.md-->

## When to Use {#when-to-use}

- Block a transition, such as a Closed Won opportunity moving back to an open stage.
- Keep a value from being cleared, or require a field when another field changes.
- Compare the old and the new parent before allowing a move, with [PriorParentQuery](/before-update/add-ons/prior-parent-query) and [ParentQuery](/before-update/add-ons/parent-query).

Use a [Populator](/before-update/populator) when you can fix the value instead of rejecting it. When the check needs the saved state, call `record.getNewSObject().addError(…)` from an [AfterUpdate.Writer](/after-update/writer): it fails that record's save.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/validator/signature.md-->

<!--@include: @/_parts/generated/before-update/validator/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/validator/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityWinAmountValidator.cls [Minimal]

<<< @/../examples/main/default/classes/account/before-update/validator/AccountBillingCountryValidator.cls [Old value in the message]

<<< @/../examples/main/default/classes/account/before-update/validator/AccountDemotionValidator.cls [Block a transition]

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityLargeDealValidator.cls [No change gate]

:::

`AccountBillingCountryValidator` attaches its error with `record.addError(Account.BillingCountry, …)`. `BillingCountry` is part of the billing address, and that form loses field attribution on address fields, so expect this message at record level ([Gotchas](#gotchas)).

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/validator.md-->

In before update:

- **The names.** The error method is `addErrorOnBeforeUpdate`, and its record is a `TriggerHandler.RejectableUpdateRecord`.
- **No recursion budget.** A Validator runs on every pass, nested updates and partial-save retries included. A RecursionGuard on it is ignored.
- **No parent query after it.** Only Populators refresh parents.
- **Parent and related data.** Declare [ParentQuery](/before-update/add-ons/parent-query), [PriorParentQuery](/before-update/add-ons/prior-parent-query) or [RelatedQuery](/before-update/add-ons/related-query) on the Validator; the predicate and `addErrorOnBeforeUpdate` both read them.

## Register {#register}

<!--@include: @/_parts/generated/before-update/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/before-update/accessors.md-->

The predicate gets an `UpdateRecord`; `addErrorOnBeforeUpdate` gets a `RejectableUpdateRecord` for the same record. Both read the old row, as `AccountBillingCountryValidator` does, and the previous parent when a PriorParentQuery declares it, as `AccountParentMoveValidator` does, but never write to them.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/validator/works-with.md-->

## Gotchas {#gotchas}

- **Field-level errors.** `record.addError(Opportunity.Amount, message)` puts the message on the field, as `OpportunityWinAmountValidator` does. On Name and address fields that form shows the message at record level instead; use the static form, `((Account) record.getNewSObject()).BillingCountry.addError(message)`, inside `addErrorOnBeforeUpdate`.
- **Translated messages.** Pass a custom label: `record.addError(Opportunity.StageName, System.Label.ReopenBlocked)`.
- **Never call `addError` on `getOldSObject()`.** It throws "SObject row does not allow errors", a `FinalException` that nothing inside the trigger can catch. Errors on the old row are allowed in the delete contexts only.
- **A qualified record must get an error.** Here the exception reads `<Handler> qualified a record in errorShouldBeAttachedOnBeforeUpdateWhen but attached no error in addErrorOnBeforeUpdate.` It fails the whole chunk, with or without ContinueOnError.
- **A check without a change gate blocks every later edit.** `OpportunityLargeDealValidator` does not ask `isChanged`, so a record that fails it cannot be updated at all until the data is fixed, including by AfterUpdate Writers, Flows and other automation.
- **`put` compiles in the predicate.** The predicate receives an `UpdateRecord`, so `put` compiles there and writes the row, but no parent query follows a Validator. Keep writes in Populators.

<!--@include: @/_parts/roles/dml-guard.md-->

<!--@include: @/_parts/roles/one-role.md#before-->

## Test It {#test}

Build the record from two in-memory rows and call each method directly. `addError` works on an in-memory row, and `getErrors()` reads it back:

::: code-group

```apex [Predicate]
@IsTest
static void errorShouldBeAttachedOnBeforeUpdateWhenWonWithZeroAmount() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
        new Opportunity(StageName = 'Closed Won', Amount = 0),
        new Opportunity(StageName = 'Negotiation/Review')
    );

    // Test
    Boolean result = new OpportunityWinAmountValidator().errorShouldBeAttachedOnBeforeUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should be rejected.');
}
```

```apex [Error method]
@IsTest
static void addErrorOnBeforeUpdate() {
    // Setup
    Opportunity newRow = new Opportunity(StageName = 'Closed Won', Amount = 0);
    TriggerHandler.RejectableUpdateRecord record = new TriggerHandler.TriggerRecord(newRow, new Opportunity(StageName = 'Negotiation/Review'));

    // Test
    new OpportunityWinAmountValidator().addErrorOnBeforeUpdate(record);

    // Verify
    Assert.areEqual(new List<String>{ 'Amount' }, newRow.getErrors()[0].getFields(), 'The error should be on Amount.');
}
```

:::

More techniques: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/validator/other-contexts.md-->

To stop a delete, use the [BeforeDelete.Handler](/before-delete/handler) and call `addError` on the old row. After the save, call `record.getNewSObject().addError(…)` from a Writer or a Dispatcher.

## See Also {#see-also}

- [Change Detection](/before-update/record-api#change-detection)
- [Errors & Logging](/guide/error-handling)
- [BeforeUpdate overview](/before-update/)
