---
template: role
context: AfterUpdate
interface: Writer
description: After update, create, update or delete other records or publish platform events through a unit of work that commits with the save.
---

# AfterUpdate.Writer

Change other records or publish platform events after the update, through a unit of work.

**Signature**

<!--@include: @/_parts/generated/after-update/writer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/writer/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [Update the parent]

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [Insert a record]

:::

## Rules {#rules}

- **Register, do not run DML.** `toInsert`, `toUpdate`, `toUpsert`, `toDelete` and `toPublish` (platform events) take one record each. The shared unit runs in system mode without sharing. Direct DML runs at once and bypasses the unit.
- **Gate on a change.** A `toUpdate` of records of this object runs the update triggers again. Qualify with `isChanged` or `isChangedTo`, so the nested run skips the record.
- **Nothing is saved inside the handler.** A `toInsert` record has no Id yet in the action or the Finalizer. For user mode, partial success or commit results, add [OwnUnitOfWork](/after-update/add-ons/own-unit-of-work).
- **Writer wins.** A class that also implements `AfterUpdate.Dispatcher` runs only as a Writer.

::: warning
The trigger rows are read-only. Register a new record with the Id and only the fields to change, such as `new Account(Id = accountId, Type = 'Customer - Direct')`.
:::

## Test {#test}

```apex
@IsTest
static void writeOnAfterUpdateWhenStageChangedToClosedWon() {
    // Setup
    TriggerTypes.UpdateRecord record = new TriggerTypes.TriggerRecord(new Opportunity(StageName = 'Closed Won'), new Opportunity(StageName = 'Negotiation/Review'));

    // Test
    Boolean result = new OpportunityWinTaskWriter().writeOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```
