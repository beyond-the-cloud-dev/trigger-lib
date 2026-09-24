---
template: add-on
context: AfterUndelete
interface: Finalizer
description: Run code once per chunk after an after undelete Writer or Dispatcher, with the restored records that qualified - aggregate queries, bulk registrations.
---

# AfterUndelete.Finalizer

Run code once per chunk with the records that qualified, such as one aggregate query or one bulk registration.

**Signature**

<!--@include: @/_parts/generated/after-undelete/finalizer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/finalizer/skeleton.md-->

:::

## Rules {#rules}

- **Keep the unit of work in a field.** Store the `unitOfWork` from the action, as the Skeleton does. What you register here commits with the Writer's other writes.
- **Not an end-of-restore hook.** Restoring 1,000 records runs it 5 times.
- **Direct DML runs at once.** It is not merged with any unit of work.
