---
template: add-on
context: BeforeInsert
interface: Finalizer
description: Run code once after a before insert handler has processed its records, with the records that qualified, for checks across records.
---

# BeforeInsert.Finalizer

Runs once after the handler has processed every record of the chunk, with the records that qualified. Use it for checks across records, such as two new contacts with the same email.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/finalizer/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Put it on a Populator.** A Validator's qualified records already carry an error, so its Finalizer sees only rejected records. The Skeleton normalizes emails in the action and rejects duplicates here.
- **Reject on the row.** `InsertRecord` has no `addError`. Call `((Contact) record.getNewSObject()).Email.addError(message)` to keep the message on the field.
- **One chunk at a time.** A 1,000-record insert runs in five chunks of 200. Duplicates in different chunks are never compared.
- **No DML.** If the Finalizer runs DML or publishes an event, the library throws, even with ContinueOnError.
- **Skipped after a swallowed exception.** With [ContinueOnError](/before-insert/add-ons/continue-on-error), an exception in the predicate or the action skips the Finalizer for that chunk.
