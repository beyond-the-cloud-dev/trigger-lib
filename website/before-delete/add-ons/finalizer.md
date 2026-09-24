---
template: add-on
context: BeforeDelete
interface: Finalizer
description: Run once per chunk after a before delete Handler, with the qualified records - the place for one bulk DML statement.
---

# BeforeDelete.Finalizer

Run code once per chunk with the records that qualified, such as one bulk DML statement.

**Signature**

<!--@include: @/_parts/generated/before-delete/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **DML is allowed here.** Before delete has no unit of work, so a statement runs at once.
- **The DML fires triggers.** Records written here run their own triggers at once, nested in this run. Every statement counts against the transaction's limits.
- **An exception skips it.** When the action throws, the Finalizer does not run for that chunk. With ContinueOnError, statements that already ran keep their changes.

::: warning
Leave the records being deleted alone. Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`. An update of one is lost when the delete goes through.
:::
