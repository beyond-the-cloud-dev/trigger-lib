---
template: record-api
context: BeforeUpdate
description: The record API in before update. The writable new row, the read-only old row, change detection, value predicates, parents, related records and collections.
---

# Record API in BeforeUpdate

What a **before update** handler receives and how to read it: the new values (`Trigger.new`, writable with `put`), the old values (`Trigger.old`, `Trigger.oldMap`, read-only), change detection (`isChanged`, old value vs new value), value predicates, parents, related records and collections.

## What You Receive {#receive}

- `TriggerHandler.UpdateRecord` in `populateOnBeforeUpdateWhen`, `populateOnBeforeUpdate` and `errorShouldBeAttachedOnBeforeUpdateWhen`.
- `TriggerHandler.RejectableUpdateRecord` in `addErrorOnBeforeUpdate`: the same predicates and read accessors, no `put`, plus `addError(String)` and `addError(SObjectField, String)`.
- `TriggerHandler.UpdateRecords` in `RecordsProvider.query`, with every record in the chunk, and in `finalizeBeforeUpdate`, with the qualified records only.

## Accessors {#accessors}

<!--@include: @/_parts/generated/before-update/accessors.md-->

## Change Detection {#change-detection}

<!--@include: @/_parts/records/change-detection.md-->

In before update, change detection reads the new row as it is now. A value that an earlier Populator put counts as a change for every later handler, and putting the old value back makes the field unchanged for them.

::: code-group

<<< @/../examples/main/default/classes/account/before-update/populator/AccountShippingSyncPopulator.cls [isAnyChanged and the old row]

<<< @/../examples/main/default/classes/contact/before-update/validator/ContactDoNotCallValidator.cls [isChangedTo]

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityReopenValidator.cls [isChangedFrom]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactTitleDepartmentPopulator.cls [isChanged and isBlank]

:::

## Value Predicates {#predicates}

<!--@include: @/_parts/records/predicates.md#before-update-->

`ContactEmailRemovalValidator` combines change detection with two value predicates, `isBlank` and `isFalse`:

<<< @/../examples/main/default/classes/contact/before-update/validator/ContactEmailRemovalValidator.cls

## Comparisons {#comparisons}

<!--@include: @/_parts/records/comparisons.md-->

## Record Type {#record-type}

<!--@include: @/_parts/records/record-type.md-->

In before update, `isRecordTypeEqual` reads the new row, so it tests the record type the record is changing to. To react to the change itself, use `isChanged(Opportunity.RecordTypeId)`.

## Parents and Related {#parents}

- `getNewParent(relationshipName)` returns the current parent, loaded by [ParentQuery](/before-update/add-ons/parent-query). After a Populator points the lookup somewhere new, every later handler gets the new parent.
- `getOldParent(relationshipName)` returns the previous parent, loaded by [PriorParentQuery](/before-update/add-ons/prior-parent-query). It is loaded once per run and never refreshed.
- `getRelated(providerName)` returns what a [RelatedQuery](/before-update/add-ons/related-query) provider loaded. An unknown name throws `TriggerHandler.TriggerHandlerException`.
- Relationship fields on the rows themselves, such as `getNewSObject().Account`, are empty.

## Collections {#collections}

<!--@include: @/_parts/generated/before-update/collections.md-->

Every collection method, and why `getRecords()` returns the internal list rather than a copy: [Record Collections](/api/record-collections).

## From Trigger Variables {#trigger-variables}

<!--@include: @/_parts/generated/before-update/trigger-variables.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/records/gotchas.md#before-update-->

Rules that hold in every context: [Comparisons](#comparisons) and [Record Type](#record-type).

## See Also {#see-also}

- [Record API reference](/api/record)
- [Record Collections](/api/record-collections)
- [Record API in AfterUpdate](/after-update/record-api)
- [Record API in BeforeInsert](/before-insert/record-api)
