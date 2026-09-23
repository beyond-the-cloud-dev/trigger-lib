---
template: record-api
context: BeforeUpdate
description: What a before update handler receives - UpdateRecord, RejectableUpdateRecord and UpdateRecords - with every method.
---

# Record API in BeforeUpdate

## Record {#record}

<!--@include: @/_parts/generated/before-update/record-methods.md-->

## Records {#records}

<!--@include: @/_parts/generated/before-update/collection-methods.md-->

## Good to Know {#good-to-know}

- **Changes include earlier `put`s.** A value that an earlier handler set counts as a change.
- **Text changes ignore case.** `'Doe'` to `'DOE'` is not a change.
- **Only the Validator gets `addError`.** Elsewhere, call `record.getNewSObject().addError(…)`.
