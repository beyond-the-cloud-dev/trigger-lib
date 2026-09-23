---
template: role
context: AfterInsert
interface: Writer
description: AfterInsert.Writer - after insert, create child records, update other records or publish platform events through a unit of work that commits with the save.
---

# AfterInsert.Writer

After insert, create, update or delete other records, or publish platform events, through a unit of work that commits with the save. The new records have Ids, so this is where child records, junction records and share rows that need the new Id are created, without DML in your loop.

<!--@include: @/_parts/generated/after-insert/writer/available-in.md-->

## When to Use {#when-to-use}

- Create child records, junction records or share rows that need the new record's Id.
- Update a parent or other existing records.
- Publish a platform event that should roll back with the save.
- Use a [Dispatcher](/after-insert/dispatcher) instead for async work, callouts through a Queueable, email or approvals. Use a [BeforeInsert.Populator](/before-insert/populator) instead for fields on the new record itself.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/writer/signature.md-->

<!--@include: @/_parts/generated/after-insert/writer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/writer/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [Insert a record]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Update the inserted record]

:::

`ContactOwnerAlignmentWriter` updates the Contact it has just inserted. Its value is known before the save, so a BeforeInsert.Populator could set it without a second save; the tab shows the after insert path and its cost, described in [Gotchas](/after-insert/#gotchas).

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/writer.md-->

### Unit of Work Methods {#unit-of-work-methods}

<!--@include: @/_parts/uow/methods.md-->

### Which Unit You Get {#which-unit}

<!--@include: @/_parts/uow/which-unit.md-->

### When It Commits {#when-it-commits}

<!--@include: @/_parts/uow/commit-timing.md-->

Here that includes an update of the records just inserted: registered on the shared unit, it fires before update and after update for them during the shared commit.

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

Receiving events, that is a trigger on the event object itself, is not tested with Trigger Lib: see [AfterInsert Gotchas](/after-insert/#gotchas).

## Register {#register}

<!--@include: @/_parts/generated/after-insert/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-insert/accessors.md-->

- **Read-only rows.** `put` and any write to `getNewSObject()` throw a `FinalException` that fails the insert. Register `toUpdate(new Contact(Id = record.getId(), …))` instead.
- **No relationship fields on the row.** `getNewSObject().Account` is empty; declare a [ParentQuery](/after-insert/add-ons/parent-query) and read `record.getNewParent('Account')`.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/writer/works-with.md-->

## Gotchas {#gotchas}

- **An update of the inserted record runs the update triggers**, and a delete of it succeeds. See [AfterInsert Gotchas](/after-insert/#gotchas) 2 and 3.
- **Registrations are invisible to later handlers** until the unit commits. A later Writer reads the rows as they were saved. See [AfterInsert Gotchas](/after-insert/#gotchas) 4.
- **A failed shared commit fails the insert.** It is not swallowed and never reaches `TriggerOrchestrator.Logger`; only a DML Lib `DML.Logger` implementation, if the org has one, sees the failed statement.
- **Inserting records of the handler's own object** fires after insert again for the new records, and nothing but your predicate stops the chain.

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the predicate and the action directly with an in-memory record. The action gets a small unit of work of your own that keeps what it receives:

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

::: details The recording unit of work

```apex
private class RecordingUnitOfWork implements TriggerHandler.UnitOfWork {
    public List<SObject> inserted = new List<SObject>();

    public TriggerHandler.UnitOfWork toInsert(SObject record) {
        this.inserted.add(record);
        return this;
    }

    public TriggerHandler.UnitOfWork toInsert(DML.Record record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpdate(SObject record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpdate(DML.Record record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) {
        return this;
    }

    public TriggerHandler.UnitOfWork toDelete(SObject record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toPublish(SObject event) {
        return this;
    }
}
```

:::

Nothing is inserted: the recording unit never commits. Test the predicate the same way, one case per test, such as `writeOnAfterInsertWhenTypeIsProspect`. `startsWith` is case-sensitive, so `'customer - direct'` does not qualify. Running the whole orchestrator with the shared unit mocked works in the same namespace only: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/writer/other-contexts.md-->

Before contexts have no Writer: there, change the record being saved with a Populator.

## See Also {#see-also}

- [Unit of Work](/guide/unit-of-work) and [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [AfterInsert.OwnUnitOfWork](/after-insert/add-ons/own-unit-of-work): user mode, sharing, partial success or your own statement order
- [AfterInsert.Dispatcher](/after-insert/dispatcher): async work, once per chunk
- [AfterInsert](/after-insert/): how the run is ordered
