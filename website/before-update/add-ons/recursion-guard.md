---
template: add-on
context: BeforeUpdate
interface: RecursionGuard
description: Limit how many times a before update Populator acts on the same record in one transaction. At the limit, the record is skipped and an error is logged.
---

# BeforeUpdate.RecursionGuard

Cap how many times a Populator acts on the same record in one transaction.

**Signature**

<!--@include: @/_parts/generated/before-update/recursion-guard/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/recursion-guard/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/populator/OpportunityClosingPopulator.cls [One pass]

<<< @/../examples/main/default/classes/account/before-update/populator/AccountTypeAuditPopulator.cls [Audit line]

:::

## Rules {#rules}

- **Without it, the depth is 3 and nothing is skipped.** When a record comes back after 3 passes, each run logs an error and the Populator keeps acting.
- **It counts qualifying passes.** The count goes up by 1 each time the predicate returns true for a record Id. It is not the nesting level. RecursionGuard exists only in BeforeUpdate and AfterUpdate, and each keeps its own count.
- **A limit of 1 blocks a second edit.** When one transaction updates a record twice, both updates qualify, and the second one is skipped and logged.
- **Skipped records are logged.** Each run that skips a record logs an error. The Finalizer does not get the record.

::: tip
A change gate often does the job. On a nested update, `isChanged` compares with the values the previous update saved, so it is false unless the field changed again.
:::
