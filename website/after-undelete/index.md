---
template: context
context: AfterUndelete
description: Run Apex after records are restored from the Recycle Bin (after undelete, AFTER_UNDELETE) with a Writer or Dispatcher, and veto a restore.
---

# AfterUndelete

Runs in **after undelete** (`AFTER_UNDELETE`, `Trigger.isAfter && Trigger.isUndelete`), after records are restored from the Recycle Bin by a user, an `undelete` statement or `Database.undelete`, and before the transaction commits, once per chunk of up to 200 records. Only the new side exists: the restored rows have Ids and are read-only, and there is no old row. Use a Writer to create or update other records through a unit of work, and a Dispatcher to enqueue async work, call out through a Queueable, publish events or send email once per chunk. Parent (lookup) fields come from ParentQuery, other records from RelatedQuery, and Bypassable skips (disables) a handler.

## At a Glance {#at-a-glance}

<<< @/../force-app/main/default/classes/AfterUndelete.cls

<!--@include: @/_parts/generated/after-undelete/facts.md-->

### There Is No BeforeUndelete {#no-before-undelete}

Salesforce has no before undelete trigger event: a trigger that lists `before undelete` fails to compile with "Trigger Usage Before Undelete is not supported". There is no Populator or Validator for a restore, and the restored rows keep the values they had when they were deleted.

To veto a restore, call `record.getNewSObject().addError(…)` from an AfterUndelete Writer or Dispatcher. The platform rolls the restore back and the record stays in the Recycle Bin (`IsDeleted = true`). For example, a Writer that lets only users with a custom permission restore accounts:

```apex
public with sharing class AccountRestoreGuardWriter implements AfterUndelete.Writer {
    public Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
        return !FeatureManagement.checkPermission('Restore_Accounts');
    }

    public void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        record.getNewSObject().addError('You are not allowed to restore accounts.');
    }
}
```

