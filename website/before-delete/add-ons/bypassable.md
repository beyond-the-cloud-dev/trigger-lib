---
template: add-on
context: BeforeDelete
interface: Bypassable
description: Skip a before delete Handler for the chunk when a condition holds, such as a static flag or a batch purge.
---

# BeforeDelete.Bypassable

Skips a before delete handler when a condition holds, such as a static flag during a batch purge.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/bypassable/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **No records.** The method decides for the whole chunk. To skip only some records, return false from `qualifiesForBeforeDeleteWhen`.
- **Outside the error handling.** An exception in `bypassOnBeforeDeleteWhen()` is not logged, ContinueOnError does not apply, and the delete fails.
- **Reset static flags.** A static flag lasts the whole transaction, nested saves included. Reset it in a `finally` block after the DML it was meant for.
- **A bypassed guard blocks nothing.** While a handler that blocks deletes is switched off, those deletes go through. An object-wide switch has the same effect.
- **Inner classes need metadata.** `TriggerOrchestrator.bypass().handler(X.class)` never matches an inner class. Use a `TriggerHandler__mdt` record or this add-on instead. See [Bypassing](/guide/bypasses).
