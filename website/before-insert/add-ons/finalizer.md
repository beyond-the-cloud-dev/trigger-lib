---
template: add-on
context: BeforeInsert
interface: Finalizer
description: Run code once after a before insert handler has processed its records, with the records that qualified, for checks across records.
---

# BeforeInsert.Finalizer

Run code once after a **before insert** handler has processed every record of the chunk (a post-processing or "after all records" hook for that handler), with the records that qualified. Use it for checks across records, such as duplicates within one import, which the per-record methods cannot see.

<!--@include: @/_parts/generated/before-insert/finalizer/available-in.md-->

## When to Use {#when-to-use}

- Compare the records of one save with each other, such as two new contacts with the same email.
- Work that needs every qualified record at once, such as a total across the chunk.

Use a [RelatedQuery](/before-insert/add-ons/related-query) instead to compare with records already in the database, and an [AfterInsert.Writer](/after-insert/writer) for anything that needs DML.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/finalizer/signature.md-->

<!--@include: @/_parts/generated/before-insert/finalizer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/finalizer/skeleton.md-->

:::

The Skeleton is a Populator on purpose: it normalizes every email in its action, then rejects the second record with the same email in its Finalizer. A Validator would not do: every record it qualifies must already carry an error, so its Finalizer sees only rejected records.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#before-->

## Records Here {#records}

`finalizeBeforeInsert` receives a `TriggerHandler.InsertRecords` with only the records this handler qualified. `getIds()` is empty here, and `getRecords()` returns the library's own list, not a copy (see [Record Collections](/api/record-collections)). Each item is an `InsertRecord`: it has `put`, and no `addError`.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **Rejecting from the Finalizer.** `InsertRecord` has no `addError`. Call it on the row: `record.getNewSObject().addError(message)`, or the field form on the cast row, such as `((Contact) record.getNewSObject()).Email.addError(message)`, which keeps the message on the field.
- **Only this chunk.** A 1,000-record insert runs in five chunks of 200, each with its own Finalizer call, so duplicates that land in different chunks are never compared.
- **Skipped after a swallowed failure.** With ContinueOnError, an exception in the predicate or the action skips the Finalizer for that chunk.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

For the Skeleton, pass two records with the same email in `qualified`, then assert that the second row `hasErrors()`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/finalizer/other-contexts.md-->

## See Also {#see-also}

- [BeforeInsert.Populator](/before-insert/populator) and [BeforeInsert.Validator](/before-insert/validator).
- [BeforeDelete.Finalizer](/before-delete/add-ons/finalizer), where DML is allowed.
- [Execution Order & Cost](/guide/execution-order).
