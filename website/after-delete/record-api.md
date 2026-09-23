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

## Good to Know {#good-to-know}

- **Ids without rows.** `getId()` and `getIds()` return the deleted Ids, but SOQL no longer finds those rows. Key queries by `getIdsOf(Contact.AccountId)`.
- **Lookups hold only the Id.** `((Contact) record.getOldSObject()).Account` is null. Declare a [PriorParentQuery](/after-delete/add-ons/prior-parent-query) and read `record.getOldParent('Account')`.
- **The old row is read-only.** Writing a field on `getOldSObject()` throws a `FinalException` that cannot be caught, not even with ContinueOnError.
- **`0` and `false` are values.** They are not null, empty or blank.
- **Record types.** `isRecordTypeEqual` throws on an object without record types. An unknown name never matches.
