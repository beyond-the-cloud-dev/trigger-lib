---
template: add-on
context: BeforeDelete
interface: Finalizer
description: Run once per chunk after a before delete Validator or Writer, with the qualified records - one bulk registration or one check across records.
---

# BeforeDelete.Finalizer

Run code once per chunk with the records that qualified, such as one registration per parent.

**Signature**

<!--@include: @/_parts/generated/before-delete/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Keep the unit in a field.** The Finalizer gets no unit of work. Store the one from `writeOnBeforeDelete`, as the Skeleton does. Its writes commit with the rest.
- **The rows still exist.** A query by `records.getIds()` still finds the records being deleted and the records that point at them.
- **An exception skips it.** When the action throws, the Finalizer does not run for that chunk.

::: warning
Leave the records being deleted alone. A `toDelete` of one fails the commit with `SELF_REFERENCE_FROM_TRIGGER`, and an update of one is lost when the delete goes through.
:::
