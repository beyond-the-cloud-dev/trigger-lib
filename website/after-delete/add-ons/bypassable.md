---
template: add-on
context: AfterDelete
interface: Bypassable
description: Skip an after delete Writer or Dispatcher for a chunk when a condition holds, for example during a batch purge or a data migration.
---

# AfterDelete.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/after-delete/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-delete/bypassable/skeleton.md-->

:::

## Rules {#rules}

- **To skip single records, use the predicate.** Return false from `writeOnAfterDeleteWhen` or `dispatchOnAfterDeleteWhen`.
- **Static flags last the whole transaction.** Later chunks and nested saves see them too. Reset a flag in a `finally` block.
- **Only this context.** [Other switches](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: warning
Outside the error handling. An exception here is not logged, ContinueOnError does not apply, and the delete fails.
:::
