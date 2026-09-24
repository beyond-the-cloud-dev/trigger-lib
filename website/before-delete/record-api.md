---
template: record-api
context: BeforeDelete
description: What a before delete Handler receives - DeleteRecord and DeleteRecords - with every method.
---

# Record API in BeforeDelete

## Record {#record}

<!--@include: @/_parts/generated/before-delete/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/before-delete/collection-methods.md-->

## Rules {#rules}

- **Read-only, but takes errors.** Writing to `getOldSObject()` throws. `getOldSObject().addError('…')` blocks the delete of that record.
- **Lookups hold only the Id.** `((Contact) record.getOldSObject()).Account` is null. Declare a [PriorParentQuery](/before-delete/add-ons/prior-parent-query) and read `getOldParent('Account')`.
- **No merge winner yet.** `MasterRecordId` is set only in [AfterDelete](/after-delete/record-api).
