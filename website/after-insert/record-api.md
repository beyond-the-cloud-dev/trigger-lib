---
template: record-api
context: AfterInsert
description: What an after insert handler receives - InsertRecord and InsertRecords - with every accessor, predicate and collection method, and why put throws here.
---

# Record API in AfterInsert

What an **after insert** handler receives in place of `Trigger.new` and `Trigger.newMap`: the record and collection types, their accessors and value predicates, parent (lookup) fields and related records. The records are saved, have Ids and are read-only.

## What You Receive {#receive}

<!--@include: @/_parts/generated/after-insert/records.md-->

## Accessors {#accessors}

<!--@include: @/_parts/generated/after-insert/accessors.md-->

## Change Detection {#change-detection}

Not available: an insert has no prior values, so there is no `isChanged` and no `getOldSObject()`. Use [AfterUpdate](/after-update/record-api#change-detection).

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#after-insert-->

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

## Parents and Related {#parents}

- **`getNewParent(relationshipName)`** returns the parent that an [AfterInsert.ParentQuery](/after-insert/add-ons/parent-query) declared, for example `record.getNewParent('Account')`. Grandparent fields are read through it: `((Account) record.getNewParent('Account')).Owner.IsActive`. There is no `getOldParent` on `InsertRecord`.
- **`getRelated(providerName)`** returns the rows of an [AfterInsert.RelatedQuery](/after-insert/add-ons/related-query) provider. A name the handler did not return throws [`TriggerHandler.TriggerHandlerException`](/api/record#triggerhandlerexception).

## Collections {#collections}

<!--@include: @/_parts/generated/after-insert/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/after-insert/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#after-insert-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [Record API](/api/record): every record type in one place
- [AfterInsert](/after-insert/): the context overview
- [Record API in AfterUpdate](/after-update/record-api): change detection and old values
