---
template: record-api
context: BeforeInsert
description: What a before insert handler receives - InsertRecord, RejectableInsertRecord and InsertRecords - with every method.
---

# Record API in BeforeInsert

## Record {#record}

<!--@include: @/_parts/generated/before-insert/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/before-insert/collection-methods.md-->

## Good to Know {#good-to-know}

- **No Id yet.** Key maps by a lookup or a field value, never by `getId()`.
- **Predicates see earlier changes.** They count a value that an earlier handler set with `put`.
- **Only the Validator gets `addError`.** Elsewhere, call `record.getNewSObject().addError(…)`.
- **`0` and `false` are values.** They are not null, empty or blank.
- **Record types.** `isRecordTypeEqual` throws on an object without record types. An unknown name never matches.
