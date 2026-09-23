---
template: add-on
context: AfterDelete
interface: RelatedQuery
description: Query the records that remain after a delete, or records that still look up to the deleted rows, once per chunk in an after delete handler.
---

# AfterDelete.RelatedQuery

Loads records other than parents with one query per provider, instead of SOQL per record. Use it to recompute a former parent from the records that remain.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/related-query/signature.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-delete/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/related-query/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Deleted rows are invisible.** A query by `records.getIds()` finds nothing, with no error. Key providers by the old lookups: `records.getIdsOf(Contact.AccountId)`.
- **Inbound lookups may be stale.** Records that looked up to a deleted row may still point at it during this trigger. Exclude them with `AND ReportsToId NOT IN :records.getIds()`.
- **Providers run even when nothing qualifies.** They run before the first predicate and cost their SOQL on every chunk.
- **Write once per parent.** Two deleted contacts of one account both see the same remaining contacts. Write to the account once from a [Finalizer](/after-delete/add-ons/finalizer).
- **Set sharing on the provider.** Its SOQL runs under the provider class's own sharing keyword. An inner class does not inherit its outer class's keyword.
