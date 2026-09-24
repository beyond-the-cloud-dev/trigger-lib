---
template: add-on
context: BeforeUpdate
interface: RecursionGuard
description: Limit how many times a before update Populator acts on the same record in one transaction. The default is 3.
---

# BeforeUpdate.RecursionGuard

Cap how many times a Populator acts on the same record in one transaction (default 3).

**Signature**

<!--@include: @/_parts/generated/before-update/recursion-guard/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/recursion-guard/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/populator/OpportunityClosingPopulator.cls [One pass]

<<< @/../examples/main/default/classes/account/before-update/populator/AccountTypeAuditPopulator.cls [Audit line]

:::

## Rules {#rules}

- **Update contexts only.** RecursionGuard exists in BeforeUpdate and AfterUpdate, and each keeps its own count.
- **It counts qualifying passes.** The count goes up by 1 each time the predicate returns true for a record Id. It is not the nesting level.
- **A limit of 1 blocks a second edit.** When one transaction updates a record twice, both updates qualify, and the second one is skipped.
- **Skipped records vanish silently.** A skipped record is not logged, and the Finalizer does not get it.

::: tip
A change gate often does the job. On a nested update, `isChanged` compares with the values the previous update saved, so it is false unless the field changed again.
:::
