---
template: add-on
context: AfterUpdate
interface: PriorParentQuery
description: Read fields of the parent a lookup pointed to before the update, such as the previous owner, in an after update Writer or Dispatcher.
---

# AfterUpdate.PriorParentQuery

Reads fields of the parent a lookup pointed to before this update, such as the previous owner, without SOQL in your handler.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/prior-parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/prior-parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Previous and new owner]

:::

## Good to Know {#good-to-know}

- **Read with `getOldParent`.** Use `getOldParent('Owner')` for `OwnerId`. It is null when the old lookup was empty or the parent no longer exists.
- **Each side needs its own declaration.** `getOldParent` needs PriorParentQuery and `getNewParent` needs [ParentQuery](/after-update/add-ons/parent-query), even when the lookup did not change. Implement both to compare the two parents.
- **Fields merge per lookup.** When both declare the same lookup, both parents carry every declared field. An unchanged lookup returns the same record on both sides.
- **Current values.** The previous parent is queried now, so its fields show today's values.
- **One query per lookup.** Previous parents that are not loaded yet cost one query per lookup per chunk, even when no record qualifies. They are read in system mode without sharing.
