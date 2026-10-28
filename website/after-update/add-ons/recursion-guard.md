---
template: add-on
context: AfterUpdate
interface: RecursionGuard
description: Cap how many times an after update Writer or Dispatcher acts on the same record in one transaction. At the cap, the record is skipped and an error is logged.
---

# AfterUpdate.RecursionGuard

Cap how many times a Writer or Dispatcher acts on the same record in one transaction.

**Signature**

<!--@include: @/_parts/generated/after-update/recursion-guard/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/recursion-guard/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [One pass per transaction]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [With ContinueOnError]

:::

## Rules {#rules}

- **Without it, the depth is 3 and nothing is skipped.** When a record comes back after 3 runs, each run logs an error and the handler keeps acting. A loop that never ends fails the save at the platform's limit of 16 nested triggers.
- **It counts passes per class name and context, not nesting depth.** The count goes up each time the predicate returns true and never resets during the transaction. Separate updates of the same record count too. Two instances of one class share one count, and BeforeUpdate keeps its own.
- **Skipped and logged.** A record at the cap is skipped before its predicate, and the run logs an error. The Finalizer does not get the record.
- **`0` or less stops the handler.** Every record is skipped, and every run logs an error. `null` means no cap and no error.

::: tip
Prefer a change gate. `isChanged` or `isChangedTo` in the predicate stops re-entry without counting.
:::
