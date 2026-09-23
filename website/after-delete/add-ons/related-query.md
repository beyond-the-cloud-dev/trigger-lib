---
template: add-on
context: AfterDelete
interface: RelatedQuery
description: Query the records that remain after a delete (siblings, other children of the former parent), records that still look up to the deleted rows, or configuration, once per run in an after delete handler.
---

# AfterDelete.RelatedQuery

Load records other than parents in **after delete**, with one query per provider instead of SOQL per record: the records that remain (siblings, the former parent's other children), records that still look up to the deleted rows, or configuration.

<!--@include: @/_parts/generated/after-delete/related-query/available-in.md-->

## When to Use {#when-to-use}

- Recompute a parent from the records that remain. The deleted rows no longer come back from SOQL, so a query over the former parent's children already leaves them out.
- Find records that still look up to the deleted rows, before the platform clears those lookups.
- Load configuration or other unrelated records once per run.
- Use [PriorParentQuery](/after-delete/add-ons/prior-parent-query) instead for fields of the former parent itself.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/related-query/signature.md-->

<!--@include: @/_parts/generated/after-delete/related-query/method-table.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-delete/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/related-query/skeleton.md-->

:::

The provider keys the remaining contacts by `AccountId`, taken from the old rows with `records.getIdsOf(Contact.AccountId)`. It needs no `Id NOT IN :records.getIds()`, because the deleted contacts are already gone.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-after-delete-->

Recompute by querying again here, where the deleted rows are already gone. To subtract from a stored total instead, work in [BeforeDelete](/before-delete/add-ons/related-query), where the rows are still present and linked.

### Key Patterns {#key-patterns}

::: details Provider patterns: children, siblings, text and composite keys, configuration

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

- `query(records)` receives `DeleteRecords` with every record in the chunk, qualified or not.
- The handler reads the result with `record.getRelated('<provider name>')`, then `getFirstWhereKeyEquals`, `getAllWhereKeyEquals`, `getRecords` or `isEmpty`.
- Keys are compared as text: `getAllWhereKeyEquals(accountId)` matches the `String` that `keyOf` returned for the same Id.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/related-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

- **Querying the deleted Ids finds nothing, forever.** A provider that selects from the trigger object `WHERE Id IN :records.getIds()` returns zero rows on every run, with no error. Filter by the old lookups instead.
- **One parent, several deleted records.** Two deleted contacts of the same account both see the same remaining contacts, so an action that writes to the account runs once per deleted contact. Write once per parent from a [Finalizer](/after-delete/add-ons/finalizer) that loops over `records.getIdsOf(Contact.AccountId)`.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

For the Skeleton, the provider name is `'accountContacts'`, and each row is grouped under its `AccountId`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [RelatedRecords & RecordsProvider](/api/related-records)
- [AfterDelete.PriorParentQuery](/after-delete/add-ons/prior-parent-query), for the former parent's fields
- [Record API in AfterDelete](/after-delete/record-api#parents)
