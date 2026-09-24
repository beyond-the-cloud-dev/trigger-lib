---
template: add-on
context: BeforeInsert
interface: Finalizer
description: Run code once after a before insert handler has processed its records, with the records that qualified, for checks across records.
---

# BeforeInsert.Finalizer

Run code once per chunk with the records that qualified, such as a duplicate check across the new records.

**Signature**

<!--@include: @/_parts/generated/before-insert/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-insert/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Put it on a Populator.** A Validator's qualified records already carry an error, so its Finalizer sees only rejected records.
- **Reject on the row.** `InsertRecord` has no `addError`. Call it on a field of `record.getNewSObject()`.
- **One chunk at a time.** A 1,000-record insert runs in five chunks of 200. Duplicates in different chunks are never compared.
- **Skipped after a swallowed exception.** With [ContinueOnError](/before-insert/add-ons/continue-on-error), an exception in the predicate or the action skips the Finalizer for that chunk.

::: warning
No DML. If the Finalizer runs DML or publishes an event, the library throws, even with ContinueOnError.
:::
