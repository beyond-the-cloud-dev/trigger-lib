---
template: add-on
context: AfterDelete
interface: Bypassable
description: Skip an after delete Writer or Dispatcher for a chunk when a condition holds, for example during a batch purge or a data migration.
---

# AfterDelete.Bypassable

Skips a Writer or Dispatcher when a condition holds, for example during a batch purge. Read a static flag, a custom permission or `System.isBatch()`.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/bypassable/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **To skip single records, use the predicate.** Return false from `writeOnAfterDeleteWhen` or `dispatchOnAfterDeleteWhen`.
- **Outside the error handling.** An exception here is not logged, ContinueOnError does not apply, and the delete fails.
- **Static flags last the whole transaction.** Later chunks and nested saves see them too. Reset a flag in a `finally` block.
- **Other switches apply in every context.** `TriggerOrchestrator.bypass().handler(ContactWriter.class)` works for one transaction; a `TriggerHandler__mdt` record works org-wide. See [Bypassing](/guide/bypasses).
- **Inner classes never match by class.** `bypass().handler(X.class)` and `.orchestrator(X.class)` ignore inner classes. Use a `TriggerHandler__mdt` record or this add-on.