List it first in `afterUndeleteHandlers()`. Later handlers still run for a rejected record, but their unit-of-work writes roll back with it, while an earlier Dispatcher may already have published a Publish Immediately event for it. More: [No BeforeUndelete](/after-undelete/#no-before-undelete).

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| Create or update other records when a record comes back (a Task for the owner, a parent's summary field) | [AfterUndelete.Writer](/after-undelete/writer) with `toInsert` or `toUpdate` |
| Publish a platform event that rolls back with the restore | [AfterUndelete.Writer](/after-undelete/writer#platform-events) with `toPublish` |
| Enqueue a Queueable, call out, send email or publish once per chunk | [AfterUndelete.Dispatcher](/after-undelete/dispatcher), passing `records.getIds()` to async work |
| Change a field on the restored record | a Writer with `toUpdate(new Account(Id = record.getId(), …))`; it fires the update triggers again ([Gotchas](#gotchas)) |
| Block the restore | `record.getNewSObject().addError(…)` from a Writer or Dispatcher ([There Is No BeforeUndelete](#no-before-undelete)) |
| Run the same logic as on insert | one class that implements [AfterInsert.Writer](/after-insert/writer) and AfterUndelete.Writer (below) |
| React to the delete itself | [AfterDelete](/after-delete/) |

**One class for insert and restore.** `TriggerHandler.InsertRecord` and `TriggerHandler.UndeleteRecord` are separate interfaces, and there is no combined one. Implement each context's methods, share the logic through a private method that takes `record.getNewSObject()`, and add an instance to both `afterInsertHandlers()` and `afterUndeleteHandlers()`. Add-ons are per context too: the class declares `AfterInsert.ParentQuery` and `AfterUndelete.ParentQuery` separately.

```apex
public with sharing class AccountReviewTaskWriter implements AfterInsert.Writer, AfterUndelete.Writer {
    public Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer');
    }

    public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        this.registerReviewTask((Account) record.getNewSObject(), unitOfWork);
    }

    public Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
        return record.startsWith(Account.Type, 'Customer');
    }

    public void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        this.registerReviewTask((Account) record.getNewSObject(), unitOfWork);
    }

    private void registerReviewTask(Account accountRecord, TriggerHandler.UnitOfWork unitOfWork) {
        unitOfWork.toInsert(new Task(WhatId = accountRecord.Id, OwnerId = accountRecord.OwnerId, Subject = 'Review account - ' + accountRecord.Name));
    }
}
```

More on one class in several contexts: [Trigger & Orchestrator](/guide/orchestrator#one-class-several-contexts).

<!--@include: @/_parts/roles/one-role.md#after-->

Here the marker is `AfterUndelete.Handler`.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-undelete/add-ons-table.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-undelete/records.md-->

- **Ids are set.** `record.getId()` and `records.getIds()` return the Ids of the restored records.
- **Read-only, no `put`.** `UndeleteRecord` has no `put`, and writing to `getNewSObject()` throws a `FinalException` that no `catch` inside the trigger stops.
- **No parent records on the row.** The row carries lookup Ids only, so `getNewSObject().Account` and other relationship fields are empty. Declare a [ParentQuery](/after-undelete/add-ons/parent-query) and read `getNewParent('Account')`.

## Register {#register}

<!--@include: @/_parts/generated/after-undelete/register.md-->

The example triggers list `after undelete` among their events:

<<< @/../examples/main/default/triggers/AccountTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

::: details Full orchestrator

The example orchestrator does not implement `TriggerOrchestrator.AfterUndelete` yet, so restoring an example Account fires the trigger and runs no handler. Add `TriggerOrchestrator.AfterUndelete` to its `implements` list and an `afterUndeleteHandlers()` method to register handlers.

<<< @/../examples/main/default/classes/account/AccountTriggerOrchestrator.cls

:::

## How AfterUndelete Runs {#how-it-runs}

<!--@include: @/_parts/run-order/after.md-->

In after undelete:

- **Units are chosen first.** Each Writer's unit is resolved while the handler list is adapted, so `ownUnitOfWorkOnAfterUndelete()` runs before `bypassOnAfterUndeleteWhen()`, even for a Writer that is then switched off.
- **Parents load through the restored rows.** If an active handler declares a ParentQuery, one SOQL query on the restored records reads the declared parents through their relationship paths, such as `Account.Name`. A parent that query did not return costs one query per lookup. Nothing is queried again during the run.
- **Own and private units commit at the Writer's turn**, right after its Finalizer and only when at least one record qualified, before the shared unit commits.
- **No recursion counting.** There is no RecursionGuard here. A self-update registered from here fires BeforeUpdate and AfterUpdate during the shared commit, and those contexts count it.
- **Method names here:** `afterUndeleteHandlers()`, `bypassOnAfterUndeleteWhen()`, `ownUnitOfWorkOnAfterUndelete()`, `queryParentsOnAfterUndelete()`, `queryRelatedOnAfterUndelete()` and `finalizeAfterUndelete(records)`.

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

To skip only the restore run of a class that also serves other contexts, implement [AfterUndelete.Bypassable](/after-undelete/add-ons/bypassable) or leave the class out of `afterUndeleteHandlers()`.

## Gotchas {#gotchas}

- **Changing the restored record fires the update triggers.** The row is read-only. `unitOfWork.toUpdate(new Account(Id = record.getId(), Rating = 'Warm'))` commits with the shared unit after the last handler, and the platform then runs BeforeUpdate and AfterUpdate for those rows synchronously, as nested runs. That is a second save for every restored record.
- **Deleting the restored record fails.** A delete of a record that is being restored, registered with `toDelete` or run as direct DML, throws a `DmlException` with `SELF_REFERENCE_FROM_TRIGGER`. Reject the restore with `addError` instead.
- **Only the top-level record's trigger runs.** Salesforce restores cascade-deleted children with their parent, such as the opportunities of a restored account, but documents that only the parent's after undelete trigger runs. Handle the children from the parent's handlers.
- **Restored lookups.** When a record is deleted, lookup fields on other records that pointed at it are cleared (the default for a lookup field). Salesforce restores such a lookup on undelete only if it was not changed in the meantime, and whether it is already back while AfterUndelete runs has not been verified. Don't rely on inbound lookups, or a RelatedQuery over them, in a restore handler.
- **Partial restores run the handlers again.** With `Database.undelete(records, false)` and a failing record, Salesforce rolls back the first attempt and runs the trigger again for the remaining records. Unit-of-work DML rolls back with the first attempt, but Publish Immediately events may go out twice; whether emails repeat is not verified.
- **Everything runs once per 200-record chunk.** Restoring 1,000 records means 5 runs, 5 shared commits and 5 Dispatcher calls. Statics persist across chunks; instance fields reset when `afterUndeleteHandlers()` returns new instances.
- **There is no DML guard.** Direct DML in a Writer, Finalizer or Dispatcher runs at once and bypasses the unit: it is not merged, costs its own statements and lands before the shared commit.

<!--@include: @/_parts/notes/stale-api.md-->

Here the empty marker is `AfterUndelete.Handler`: a class that implements only it compiles, fits in the list and never runs.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-undelete/not-available.md-->

Also missing in after undelete:

| Not here | Use instead |
|---|---|
| `put` on the restored record | a Writer's `toUpdate(new Account(Id = record.getId(), …))`, which fires the update triggers ([Gotchas](#gotchas)) |
| Old values and change detection | none: a restore has no old row → [AfterUpdate](/after-update/) |
| A restore Validator | `record.getNewSObject().addError(…)` from a Writer or Dispatcher → [There Is No BeforeUndelete](#no-before-undelete) |
| Undelete, merge or hard delete through the unit of work | direct DML, which runs at once |
| DML results or new Ids inside the handler | none: the unit commits later. An [OwnUnitOfWork](/after-undelete/add-ons/own-unit-of-work) can read them with `commitHook` or `DML.retrieveResultFor` |

## See Also {#see-also}

- [AfterInsert](/after-insert/): the same logic for new records.
- [AfterDelete](/after-delete/): the delete that sent the record to the Recycle Bin.
- [Contexts at a Glance](/contexts)
- [Unit of Work](/guide/unit-of-work)
- [Execution Order & Cost](/guide/execution-order)
