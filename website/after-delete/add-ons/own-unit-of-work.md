---
template: add-on
context: AfterDelete
interface: OwnUnitOfWork
description: Give an after delete Writer its own DML Lib unit of work — user mode, sharing, partial success, statement order, commit hook — committed right after that Writer.
---

# AfterDelete.OwnUnitOfWork

Give an **after delete** Writer its own DML Lib unit of work, with user mode, sharing, partial success, its own statement order or a commit hook, committed right after that Writer instead of with the shared unit.

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/available-in.md-->

## When to Use {#when-to-use}

- The Writer's writes must be saved right after its turn, so that later handlers can query them.
- You need user mode, `with sharing` or partial success.
- You need your own statement order, or the results of the commit (`commitHook`, `DML.retrieveResultFor`).
- Otherwise the shared unit is fine: it commits once, after the last handler.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/signature.md-->

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/own-unit-of-work.md-->

### Configuring the Unit {#configuring}

<!--@include: @/_parts/add-ons/configuring-unit.md-->

## Records Here {#records}

The method takes no records. The Writer still receives each `DeleteRecord` in `writeOnAfterDeleteWhen` and `writeOnAfterDelete`, and registers on the `unitOfWork` parameter as usual.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/works-with.md-->

## Gotchas {#gotchas}

- **Your unit cannot do what the shared one cannot.** Updating a deleted row still fails with `ENTITY_IS_DELETED`, whatever mode you choose.
- **Partial success hides failures from the Logger.** With `allowPartialSuccess()`, failed rows do not throw, so nothing reaches `TriggerOrchestrator.Logger`. Read them in a `commitHook`, or with `DML.retrieveResultFor('<your identifier>')`. A DML Lib `DML.Logger` implementation, if the org has one, still records them.
- **Each own unit costs its own statements.** It commits separately from the shared unit: at least one DML statement per operation and object type, per chunk.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#uow-->

For the Skeleton, the identifier is `'ContactWriter'` and the method is `ownUnitOfWorkOnAfterDelete()`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/other-contexts.md-->

## See Also {#see-also}

- [AfterDelete.Writer](/after-delete/writer#which-unit), for which unit a Writer gets
- [Unit of Work](/guide/unit-of-work)
- [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [AfterDelete.ContinueOnError](/after-delete/add-ons/continue-on-error), which gives a Writer a private unit instead
