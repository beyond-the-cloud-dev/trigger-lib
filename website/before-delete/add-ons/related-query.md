---
template: add-on
context: BeforeDelete
interface: RelatedQuery
description: Query children, siblings or other records in a before delete Handler with one query per provider, while the rows are still linked.
---

# BeforeDelete.RelatedQuery

Query children, siblings or other records once per chunk, and read them per record with `record.getRelated(name)`.

**Signature**

<!--@include: @/_parts/generated/before-delete/related-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/related-query/skeleton.md-->

:::

## RecordsProvider {#records-provider}

**Signature**

<!--@include: @/_parts/generated/before-delete/related-query/records-provider.md-->

## Rules {#rules}

- **An unknown name throws.** `getRelated` throws `TriggerHandler.TriggerHandlerException` when no provider has that name.
- **Counts include the records being deleted.** A query here still returns them. To count what will remain, add `Id NOT IN :records.getIds()`.
- **Last chance for cascade children.** Children removed by a cascade delete run no delete triggers of their own. Read them here.
- **Runs even when nothing qualifies.** Return an empty list from `query` when no record can qualify.

::: warning
Sharing can hide rows. A `with sharing` provider misses rows the user cannot see, so a guard can let a delete through. Use `without sharing` when it must see every row.
:::
