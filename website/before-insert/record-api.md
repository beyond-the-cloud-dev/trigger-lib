---
template: record-api
context: BeforeInsert
description: What a before insert handler receives - InsertRecord, RejectableInsertRecord and InsertRecords - with every accessor, predicate and collection method.
---

# Record API in BeforeInsert

What a **before insert** handler receives in place of `Trigger.new`: the record types, their accessors and value predicates, parent (lookup) fields and related records, and the bulk collection that providers and Finalizers get.

## What You Receive {#receive}

<!--@include: @/_parts/generated/before-insert/records.md-->

## Accessors {#accessors}

<!--@include: @/_parts/generated/before-insert/accessors.md-->

## Change Detection {#change-detection}

Not available: an insert has no prior values, so there is no `isChanged` and no `getOldSObject()`. Use [BeforeUpdate](/before-update/record-api#change-detection).

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#before-insert-->

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

## Parents and Related {#parents}

- **Parents.** `record.getNewParent('Account')` returns the parent that a [ParentQuery](/before-insert/add-ons/parent-query) declared, loaded before the first handler runs and refreshed after each Populator. It is null when the lookup is empty, no active handler declared it, or no record with that Id exists. The row's own relationship field, such as `getNewSObject().Account`, stays empty in before insert.
- **Related records.** `record.getRelated('<provider name>')` returns what this handler's [RelatedQuery](/before-insert/add-ons/related-query) providers returned, with `getFirstWhereKeyEquals`, `getAllWhereKeyEquals`, `getRecords` and `isEmpty`.
- **No old side.** `InsertRecord` has no `getOldParent` and no `getOldSObject`.

## Collections {#collections}

<!--@include: @/_parts/generated/before-insert/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/before-insert/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#before-insert-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [Record API](/api/record): the full reference.
- [BeforeInsert](/before-insert/) overview, [BeforeInsert.Populator](/before-insert/populator) and [BeforeInsert.Validator](/before-insert/validator).
- [Record API in AfterInsert](/after-insert/record-api): the same records after the save, with an Id.
