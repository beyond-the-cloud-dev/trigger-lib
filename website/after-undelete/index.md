---
template: context
context: AfterUndelete
description: After undelete in Trigger Lib - react to records restored from the Recycle Bin with a Writer or a Dispatcher, and block a restore.
---

# AfterUndelete

Runs in **after undelete**, after records are restored from the Recycle Bin.

## Roles {#roles}

- [Writer](/after-undelete/writer): change other records or publish events through a unit of work.
- [Dispatcher](/after-undelete/dispatcher): make one bulk call per chunk, such as enqueueing a Queueable.

## Register {#register}

<!--@include: @/_parts/generated/after-undelete/register.md-->

## Rules {#rules}

- **No Validator.** Salesforce has no before undelete event. To block a restore, call `record.getNewSObject().addError(…)` from a Writer or Dispatcher and list that handler first. The record stays in the Recycle Bin.
- **Lookups hold only the Id.** `((Contact) record.getNewSObject()).Account` is null. Declare a [ParentQuery](/after-undelete/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **Only the top-level record's trigger runs.** Salesforce restores cascade-deleted children with their parent, but runs only the parent's after undelete trigger. Handle the children from the parent's handlers.
- **Called per chunk.** `afterUndeleteHandlers()` runs for every chunk of up to 200 records. Restoring 1,000 records means 5 runs and 5 Dispatcher calls.

::: warning
The restored row is read-only. Writing to `getNewSObject()` throws a `FinalException` that no `catch` stops. To change the record, register a `toUpdate` of its Id, which fires BeforeUpdate and AfterUpdate again.
:::
