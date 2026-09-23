---
template: record-api
context: AfterUpdate
description: What an after update handler receives - UpdateRecord and UpdateRecords - with every method, change detection included.
---

# Record API in AfterUpdate

## Record {#record}

<!--@include: @/_parts/generated/after-update/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-update/collection-methods.md-->

## Good to Know {#good-to-know}

- **Both rows are read-only.** Any write throws `System.FinalException`, which no `catch` stops.
- **Parents are not on the row.** `getNewSObject().Account` is null. Read `getNewParent` or `getOldParent`.
- **`getRecords()` is not a copy.** Removing items also removes them from what the Finalizer receives.
