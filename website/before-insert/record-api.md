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

## Rules {#rules}

- **No Id yet.** Key maps by a lookup or a field value, never by `getId()`.
- **Predicates see earlier changes.** They count a value that an earlier handler set with `put`.
- **`0` and `false` are values.** They are not null, empty or blank.
