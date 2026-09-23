---
template: add-on
context: AfterUndelete
interface: Finalizer
description: Run code once per chunk after an after undelete Writer or Dispatcher, with the restored records that qualified - aggregate queries, bulk registrations.
---

# AfterUndelete.Finalizer

Run code once after an **after undelete** Writer or Dispatcher has processed the chunk, with the restored records that qualified: one aggregate query, one bulk registration or one summary for the whole chunk.

<!--@include: @/_parts/generated/after-undelete/finalizer/available-in.md-->

## When to Use {#when-to-use}

- Work that needs every qualified record at once, such as one update per parent of the restored records.
- One query for the whole chunk instead of one per record.
- For a Dispatcher, the dispatch method already receives all qualified records; add a Finalizer only for work that must come after the dispatch.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/finalizer/skeleton.md-->

:::

The Skeleton keeps the `unitOfWork` from the action in a field and registers one Account update per parent of the restored contacts from the Finalizer.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#after-->

## Records Here {#records}

`finalizeAfterUndelete(records)` receives `TriggerHandler.UndeleteRecords` with the qualified records only. `getIds()` returns their Ids, and `getIdsOf(…)` and `getValuesOf(…)` collect lookups and values, including fields of parents loaded by ParentQuery.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **Clearing the list skips the commit.** `records.getRecords()` is the library's own list of qualified records, not a copy. Clearing it in a Writer's Finalizer empties that list, so a Writer with an own or private unit (OwnUnitOfWork, ContinueOnError) silently skips its commit, and its registrations are lost.
- **Not an end-of-restore hook.** Restoring 1,000 records runs the Finalizer 5 times, once per chunk, each time with that chunk's qualified records.
- **Direct DML works but bypasses the unit.** There is no DML guard, so a DML statement here runs at once and is not merged with any unit.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

For the Skeleton above, `<X>` is `Undelete`: call `writeOnAfterUndelete` first with your own `TriggerHandler.UnitOfWork` class, then `finalizeAfterUndelete`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/finalizer/other-contexts.md-->

## See Also {#see-also}

- [AfterUndelete.Writer: When It Commits](/after-undelete/writer#when-it-commits)
- [Unit of Work](/guide/unit-of-work)
- [Execution Order & Cost](/guide/execution-order)
