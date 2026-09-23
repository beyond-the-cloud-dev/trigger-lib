---
template: add-on
context: BeforeUpdate
interface: Finalizer
description: Run once after a before update handler has processed the chunk, with the qualified records, for checks across records.
---

# BeforeUpdate.Finalizer

Runs once after the handler has processed the chunk, with the records that qualified. Use it for checks across records, such as duplicates within one save.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/finalizer/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Put it on a Populator.** On a Validator, it receives only the records that Validator already rejected.
- **`put` works here.** `records.getRecords()` returns `UpdateRecord`s. On a Populator, a lookup the Finalizer re-points is loaded before the next handler runs.
- **Reject with the field form.** `UpdateRecord` has no `addError`. Call `((Contact) record.getNewSObject()).Email.addError(message)`, as the Skeleton does.
- **Only this chunk.** Other chunks of the same update are out of reach. A query returns their saved values.
- **No DML.** If the Finalizer runs DML or publishes an event, the library throws, even with ContinueOnError.
