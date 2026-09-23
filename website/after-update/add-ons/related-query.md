---
template: add-on
context: AfterUpdate
interface: RelatedQuery
description: Query children, siblings or any other records once per chunk in an after update Writer or Dispatcher, and read them per record by key.
---

# AfterUpdate.RelatedQuery

Queries children, siblings or any other records once per chunk, and reads them per record by key. No SOQL in the predicate or the action.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/related-query/signature.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/after-update/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/related-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [Children by AccountId]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Open opportunities]

:::

## Good to Know {#good-to-know}

- **Read your own providers by name.** Call `record.getRelated('contacts').getAllWhereKeyEquals(record.getId())`. An unknown name throws `TriggerHandler.TriggerHandlerException`, even with ContinueOnError.
- **Keys match exactly.** Keys compare as text, case included. Normalize text keys the same way in `keyOf` and in the lookup.
- **Providers run even when nothing qualifies.** They run before the first predicate, with every record in the chunk. Return an empty list from `query` when no record can qualify.
- **Both rows.** `records.getIdsOf(…)` reads the new rows and `records.getOldIdsOf(…)` the old ones. SOQL sees the saved new values. Add `Id NOT IN :records.getIds()` to leave out the trigger records.
- **Declare sharing on every provider class.** A provider's query runs under its own class's sharing keyword. An inner class does not take its outer class's keyword.
