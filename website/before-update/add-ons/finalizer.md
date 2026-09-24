---
template: add-on
context: BeforeUpdate
interface: Finalizer
description: Run once after a before update handler has processed the chunk, with the qualified records, for checks across records.
---

# BeforeUpdate.Finalizer

Run code once per chunk with the records that qualified, such as a duplicate check across records.

**Signature**

<!--@include: @/_parts/generated/before-update/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Put it on a Populator.** On a Validator, it receives only the records that Validator already rejected.
- **`put` works here.** `records.getRecords()` returns `UpdateRecord`s.
- **Reject with the field form.** `UpdateRecord` has no `addError`, so call it on a field of `getNewSObject()`, as the Skeleton does.
- **Only this chunk.** Other chunks of the same update are out of reach.

::: warning
No DML. If the Finalizer runs DML or publishes an event, the library throws, even with ContinueOnError.
:::
