---
template: record-api
context: AfterUndelete
description: What an after undelete handler receives - UndeleteRecord and UndeleteRecords - with every method.
---

# Record API in AfterUndelete

## Record {#record}

<!--@include: @/_parts/generated/after-undelete/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-undelete/collection-methods.md-->

## Rules {#rules}

- **No change detection.** The record holds the values it had when it was deleted.
- **Reject with `addError`.** `record.getNewSObject().addError(…)` keeps that record in the Recycle Bin.
- **`0` and `false` are values.** They are not null, empty or blank.
