---
template: context
context: AfterInsert
description: After insert in Trigger Lib - write other records with a Writer or start async work with a Dispatcher after new records are saved.
---

# AfterInsert

Runs in **after insert**, after new records are saved.

## Roles {#roles}

- [Writer](/after-insert/writer): change other records or publish events through a unit of work.
- [Dispatcher](/after-insert/dispatcher): make one bulk call per chunk, such as enqueueing a Queueable.

## Register {#register}

<!--@include: @/_parts/generated/after-insert/register.md-->

## Rules {#rules}

- **Lookups hold only the Id.** `((Contact) record.getNewSObject()).Account` is null. Declare a [ParentQuery](/after-insert/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **Updating the new record saves it again.** A Writer's `toUpdate` with the record Id runs before update and after update for it.
- **One role per class.** A class that implements both roles runs only as a Writer.
- **Called per chunk.** A 1,000-record insert is 5 runs, so each Dispatcher and Finalizer can run 5 times. Static fields keep their values across chunks.

::: warning
Rows are read-only. `record.put(…)` throws a `System.FinalException` that nothing can catch, and the insert fails. Set fields on the new record in a [BeforeInsert.Populator](/before-insert/populator).
:::
