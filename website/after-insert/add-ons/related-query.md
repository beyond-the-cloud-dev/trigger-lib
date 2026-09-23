---
template: add-on
context: AfterInsert
interface: RelatedQuery
description: Query children, siblings or other records once per chunk in an after insert Writer or Dispatcher, and read them by key per record.
---

# AfterInsert.RelatedQuery

Queries other records once per chunk, such as the other contacts of the same account, without SOQL in your loop. Read the rows per record with `record.getRelated('<provider name>')`.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/related-query/signature.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-insert/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/related-query/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **SOQL sees the new records.** They are saved but not committed. Add `Id NOT IN :records.getIds()` to leave them out.
- **Providers run before any predicate.** They query even when no record qualifies. Return an empty list from `query` when no record can qualify.
- **Keys are case-sensitive.** Normalize text keys the same way in `keyOf` and when you read.
- **Unknown names throw.** `getRelated` with a name the handler did not return throws `TriggerHandler.TriggerHandlerException`, even with ContinueOnError.
- **Set sharing on the provider.** Its query runs under its own class's sharing keyword. An inner class does not take its outer class's keyword.
