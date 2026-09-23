---
description: 'TriggerHandler.UnitOfWork reference: the seven registration methods a Writer uses to insert, update, upsert, delete and publish in after contexts, DML.Record lookups to records inserted in the same unit, which unit a Writer gets, and a recording unit for unit tests.'
---

# TriggerHandler.UnitOfWork

An after-context Writer gets it in its action, `writeOn<Ctx>(record, unitOfWork)`. Register your writes on it. The library commits them later, in bulk.

## Interface {#interface}

```apex
public interface UnitOfWork {
    UnitOfWork toInsert(SObject record);
    UnitOfWork toInsert(DML.Record record);

    UnitOfWork toUpdate(SObject record);
    UnitOfWork toUpdate(DML.Record record);

    UnitOfWork toUpsert(SObject record, SObjectField externalIdField);

    UnitOfWork toDelete(SObject record);

    UnitOfWork toPublish(SObject event);
}
```

Every method returns the unit, so calls chain:

```apex
unitOfWork
    .toInsert(new Task(WhatId = accountId, Subject = 'Welcome call'))
    .toUpdate(new Account(Id = accountId, Rating = 'Hot'))
    .toPublish(new AccountSync__e(AccountId__c = accountId));
```

- **One record per call.** There are no List overloads.
- **New instances only.** Build a record with the Id and the changed fields. A commit that includes a trigger row throws.
- **Ids are checked at commit.** `toInsert` of a record with an Id, or `toUpdate` and `toDelete` of a record without one, throw a `DmlException` then.
- **`toUpsert` with a `null` field** matches on the record Id.
- **No undelete, merge, hard delete or commit.** Run direct DML for those operations.

## DML.Record {#dml-record}

`DML.Record` comes from DML Lib, which ships with Trigger Lib. Use it to point a lookup at a record inserted in the same unit:

```apex
Account branch = new Account(Name = 'Acme Branch');

unitOfWork
    .toInsert(branch)
    .toInsert(DML.Record(new Contact(LastName = 'Doe')).withRelationship(Contact.AccountId, branch));
```

- **The parent goes first.** The unit inserts it, then fills the lookup with its new Id.
- **Register the parent in the same unit,** with `toInsert` or `toUpsert`, or give it an Id. Otherwise a `toInsert` child makes the commit throw.
- **Other members.** `DML.Record(recordId)` starts an update from an Id. `with(field, value)` sets a field. `withRelationship(lookupField, externalIdField, externalIdValue)` links by external Id.

## Which Unit a Writer Gets {#which-unit}

| The Writer implements | Its unit |
|---|---|
| OwnUnitOfWork | the unit its `ownUnitOfWorkOn<Ctx>()` method returns |
| ContinueOnError, without OwnUnitOfWork | a private unit, so a failure drops only this Writer's writes |
| neither | the default unit, shared by all such Writers in the run |

- **The default unit** is `new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow')`. It commits once, after the last handler of the run.
- **An own or private unit** commits right after its Writer, when at least one record qualified.
- **Need user mode, sharing or partial success?** Implement OwnUnitOfWork and configure the `DML.Committable` it returns.
- **Only Writers get a unit.** A Dispatcher gets none.

Commit order, duplicates and failures: [Unit of Work](/guide/unit-of-work).

## In Unit Tests {#test}

Pass a small recording unit to the Writer's action, then assert on what it kept. Nothing reaches the database.

::: details A recording unit of work

```apex
private class RecordingUnitOfWork implements TriggerHandler.UnitOfWork {
    public List<SObject> inserted = new List<SObject>();
    public List<SObject> updated = new List<SObject>();

    public TriggerHandler.UnitOfWork toInsert(SObject record) {
        this.inserted.add(record);
        return this;
    }

    public TriggerHandler.UnitOfWork toInsert(DML.Record record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpdate(SObject record) {
        this.updated.add(record);
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

```apex
@IsTest
static void writeOnAfterUpdateRegistersAccountType() {
    // Setup
    Id accountId = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType);
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Opportunity(AccountId = accountId, StageName = 'Closed Won'), new Opportunity(AccountId = accountId, StageName = 'Prospecting'));
    RecordingUnitOfWork unitOfWork = new RecordingUnitOfWork();

    // Test
    new OpportunityAccountTypeWriter().writeOnAfterUpdate(record, unitOfWork);

    // Verify
    Assert.areEqual('Customer - Direct', ((Account) unitOfWork.updated[0]).Type, 'The account type should be updated.');
}
```
