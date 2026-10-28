---
template: context
context: AfterUpdate
description: After update in Trigger Lib - change other records with a Writer or hand bulk and async work to a Dispatcher, with old and new values.
---

# AfterUpdate

Runs in **after update**, after the records are saved and before the transaction commits.

## Roles {#roles}

- [Writer](/after-update/writer): change other records or publish events through a unit of work.
- [Dispatcher](/after-update/dispatcher): make one bulk call per chunk, such as enqueueing a Queueable.

## Register {#register}

<!--@include: @/_parts/generated/after-update/register.md-->

## Rules {#rules}

- **Updating this object runs the update triggers again.** Gate the predicate on a change, such as `isChangedTo`, so the nested run skips the record.
- **A recursion depth of 3 is logged.** When a record comes back to a handler that already acted on it 3 times in the transaction, the run logs an error and the handler keeps running. [RecursionGuard](/after-update/add-ons/recursion-guard) sets its own depth and also skips the record there.
- **Writer wins.** A class that implements both roles runs only as a Writer.
- **Called per chunk.** `afterUpdateHandlers()` runs for every chunk of up to 200 records, and each chunk commits its own unit of work.

::: warning
The trigger rows are read-only. Any write to them throws `System.FinalException`, and the update fails. Set fields in a [BeforeUpdate.Populator](/before-update/populator).
:::
