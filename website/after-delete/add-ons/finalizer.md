---
template: add-on
context: AfterDelete
interface: Finalizer
description: Run one step per chunk after an after delete Writer or Dispatcher - one aggregate query or one write per former parent.
---

# AfterDelete.Finalizer

Run code once per chunk with the records that qualified, such as one aggregate query or one write per former parent.

**Signature**

<!--@include: @/_parts/generated/after-delete/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-delete/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Keep the unit in a field.** The Finalizer gets no unit of work. Store the one from `writeOnAfterDelete`, as the Skeleton does. Its writes commit with the rest.
- **Aggregate over what remains.** The deleted rows are gone from SOQL, so a query over the former parents' children counts only the survivors.
- **A swallowed throw skips the commit, not the dispatch.** With ContinueOnError, a Writer's automatic unit commits after the Finalizer, so its writes are lost. A Dispatcher's call already ran.

::: info
Not an end-of-statement hook. A delete of 1,000 records runs it once per chunk of up to 200.
:::
