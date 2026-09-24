---
template: record-api
context: AfterDelete
description: What an after delete handler receives - DeleteRecord and DeleteRecords - with every method.
---

# Record API in AfterDelete

## Record {#record}

<!--@include: @/_parts/generated/after-delete/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-delete/collection-methods.md-->

## Rules {#rules}

- **Ids without rows.** `getId()` and `getIds()` return the deleted Ids, but SOQL no longer finds those rows. Key queries by `getIdsOf(Contact.AccountId)`.
- **Lookups hold only the Id.** `((Contact) record.getOldSObject()).Account` is null. Declare a [PriorParentQuery](/after-delete/add-ons/prior-parent-query) and read `record.getOldParent('Account')`.
- **`0` and `false` are values.** They are not null, empty or blank.
