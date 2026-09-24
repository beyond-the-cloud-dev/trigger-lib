---
template: add-on
context: AfterInsert
interface: Bypassable
description: Skip an after insert Writer or Dispatcher for the whole chunk when a condition holds, such as a static flag or a custom permission.
---

# AfterInsert.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/after-insert/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Static flag]

:::

## Rules {#rules}

- **To skip single records, return false from the predicate.**
- **Checked before the first handler runs.** A flag that an earlier handler sets takes effect from the next chunk.
- **Static flags last the transaction.** `ContactOwnerAlignmentWriter.isBypassed = true` stays set for every later chunk and nested save until you reset it.
- **Only this context.** [Other bypasses](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: warning
An exception from `bypassOnAfterInsertWhen()` is not logged, ContinueOnError does not apply, and the insert fails.
:::
