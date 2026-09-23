---
template: add-on
context: BeforeUpdate
interface: PriorParentQuery
description: BeforeUpdate.PriorParentQuery loads fields of the parent a lookup pointed to before this update, to compare the old and new parent or describe a move.
---

# BeforeUpdate.PriorParentQuery

Read fields of the parent a lookup pointed to before this update (previous parent, old account, prior owner) in a **before update** Populator or Validator, to compare the old and the new parent or to describe a move.

<!--@include: @/_parts/generated/before-update/prior-parent-query/available-in.md-->

## When to Use {#when-to-use}

- Block a move between parents that differ in something that matters, such as the billing country.
- Write an audit line that names the previous parent.
- Together with [ParentQuery](/before-update/add-ons/parent-query), whenever you compare both sides.

For the previous lookup Id alone you need no add-on: read `getOldSObject()`, or `records.getOldIdsOf(Contact.AccountId)` in a provider.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/prior-parent-query/signature.md-->

<!--@include: @/_parts/generated/before-update/prior-parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/prior-parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityAccountMoveValidator.cls [Old and new account]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [In a Populator]

<<< @/../examples/main/default/classes/account/before-update/validator/AccountParentMoveValidator.cls [Compare the parents]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/prior-parent-query.md-->

In before update, the previous parent Ids go into the same per-lookup query as the current ones, before the first handler runs. The query after a Populator loads current parents only, so `getOldParent` returns the same record for the whole run.

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

## Records Here {#records}

The method takes no records. Read the previous parent with `record.getOldParent('Account')`. It is null when the old lookup was empty, when no active handler declared it, or when the parent has been deleted since: `ContactAccountTransferPopulator` falls back to `'a deleted account'` for that case.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/prior-parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **The old lookup comes from `Trigger.old`.** A Populator that changes the lookup changes the current parent, never the previous one.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

`OpportunityAccountMoveValidator` reads both sides in `addErrorOnBeforeUpdate`, so its test sets `enrichOld` and `enrichNew`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/prior-parent-query/other-contexts.md-->

## See Also {#see-also}

- [Field Selection](/api/field-selection)
- [Parents and Related in BeforeUpdate](/before-update/record-api#parents)
- [AfterUpdate.PriorParentQuery](/after-update/add-ons/prior-parent-query)
