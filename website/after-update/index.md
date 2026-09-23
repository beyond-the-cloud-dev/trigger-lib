---
template: context
context: AfterUpdate
description: 'After update in Trigger Lib: Writers and Dispatchers on saved, read-only records with old and new values, change detection, parent fields, a recursion guard and a shared unit of work.'
---

# AfterUpdate

**After update** (`AFTER_UPDATE`, `Trigger.isAfter && Trigger.isUpdate`) runs after the platform has saved the updated records and before the transaction commits, once per chunk of up to 200 records. The records are saved but not committed, they are read-only, and both the old and the new values are available. Change other records (children, parents, follow-up tasks) with a Writer, or hand bulk and async work, such as a Queueable that makes a callout, to a Dispatcher. Lookup (parent) fields, related records, bypass switches and recursion limits come as add-ons.

## At a Glance {#at-a-glance}

<<< @/../force-app/main/default/classes/AfterUpdate.cls

<!--@include: @/_parts/generated/after-update/facts.md-->

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| create, update or delete other records, or publish a platform event that commits with the save | [Writer](/after-update/writer) |
| enqueue a Queueable, call out from it, or send email once per chunk | [Dispatcher](/after-update/dispatcher) |
| change a field on the record being updated | [BeforeUpdate.Populator](/before-update/populator): no second save, and the triggers do not fire again |
| reject the update | [BeforeUpdate.Validator](/before-update/validator) |
| act after the save on something BeforeUpdate decided | a Writer or Dispatcher that qualifies with `isChangedTo` on the field a BeforeUpdate Populator stamped: [before → after handoff](/guide/orchestrator#before-after-handoff) |

<!--@include: @/_parts/roles/one-role.md#after-->

Here the marker is `AfterUpdate.Handler`, the element type of the list that `afterUpdateHandlers()` returns.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-update/add-ons-table.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-update/records.md-->

- **Both sides.** `getNewSObject()` is the row as it was saved, and `getOldSObject()` is the row as it was before this update, so change detection (`isChanged`, `isChangedTo`, `isChangedFrom`, …) works here.
- **Read-only.** `put` compiles, but it throws `System.FinalException`, like any write to either row. No `catch` inside the trigger stops it, ContinueOnError included, and the caller's update fails with a `DmlException` (`CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY`).
- **No parent records on the row.** The rows carry lookup Ids only; relationship fields such as `Account` are empty. Declare a [ParentQuery](/after-update/add-ons/parent-query) or a [PriorParentQuery](/after-update/add-ons/prior-parent-query) and read `getNewParent` or `getOldParent`.

## Register {#register}

<!--@include: @/_parts/generated/after-update/register.md-->

In the examples, the Opportunity trigger lists every event, and its orchestrator returns two AfterUpdate Writers:

<<< @/../examples/main/default/triggers/OpportunityTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

::: details Full orchestrator

<<< @/../examples/main/default/classes/opportunity/OpportunityTriggerOrchestrator.cls

:::

## How AfterUpdate Runs {#how-it-runs}

<!--@include: @/_parts/run-order/after.md-->

In after update:

- **Step 2.** Building the handler list calls `maxRecursionDepthOnAfterUpdate()` on every Writer and Dispatcher that implements RecursionGuard, and `ownUnitOfWorkOnAfterUpdate()` on every Writer that implements OwnUnitOfWork, even for a handler that step 3 then switches off.
- **Step 4.** If an active handler implements ParentQuery, one query on the saved trigger records reads every declared current parent through its relationship path. Current parents that this query did not return, and previous parents (PriorParentQuery) that are not loaded yet, cost one query per lookup.
- **Step 5.** Before each predicate, a record that has used up this handler's recursion budget is skipped. When the predicate returns true, the record's count goes up by 1, then a Writer's action runs at once, while a Dispatcher only collects the record. A Writer with its own or a private unit (OwnUnitOfWork, ContinueOnError) commits it right after its Finalizer, if at least one record qualified.
- **Step 6.** Updates of records of the same object fire BeforeUpdate and AfterUpdate again during this commit, as nested runs.

The methods named in steps 2 and 3 are `afterUpdateHandlers()` and `bypassOnAfterUpdateWhen()`.

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

To skip one handler in after update only, on a condition such as a static flag or a batch context, implement [AfterUpdate.Bypassable](/after-update/add-ons/bypassable).

## Gotchas {#gotchas}

- **Updating the same object fires the update triggers again.** A Writer that registers `toUpdate(new Opportunity(Id = record.getId(), …))`, or updates any other record of the object, makes the shared commit run BeforeUpdate and AfterUpdate for those rows, synchronously, before this run ends. By default each AfterUpdate handler acts on the same record at most 3 times per transaction ([RecursionGuard](/after-update/add-ons/recursion-guard)). Gate the Writer on a change (`isChanged`, `isChangedTo`), so the nested run does not qualify the record again. The platform stops at 16 nested trigger frames, and that error cannot be caught inside the nested frames.
- **The recursion count is per transaction, not per statement.** It is never reset during the transaction, so separate updates of the same record in one transaction (a Flow, then Apex, then another `update`) spend it too. With the default of 3, the fourth update in one transaction that qualifies the same record skips the handler, silently.
- **Every chunk is its own run.** A statement of 1,000 records runs the handlers 5 times, with 5 shared commits and 5 dispatches. Statics persist across chunks; instance fields reset whenever `afterUpdateHandlers()` returns new instances.
- **Partial saves run the handlers twice.** With `Database.update(records, false)`, Data Loader or the Bulk API, a failing record rolls the first attempt back, and the platform runs the triggers again for the surviving records. Unit-of-work writes of the first attempt roll back with it, but both attempts spend recursion budget: with a limit of 1, the retry skips every survivor and their writes are lost ([Edge Values](/after-update/add-ons/recursion-guard#edge-values)). Publish Immediately events of the first attempt are not rolled back, and whether emails and enqueued jobs repeat is not verified. Keep side effects idempotent.

<!--@include: @/_parts/notes/stale-api.md-->

Here the empty marker is `AfterUpdate.Handler`. After-update handlers written for the earlier API implement only that marker, so they compile and never run.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-update/not-available.md-->

| Also not here | Use instead |
|---|---|
| `put` on the trigger record | [BeforeUpdate.Populator](/before-update/populator), or a Writer's `toUpdate` of a new instance with the record Id, which fires the update triggers again |
| Rejecting the update before it is saved | [BeforeUpdate.Validator](/before-update/validator). From here, `record.getNewSObject().addError(…)` in a Writer or Dispatcher reverts that record's update. |
| Undelete, merge or hard delete through the unit of work | not supported: use direct DML, which runs at once |
| DML results or new Ids inside the handler | none: the unit commits after the handler. An [OwnUnitOfWork](/after-update/add-ons/own-unit-of-work) sees them in a `commitHook`, or later through `DML.retrieveResultFor(identifier)`. |

## See Also {#see-also}

- [BeforeUpdate](/before-update/): set fields and validate before the save. Its recursion budget is separate from this one.
- [AfterInsert](/after-insert/): a Writer there that updates the new records lands here.
- [Contexts at a Glance](/contexts)
- [Unit of Work](/guide/unit-of-work) and [Execution Order & Cost](/guide/execution-order)
- [Before → after handoff](/guide/orchestrator#before-after-handoff)
