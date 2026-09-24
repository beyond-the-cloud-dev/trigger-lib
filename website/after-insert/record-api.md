---
template: record-api
context: AfterInsert
description: What an after insert handler receives - InsertRecord and InsertRecords - with every method.
---

# Record API in AfterInsert

## Record {#record}

<!--@include: @/_parts/generated/after-insert/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-insert/collection-methods.md-->

## Rules {#rules}

- **Ids are set.** Key maps by `getId()`, and pass `records.getIds()` to async work.
- **`put` fails the insert.** Nothing catches the exception, not even ContinueOnError. Register `toUpdate` with the record Id in a Writer instead.
- **Reject with the row.** `record.getNewSObject().addError(…)` fails that record like a validation error.
