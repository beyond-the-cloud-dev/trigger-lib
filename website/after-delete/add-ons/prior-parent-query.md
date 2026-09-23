---
template: add-on
context: AfterDelete
interface: PriorParentQuery
description: Read fields of the former parent (lookup, account, owner, manager) of a deleted record in an after delete Writer or Dispatcher, without SOQL in the handler.
---

# AfterDelete.PriorParentQuery

Read fields of the record a lookup pointed to before the delete (the former parent: an account, an owner, a manager) in **after delete**, without SOQL in your handler.

<!--@include: @/_parts/generated/after-delete/prior-parent-query/available-in.md-->

## When to Use {#when-to-use}

- You need a field of the former parent, such as its owner or type, in a predicate, action, dispatch or Finalizer.
- You do not need it for the parent Id: the old row still carries the lookup, so `records.getIdsOf(Contact.AccountId)` returns the former parents' Ids.
- Use a [RelatedQuery](/after-delete/add-ons/related-query) instead for children, siblings or any records that are not the parent.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/prior-parent-query/signature.md-->

<!--@include: @/_parts/generated/after-delete/prior-parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/prior-parent-query/skeleton.md-->

:::

The Writer page shows a second use, which leaves a task for the former account's owner and skips merge losers: [AfterDelete.Writer](/after-delete/writer#example).

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/prior-parent-query.md-->

A delete has no new row, so only the old side is loaded: no query runs on the trigger object, and nothing is queried again during the run. Each declared lookup costs at most one query, for the chunk's previous parent Ids, and the next chunk queries again.

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

Only the prior side exists here: `DeleteRecord` has no `getNewParent`, and after delete has no ParentQuery.

## Records Here {#records}

- The method takes no records. It declares lookups for the whole run.
- Read the parent with `record.getOldParent('Account')` in the predicate, the action, the dispatch or the Finalizer, or in bulk with `records.getIdsOf('Account', Account.OwnerId)`.
- It returns null when the lookup was empty, when no active handler declared it, or when the parent no longer exists.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/prior-parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **The trigger row has no parent object.** `getOldSObject().Account` is null even when `AccountId` is set, because `Trigger.old` carries lookup Ids only. That is what this add-on fills in.
- **The method name has no "Prior".** Implement `queryParentsOnAfterDelete()`; the interface is still `AfterDelete.PriorParentQuery`.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

Here build the record as `new TriggerHandler.TriggerRecord(null, oldContact)` and attach the former account with `enrichOld('Account', …)`, then call the Skeleton's `writeOnAfterDeleteWhen`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/prior-parent-query/other-contexts.md-->

## See Also {#see-also}

- [Field Selection](/api/field-selection), for `TriggerHandler.ParentFields`
- [AfterDelete.RelatedQuery](/after-delete/add-ons/related-query), for records other than the parent
- [Execution Order & Cost](/guide/execution-order#query-cost), for what the parent queries cost
- [Record API in AfterDelete](/after-delete/record-api#parents)
