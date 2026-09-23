---
template: role
context: AfterUpdate
interface: Writer
description: After update, create, update or delete other records or publish platform events through a unit of work that commits with the save.
---

# AfterUpdate.Writer

Changes other records after the update: children, the parent, a follow-up task. Register the writes on the unit of work, and the library commits them with the save.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/writer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/writer/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [Update the parent]

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [Insert a record]

:::

## Good to Know {#good-to-know}

- **Register, do not run DML.** `toInsert`, `toUpdate`, `toUpsert`, `toDelete` and `toPublish` take one record each. By default, the unit commits after the last handler, in system mode without sharing. Direct DML runs at once and bypasses the unit.
- **Register new instances.** The trigger rows are read-only. Build a new record with the Id and only the fields to change, such as `new Account(Id = accountId, Type = 'Customer - Direct')`.
- **Gate on a change.** A `toUpdate` of records of this object runs the update triggers again. Qualify with `isChanged` or `isChangedTo`, so the nested run skips the record.
- **Nothing is saved inside the handler.** A `toInsert` record has no Id yet in the action or the Finalizer. For user mode, partial success or commit results, add [OwnUnitOfWork](/after-update/add-ons/own-unit-of-work).
- **Writer wins.** A class that also implements `AfterUpdate.Dispatcher` runs only as a Writer.

## Test {#test}

```apex
@IsTest
static void writeOnAfterUpdateWhenStageChangedToClosedWon() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Opportunity(StageName = 'Closed Won'), new Opportunity(StageName = 'Negotiation/Review'));

    // Test
    Boolean result = new OpportunityWinTaskWriter().writeOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```
