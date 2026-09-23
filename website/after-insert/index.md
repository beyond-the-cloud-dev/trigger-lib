---
template: context
context: AfterInsert
description: After insert in Trigger Lib - write other records with a Writer or start async work with a Dispatcher after new records are saved.
---

# AfterInsert

Runs in **after insert**, after new records are saved. The records have Ids and are read-only. Write other records with a Writer or start async work with a Dispatcher.

## Roles {#roles}

- [Writer](/after-insert/writer): create, update or delete other records, or publish events, through a unit of work that commits with the save.
- [Dispatcher](/after-insert/dispatcher): make one bulk call per chunk, such as enqueueing a Queueable.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-insert/add-ons-list.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-insert/register.md-->

## Good to Know {#good-to-know}

- **Read-only rows.** `record.put(…)` compiles, but it throws a `System.FinalException` that nothing can catch, and the insert fails. Set fields on the new record in a [BeforeInsert.Populator](/before-insert/populator).
- **Lookups hold only the Id.** `((Contact) record.getNewSObject()).Account` is null. Declare a [ParentQuery](/after-insert/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **Updating the new record saves it again.** A Writer's `toUpdate(new Contact(Id = record.getId(), …))` runs before update and after update for it. When the value is known before the save, set it in a BeforeInsert.Populator instead.
- **One role per class.** A class that implements both roles runs only as a Writer.
- **Called per chunk.** A 1,000-record insert is 5 runs, so each Dispatcher and Finalizer can run 5 times. Static fields keep their values across chunks.
