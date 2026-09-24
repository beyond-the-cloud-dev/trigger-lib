---
template: add-on
context: BeforeUpdate
interface: RelatedQuery
description: Load children, siblings or other records once per handler per run in before update, keyed for fast reads, instead of a query per record.
---

# BeforeUpdate.RelatedQuery

Query children, siblings or other records once per handler per run, and read them per record with `record.getRelated(name)`.

**Signature**

<!--@include: @/_parts/generated/before-update/related-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/related-query/skeleton.md-->

:::

## RecordsProvider {#records-provider}

**Signature**

<!--@include: @/_parts/generated/before-update/related-query/records-provider.md-->

## Rules {#rules}

- **SOQL sees the saved values.** A query on the records being updated returns their values from before this update. Two records in one chunk that change to the same email do not find each other; compare them in a [Finalizer](/before-update/add-ons/finalizer).
- **Exclude the records themselves.** To look at other records of the same object, add `Id NOT IN :records.getIds()`.
- **Keys match exactly.** Key lookups are case-sensitive. Normalize text keys the same way in `keyOf` and in the lookup.
- **Runs on every pass.** Providers query for every chunk and every nested update, even when no record qualifies.

::: warning
The provider sets the sharing. Its SOQL runs under the provider class's own sharing keyword. Use `without sharing` when a check must see every record.
:::
