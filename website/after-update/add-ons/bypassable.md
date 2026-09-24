---
template: add-on
context: AfterUpdate
interface: Bypassable
description: Skip an after update Writer or Dispatcher for a whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.
---

# AfterUpdate.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/after-update/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Static flag or batch]

:::

## Rules {#rules}

- **Reset static flags in `finally`.** A static flag lasts for the whole transaction, nested saves included.
- **Outside the error handling.** An exception here is not logged, ContinueOnError does not apply, and the update fails.
- **Only this context.** [Other switches](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: tip
To skip single records, return false from the predicate.
:::
