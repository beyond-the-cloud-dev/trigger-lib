---
template: add-on
context: BeforeUpdate
interface: Bypassable
description: Skip a before update Populator or Validator when a condition holds, such as a static flag or a custom permission.
---

# BeforeUpdate.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/before-update/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityReopenValidator.cls [Static flag]

:::

## Rules {#rules}

- **To skip single records, return false from the predicate.**
- **Reset a static flag in `finally`.** The flag stays set for every chunk and every nested update in the transaction.
- **Only this context.** [Other bypasses](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: warning
Exceptions here are not logged. `bypassOnBeforeUpdateWhen()` runs outside the handler's error handling. ContinueOnError does not apply, and the update fails.
:::
