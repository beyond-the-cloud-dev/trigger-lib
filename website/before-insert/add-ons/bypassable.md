---
template: add-on
context: BeforeInsert
interface: Bypassable
description: Skip (bypass, disable) a before insert handler for the whole chunk when a condition holds, such as a static flag or a batch.
---

# BeforeInsert.Bypassable

Skip a handler for the whole chunk when a condition holds, such as a static flag, a batch job or a custom permission.

**Signature**

<!--@include: @/_parts/generated/before-insert/bypassable/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-insert/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactReachabilityValidator.cls [Static flag or batch]

:::

## Rules {#rules}

- **Reset static flags.** A flag stays set for the rest of the transaction, nested saves included. Set it back to false in a `finally` block after your DML.
- **Checked before any handler runs.** A flag that an earlier handler sets takes effect only from the next chunk.
- **Exceptions here are not logged.** The method runs outside the handler's error handling. An exception fails the insert, even with [ContinueOnError](/before-insert/add-ons/continue-on-error).
- **Only this context.** [Other bypasses](/guide/bypasses) cover every context, and `bypass().handler(X.class)` never matches an inner class.

::: tip
To skip only some records, return false from the predicate instead.
:::
