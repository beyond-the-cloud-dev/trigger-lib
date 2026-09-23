---
template: add-on
context: AfterInsert
interface: RelatedQuery
description: AfterInsert.RelatedQuery - query children, siblings or configuration once per run in an after insert Writer or Dispatcher, and read the rows by key per record.
---

# AfterInsert.RelatedQuery

Query other records once per run in **after insert**, such as the other contacts of the same account, possible duplicates or configuration rows, and read them per record by key, without SOQL in your loop. Each provider runs one query over the whole chunk; the handler reads the rows with `record.getRelated('<provider name>')`.

<!--@include: @/_parts/generated/after-insert/related-query/available-in.md-->

## When to Use {#when-to-use}

- A predicate or action needs records that no lookup on the trigger object points to: children, siblings, records that share a value, custom metadata.
- The trigger records' own formula or roll-up values, read back from the database.
- Use a [ParentQuery](/after-insert/add-ons/parent-query) instead for fields of the record a lookup points to.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/related-query/signature.md-->

<!--@include: @/_parts/generated/after-insert/related-query/method-table.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-insert/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/related-query/skeleton.md-->

:::

The Skeleton's provider loads every contact of the new contacts' accounts, the new contacts included: they are saved, so SOQL sees them. Worked Writers with children providers, in after update: [AfterUpdate.RelatedQuery](/after-update/add-ons/related-query#example).

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-after-->

A record inserted in this statement has no children yet, unless they were created earlier in the same transaction. To reach the parent's other children, filter by the lookup: `records.getIdsOf(Contact.AccountId)`.

### Key Patterns {#key-patterns}

::: details Children, siblings, text and composite keys, configuration, dependent queries

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

`query(records)` receives `InsertRecords` with every record in the chunk, not only the ones that will qualify: providers run before the first predicate. `records.getIds()` works here.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/related-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

- **No DML guard.** DML in a provider runs at once in after insert, outside any unit of work. Keep providers read-only.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

For the Skeleton, group each contact under its `AccountId` and register the result as `'accountContacts'`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [RelatedRecords & RecordsProvider](/api/related-records)
- [Record API in AfterInsert](/after-insert/record-api#parents)
