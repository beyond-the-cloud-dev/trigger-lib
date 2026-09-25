---
template: add-on
context: AfterUpdate
interface: PriorParentQuery
description: Read fields of the parent a lookup pointed to before the update, such as the previous owner, in an after update Writer or Dispatcher.
---

# AfterUpdate.PriorParentQuery

Read fields of the parent the old row pointed to, such as the previous owner, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/after-update/prior-parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/prior-parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Previous and new owner]

:::

## Rules {#rules}

- **Read with `getOldParent`.** Pass the lookup field you declared, such as `getOldParent(Account.OwnerId)`. It is null when the old lookup was empty or the parent no longer exists.
- **Each side needs its own declaration.** `getOldParent` needs PriorParentQuery and `getNewParent` needs [ParentQuery](/after-update/add-ons/parent-query), even when the lookup did not change. Implement both to compare the two parents.
- **Current values.** The previous parent is queried now, so its fields show today's values.
- **At most one query per lookup per chunk.** It runs when a handler first reads that lookup's parent. A lookup no handler reads costs nothing.

::: warning
Parents are read in system mode without sharing.
:::
