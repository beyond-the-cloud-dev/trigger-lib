---
template: add-on
context: BeforeUpdate
interface: PriorParentQuery
description: Read fields of the parent a lookup pointed to before this update, to compare the old and new parent or to name the previous one.
---

# BeforeUpdate.PriorParentQuery

Reads fields of the parent a lookup pointed to before this update. Use it to compare the old and the new parent, or to name the previous one.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/prior-parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/prior-parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityAccountMoveValidator.cls [Old and new account]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [In a Populator]

:::

## Good to Know {#good-to-know}

- **Read with `getOldParent`.** `record.getOldParent('Account')` is null when the old lookup was empty or the parent has been deleted since.
- **Current field values.** The previous parent is queried when the trigger runs, so its fields show their values now, not when the record pointed to it.
- **Never refreshed.** A Populator that changes the lookup changes the current parent, never the previous one.
- **One query for both sides.** With a [ParentQuery](/before-update/add-ons/parent-query) on the same lookup, both parents load in one query, and each gets every field either side declared.
- **Only need the old Id?** Read `getOldSObject()`. No add-on is needed.
