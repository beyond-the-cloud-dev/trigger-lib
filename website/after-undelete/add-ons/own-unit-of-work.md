---
template: add-on
context: AfterUndelete
interface: OwnUnitOfWork
description: Give an after undelete Writer its own DML Lib unit of work - user mode, sharing, partial success, statement order - that commits at the Writer's turn.
---

# AfterUndelete.OwnUnitOfWork

Give a Writer its own DML Lib unit of work, for user mode, sharing, partial success or your own statement order.

**Signature**

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/own-unit-of-work/skeleton.md-->

:::

## Rules {#rules}

- **Commits at the Writer's turn.** The unit commits right after this Writer and its Finalizer, only when a record qualified. Later handlers can query what it wrote.
- **A plain `new DML()` runs in user mode.** It also inherits sharing and throws on a duplicate registration. Add `combineOnDuplicate()` to merge a second `toUpdate` or `toDelete` of the same Id.
- **Each unit costs its own statements.** It commits apart from the default unit of work: one DML statement per operation and object type.

::: warning
Failed rows are not logged. With `allowPartialSuccess()`, a failing row does not throw. Read the results with `commitHook` or `DML.retrieveResultFor('<identifier>')`.
:::
