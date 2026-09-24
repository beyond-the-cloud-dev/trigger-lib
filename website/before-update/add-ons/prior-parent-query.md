---
template: add-on
context: BeforeUpdate
interface: PriorParentQuery
description: Read fields of the parent a lookup pointed to before this update, to compare the old and new parent or to name the previous one.
---

# BeforeUpdate.PriorParentQuery

Read fields of the parent the old row pointed to, such as a contact's previous account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/before-update/prior-parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/prior-parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityAccountMoveValidator.cls [Old and new account]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [In a Populator]

:::

## Rules {#rules}

- **Read with `getOldParent`.** `record.getOldParent('Account')` is null when the old lookup was empty or the parent has been deleted since.
- **Current field values.** The previous parent is queried when the trigger runs, so its fields show their values now, not when the record pointed to it.
- **One query for both sides.** With a [ParentQuery](/before-update/add-ons/parent-query) on the same lookup, both parents load in one query, and each gets every field either side declared.

::: tip
Only need the old Id? Read `getOldSObject()`. No add-on is needed.
:::
