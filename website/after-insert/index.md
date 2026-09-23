---
template: context
context: AfterInsert
description: After insert in Trigger Lib - create child records, update other records or publish events with a Writer, or enqueue async work once per chunk with a Dispatcher, after new records are saved.
---

# AfterInsert

Runs in **after insert** (`AFTER_INSERT`, `Trigger.isAfter && Trigger.isInsert`), after new records are saved and before the transaction commits, once per chunk of up to 200 records. The records now have Ids and audit fields, and they are read-only. Use a Writer to create child records, update other records or publish a platform event through a unit of work; use a Dispatcher to enqueue a Queueable (for a callout), send email or start other async work once per chunk. Read parent (lookup) fields and other records without SOQL in your loop, and skip or bypass a handler on a condition.

## At a Glance {#at-a-glance}

<<< @/../force-app/main/default/classes/AfterInsert.cls

<!--@include: @/_parts/generated/after-insert/facts.md-->

## Pick a Role {#pick-a-role}

| I want to… | Use |
|---|---|
| Create records that need the new Id: a child Task, a junction record, a share row | [AfterInsert.Writer](/after-insert/writer) with `toInsert`, like `AccountWelcomeTaskWriter` |
| Update a parent or other existing records | [AfterInsert.Writer](/after-insert/writer) with `toUpdate` |
| Publish a platform event that commits with the save | [AfterInsert.Writer](/after-insert/writer) with `toPublish` |
| Publish events, enqueue a Queueable, call out, send email or submit for approval, once per chunk | [AfterInsert.Dispatcher](/after-insert/dispatcher); pass `records.getIds()` to async work, not the rows |
| Set or default a field on the record being inserted | [BeforeInsert.Populator](/before-insert/populator): no second save |
| Change the inserted record with a value that needs its Id | [AfterInsert.Writer](/after-insert/writer) with `toUpdate(new Contact(Id = record.getId(), …))`, which fires the update triggers again (see [Gotchas](#gotchas)) |
| Reject the insert | [BeforeInsert.Validator](/before-insert/validator); if the check needs the Id or the saved values, `record.getNewSObject().addError(…)` from a Writer rolls back that record's insert |
| Run the same logic when a record is restored | also implement [AfterUndelete.Writer](/after-undelete/writer) |

<!--@include: @/_parts/roles/one-role.md#after-->

Here the marker is `AfterInsert.Handler`: it types the list that `afterInsertHandlers()` returns, and only its two roles, Writer and Dispatcher, ever run.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-insert/add-ons-table.md-->

## Records {#records}

<!--@include: @/_parts/generated/after-insert/records.md-->

- **Ids are set.** `record.getId()` returns the new Id, and `records.getIds()` returns the Ids of the records it holds.
- **The rows are read-only.** `put` compiles, because `InsertRecord` declares it, but it throws here (see [Gotchas](#gotchas)). Change the new record in [BeforeInsert](/before-insert/), or register a new instance with its Id through a Writer.
- **No parent records on the row.** Audit fields such as `CreatedDate` and `CreatedById` are set, but relationship fields such as `getNewSObject().Account` stay empty. Declare a [ParentQuery](/after-insert/add-ons/parent-query) and read `record.getNewParent('Account')`.

## Register {#register}

<!--@include: @/_parts/generated/after-insert/register.md-->

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

<!--@include: @/_parts/notes/name-collisions.md-->

::: details Full orchestrator

The Contact orchestrator lists two after insert Writers. Their order matters: see Gotcha 4.

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

:::

## How AfterInsert Runs {#how-it-runs}

<!--@include: @/_parts/run-order/after.md-->

In after insert, the steps above use these methods and paths:

- **Step 2.** `afterInsertHandlers()` builds the list. Each Writer's unit is chosen while the list is built, so `ownUnitOfWorkOnAfterInsert()` runs even for a Writer that a bypass skips right after.
- **Step 3.** The handler's own check is `bypassOnAfterInsertWhen()`.
- **Step 4.** When an active handler declares a ParentQuery, one SOQL query on the saved trigger records reads the declared parents through relationship paths, in system mode without sharing. A parent that this query did not return is queried by Id, one query per lookup. Nothing is queried again during the run, because after insert has no Populators.
- **Step 5.** A Writer with its own unit (OwnUnitOfWork) or a private unit (ContinueOnError) commits it right after its Finalizer, when at least one record qualified.
- **Step 6.** An update of the records just inserted, registered on the shared unit, fires before update and after update for them during this commit, as nested runs.

## Switching Handlers Off {#switching-off}

<!--@include: @/_parts/add-ons/switch-off.md-->

The condition-based switch here is [AfterInsert.Bypassable](/after-insert/add-ons/bypassable). For a top-level class, `TriggerOrchestrator.bypass().handler(ContactOwnerAlignmentWriter.class)` switches it off for the rest of the transaction.

## Gotchas {#gotchas}

1. **`put` compiles but throws.** The row is read-only after the save, so `record.put(…)`, like any write to `getNewSObject()`, throws `System.FinalException: Record is read-only`. Nothing inside the trigger can catch it: not your `try`, not the library, not ContinueOnError, so it is never passed to the Logger. The caller's insert fails with a catchable `DmlException` (`CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY`).
2. **Updating the record you just inserted fires the update triggers.** `ContactOwnerAlignmentWriter` registers `toUpdate(new Contact(Id = record.getId(), OwnerId = …))`. The shared unit commits it after the last handler, and the platform then runs before update and after update for those Contacts: in the examples, every handler in `ContactTriggerOrchestrator.beforeUpdateHandlers()`. The after update run ends at once, because the orchestrator does not implement `TriggerOrchestrator.AfterUpdate`.
   - The cost is a second save of those records and one more level of trigger depth. Each before update Populator or after update Writer or Dispatcher that qualifies the record on that pass spends one pass of its recursion budget.
   - Prefer [BeforeInsert.Populator](/before-insert/populator) when the value is known before the save. Here it is: a BeforeInsert.ParentQuery can declare the same `Contact.AccountId => TriggerHandler.ParentFields.with(Account.OwnerId).with('Owner', User.IsActive)`.
   - Update the inserted record from here only when the value needs its Id, or a record created in the same transaction.
3. **Deleting the record you just inserted succeeds.** With `toDelete(new Contact(Id = record.getId()))`, the caller's insert still succeeds and returns the Id of a record that is already in the Recycle Bin.
4. **Later handlers see neither the changed rows nor earlier registrations.** `ContactFollowUpTaskWriter` runs second and assigns its Task to the Contact's `OwnerId`, which is still the owner from before `ContactOwnerAlignmentWriter`'s update: that update waits in the shared unit. Because `ContactFollowUpTaskWriter` implements ContinueOnError, its private unit even commits the Task before the shared unit commits the owner change.
5. **Inserting records of the same object fires after insert again, for the new records.** There is no RecursionGuard in insert contexts, and a count per Id could not recognise new records anyway. Only your predicate stops the chain; otherwise Salesforce stops it at the maximum trigger depth of 16 and the save fails.
6. **Platform-event and change-event objects are not tested.** After insert is the only event their triggers have, and `run()` treats it like any after insert. But event objects have no lookup fields for a ParentQuery, event messages cannot be queried with SOQL, and ContinueOnError would swallow the `EventBus.RetryableException` a subscriber throws to ask for a retry. Treat these objects as unsupported.
7. **Partial saves run every handler again.** When `Database.insert(records, false)`, Data Loader or the Bulk API saves a chunk with a failing record, the platform rolls back the first attempt and runs the triggers again for the records that did not fail. Unit-of-work DML and Publish After Commit events roll back with the first attempt. Publish Immediately events do not, whichever handler published them, so they can go out twice.
8. **Everything runs once per chunk.** A 1,000-record insert is 5 runs: 5 shared commits, 5 dispatches, 5 calls of each Finalizer. Static variables keep their values across chunks; instance fields start fresh when `afterInsertHandlers()` returns new instances.
9. **There is no DML guard.** A direct `insert` or `update` in a Writer, Dispatcher or Finalizer runs at once. It bypasses the unit of work: it is not merged, costs its own DML statement and lands before the shared commit.

<!--@include: @/_parts/notes/stale-api.md-->

In after insert that marker is `AfterInsert.Handler`.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-insert/not-available.md-->

| Also not here | Use instead |
|---|---|
| `put` on the inserted record | [BeforeInsert.Populator](/before-insert/populator), or a Writer's `toUpdate` with the record Id (see [Gotchas](#gotchas)) |
| Old values and change detection | an insert has no previous values → [AfterUpdate](/after-update/record-api#change-detection) |
| An after insert Validator | `record.getNewSObject().addError(…)` from a Writer or Dispatcher |
| Undelete, merge or hard delete through the unit of work | not on `TriggerHandler.UnitOfWork`; use direct DML |
| DML results or the Ids of records you registered, inside the handler | none: the unit commits later. An [OwnUnitOfWork](/after-insert/add-ons/own-unit-of-work#configuring) can read them in a `commitHook`, or later with `DML.retrieveResultFor(identifier)` |
| A before phase for platform-event or change-event objects | none: those objects only have after insert |

## See Also {#see-also}

- [BeforeInsert](/before-insert/): set fields before the save, which costs no second save.
- [AfterUpdate](/after-update/): where an update of the inserted records lands, with RecursionGuard.
- [AfterUndelete](/after-undelete/): run insert logic again when a record is restored.
- [Contexts at a Glance](/contexts)
- [Unit of Work](/guide/unit-of-work) and [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [Execution Order & Cost](/guide/execution-order)
