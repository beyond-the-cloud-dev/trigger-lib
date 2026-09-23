---
template: record-api
context: AfterDelete
description: What an after delete handler can read from DeleteRecord and DeleteRecords — the old row, former parent (lookup) fields, related records, value predicates — and what maps to Trigger.old and Trigger.oldMap.
---

# Record API in AfterDelete

What an **after delete** handler receives and can read: the deleted record's old values (`Trigger.old`), its former parent (lookup) fields, related records, value predicates and bulk collections.

## What You Receive {#receive}

- `TriggerHandler.DeleteRecord`, one record, in the predicates and the action: `writeOnAfterDeleteWhen`, `writeOnAfterDelete` and `dispatchOnAfterDeleteWhen`.
- `TriggerHandler.DeleteRecords`, a collection, in `RecordsProvider.query` (every record in the chunk), and in `dispatchOnAfterDelete` and `finalizeAfterDelete` (the qualified records only).

## Accessors {#accessors}

<!--@include: @/_parts/generated/after-delete/accessors.md-->

## Change Detection {#change-detection}

Not available: a deleted record has only old values, so `DeleteRecord` has no `isChanged…` methods. Change detection exists in [BeforeUpdate](/before-update/record-api#change-detection) and [AfterUpdate](/after-update/record-api#change-detection).

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#after-delete-->

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

Here `isRecordTypeEqual` and `isRecordTypeNotEqual` read the `RecordTypeId` of the old row.

## Parents and Related {#parents}

- **Lookup Ids are still set, parent objects are not.** `((Contact) record.getOldSObject()).AccountId` holds the former account's Id, but `getOldSObject().Account` is null.
- **Former parents.** Declare the lookup with [PriorParentQuery](/after-delete/add-ons/prior-parent-query), `queryParentsOnAfterDelete()`, and read `record.getOldParent('Account')`. There is no `getNewParent` here.
- **Other records.** Declare a [RelatedQuery](/after-delete/add-ons/related-query) and read `record.getRelated('<provider name>')`.

## Collections {#collections}

<!--@include: @/_parts/generated/after-delete/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/after-delete/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#after-delete-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [AfterDelete](/after-delete/#records) overview
- [Record API](/api/record), for every method on every record type
- [Record Collections](/api/record-collections)
- [Record API in BeforeDelete](/before-delete/record-api), where the rows are still in the database
