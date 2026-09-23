---
template: context
context: BeforeDelete
description: "Veto (block, prevent) a delete or clean up related records in before delete, while the rows and their links still exist."
---

# BeforeDelete

BeforeDelete runs in **before delete** (`BEFORE_DELETE`, `Trigger.isBefore && Trigger.isDelete`), before the records are removed. Only the old rows exist (`Trigger.old`, `Trigger.oldMap`), and they are still in the database and still linked, so this is where you block (veto, prevent) a delete, read parent fields and children, or clean up related records with direct DML before the links are gone.

## At a Glance {#at-a-glance}

<<< @/../force-app/main/default/classes/BeforeDelete.cls

<!--@include: @/_parts/generated/before-delete/facts.md-->

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| Block (veto, prevent) the delete of a record | [BeforeDelete.Handler](/before-delete/handler) + `record.getOldSObject().addError(…)` |
| Clean up, archive or reassign records that point at the deleted rows | [BeforeDelete.Handler](/before-delete/handler) + [Finalizer](/before-delete/add-ons/finalizer) with direct DML |
| Read children or records that look up to the rows being deleted | [BeforeDelete.Handler](/before-delete/handler) + [RelatedQuery](/before-delete/add-ons/related-query) |
| Read fields of the parent (the account of a deleted contact) | [BeforeDelete.Handler](/before-delete/handler) + [PriorParentQuery](/before-delete/add-ons/prior-parent-query) |
| Write other records only if the delete really happens, or recompute a parent from what remains | [AfterDelete.Writer](/after-delete/writer) |
| Enqueue a job, call out or send email after the delete | [AfterDelete.Dispatcher](/after-delete/dispatcher) |
| Tell a merge from a plain delete (`MasterRecordId`) | [AfterDelete](/after-delete/#gotchas) |
| Block a restore from the Recycle Bin | [AfterUndelete](/after-undelete/#no-before-undelete) |

BeforeDelete has a single role, `BeforeDelete.Handler`, and it is the interface itself, not a marker. Its methods, `qualifiesForBeforeDeleteWhen` and `onBeforeDelete`, exist in no other context. Every class in `beforeDeleteHandlers()` runs as a Handler, in list order.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/before-delete/add-ons-table.md-->

The PriorParentQuery method has no "Prior" in its name here: in delete contexts the PriorParentQuery method is named `queryParentsOn<Ctx>()`, so in before delete it is `queryParentsOnBeforeDelete()`.

## Records {#records}

<!--@include: @/_parts/generated/before-delete/records.md-->

- **Ids are set.** `record.getId()` and `records.getIds()` return the Ids of the records being deleted, and those rows can still be queried.
- **Only the old row.** Predicates, `getIdsOf` and `getValuesOf` read `Trigger.old`. There is no `put`, `getNewSObject` or `getNewParent`.
- **Read-only, but takes errors.** Writing to `getOldSObject()` throws, while `getOldSObject().addError(…)` blocks the delete of that record.

## Register {#register}

<!--@include: @/_parts/generated/before-delete/register.md-->

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

The example orchestrator below does not implement `TriggerOrchestrator.BeforeDelete` yet. With the trigger above, deleting a contact runs no handler until it does, as in the snippet at the top of this section.

::: details Full orchestrator

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

:::

## How BeforeDelete Runs {#how-it-runs}

<!--@include: @/_parts/run-order/before-delete.md-->

- **Method names here.** The orchestrator method is `beforeDeleteHandlers()` and the per-handler switch is `bypassOnBeforeDeleteWhen()`. Parents are declared with `queryParentsOnBeforeDelete()` (the PriorParentQuery method) and related records with `queryRelatedOnBeforeDelete()`.
- **Parents: old side only.** Only PriorParentQuery declares parents in this context. There is no query on the trigger object: each declared lookup costs at most one SOQL query for the old parent Ids, against the object the lookup references.
- **No unit of work and no recursion guard.** No handler receives a unit, and nothing is counted per record. A handler that deletes other records of the same object starts a nested BeforeDelete run.

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

To switch off one handler on a condition, implement [BeforeDelete.Bypassable](/before-delete/add-ons/bypassable). A switch on the whole object, `TriggerObject__mdt.Bypass__c` or `TriggerOrchestrator.bypass().sObject(…)`, also turns off the handlers that block deletes, so records they protect can be deleted while it is on.

## Gotchas {#gotchas}

- **No DML guard and no unit of work.** DML in a provider, the action or the Finalizer runs at once, one statement per call, and fires the triggers of the records it writes. Collect in `onBeforeDelete` and write once in `finalizeBeforeDelete`. With ContinueOnError, a failed statement is logged and swallowed, and the delete proceeds.
- **Leave the records being deleted alone.** DML on the `Trigger.old` rows themselves throws `System.SObjectException` ("DML statement cannot operate on trigger.new or trigger.old"). Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`. Updating a fresh instance succeeds and fires the update triggers, and then the record is deleted anyway.
- **An error does not stop the other handlers.** A record with an error still reaches every later handler in the list. With all-or-none DML, the default for `delete`, one error fails the whole statement; with `Database.delete(records, false)` only that record stays.
- **Partial deletes run twice.** With `Database.delete(records, false)` and a failing record, the platform rolls back the first attempt and runs every handler again for the surviving records (proven in an org). Direct DML from the first attempt is rolled back with it. An immediately published event from the first attempt can go out twice; whether an email repeats is not verified.
- **Cascade deletes fire no triggers for the children.** Records that a cascade delete removes, such as the contacts of a deleted account, do not run their own delete triggers. In the parent's before delete they can still be queried, so handle them there with a [RelatedQuery](/before-delete/add-ons/related-query).
- **Merges arrive as deletes.** The losing records of a merge fire before delete like a plain delete; see [Record API gotchas](/before-delete/record-api#gotchas).
- **The Logger sees the whole chunk.** `TriggerOrchestrator.Error.getRecordIds()` holds every Id in the chunk, whether or not the failing handler qualified it.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/before-delete/not-available.md-->

- **`put`, `getNewSObject()` and `getNewParent()`**: a delete has no new row, and `getOldSObject()` is read-only.
- **Change detection** (`isChanged` and the rest): → [BeforeUpdate](/before-update/record-api#change-detection) and [AfterUpdate](/after-update/record-api#change-detection).
- **A unit of work** (`TriggerHandler.UnitOfWork`): write directly from the [Finalizer](/before-delete/add-ons/finalizer), or register the writes in an [AfterDelete.Writer](/after-delete/writer).
- **A DML guard**: none; DML runs at once in this context.
- **The merge winner** (`MasterRecordId`): → [AfterDelete](/after-delete/#gotchas).
- **before undelete**: the platform has no such event → [There Is No BeforeUndelete](/after-undelete/#no-before-undelete).

## See Also {#see-also}

- [AfterDelete](/after-delete/): the paired context, after the rows are gone.
- [AfterUndelete](/after-undelete/): restores from the Recycle Bin.
- [Contexts at a Glance](/contexts): every context side by side.
- [Execution Order & Cost](/guide/execution-order)
- [Errors & Logging](/guide/error-handling)
