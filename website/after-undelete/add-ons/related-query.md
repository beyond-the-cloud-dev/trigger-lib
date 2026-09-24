---
template: add-on
context: AfterUndelete
interface: RelatedQuery
description: Query children, siblings or configuration once per handler per run for restored records in an after undelete Writer or Dispatcher, and read them by key.
---

# AfterUndelete.RelatedQuery

Query children, siblings or other records once per handler per run, and read them per record with `record.getRelated(name)`.

**Signature**

<!--@include: @/_parts/generated/after-undelete/related-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/related-query/skeleton.md-->

:::

## RecordsProvider {#records-provider}

**Signature**

<!--@include: @/_parts/generated/after-undelete/related-query/records-provider.md-->

## Rules {#rules}

- **SOQL runs even when no record qualifies.** Return an empty list when no record can qualify.
- **SOQL sees the restored records.** Add `Id NOT IN :records.getIds()` to look only at other records.
- **Exact keys.** Keys are compared as text, case included. Normalize text keys the same way on both sides.
- **Unknown names throw.** `record.getRelated('<name>')` with a name the handler did not return throws `TriggerTypes.TriggerLibException`, even with ContinueOnError.

::: warning
Set sharing on the provider. Its SOQL runs under its own class's sharing keyword. An inner class does not take its outer class's keyword.
:::
