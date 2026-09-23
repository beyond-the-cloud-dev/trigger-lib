---
template: add-on
context: AfterUpdate
interface: Finalizer
description: Run once after an after update Writer or Dispatcher has processed its records, with the qualified records, for one bulk query or registration per chunk.
---

# AfterUpdate.Finalizer

Runs once after an after update Writer or Dispatcher has processed its records, with the records that qualified. Use it for one bulk query or registration per chunk instead of work per record.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/finalizer/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Once per chunk.** It is not a hook for the whole statement: an update of 1,000 records runs it 5 times.
- **Queries see this update.** A query here returns the trigger records with their saved new values.
- **Keep the unit of work in a field.** The Finalizer gets no unit of work. Store the one from the action, as the Skeleton does. Those registrations commit with the rest.
- **Runs before the commit.** A Writer's Finalizer runs before any of its registrations are saved.
- **Direct DML runs at once.** DML here is not merged with the unit of work and costs its own statement.
