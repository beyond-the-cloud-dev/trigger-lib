---
template: add-on
context: BeforeUpdate
interface: Finalizer
description: BeforeUpdate.Finalizer runs once after a before update handler has processed the chunk, with the qualified records, for cross-record checks and totals.
---

# BeforeUpdate.Finalizer

Run once after a **before update** handler has processed every record in the chunk: cross-record checks (duplicates within the chunk), totals, or one aggregate over the qualified records.

<!--@include: @/_parts/generated/before-update/finalizer/available-in.md-->

## When to Use {#when-to-use}

- Compare the qualified records with each other, such as two contacts in one save that change to the same email.
- Compute one value over the chunk and put it on each record.

Put it on a Populator: on a Validator it receives only records that Validator already rejected. For work after the save, or DML, use a Writer with [AfterUpdate.Finalizer](/after-update/add-ons/finalizer).

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/finalizer/signature.md-->

<!--@include: @/_parts/generated/before-update/finalizer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/finalizer/skeleton.md-->

:::

The Skeleton is a complete in-chunk duplicate check: the Populator normalizes each changed email, and the Finalizer rejects every qualified record whose email an earlier qualified record in the chunk already uses.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#before-->

In before update:

- **Records the recursion guard skipped are not in `records`.**
- **On a Populator, the parent query comes after it.** A lookup that the Finalizer points somewhere new is loaded before the next handler runs, like one changed in the action. A Validator's Finalizer is never followed by a parent query.

## Records Here {#records}

`TriggerHandler.UpdateRecords` with the qualified records only. `getIds()`, `getOldIdsOf` and `getOldValuesOf` work. `records.getRecords()` returns them as `UpdateRecord`, so `put` works, and `getNewSObject().addError(…)` rejects one.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **Field-level errors from here.** `UpdateRecord` has no `addError`. Use the static field form on the row, `((Contact) record.getNewSObject()).Email.addError(message)`, as the Skeleton does; it keeps the field attribution.
- **Only this chunk.** The Finalizer sees the qualified records of this chunk of up to 200. The pending values of other chunks in the same update are out of reach: a [RelatedQuery](/before-update/add-ons/related-query) returns their saved values, as for any other record in the database.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

For the Skeleton, pass two rows with the same email and assert on `getErrors()` of the second row.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/finalizer/other-contexts.md-->

## See Also {#see-also}

- [Populator](/before-update/populator)
- [Execution Order & Cost](/guide/execution-order)
- [BeforeInsert.Finalizer](/before-insert/add-ons/finalizer)
