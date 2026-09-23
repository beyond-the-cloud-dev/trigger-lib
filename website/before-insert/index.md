---
template: context
context: BeforeInsert
description: Before insert in Trigger Lib - set fields with a Populator or reject records with a Validator before new records are saved, with no Id and no DML.
---

# BeforeInsert

Runs in **before insert** (`BEFORE_INSERT`, `Trigger.isBefore && Trigger.isInsert`), before new records are written, once per chunk of up to 200 records. Set, default or normalize fields with a Populator, or reject records with a Validator. Read parent (lookup) fields and other records without SOQL in your loop, skip or bypass a handler on a condition, and keep callouts and DML for after insert: records have no Id yet, and DML is not allowed.

## At a Glance {#at-a-glance}

<<< @/../force-app/main/default/classes/BeforeInsert.cls

<!--@include: @/_parts/generated/before-insert/facts.md-->

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| Set, default, derive or normalize a field on the record being inserted | [BeforeInsert.Populator](/before-insert/populator) |
| Reject the record with a message (validation) | [BeforeInsert.Validator](/before-insert/validator) |
| Reject records that clash with each other in the same save, such as two new contacts with one email | a Populator with a [Finalizer](/before-insert/add-ons/finalizer) |
| Create or update other records, or publish a platform event | [AfterInsert.Writer](/after-insert/writer) |
| Use the new record's Id, for example to link child records | [AfterInsert.Writer](/after-insert/writer) |
| Enqueue a job, call out or send email | [AfterInsert.Dispatcher](/after-insert/dispatcher) |

<!--@include: @/_parts/roles/one-role.md#before-->

Here the marker is `BeforeInsert.Handler`: it types the list that `beforeInsertHandlers()` returns, and only its two roles, Populator and Validator, ever run.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/before-insert/add-ons-table.md-->

## Records {#records}

<!--@include: @/_parts/generated/before-insert/records.md-->

- **No Id.** `record.getId()` is null and `records.getIds()` is empty in every method, because nothing is saved yet.
- **`put` writes to the `Trigger.new` row.** The platform saves the value with the record, and every handler listed later sees it.
- **Only the Validator's error method gets `addError`.** `addErrorOnBeforeInsert` receives a `TriggerHandler.RejectableInsertRecord`, which has `addError` and no `put`. Every other method receives an `InsertRecord`, which has `put` and no `addError`; to reject a record from there, call `record.getNewSObject().addError(…)`.

## Register {#register}

<!--@include: @/_parts/generated/before-insert/register.md-->

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

::: details Full orchestrator

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

:::

## How BeforeInsert Runs {#how-it-runs}

<!--@include: @/_parts/run-order/before-insert-update.md-->

In before insert:

- **Parents.** Each lookup declared with `queryParentsOnBeforeInsert()` costs one SOQL query against its parent object, covering every parent Id in the chunk, and none when no record has that lookup set. After a Populator, only parent Ids not loaded yet cost another query. Only the new side exists: there is no old row to load a previous parent from.
- **No unit of work and no recursion guard.** Nothing registers DML in this context, and the recursion guard exists only in the update contexts.
- **Method names.** `beforeInsertHandlers()` builds the list, `bypassOnBeforeInsertWhen()` switches a handler off, `queryParentsOnBeforeInsert()` and `queryRelatedOnBeforeInsert()` declare data, `populateOnBeforeInsertWhen` / `populateOnBeforeInsert` and `errorShouldBeAttachedOnBeforeInsertWhen` / `addErrorOnBeforeInsert` run per record, and `finalizeBeforeInsert` runs once per handler.

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

To switch one before insert handler off on a condition, implement [BeforeInsert.Bypassable](/before-insert/add-ons/bypassable). Its page also covers [data migrations](/before-insert/add-ons/bypassable#data-migration).

## Gotchas {#gotchas}

- **No Id yet.** `getId()` is null and `getIds()` is empty, so never key a map by the record Id here. A `TriggerOrchestrator.Error` logged in before insert carries an empty set from `getRecordIds()`, not null.
- **No parent records on the row.** `((Contact) record.getNewSObject()).Account` is null: the row carries lookup Ids only. Declare a [ParentQuery](/before-insert/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **No saved values yet.** Audit fields such as `CreatedDate` and `CreatedById`, and auto-number fields, are empty until the record is saved. Read them in after insert.
- **A new handler list per run.** `beforeInsertHandlers()` is called on every run. The example orchestrators return new instances, so instance fields start empty in every chunk of 200 records and in every nested save. Static fields, including handlers kept in static fields, last for the whole transaction. See [instances per chunk](/guide/orchestrator#instances-per-chunk).
- **Partial success runs handlers twice.** With `Database.insert(records, false)`, when some records fail, the platform rolls back and runs every handler again for the records that did not fail. Static counters and flags see those records twice.

<!--@include: @/_parts/roles/dml-guard.md-->

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/before-insert/not-available.md-->

| Also not here | Use instead |
|---|---|
| Old values and change detection (`isChanged`, `getOldSObject()`) | [BeforeUpdate](/before-update/) |
| DML on other records, platform events | [AfterInsert.Writer](/after-insert/writer) |
| The record Id, auto-numbers, audit fields and other saved values | [AfterInsert](/after-insert/) |

## See Also {#see-also}

- [AfterInsert](/after-insert/): the same insert, after the save.
- [BeforeUpdate](/before-update/): one class can implement both `BeforeInsert.Populator` and `BeforeUpdate.Populator` and serve both lists.
- [Add-ons in BeforeInsert](/before-insert/add-ons/) and [Record API in BeforeInsert](/before-insert/record-api).
- [Contexts at a Glance](/contexts) and [Execution Order & Cost](/guide/execution-order).
