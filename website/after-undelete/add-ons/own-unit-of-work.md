---
template: add-on
context: AfterUndelete
interface: OwnUnitOfWork
description: Give an after undelete Writer its own DML Lib unit of work - user mode, sharing, partial success, statement order - that commits at the Writer's turn.
---

# AfterUndelete.OwnUnitOfWork

Gives a Writer its own DML Lib unit of work instead of the shared one. Use it for user mode, partial success or a custom statement order.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Commits at the Writer's turn.** The unit commits right after this Writer and its Finalizer, only when a record qualified. Later handlers can query what it wrote.
- **A plain `new DML()` runs in user mode.** It also inherits sharing and throws on a duplicate registration. Add `combineOnDuplicate()` to merge a second `toUpdate` or `toDelete` of the same Id.
- **Failed rows are not logged.** With `allowPartialSuccess()`, a failing row does not throw. Read the results with `commitHook` or `DML.retrieveResultFor('<identifier>')`.
- **Each unit costs its own statements.** It commits apart from the shared unit: one DML statement per operation and object type.
- **Getter errors fail the restore.** An exception in `ownUnitOfWorkOnAfterUndelete()` is not logged.
