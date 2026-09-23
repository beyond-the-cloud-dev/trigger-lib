---
template: record-api
context: AfterUndelete
description: What an after undelete handler can read from a restored record - Id, the read-only new row, parent (lookup) fields, related records, predicates - and how Trigger.new maps to it.
---

# Record API in AfterUndelete

What an **after undelete** Writer, Dispatcher, provider or Finalizer can read from the restored records: the Id, the read-only new row, parent (lookup) fields, related records and value predicates. There is no old row, no `put` and no change detection.

## What You Receive {#receive}

- `TriggerHandler.UndeleteRecord`, one restored record, goes to `writeOnAfterUndeleteWhen`, `writeOnAfterUndelete` and `dispatchOnAfterUndeleteWhen`.
- `TriggerHandler.UndeleteRecords`, a collection, goes to `RecordsProvider.query` with every record in the chunk, and to `dispatchOnAfterUndelete` and `finalizeAfterUndelete` with the qualified records only.

## Accessors {#accessors}

<!--@include: @/_parts/generated/after-undelete/accessors.md-->

## Change Detection {#change-detection}

Not available: a restore has no old row, so `UndeleteRecord` has no `isChanged` methods. The restored record has the values it had when it was deleted. Change detection exists in [BeforeUpdate](/before-update/record-api#change-detection) and [AfterUpdate](/after-update/record-api#change-detection).

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#after-undelete-->

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

## Parents and Related {#parents}

- `record.getNewParent('Account')` returns the parent that a [ParentQuery](/after-undelete/add-ons/parent-query) declared, by relationship name, and grandparents through it: `((Account) record.getNewParent('Account')).Owner.IsActive`. There is no `getOldParent` here.
- `record.getRelated('<provider name>')` returns the rows of this handler's [RelatedQuery](/after-undelete/add-ons/related-query) provider, read with `getFirstWhereKeyEquals(key)`, `getAllWhereKeyEquals(key)` or `getRecords()`. An unknown name throws [`TriggerHandlerException`](/api/record#triggerhandlerexception).

## Collections {#collections}

<!--@include: @/_parts/generated/after-undelete/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/after-undelete/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#after-undelete-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [AfterUndelete overview](/after-undelete/)
- [Record API reference](/api/record)
- [Record API in AfterInsert](/after-insert/record-api)
