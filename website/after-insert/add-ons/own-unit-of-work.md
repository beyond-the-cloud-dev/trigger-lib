---
template: add-on
context: AfterInsert
interface: OwnUnitOfWork
description: AfterInsert.OwnUnitOfWork - give an after insert Writer its own DML Lib unit for user mode, sharing, partial success or a custom statement order, committed right after the Writer.
---

# AfterInsert.OwnUnitOfWork

Give an **after insert** Writer its own DML Lib unit of work instead of the shared one: write in user mode or with sharing, allow partial success, set your own statement order, or commit before the next handler runs. The Writer still registers through the `unitOfWork` its action receives.

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/available-in.md-->

## When to Use {#when-to-use}

- The writes must respect the running user's permissions or sharing (user mode, `withSharing()`).
- One failing record must not fail the others (`allowPartialSuccess()`).
- The statements need an order DML Lib would not choose, such as deletes before inserts.
- A later handler must query what this Writer wrote: the own unit commits at this Writer's turn.
- Keep the shared unit otherwise: it merges every Writer's registrations into the fewest statements.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/signature.md-->

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/skeleton.md-->

:::

The Skeleton's unit runs in user mode, so the running user's object permissions, field-level security and sharing apply to the Task insert.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/own-unit-of-work.md-->

### Configuring the Unit {#configuring}

<!--@include: @/_parts/add-ons/configuring-unit.md-->

## Records Here {#records}

`ownUnitOfWorkOnAfterInsert()` takes no records: it is called once per run, when the handler list is built, before any record is looked at.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/works-with.md-->

## Gotchas {#gotchas}

- **Duplicates throw.** Without `combineOnDuplicate()`, a second `toUpdate` or `toDelete` of the same Id throws "Duplicate records found during registration. Fix the code or use the combineOnDuplicate() method." at registration. The shared unit merges them instead.
- **Its own statements.** An own unit is never merged with the shared unit: each commit costs at least one DML statement per operation and object type it registers, and it commits once per chunk in which a record qualified.
- **Partial success hides failures.** With `allowPartialSuccess()`, failed rows do not throw, and the library does not read the result, so they never reach `TriggerOrchestrator.Logger`. Read them in a `commitHook`, or with `DML.retrieveResultFor('<your identifier>')`.
- **It commits before the shared unit.** Its rows exist when the shared commit runs, and a later handler's provider can query them.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#uow-->

The Skeleton's identifier is `'ContactWriter'`; to test what the action registers, use the recording unit from [AfterInsert.Writer](/after-insert/writer#test).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/other-contexts.md-->

## See Also {#see-also}

- [Which Unit You Get](/after-insert/writer#which-unit) and [When It Commits](/after-insert/writer#when-it-commits)
- [Unit of Work](/guide/unit-of-work)
- [TriggerHandler.UnitOfWork](/api/unit-of-work)
