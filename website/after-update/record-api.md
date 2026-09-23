---
template: record-api
context: AfterUpdate
description: 'What an after update handler reads: UpdateRecord and UpdateRecords accessors, change detection on old and new values, value predicates, parents, collections and the Trigger.new, Trigger.old and Trigger.oldMap equivalents.'
---

# Record API in AfterUpdate

What an **after update** Writer or Dispatcher can read from a record: the saved new row and the old row (`Trigger.new`, `Trigger.old`, `Trigger.oldMap`), change detection, value predicates, parent (lookup) fields and related records. Both rows are read-only here.

## What You Receive {#receive}

- `TriggerHandler.UpdateRecord`, one record with both rows, in `writeOnAfterUpdateWhen`, `writeOnAfterUpdate` and `dispatchOnAfterUpdateWhen`.
- `TriggerHandler.UpdateRecords`, a collection, in `RecordsProvider.query` (every record in the chunk), `dispatchOnAfterUpdate` and `finalizeAfterUpdate` (the qualified records).

## Accessors {#accessors}

<!--@include: @/_parts/generated/after-update/accessors.md-->

## Change Detection {#change-detection}

<!--@include: @/_parts/records/change-detection.md-->

In after update, gate Writers and Dispatchers on a change: a nested update run, or a later update in the same transaction that does not touch the field, then does not qualify the record again.

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#after-update-->

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

## Parents and Related {#parents}

- `record.getNewParent('Account')` returns the parent the lookup points to now, loaded by [ParentQuery](/after-update/add-ons/parent-query).
- `record.getOldParent('Account')` returns the parent the lookup pointed to before the update, loaded by [PriorParentQuery](/after-update/add-ons/prior-parent-query). When the lookup did not change and both sides are declared, the two return the same record.
- `record.getRelated('<provider name>')` returns what a [RelatedQuery](/after-update/add-ons/related-query) provider loaded. A name the handler did not return throws `TriggerHandler.TriggerHandlerException`; see [TriggerHandlerException](/api/record#triggerhandlerexception).
- Relationship names are case-sensitive, and relationship fields on the rows themselves, such as `getNewSObject().Account`, are empty.

## Collections {#collections}

<!--@include: @/_parts/generated/after-update/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/after-update/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#after-update-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [Record API](/api/record): the full reference.
- [Record API in BeforeUpdate](/before-update/record-api): the same record type, where the new row can still be written.
- [AfterUpdate.Writer](/after-update/writer) and [AfterUpdate.Dispatcher](/after-update/dispatcher)
