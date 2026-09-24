---
template: add-on
context: AfterInsert
interface: Finalizer
description: Run once after an after insert Writer or Dispatcher has processed the chunk, with the records that qualified.
---

# AfterInsert.Finalizer

Run code once per chunk with the records that qualified, such as one write per parent.

**Signature**

<!--@include: @/_parts/generated/after-insert/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Keep the unit in a field.** The Finalizer gets no unit of work. Save the `unitOfWork` from the action in an instance field.
- **Not once per statement.** A 1,000-record insert can call it 5 times.
- **Registrations commit with the rest.** By default after the last handler; with OwnUnitOfWork or ContinueOnError, right after the Finalizer.

::: warning
Direct DML runs at once and skips the unit of work.
:::
