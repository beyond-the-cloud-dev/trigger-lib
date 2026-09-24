---
template: add-on
context: BeforeDelete
interface: OwnUnitOfWork
description: Give a before delete Writer its own DML Lib unit of work - user mode, sharing, partial success, statement order - committed right after that Writer.
---

# BeforeDelete.OwnUnitOfWork

Give a Writer its own DML Lib unit of work, for user mode, sharing, partial success or your own statement order.

**Signature**

<!--@include: @/_parts/generated/before-delete/own-unit-of-work/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/own-unit-of-work/skeleton.md-->

:::

## Rules {#rules}

- **The shared unit.** Without this add-on, Writers share one unit in system mode, without sharing, all or none. It commits once, after the last handler.
- **Commits at the Writer's turn.** Your unit commits right after this Writer, only when at least one record qualified. Later handlers can query its rows.
- **The records being deleted are still off-limits.** A `toDelete` of one fails with `SELF_REFERENCE_FROM_TRIGGER` in any mode.
- **Wins over ContinueOnError.** A Writer that implements both gets the unit it returns, not the automatic one.

::: warning
Partial success hides failures from the Logger. With `allowPartialSuccess()`, failed rows do not throw. Read them with `DML.retrieveResultFor('<identifier>')`.
:::
