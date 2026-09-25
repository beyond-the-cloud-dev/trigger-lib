---
template: add-on
context: AfterUpdate
interface: RelatedQuery
description: Query children, siblings or any other records once per handler per run in an after update Writer or Dispatcher, and read them per record by key.
---

# AfterUpdate.RelatedQuery

Query children, siblings or other records once per handler per run, and read them per record with `record.getRelated(name)`.

**Signature**

<!--@include: @/_parts/generated/after-update/related-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/related-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [Children by AccountId]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Open opportunities]

:::

## RecordsProvider {#records-provider}

**Signature**

<!--@include: @/_parts/generated/after-update/related-query/records-provider.md-->

## Rules {#rules}

- **Read your own providers by name.** Call `record.getRelated('contacts').getAllWhereKeyEquals(record.getId())`. An unknown name throws `TriggerTypes.TriggerLibException`, even with ContinueOnError.
- **Keys match exactly, case included.** Normalize text keys the same way in `keyOf` and in the lookup.
- **Providers run on the first read.** A provider queries when the handler first calls `getRelated` with its name. A read in a predicate queries even when nothing qualifies, so return an empty list from `query` when no record can qualify.
- **Both rows.** `records.getIdsOf(…)` reads the new rows and `records.getOldIdsOf(…)` the old ones. SOQL sees the saved new values. Add `Id NOT IN :records.getIds()` to leave out the trigger records.

::: warning
Declare sharing on every provider class. An inner class does not take its outer class's keyword.
:::
