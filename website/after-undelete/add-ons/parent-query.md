---
template: add-on
context: AfterUndelete
interface: ParentQuery
description: Read parent (lookup) fields of restored records in an after undelete Writer or Dispatcher without SOQL in the handler.
---

# AfterUndelete.ParentQuery

Read fields of the record a lookup points to, such as the account of a restored contact or the owner of a restored account, in **after undelete**, without SOQL in your handler.

<!--@include: @/_parts/generated/after-undelete/parent-query/available-in.md-->

## When to Use {#when-to-use}

- A predicate or action needs a field of the parent: the owner's `IsActive`, the account's `Name` or `Type`.
- Several handlers read the same parent: their declarations are merged into one query.
- Use [RelatedQuery](/after-undelete/add-ons/related-query) instead for children, siblings or records that no lookup of the restored record points to.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/parent-query/skeleton.md-->

:::

A Writer that reads the owner's `IsActive` in its predicate: [AfterUndelete.Writer example](/after-undelete/writer#example).

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/parent-query.md#after-->

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

There is no PriorParentQuery in after undelete: a restore has no old row. The lookups of a restored record hold what they held when it was deleted.

## Records Here {#records}

`queryParentsOnAfterUndelete()` takes no records. Read the loaded parent from any method that receives a record with `record.getNewParent('Account')`, and a grandparent through it, for example `((Account) record.getNewParent('Account')).Owner.IsActive`. `records.getIdsOf('Account', Account.OwnerId)` collects a parent field over a whole `UndeleteRecords` collection, in a provider, the dispatch method or the Finalizer.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **The row's relationship fields stay empty.** `((Contact) record.getNewSObject()).Account` is null even when the parent is declared; only `getNewParent` returns it.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

The Writer example's owner is attached with `record.enrichNew('Owner', new User(IsActive = true))`; its test is under [AfterUndelete.Writer](/after-undelete/writer#test).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/parent-query/other-contexts.md-->

## See Also {#see-also}

- [Field Selection](/api/field-selection)
- [AfterUndelete.RelatedQuery](/after-undelete/add-ons/related-query)
- [Execution Order & Cost](/guide/execution-order)
