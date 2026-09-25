---
template: add-on
context: AfterInsert
interface: RelatedQuery
description: Query children, siblings or other records once per handler per run in an after insert Writer or Dispatcher, and read them by key per record.
---

# AfterInsert.RelatedQuery

Query children, siblings or other records once per handler per run, and read them per record with `record.getRelated(name)`.

**Signature**

<!--@include: @/_parts/generated/after-insert/related-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/related-query/skeleton.md-->

:::

## RecordsProvider {#records-provider}

**Signature**

<!--@include: @/_parts/generated/after-insert/related-query/records-provider.md-->

## Rules {#rules}

- **SOQL sees the new records.** They are saved but not committed. Add `Id NOT IN :records.getIds()` to leave them out.
- **Providers query on the first read.** A provider queries when the handler first calls `getRelated` with its name. A read in a predicate queries even when no record qualifies, so return an empty list from `query` when no record can qualify.
- **Keys are case-sensitive.** Normalize text keys the same way in `keyOf` and when you read.
- **Unknown names throw.** `getRelated` with a name the handler did not return throws `TriggerTypes.TriggerLibException`, even with ContinueOnError.

::: warning
Set sharing on the provider. Its query runs under its own class's sharing keyword, and an inner class does not take its outer class's keyword.
:::
