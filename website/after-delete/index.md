---
template: context
context: AfterDelete
description: Run Apex after records are deleted or merged — clean up orphans, recompute a parent from the records that remain, or hand a callout to a job — with AfterDelete Writers and Dispatchers.
---

# AfterDelete

**AfterDelete** runs in after delete (`AFTER_DELETE`, `Trigger.isAfter && Trigger.isDelete`): after the rows are deleted and before the transaction commits, once per chunk of up to 200 records, with only the old values (`Trigger.old`). Clean up, annotate or recompute other records with a Writer (remove orphans, recompute a rollup, react to a merge), hand a callout, job or email to a Dispatcher, read the former parent's fields (lookup) with PriorParentQuery, and skip (bypass) a handler with Bypassable.

## At a Glance {#at-a-glance}

<<< @/../force-app/main/default/classes/AfterDelete.cls

<!--@include: @/_parts/generated/after-delete/facts.md-->

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| Create, update or delete *other* records, or publish an event, only when the delete really happens | [AfterDelete.Writer](/after-delete/writer) |
| Enqueue a job, call out from a Queueable, or send one email per chunk | [AfterDelete.Dispatcher](/after-delete/dispatcher) |
| Recompute a parent from the records that remain | a Writer with a [RelatedQuery](/after-delete/add-ons/related-query): the deleted rows no longer come back from SOQL |
| React to a merge | a Writer or Dispatcher: the losing records arrive here with `MasterRecordId` set; the winner arrives in [AfterUpdate](/after-update/) |
| Stop the delete before any other work runs | [BeforeDelete.Handler](/before-delete/handler) with `getOldSObject().addError(…)` |
| Read the deleted records' children while they are still linked, or subtract from a stored total | [BeforeDelete](/before-delete/) |
| React to a restore from the Recycle Bin | [AfterUndelete](/after-undelete/) |

<!--@include: @/_parts/roles/one-role.md#after-->

Here the marker is `AfterDelete.Handler`: `afterDeleteHandlers()` returns a `List<AfterDelete.Handler>`, and only the Writers and Dispatchers in it run.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-delete/add-ons-table.md-->

The PriorParentQuery method has no "Prior" in its name here: in delete contexts the PriorParentQuery method is named `queryParentsOn<Ctx>()`, so in after delete it is `queryParentsOnAfterDelete()`.

## Records {#records}

<!--@include: @/_parts/generated/after-delete/records.md-->

- **The Ids are set, the rows are gone.** `getId()` and `records.getIds()` return the deleted Ids, but SOQL no longer finds those rows. Key your queries by the old rows' lookups instead: `records.getIdsOf(Contact.AccountId)`.
- **Everything reads the old row.** Value predicates, `getIdsOf` and `getValuesOf` read `Trigger.old`, whose lookup fields are still set.
- **There is no new side.** `DeleteRecord` has no `put`, `getNewSObject` or `getNewParent`, and `getOldSObject()` is read-only.

## Register {#register}

<!--@include: @/_parts/generated/after-delete/register.md-->

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

::: details Full orchestrator

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

This example orchestrator does not implement `TriggerOrchestrator.AfterDelete`, so deleting a Contact runs no Trigger Lib handler in after delete, and nothing reports it. Add the interface and an `afterDeleteHandlers()` method, as in the snippet above, to register handlers.

:::

## How AfterDelete Runs {#how-it-runs}

<!--@include: @/_parts/run-order/after.md-->

In after delete:

- **The method names.** Step 2 calls `afterDeleteHandlers()`, and step 3 calls `bypassOnAfterDeleteWhen()`. A Writer's `ownUnitOfWorkOnAfterDelete()` is called while the list is adapted in step 2, even for a Writer that step 3 then switches off.
- **Parents come from the old rows only.** Only PriorParentQuery declares parents here. Each declared lookup costs at most one SOQL query against the parent object, for the previous parent Ids of the chunk; a lookup that is empty on every row costs none. No query runs on the trigger object, because a delete has no new side to load. Loaded parents are kept for this run only, so the next chunk queries again.
- **Own and private units commit at the Writer's turn.** A Writer with OwnUnitOfWork or ContinueOnError commits its unit right after its Finalizer, if at least one of its records qualified, before the shared commit in step 6.
- **No recursion counting.** AfterDelete has no RecursionGuard: every record that qualifies is processed once per run.

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

To switch one handler off on a condition in after delete only, implement [AfterDelete.Bypassable](/after-delete/add-ons/bypassable).

