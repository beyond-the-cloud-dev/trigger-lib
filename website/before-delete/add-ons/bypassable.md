---
template: add-on
context: BeforeDelete
interface: Bypassable
description: Skip a before delete Handler for the chunk when a condition holds, such as a static flag or a batch purge.
---

# BeforeDelete.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/before-delete/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/bypassable/skeleton.md-->

:::

## Rules {#rules}

- **To skip single records, return false from `qualifiesForBeforeDeleteWhen`.**
- **Reset static flags.** A static flag lasts the whole transaction, nested saves included. Reset it in a `finally` block after the DML it was meant for.
- **Only this context.** [Other switches](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: warning
The method runs outside the error handling. An exception in `bypassOnBeforeDeleteWhen()` is not logged, ContinueOnError does not apply, and the delete fails.
:::
