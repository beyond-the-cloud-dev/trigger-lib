---
template: add-on
context: AfterUpdate
interface: RelatedQuery
description: 'Query children, siblings or any other records once per run in an after update Writer or Dispatcher, and read them per record by key.'
---

# AfterUpdate.RelatedQuery

Query children, siblings or any other records once per run in an **after update** Writer or Dispatcher, and read them per record by key, without SOQL in the predicate or the action.

<!--@include: @/_parts/generated/after-update/related-query/available-in.md-->

## When to Use {#when-to-use}

- The handler needs records that do not hang off a lookup of the trigger record: children (the account's contacts), siblings (other opportunities of the same account), records matched by a text value, or configuration.
- One query for the whole chunk, read per record by a key such as `AccountId`.
- Use [ParentQuery](/after-update/add-ons/parent-query) or [PriorParentQuery](/after-update/add-ons/prior-parent-query) for fields of the record a lookup points to.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/related-query/signature.md-->

<!--@include: @/_parts/generated/after-update/related-query/method-table.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-update/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/related-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [Children by AccountId]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Open opportunities]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-after-->

- **Both sides of the lookups.** `records.getIdsOf(Contact.AccountId)` reads the new rows and `records.getOldIdsOf(Contact.AccountId)` the old ones, so a provider can load the records of the previous parent too, for example the contacts left behind on the account a contact moved away from.
- **Current formula and roll-up values.** To read them for the trigger records, query the trigger object in a provider: see "The trigger records themselves" under Key Patterns.

### Key Patterns {#key-patterns}

::: details Provider patterns: children, siblings, text key, composite key, configuration, dependent query, several contexts, the trigger records themselves

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

- `queryRelatedOnAfterUpdate()` takes no records. It returns the providers by name, once per run.
- Each provider's `query(records)` receives `TriggerHandler.UpdateRecords` with every record in the chunk, qualified or not: `getIds()`, `getIdsOf(…)`, `getOldIdsOf(…)`, `getValuesOf(…)` and `getOldValuesOf(…)` all work here.
- The handler reads the rows per record with `record.getRelated('<provider name>')`, in the predicate, the action, the dispatch or the Finalizer.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/related-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

- **Registrations are not visible yet.** A provider runs at its handler's turn, so it does not see what earlier Writers registered on the shared unit. It does see rows an earlier Writer's own or private unit has already committed.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

`AccountAddressCascadeWriter` reads its provider as `'contacts'`, keyed by `AccountId`, so group each contact under the account's Id.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [RelatedRecords & RecordsProvider](/api/related-records)
- [Record Collections](/api/record-collections)
- [Testing](/guide/testing)
