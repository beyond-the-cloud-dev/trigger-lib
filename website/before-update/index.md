---
template: context
context: BeforeUpdate
description: Before update in Trigger Lib. Set, derive or clear fields with a Populator and reject changes with a Validator, with the old and new values side by side and no DML.
---

# BeforeUpdate

BeforeUpdate runs in **before update** (`BEFORE_UPDATE`, `Trigger.isBefore && Trigger.isUpdate`): after the user's changes and before they are saved, once per chunk of up to 200 records. Both sides are there: the new values, which you can change with `put`, and the old values (`Trigger.oldMap`), which you can only read, so this is where change detection lives. Set, derive, stamp or clear fields with a Populator; reject (block, validate) the change with a Validator. DML is not allowed.

## At a Glance {#at-a-glance}

The context class. Its comments are the legend: pick one role, then add as many add-ons as you need.

<<< @/../force-app/main/default/classes/BeforeUpdate.cls

<!--@include: @/_parts/generated/before-update/facts.md-->

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| set, derive, stamp, clear or copy a field when something changed | [Populator](/before-update/populator) |
| reject a change: block a transition, keep a value from being cleared | [Validator](/before-update/validator) |
| compare the old and the new parent before allowing a move | [Validator](/before-update/validator) with [PriorParentQuery](/before-update/add-ons/prior-parent-query) and [ParentQuery](/before-update/add-ons/parent-query) |
| run the same field logic on create | also implement `BeforeInsert.Populator` in the same class → [One class in several contexts](/guide/orchestrator#one-class-several-contexts) |
| update children, the parent or other records, or publish an event | [AfterUpdate.Writer](/after-update/writer) |
| enqueue a job or send email | [AfterUpdate.Dispatcher](/after-update/dispatcher). Synchronous callouts are blocked in every trigger. |
| decide here and act after the save | a Populator that stamps a marker field, and an AfterUpdate Writer that reacts to the change → [Before-after handoff](/guide/orchestrator#before-after-handoff) |

<!--@include: @/_parts/roles/one-role.md#before-->

Here the marker is `BeforeUpdate.Handler`. The example orchestrators list their Populators before their Validators.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/before-update/add-ons-table.md-->

## Records {#records}

<!--@include: @/_parts/generated/before-update/records.md-->

- **Ids are set.** `record.getId()` returns the record Id, and `records.getIds()` the Ids of the chunk.
- **`put` writes to the `Trigger.new` row.** The platform saves the value with the record, and every later handler sees it, in its predicates, its actions and its change detection.
- **The old row is read-only.** `getOldSObject()` is the `Trigger.old` row: read it, never write to it (see [Gotchas](#gotchas)). AfterUpdate hands out the same `UpdateRecord` type, so `put` also compiles there, but it throws after the save.

## Register {#register}

<!--@include: @/_parts/generated/before-update/register.md-->

The example trigger lists every event, `before update` included:

<<< @/../examples/main/default/triggers/OpportunityTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

::: details Full orchestrator

<<< @/../examples/main/default/classes/opportunity/OpportunityTriggerOrchestrator.cls

:::

## How BeforeUpdate Runs {#how-it-runs}

<!--@include: @/_parts/run-order/before-insert-update.md-->

In before update:

- **The names.** The orchestrator returns the list from `beforeUpdateHandlers()`, and the per-handler switch is `bypassOnBeforeUpdateWhen()`. A Validator's error method is `addErrorOnBeforeUpdate`.
- **Step 2 already reads the recursion limit.** Adapting a Populator calls its `maxRecursionDepthOnBeforeUpdate()`, even when a bypass switches it off right after.
- **Step 4: one query per lookup, both sides.** Each declared lookup gets at most one SOQL query, for every current and previous parent Id not loaded yet, with the fields that either side declared. There is no query on the trigger object in before contexts.
- **Step 5: recursion.** A Populator skips a record that has used up its budget before calling the predicate. When the predicate returns true, the count goes up by 1 and then the action runs. A Validator has no budget and runs on every pass.
- **Step 5: only the current side is refreshed.** The parent query after a Populator loads current parents only; previous parents stay as they were loaded.
- **Then AfterUpdate.** Once the platform saves the chunk, AfterUpdate runs for the same chunk before the next chunk's BeforeUpdate starts: 201 records run as BeforeUpdate(200), AfterUpdate(200), BeforeUpdate(1), AfterUpdate(1).

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

In before update, that is [BeforeUpdate.Bypassable](/before-update/add-ons/bypassable) and its `bypassOnBeforeUpdateWhen()`, or leaving the class out of `beforeUpdateHandlers()`. A `TriggerHandler__mdt` row switches a class off in AfterUpdate too.

## Gotchas {#gotchas}

- **The old row is read-only.** Writing a field on `getOldSObject()` throws `System.FinalException` ("Record is read-only"), and calling `addError` on it throws "SObject row does not allow errors". No `catch` inside the trigger stops it, ContinueOnError included, and the caller's DML fails with a catchable `DmlException`.
- **No DML, not even on the record itself.** The DML guard fails the handler (→ [Populator Gotchas](/before-update/populator#gotchas)). DML on the records being updated fails anyway: `update new Opportunity(Id = record.getId(), …)` fails with `SELF_REFERENCE_FROM_TRIGGER`, and DML on the trigger rows themselves throws "DML statement cannot operate on trigger.new or trigger.old". Use `record.put`.
- **SOQL returns the saved values.** A query on the records being updated returns their values from before this update, formula fields included. So does a self-lookup parent that is part of the same update. Read a record's pending values from the record.
- **Parents: the current side is refreshed, the previous side never is.** After a Populator, only the records it qualified get their parents attached again, and only parent Ids not loaded yet are queried. A parent already loaded is not read again. Loaded parents last for one run: one chunk, one nested save.
- **Re-entry.** Any later update of the same records in the transaction runs BeforeUpdate again, for example an AfterUpdate Writer's `toUpdate(new Opportunity(Id = record.getId(), …))`. A Populator acts on a record at most 3 times per transaction by default ([RecursionGuard](/before-update/add-ons/recursion-guard)); a Validator runs on every pass. The platform stops at 16 nested trigger levels.
- **Partial saves run every handler twice.** When `Database.update(list, false)`, Data Loader or the Bulk API saves a batch with a failing record, the platform rolls the first attempt back and runs every handler again for the surviving records. That spends 2 recursion counts per survivor, so a Populator with a limit of 1 skips every survivor in the second attempt, silently → [Edge Values](/before-update/add-ons/recursion-guard#edge-values).
- **Change detection ignores letter case.** `'DOE'` → `'Doe'` is not a change, and `isChangedFromTo` does not require a change → [Change Detection](/before-update/record-api#change-detection).
- **Rows are paired by position.** `Trigger.new[i]` and `Trigger.old[i]` become one record, paired by list index, not by Id.
- **Fresh instances per run.** `beforeUpdateHandlers()` is called on every run, so handlers created there start with empty instance fields in every chunk and every nested save. Statics last for the whole transaction.
- **Relationship fields on the row are empty.** `((Contact) record.getNewSObject()).Account` is null on the trigger row, so `.Account.Name` throws a `NullPointerException`; declare a [ParentQuery](/before-update/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **Error payload.** `Error.getRecordIds()` holds the Id of every record in the chunk, and `getHandlerName()` the simple class name.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/before-update/not-available.md-->

Also missing in before update:

| Not here | Use instead |
|---|---|
| Any DML, on this object or any other | [AfterUpdate.Writer](/after-update/writer), through its unit of work |
| Writing to the old row, or `addError` on it | none: the old row is read-only |
| A recursion limit on a Validator | none: a Validator runs on every pass |
| Refreshing previous parents during the run | none: they are loaded once per run |

## See Also {#see-also}

- [AfterUpdate](/after-update/): the paired context, with the Writer for other records
- [BeforeInsert](/before-insert/): one class can implement both Populators
- [Before-after handoff](/guide/orchestrator#before-after-handoff)
- [Contexts at a Glance](/contexts)
- [Execution Order & Cost](/guide/execution-order)
