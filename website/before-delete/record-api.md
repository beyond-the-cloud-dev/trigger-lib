---
template: record-api
context: BeforeDelete
description: "What a before delete Handler receives: DeleteRecord and DeleteRecords, the old row, its parents and related records, and the value predicates."
---

# Record API in BeforeDelete

What a **before delete** handler receives and can read: `DeleteRecord` and `DeleteRecords`, the old row (`Trigger.old`, `Trigger.oldMap`), its parent fields and related records, and the value predicates, with `addError` on the old row to block the delete.

## What You Receive {#receive}

- `TriggerHandler.DeleteRecord` in `qualifiesForBeforeDeleteWhen` and `onBeforeDelete`, one record per call.
- `TriggerHandler.DeleteRecords` in a RecordsProvider's `query` (every record in the chunk) and in `finalizeBeforeDelete` (the qualified records).

## Accessors {#accessors}

<!--@include: @/_parts/generated/before-delete/accessors.md-->

To block the delete of a record, call `record.getOldSObject().addError('…')`.

## Change Detection {#change-detection}

Not available: a deleted row has only old values, and `DeleteRecord` has no `isChanged` → [BeforeUpdate](/before-update/record-api#change-detection) or [AfterUpdate](/after-update/record-api#change-detection).

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#before-delete-->

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

## Parents and Related {#parents}

- **Lookup Ids are on the old row**, but relationship fields are empty: `((Contact) record.getOldSObject()).Account` is null.
- **`getOldParent('Account')`** returns the parent that a [PriorParentQuery](/before-delete/add-ons/prior-parent-query) declared, keyed by relationship name.
- **`getRelated('<provider name>')`** returns what a [RelatedQuery](/before-delete/add-ons/related-query) provider loaded. Children and records that look up to the rows being deleted can still be queried here.
- There is no `getNewParent`: a delete has no new row.

## Collections {#collections}

<!--@include: @/_parts/generated/before-delete/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/before-delete/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#before-delete-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [Record API](/api/record): every record type and method.
- [BeforeDelete.Handler](/before-delete/handler)
- [Record API in AfterDelete](/after-delete/record-api)
