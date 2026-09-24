---
template: add-on
context: AfterUpdate
interface: Finalizer
description: Run once per chunk after an after update Writer or Dispatcher, with the qualified records, for one bulk query or registration.
---

# AfterUpdate.Finalizer

Run code once per chunk with the records that qualified, such as one bulk write.

**Signature**

<!--@include: @/_parts/generated/after-update/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Queries see this update.** A query here returns the trigger records with their saved new values.
- **Keep the unit of work in a field.** The Finalizer gets no unit of work. Store the one from the action, as the Skeleton does. Those registrations commit with the rest.
- **Direct DML runs at once.** DML here is not merged with the unit of work and costs its own statement.
