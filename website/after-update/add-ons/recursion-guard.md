---
template: add-on
context: AfterUpdate
interface: RecursionGuard
description: Cap how many times an after update Writer or Dispatcher acts on the same record in one transaction (default 3).
---

# AfterUpdate.RecursionGuard

Cap how many times a Writer or Dispatcher acts on the same record in one transaction (default 3).

**Signature**

<!--@include: @/_parts/generated/after-update/recursion-guard/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/recursion-guard/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [One pass per transaction]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [With ContinueOnError]

:::

## Rules {#rules}

- **It counts passes, not nesting depth.** The count goes up each time the predicate returns true and never resets during the transaction. Separate updates of the same record count too.
- **Skipped silently.** A record at the limit is skipped before its predicate. Nothing is logged, and the Finalizer does not get it.
- **Counted per class name and context.** Two instances of one class share one count. BeforeUpdate keeps a separate count.
- **`0` or less stops the handler.** Every record is skipped. `null` means no limit.

::: tip
Prefer a change gate. `isChanged` or `isChangedTo` in the predicate stops re-entry without counting.
:::
