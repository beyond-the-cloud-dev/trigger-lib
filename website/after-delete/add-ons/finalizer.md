---
template: add-on
context: AfterDelete
interface: Finalizer
description: Run one step per chunk after an after delete Writer or Dispatcher — one aggregate query over the former parents, one write per parent instead of per deleted record.
---

# AfterDelete.Finalizer

Run one step per chunk after an **after delete** Writer or Dispatcher has seen every record, with the records that qualified: one aggregate query over the former parents, or one write per parent instead of one per deleted record.

<!--@include: @/_parts/generated/after-delete/finalizer/available-in.md-->

## When to Use {#when-to-use}

- Work that needs the whole set of qualified records, such as one aggregate query over the former parents.
- Deduplicate: two deleted contacts of one account should produce one write to the account, not two.
- It is not an end-of-statement hook: a delete of 1,000 records runs it once per chunk of up to 200 records.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/finalizer/signature.md-->

<!--@include: @/_parts/generated/after-delete/finalizer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/finalizer/skeleton.md-->

:::

The Skeleton keeps the unit from `writeOnAfterDelete` in a field and registers one account update per former account from the Finalizer.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#after-->

After delete has no recursion guard, so every qualified record reaches the Finalizer.

## Records Here {#records}

- `finalizeAfterDelete` receives `DeleteRecords` with the qualified records only.
- `records.getIdsOf(Contact.AccountId)` reads the old rows, so it returns the former parents' Ids.
- `records.getRecords()` returns the library's own list, not a copy.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **Aggregate over what remains.** The deleted rows are already gone from SOQL, so an aggregate query over the former parents' children counts only the records that survive.
- **A throw here discards a ContinueOnError Writer's writes.** The Writer's private unit commits after the Finalizer, in the same try block, so a swallowed exception here skips that commit.
- **A Dispatcher's Finalizer runs after the dispatch.** Its job is already enqueued when the Finalizer runs, even if the Finalizer then throws.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

Here the collection is `new TriggerHandler.DeleteTriggerRecords(qualified)`, built from `new TriggerHandler.TriggerRecord(null, oldContact)`. The Skeleton's Finalizer registers on the unit its action kept, so call `writeOnAfterDelete` first.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/finalizer/other-contexts.md-->

## See Also {#see-also}

- [AfterDelete.Writer](/after-delete/writer#when-it-commits), for when the units commit
- [AfterDelete.RelatedQuery](/after-delete/add-ons/related-query), to load the remaining records
- [Execution Order & Cost](/guide/execution-order)
