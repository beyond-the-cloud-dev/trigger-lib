---
template: add-on
context: AfterDelete
interface: OwnUnitOfWork
description: Give an after delete Writer its own DML Lib unit of work - user mode, sharing, partial success, statement order - committed right after that Writer.
---

# AfterDelete.OwnUnitOfWork

Gives a Writer its own DML Lib unit of work, committed right after that Writer. Use it for user mode, sharing, partial success or your own statement order.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/own-unit-of-work/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **The default unit.** Without this add-on, Writers share one unit in system mode, without sharing, all or none. It commits once, after the last handler.
- **Commits at the Writer's turn.** Your unit commits right after this Writer, only when at least one record qualified. Later handlers can query its rows.
- **The deleted row is still off-limits.** Updating it fails with `ENTITY_IS_DELETED` in any mode.
- **Partial success hides failures from the Logger.** With `allowPartialSuccess()`, failed rows do not throw. Read them with `DML.retrieveResultFor('<identifier>')`.
- **Wins over ContinueOnError.** A Writer that implements both gets the unit it returns, not a private one.
