---
template: add-on
context: AfterUndelete
interface: RelatedQuery
description: Query children, siblings or configuration once per chunk for restored records in an after undelete Writer or Dispatcher, and read them by key.
---

# AfterUndelete.RelatedQuery

Queries other records once per chunk, such as children, siblings or configuration. Your handler reads them by key, with no SOQL per record.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/related-query/signature.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-undelete/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/related-query/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Runs before any predicate.** `query(records)` gets every record in the chunk and costs its SOQL even when none qualifies. Return an empty list when no record can qualify.
- **SOQL sees the restored records.** Add `Id NOT IN :records.getIds()` to look only at other records.
- **Exact keys.** Keys are compared as text, case included. Normalize text keys the same way on both sides.
- **Unknown names throw.** `record.getRelated('<name>')` with a name the handler did not return throws `TriggerHandler.TriggerHandlerException`, even with ContinueOnError.
- **Set sharing on the provider.** Its SOQL runs under its own class's sharing keyword. An inner class does not take its outer class's keyword.
