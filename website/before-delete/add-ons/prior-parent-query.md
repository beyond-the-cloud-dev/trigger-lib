---
template: add-on
context: BeforeDelete
interface: PriorParentQuery
description: "Read parent (lookup) fields of the records being deleted in a before delete Handler, without SOQL in the handler."
---

# BeforeDelete.PriorParentQuery

Read fields of the parent that a record being deleted points to (lookup, parent fields: the account of a deleted contact, the owner, the manager) in **before delete**, without SOQL in your handler: declare the lookup and its fields in `queryParentsOnBeforeDelete()`, then read the parent with `record.getOldParent(…)`.

<!--@include: @/_parts/generated/before-delete/prior-parent-query/available-in.md-->

## When to Use {#when-to-use}

- The predicate or the action needs a field of the parent, such as the account's type or the owner's active flag.
- You do not need it for the parent Id, which is already on the old row: `((Contact) record.getOldSObject()).AccountId`, or `records.getIdsOf(Contact.AccountId)` for all records.
- Use [RelatedQuery](/before-delete/add-ons/related-query) instead for children, siblings or any record that is not the parent.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/prior-parent-query/signature.md-->

<!--@include: @/_parts/generated/before-delete/prior-parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/prior-parent-query/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/prior-parent-query.md-->

- **Old side only.** A delete has no new row, so there is no query on the trigger object: each declared lookup costs at most one query for the old parent Ids.
- **Current values.** The parent is read when the trigger runs, before the delete, so its fields are the values it has now.

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

Only the prior side exists here: `DeleteRecord` has `getOldParent` and no `getNewParent`, and the method is `queryParentsOnBeforeDelete()`.

## Records Here {#records}

The method takes no records. Read the parent with `record.getOldParent('Account')` in the predicate, the action or the Finalizer, or collect parent values in bulk with `records.getIdsOf('Account', Account.OwnerId)`. It returns `null` when the lookup is empty, when no active handler declared it, or when the parent no longer exists.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-delete/prior-parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **The trigger row has no parent object.** `((Contact) record.getOldSObject()).Account` is null: the row carries only the lookup Id, which is why this add-on exists.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

For the Skeleton above, `record.enrichOld('Account', new Account(Name = 'Acme'))` on a `new TriggerHandler.TriggerRecord(null, contactRow)` makes `qualifiesForBeforeDeleteWhen` return true.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-delete/prior-parent-query/other-contexts.md-->

## See Also {#see-also}

- [TriggerHandler.ParentFields](/api/field-selection)
- [BeforeDelete.RelatedQuery](/before-delete/add-ons/related-query): children and other records.
- [AfterDelete.PriorParentQuery](/after-delete/add-ons/prior-parent-query)
- [Record API in BeforeDelete](/before-delete/record-api#parents)
