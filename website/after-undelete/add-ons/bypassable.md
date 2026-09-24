---
template: add-on
context: AfterUndelete
interface: Bypassable
description: Skip (bypass, disable, turn off) an after undelete Writer or Dispatcher for the whole chunk when a condition holds.
---

# AfterUndelete.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/after-undelete/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/bypassable/skeleton.md-->

:::

## Rules {#rules}

- **To skip single records, return false from the predicate.**
- **Reset static flags.** A flag lasts the whole transaction, nested saves and later chunks included. Reset it in a `finally` block.
- **Only this context.** [Other switches](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: warning
An exception in `bypassOnAfterUndeleteWhen()` is not logged, ContinueOnError does not apply, and the restore fails.
:::
