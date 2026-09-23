---
template: role
context: AfterInsert
interface: Writer
description: Create, update or delete other records, or publish platform events, after insert through a unit of work that commits with the save.
---

# AfterInsert.Writer

Creates, updates or deletes other records, or publishes platform events, after new records are saved. Register the writes on the unit of work: they commit with the save, without DML in your loop.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/writer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/writer/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [Insert a record]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Update the inserted record]

:::

## Good to Know {#good-to-know}

- **Register, don't run DML.** By default, Writers share one unit of work that merges their writes and commits once, after the last handler. A direct `insert` or `update` runs at once and skips the unit.
- **Later handlers don't see your writes.** Registered records are not in the database until the unit commits. A later Writer reads the rows as they were saved.
- **The row is read-only.** `record.put(…)` throws, and the insert fails. To change the new record, register `toUpdate(new Contact(Id = record.getId(), …))`. That saves it again and runs the update triggers.
- **Inserting the same object runs after insert again.** Insert contexts have no RecursionGuard. Only your predicate stops the chain.
- **Writer wins.** A class that also implements `AfterInsert.Dispatcher` runs only as a Writer.

## Test {#test}

```apex
@IsTest
static void writeOnAfterInsertRegistersOnboardingTask() {
    // Setup
    Id accountId = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType);
    TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Account(Id = accountId, Name = 'Acme', Type = 'Customer - Direct'), null);
    RecordingUnitOfWork unitOfWork = new RecordingUnitOfWork();

    // Test
    new AccountWelcomeTaskWriter().writeOnAfterInsert(record, unitOfWork);

    // Verify
    Assert.areEqual('Onboarding call - Acme', ((Task) unitOfWork.inserted[0]).Subject, 'The task subject should name the account.');
}
```

`RecordingUnitOfWork` is a small test class that implements `TriggerHandler.UnitOfWork` and keeps what it receives. See [Testing](/guide/testing).
