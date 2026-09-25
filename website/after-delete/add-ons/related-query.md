---
template: add-on
context: AfterDelete
interface: RelatedQuery
description: Query the records that remain after a delete, or records that still look up to the deleted rows, once per handler per run in an after delete handler.
---

# AfterDelete.RelatedQuery

Query children, siblings or other records once per handler per run, and read them per record with `record.getRelated(name)`.

**Signature**

<!--@include: @/_parts/generated/after-delete/related-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-delete/related-query/skeleton.md-->

:::

## RecordsProvider {#records-provider}

**Signature**

<!--@include: @/_parts/generated/after-delete/related-query/records-provider.md-->

## Rules {#rules}

- **Inbound lookups may be stale.** Records that looked up to a deleted row may still point at it during this trigger. Exclude them with `AND ReportsToId NOT IN :records.getIds()`.
- **Providers run on the first read.** A provider queries when the handler first calls `getRelated` with its name, at most once per chunk. A read in a predicate costs its SOQL even when nothing qualifies.
- **Write once per parent.** Two deleted contacts of one account both see the same remaining contacts. Write to the account once from a [Finalizer](/after-delete/add-ons/finalizer).
- **Set sharing on the provider.** Its SOQL runs under the provider class's own sharing keyword. An inner class does not inherit its outer class's keyword.

::: warning
Deleted rows are invisible. A query by `records.getIds()` finds nothing, with no error. Key providers by the old lookups: `records.getIdsOf(Contact.AccountId)`.
:::
