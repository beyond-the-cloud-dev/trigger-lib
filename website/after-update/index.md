---
template: context
context: AfterUpdate
description: After update in Trigger Lib - change other records with a Writer or hand bulk and async work to a Dispatcher, with old and new values.
---

# AfterUpdate

Runs in **after update**, after the records are saved and before the transaction commits. Both the old and the new values are available. Change other records with a Writer, or hand bulk and async work to a Dispatcher.

## Roles {#roles}

- [Writer](/after-update/writer): change other records or publish events through a unit of work.
- [Dispatcher](/after-update/dispatcher): make one bulk call per chunk, such as enqueueing a Queueable.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-update/add-ons-list.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-update/register.md-->

## Good to Know {#good-to-know}

- **Read-only rows.** Any write to the trigger rows throws `System.FinalException`, and the update fails. Set fields in a [BeforeUpdate.Populator](/before-update/populator).
- **Updating this object runs the update triggers again.** Gate the predicate on a change, such as `isChangedTo`, so the nested run skips the record.
- **Recursion limit of 3.** Each handler acts on the same record at most 3 times per transaction. Change the limit with [RecursionGuard](/after-update/add-ons/recursion-guard).
- **Writer wins.** A class that implements both roles runs only as a Writer.
- **Called per chunk.** `afterUpdateHandlers()` runs for every chunk of up to 200 records, and each chunk commits its own unit of work.
