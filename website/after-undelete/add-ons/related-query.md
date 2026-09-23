---
template: add-on
context: AfterUndelete
interface: RelatedQuery
description: Query children, siblings or configuration once per run for restored records in an after undelete Writer or Dispatcher, and read them by key.
---

# AfterUndelete.RelatedQuery

Query other records once per run, such as children, siblings, records that share a value, or configuration, for the records restored in **after undelete**, and read them by key in your handler instead of running SOQL per record.

<!--@include: @/_parts/generated/after-undelete/related-query/available-in.md-->

## When to Use {#when-to-use}

- The handler needs records that no lookup of the restored record points to: its children, its siblings under the same parent, or records with the same email.
- The handler needs formula or roll-up values of the restored records themselves, which the trigger rows do not carry.
- Use [ParentQuery](/after-undelete/add-ons/parent-query) instead for fields of the record a lookup points to.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/related-query/signature.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-undelete/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/related-query/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-after-->

### Key Patterns {#key-patterns}

::: details Children, siblings, text and composite keys, configuration, dependent queries, the trigger records themselves

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

`query(records)` receives `TriggerHandler.UndeleteRecords` with every restored record in the chunk, qualified or not: `getIds()`, `getIdsOf(…)`, `getValuesOf(…)`, `size()` and `getRecords()`. The RelatedQuery method itself takes no records.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/related-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

- **Records linked to a restored record may not be back yet.** Salesforce restores cascade-deleted children with their parent and restores cleared inbound lookups only when they were not changed in the meantime. Whether either is visible to a provider while AfterUndelete runs has not been verified, so check in a sandbox before a restore handler relies on them.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

With the Skeleton above, the provider name is `'accountContacts'` and the key is the contact's `AccountId`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [RelatedRecords & RecordsProvider](/api/related-records)
- [Record Collections](/api/record-collections)
