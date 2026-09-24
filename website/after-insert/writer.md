---
template: role
context: AfterInsert
interface: Writer
description: Create, update or delete other records, or publish platform events, after insert through a unit of work that commits with the save.
---

# AfterInsert.Writer

Change other records or publish platform events after the insert, through a unit of work.

**Signature**

<!--@include: @/_parts/generated/after-insert/writer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/writer/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [Insert a record]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Update the inserted record]

:::

## Rules {#rules}

- **Register, don't run DML.** Call `toInsert`, `toUpdate`, `toUpsert`, `toDelete` or `toPublish` (platform events) on `unitOfWork`. Direct DML runs at once and skips the unit.
- **By default, later handlers don't see your writes.** The shared unit of work commits after the last handler. With [OwnUnitOfWork](/after-insert/add-ons/own-unit-of-work) or [ContinueOnError](/after-insert/add-ons/continue-on-error), it commits right after this Writer.
- **Inserting the same object runs after insert again.** Insert contexts have no RecursionGuard. Only your predicate stops the chain.
- **Writer wins.** A class that also implements `AfterInsert.Dispatcher` runs only as a Writer.

::: warning
The row is read-only. `record.put(…)` throws, and the insert fails. To change the new record, register `toUpdate(new Contact(Id = record.getId(), …))`, which saves it again and runs the update triggers.
:::

## Test {#test}

```apex
@IsTest
static void writeOnAfterInsertRegistersOnboardingTask() {
    // Setup
    Id accountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType);
    TriggerTypes.InsertRecord record = new TriggerTypes.TriggerRecord(new Account(Id = accountId, Name = 'Acme', Type = 'Customer - Direct'), null);
    RecordingUnitOfWork unitOfWork = new RecordingUnitOfWork();

    // Test
    new AccountWelcomeTaskWriter().writeOnAfterInsert(record, unitOfWork);

    // Verify
    Assert.areEqual('Onboarding call - Acme', ((Task) unitOfWork.inserted[0]).Subject, 'The task subject should name the account.');
}
```

`RecordingUnitOfWork` is a small [test class](/guide/testing#writers) that implements `TriggerTypes.UnitOfWork` and keeps what it receives.