An object-wide switch, `TriggerObject__mdt.Bypass__c` or `TriggerOrchestrator.bypass().sObject(Contact.SObjectType)`, also skips the object's BeforeDelete handlers. A purge that runs with the object switched off therefore also skips the checks that would have blocked a delete.

## Gotchas {#gotchas}

- **The deleted row is off-limits.** Registering `toUpdate(new Contact(Id = record.getId(), …))` fails the commit with `ENTITY_IS_DELETED`. Deleting the row again, or undeleting it, fails with `SELF_REFERENCE_FROM_TRIGGER`, and no AfterUndelete fires. On the shared unit, that failure fails the whole delete and is not passed to `TriggerOrchestrator.Logger`. The unit of work has no undelete at all.
- **Deleted rows are invisible to SOQL.** A query on the trigger object by `records.getIds()` returns nothing, silently, and `Id NOT IN :records.getIds()` on a sibling query changes nothing. Recover the keys from the old rows' lookups: `records.getIdsOf(Contact.AccountId)`.
- **Inbound lookups may still point at the deleted rows.** Other records' lookups to a deleted row are not cleared yet during this trigger, so `WHERE ReportsToId IN :records.getIds()` can still find them. When you recompute from such records, exclude them with `AND ReportsToId NOT IN :records.getIds()`.
- **Merges arrive as deletes.** On Account, Contact, Lead and Case, the records that lose a merge fire the delete triggers with `MasterRecordId` set on the old row, all losers in one delete event. The winner fires the update triggers, and child records that the merge reparents fire no triggers. Skip the losers with `record.isNull(Contact.MasterRecordId)`.
- **Cascade-deleted records never arrive.** Records that the platform deletes because their parent was deleted, such as a master-detail child, do not fire their own delete triggers. Put that logic on the parent's delete.
- **`addError` here rolls the delete back.** `record.getOldSObject().addError(…)` from a Writer or Dispatcher keeps the record out of the Recycle Bin, but only after every BeforeDelete handler and every earlier AfterDelete handler has done its work. Stop deletes in [BeforeDelete](/before-delete/handler) instead.
- **The old row is read-only.** Writing a field on `getOldSObject()` throws a `FinalException` that cannot be caught inside the trigger, not even with ContinueOnError.
- **Partial deletes run twice.** With `Database.delete(records, false)`, one failing record rolls back the first attempt, and the platform runs every handler again for the records that survive. Writes registered on a unit of work roll back with the first attempt; Publish Immediately events sent during it do not, and whether emails repeat is not verified, so make such side effects idempotent.
- **A logged error names the whole chunk.** `getRecordIds()` on the `TriggerOrchestrator.Error` that a Logger receives holds every Id in the chunk, qualified or not.

<!--@include: @/_parts/notes/stale-api.md-->

Here the empty marker is `AfterDelete.Handler`: a class that implements only it compiles, fits in `afterDeleteHandlers()`, and never runs.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-delete/not-available.md-->

Capabilities that after delete does not have:

| Not here | Use instead |
|---|---|
| `put`, `getNewSObject()`, `getNewParent(…)` | none: `DeleteRecord` does not declare them, because a delete has no new row |
| Change detection (`isChanged`, `isChangedTo`, …) | [BeforeUpdate](/before-update/record-api#change-detection) and [AfterUpdate](/after-update/record-api#change-detection) |
| Populator and Validator | [BeforeInsert](/before-insert/) and [BeforeUpdate](/before-update/); to stop a delete, [BeforeDelete.Handler](/before-delete/handler) |
| A recursion guard | none needed for the deleted rows: updating, deleting or undeleting them from here fails, so an Id reaches after delete once per transaction, apart from a partial-delete re-run. Deleting *other* records of the same object starts a nested run, bounded only by the platform's limit of 16 nested trigger levels. |
| Stop the delete before any work runs | [BeforeDelete.Handler](/before-delete/handler) |
| Read children while they are still linked, or subtract from a stored total | [BeforeDelete](/before-delete/) |
| Undelete, merge or hard delete through the unit of work | not supported: the unit registers inserts, updates, upserts, deletes and event publishes only. Use direct DML on other records. |

## See Also {#see-also}

- [BeforeDelete](/before-delete/): the paired context, to stop a delete and to read records while they are still linked
- [AfterUndelete](/after-undelete/): the reverse; restored records keep their Ids
- [AfterUpdate](/after-update/): where the winning record of a merge arrives
- [AfterDelete add-ons](/after-delete/add-ons/) and [Record API in AfterDelete](/after-delete/record-api)
- [Contexts at a Glance](/contexts)
- [Execution Order & Cost](/guide/execution-order)
- [Unit of Work](/guide/unit-of-work)
