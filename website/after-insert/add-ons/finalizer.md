---
template: add-on
context: AfterInsert
interface: Finalizer
description: Run once after an after insert Writer or Dispatcher has processed the chunk, with the records that qualified.
---

# AfterInsert.Finalizer

Runs once after a Writer or Dispatcher has processed the chunk, with the records that qualified. Use it for one write per parent instead of one per record.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/finalizer/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Keep the unit in a field.** The Finalizer gets no unit of work. Save the `unitOfWork` from the action in an instance field, as the Skeleton does.
- **Not once per statement.** A 1,000-record insert can call it 5 times.
- **Registrations commit with the rest.** An own or private unit commits right after the Finalizer. The shared unit commits after the last handler.
- **Don't empty the list.** `records.getRecords()` is the library's own list. When it ends up empty, the Writer's own or private unit is not committed.
- **Direct DML runs at once.** After insert has no DML guard, so an `insert` here skips the unit of work.
