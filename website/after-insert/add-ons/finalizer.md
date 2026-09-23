---
template: add-on
context: AfterInsert
interface: Finalizer
description: AfterInsert.Finalizer - run once after an after insert Writer or Dispatcher has processed its records, with the records that qualified, to register bulk writes.
---

# AfterInsert.Finalizer

Run code once after an **after insert** Writer or Dispatcher has processed the chunk, with the records that qualified: register one write per parent instead of one per record, or summarise what the handler did. It runs once per chunk of up to 200 records, not once per DML statement.

<!--@include: @/_parts/generated/after-insert/finalizer/available-in.md-->

## When to Use {#when-to-use}

- Work that needs the whole set of qualified records, such as one update per account for many new contacts.
- A Writer that registers from the Finalizer keeps the unit its action received in an instance field, as the Skeleton does.
- Use the Dispatcher's dispatch method instead for a Dispatcher's main call: it already receives the qualified records once.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/finalizer/signature.md-->

<!--@include: @/_parts/generated/after-insert/finalizer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/finalizer/skeleton.md-->

:::

The Skeleton registers one update per account, however many of its new contacts qualified. The shared unit commits it with everything else after the last handler.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#after-->

## Records Here {#records}

`finalizeAfterInsert(records)` receives `InsertRecords` with the qualified records only. `records.getIds()` works. `records.getRecords()` is the list the library keeps for this handler, not a copy.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **Clearing the list skips the commit.** Removing records from `records.getRecords()` in a Writer's Finalizer changes the library's own list. When it ends up empty, the Writer's own or private unit is not committed, silently.
- **Direct DML runs at once.** There is no DML guard in after insert, so an `insert` or `update` here runs immediately and bypasses the unit of work.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

For the Skeleton, call `writeOnAfterInsert` first with the recording unit from [AfterInsert.Writer](/after-insert/writer#test), then `finalizeAfterInsert`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/finalizer/other-contexts.md-->

## See Also {#see-also}

- [When It Commits](/after-insert/writer#when-it-commits)
- [AfterInsert](/after-insert/#how-it-runs): where the Finalizer sits in the run
- [Execution Order & Cost](/guide/execution-order)
