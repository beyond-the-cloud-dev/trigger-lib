---
template: add-on
context: AfterDelete
interface: Finalizer
description: Run one step per chunk after an after delete Writer or Dispatcher - one aggregate query or one write per former parent.
---

# AfterDelete.Finalizer

Runs once after a Writer or Dispatcher has seen every record in the chunk, with the records that qualified. Use it for one aggregate query or one write per former parent.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/finalizer/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Not an end-of-statement hook.** A delete of 1,000 records runs it once per chunk of up to 200.
- **Keep the unit in a field.** The Finalizer gets no unit of work. Store the one from `writeOnAfterDelete`, as the Skeleton does. Its writes commit with the rest.
- **Aggregate over what remains.** The deleted rows are gone from SOQL, so a query over the former parents' children counts only the survivors.
- **A throw discards a ContinueOnError Writer's writes.** Its private unit commits after the Finalizer, so a swallowed exception skips that commit.
- **A Dispatcher's job is already enqueued.** Its Finalizer runs after the dispatch, so a throw here does not undo the job.
