---
template: add-on
context: AfterUndelete
interface: Finalizer
description: Run code once per chunk after an after undelete Writer or Dispatcher, with the restored records that qualified - aggregate queries, bulk registrations.
---

# AfterUndelete.Finalizer

Runs once per chunk after a Writer or Dispatcher, with the restored records that qualified. Use it for one aggregate query or one bulk registration instead of one per record.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/finalizer/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Keep the unit of work in a field.** The Finalizer receives only the records. Store the `unitOfWork` from the action, as the Skeleton does. What you register here commits with the Writer's other writes.
- **Once per chunk.** Restoring 1,000 records runs it 5 times. It is not an end-of-restore hook.
- **Don't clear `records.getRecords()`.** It is the library's own list, not a copy. Clearing it makes a Writer with OwnUnitOfWork or ContinueOnError skip its commit.
- **Direct DML runs at once.** It is not merged with any unit of work.
