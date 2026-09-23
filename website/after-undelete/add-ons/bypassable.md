---
template: add-on
context: AfterUndelete
interface: Bypassable
description: Skip (bypass, disable, turn off) an after undelete Writer or Dispatcher for the whole chunk when a condition holds.
---

# AfterUndelete.Bypassable

Skips a Writer or Dispatcher for the whole chunk when a condition holds, such as a static flag or a custom permission.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/bypassable/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **No records.** The method answers for the whole chunk. To skip single records, return false from the predicate.
- **Reset static flags.** A flag lasts the whole transaction, nested saves and later chunks included. Reset it in a `finally` block.
- **Outside the error handling.** An exception here is not logged, ContinueOnError does not apply, and the restore fails.
- **Inner classes.** `TriggerOrchestrator.bypass().handler(X.class)` and `.orchestrator(X.class)` never match an inner class. Use a `TriggerHandler__mdt` record or this interface.
- **Only this context.** Metadata and `bypass().handler(X.class)` switch a class off in every context. Implement `AfterUndelete.Bypassable` to skip only the restore. More switches: [Bypassing](/guide/bypasses).
