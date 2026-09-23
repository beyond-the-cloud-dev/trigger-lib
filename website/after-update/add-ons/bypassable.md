---
template: add-on
context: AfterUpdate
interface: Bypassable
description: Skip an after update Writer or Dispatcher for a whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.
---

# AfterUpdate.Bypassable

Skips an after update Writer or Dispatcher for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Static flag or batch]

:::

## Good to Know {#good-to-know}

- **Whole chunk, not single records.** To skip single records, return false from the predicate.
- **Reset static flags in `finally`.** A static flag lasts for the whole transaction, nested saves included.
- **Outside the error handling.** An exception here is not logged, ContinueOnError does not apply, and the update fails.
- **Other switches work in every context.** `TriggerOrchestrator.bypass().handler(X.class)` and a `TriggerHandler__mdt` row switch a handler off wherever it runs. See [Bypassing](/guide/bypasses).
- **Inner classes.** `TriggerOrchestrator.bypass().handler(X.class)` never matches an inner class. Use a `TriggerHandler__mdt` row or this add-on.
