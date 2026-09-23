---
template: add-on
context: AfterUndelete
interface: OwnUnitOfWork
description: Give an after undelete Writer its own DML Lib unit of work - user mode, sharing, partial success, statement order - that commits at the Writer's turn.
---

# AfterUndelete.OwnUnitOfWork

Give an **after undelete** Writer its own DML Lib unit of work instead of the shared one: user mode, with sharing, partial success or your own statement order, committed right after this Writer.

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/available-in.md-->

## When to Use {#when-to-use}

- The writes must respect the running user's permissions and sharing (`userMode()`).
- One failing row must not fail the restore (`allowPartialSuccess()`).
- The statements need a custom order, for example deletes before inserts.
- A later handler must query what this Writer wrote: the own unit commits at this Writer's turn.
- Use the shared unit, with no add-on, for everything else. A Dispatcher never gets a unit.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/own-unit-of-work.md-->

### Configuring the Unit {#configuring}

<!--@include: @/_parts/add-ons/configuring-unit.md-->

## Records Here {#records}

`ownUnitOfWorkOnAfterUndelete()` takes no records. It runs once per run, while the handler list is built, before any record is looked at.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/works-with.md-->

## Gotchas {#gotchas}

- **Duplicates throw without `combineOnDuplicate()`.** A second `toUpdate` or `toDelete` of the same Id throws "Duplicate records found during registration. Fix the code or use the combineOnDuplicate() method." In a unit with the default statement order, a second `toInsert` or `toUpsert` of the same record throws "Duplicate records found during registration. Fix the code." at commit, with or without it.
- **Each unit costs its own statements.** An own unit commits separately from the shared unit: one DML statement per operation and object type, and for inserts and upserts one per object type in each wave.
- **Failed rows are not logged.** With `allowPartialSuccess()`, a failing row does not throw, so it never reaches `TriggerOrchestrator.Logger`. Read the results with `commitHook` or `DML.retrieveResultFor('<your identifier>')`; a DML Lib `DML.Logger` implementation, if the org has one, also records them.
- **A plain `new DML()` is user mode.** It also inherits sharing and throws on duplicate registrations, unlike the shared unit.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#uow-->

With the Skeleton above, the identifier is `'ContactWriter'`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/other-contexts.md-->

## See Also {#see-also}

- [Unit of Work](/guide/unit-of-work)
- [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [AfterUndelete.Writer: Which Unit You Get](/after-undelete/writer#which-unit)
