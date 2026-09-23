---
template: add-on
context: AfterInsert
interface: OwnUnitOfWork
description: Give an after insert Writer its own DML Lib unit of work for user mode, sharing, partial success or your own statement order.
---

# AfterInsert.OwnUnitOfWork

Gives a Writer its own DML Lib unit of work instead of the shared one. Use it for user mode, sharing, partial success or your own statement order.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/own-unit-of-work/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Commits at the Writer's turn.** The unit commits right after this Writer's Finalizer, when at least one record qualified. Later handlers can query its rows.
- **Costs its own statements.** It is never merged with the shared unit. Each commit costs at least one DML statement per operation and object type.
- **Duplicates throw.** Without `combineOnDuplicate()`, a second `toUpdate` or `toDelete` of the same Id throws at registration.
- **Partial success hides failures.** With `allowPartialSuccess()`, failed rows do not throw and never reach `TriggerOrchestrator.Logger`. Read them with `DML.retrieveResultFor('<your identifier>')`.
- **A failed commit is this Writer's error.** It is logged under the Writer's name and fails the insert, unless the Writer implements ContinueOnError.
