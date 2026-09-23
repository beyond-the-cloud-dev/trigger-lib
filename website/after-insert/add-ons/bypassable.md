---
template: add-on
context: AfterInsert
interface: Bypassable
description: Skip an after insert Writer or Dispatcher for the whole chunk when a condition holds, such as a static flag or a custom permission.
---

# AfterInsert.Bypassable

Skips a Writer or Dispatcher for the whole chunk when a condition holds, such as a static flag or a custom permission. The handler's other contexts are not affected.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Static flag]

:::

## Good to Know {#good-to-know}

- **Skip single records in the predicate.** Bypassable switches off the whole handler.
- **Checked before the first handler runs.** A flag that an earlier handler sets takes effect from the next chunk.
- **Outside the error handling.** An exception from `bypassOnAfterInsertWhen()` is not logged, ContinueOnError does not apply, and the insert fails.
- **Static flags last the transaction.** `ContactOwnerAlignmentWriter.isDisabled = true` stays set for every later chunk and nested save until you reset it.
- **Class switches miss inner classes.** `TriggerOrchestrator.bypass().handler(X.class)` and `.orchestrator(X.class)` do not match an inner class. Use a `TriggerHandler__mdt` record or this interface. See [Bypassing](/guide/bypasses).
