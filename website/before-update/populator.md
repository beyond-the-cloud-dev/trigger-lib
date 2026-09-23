---
template: role
context: BeforeUpdate
interface: Populator
description: BeforeUpdate.Populator sets, derives, stamps or clears fields on records being updated, usually when another field changed, before they are saved and without DML.
---

# BeforeUpdate.Populator

Set, derive, default, stamp or clear fields on records being updated in **before update**, usually because another field changed (old value vs new value), before they are saved. It needs no DML and no second save.

<!--@include: @/_parts/generated/before-update/populator/available-in.md-->

## When to Use {#when-to-use}

- Recompute a field when its inputs change: a rating from revenue, a probability from the stage.
- Stamp an audit or closing note, or clear a field on a transition.
- Copy values between fields of the same record, reading the old row to decide.
- Set a marker field that an AfterUpdate Writer reacts to → [Before-after handoff](/guide/orchestrator#before-after-handoff).

Use something else when you need to reject the change ([Validator](/before-update/validator)), change other records ([AfterUpdate.Writer](/after-update/writer)), or run the same logic on create (also implement [BeforeInsert.Populator](/before-insert/populator) in the same class).

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/populator/signature.md-->

<!--@include: @/_parts/generated/before-update/populator/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/populator/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/populator/OpportunityForecastPopulator.cls [Minimal]

<<< @/../examples/main/default/classes/account/before-update/populator/AccountRatingRefreshPopulator.cls [Derive on change]

<<< @/../examples/main/default/classes/account/before-update/populator/AccountShippingSyncPopulator.cls [Old row in the predicate]

<<< @/../examples/main/default/classes/opportunity/before-update/populator/OpportunityProbabilityPopulator.cls [Lookup table]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/populator.md-->

In before update:

- **The recursion budget comes first.** A record that has used up this Populator's budget is skipped before `populateOnBeforeUpdateWhen` is called. When the predicate returns true, the count goes up by 1, then `populateOnBeforeUpdate` runs. The default is 3 per record per transaction → [RecursionGuard](/before-update/add-ons/recursion-guard).
- **A `put` changes what later handlers compare.** Change detection reads the live new row, so a value put here is a change for every handler after this one, and putting the old value back makes the field unchanged for them.

## Register {#register}

<!--@include: @/_parts/generated/before-update/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/before-update/accessors.md-->

Every handler in the list works on the same rows, so the record this Populator receives already carries what earlier handlers put. The old row does not change during the run: `isChanged` always compares with the values from before this update, so a value this Populator puts makes `isChanged` true for every later handler, even on records where the user did not edit that field.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/populator/works-with.md-->

## Gotchas {#gotchas}

- **Never write to `getOldSObject()`.** The `FinalException` cannot be caught and fails the update.
- **Appending is not idempotent.** An audit line appended on every pass is written again each time the update re-enters. Gate it on a change (`isChanged`), and read [Edge Values](/before-update/add-ons/recursion-guard#edge-values) before using a limit of 1: partial saves lose the line.
- **Relationship fields on the row are empty.** `((Contact) record.getNewSObject()).Account` is null, so `.Account.Name` throws a `NullPointerException`; declare a [ParentQuery](/before-update/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **One exception fails the chunk.** Values put on earlier records stay only when the Populator implements [ContinueOnError](/before-update/add-ons/continue-on-error). Without it, the exception fails every record in the chunk, and with all-or-none DML, the default for `update`, the whole statement → [Fail one record](/guide/error-handling#one-record).

<!--@include: @/_parts/roles/dml-guard.md-->

<!--@include: @/_parts/roles/one-role.md#before-->

## Test It {#test}

Build the record from two in-memory rows, new first, and call the method directly. No DML and no trigger:

::: code-group

```apex [Predicate]
@IsTest
static void populateOnBeforeUpdateWhenSmallOpenDealChanged() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
        new Opportunity(Amount = 4000, StageName = 'Prospecting'),
        new Opportunity(Amount = 9000, StageName = 'Prospecting')
    );

    // Test
    Boolean result = new OpportunityForecastPopulator().populateOnBeforeUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```

```apex [Action]
@IsTest
static void populateOnBeforeUpdate() {
    // Setup
    Opportunity newRow = new Opportunity(Amount = 4000, StageName = 'Prospecting');
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(newRow, new Opportunity(Amount = 9000, StageName = 'Prospecting'));

    // Test
    new OpportunityForecastPopulator().populateOnBeforeUpdate(record);

    // Verify
    Assert.areEqual('Omitted', newRow.ForecastCategoryName, 'The forecast category should be set.');
}
```

:::

`put` writes to the row you passed in, so assert on that row. Parents, providers and running the whole orchestrator: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/populator/other-contexts.md-->

After contexts have no Populator, because the rows are read-only after the save. Change saved records from an [AfterUpdate.Writer](/after-update/writer) with `toUpdate`.

## See Also {#see-also}

- [Change Detection](/before-update/record-api#change-detection)
- [Before-after handoff](/guide/orchestrator#before-after-handoff)
- [BeforeUpdate overview](/before-update/)
