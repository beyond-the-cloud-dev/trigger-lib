---
description: 'TriggerHandler.UnitOfWork reference: the seven registration methods a Writer uses to insert, update, upsert, delete and publish in after contexts, DML.Record lookups to records inserted in the same unit, what the interface does not offer, and a recording unit for unit tests.'
---

# TriggerHandler.UnitOfWork

The unit of work an after-context Writer receives in its action. It registers inserts, updates, upserts, deletes and platform event publishes (DML) for the library to commit later, in bulk.

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

It reaches only the Writer's action, `writeOn<Ctx>(record, unitOfWork)`, in after insert, after update, after delete and after undelete:

<!--@include: @/_parts/generated/chips/writer/unit-of-work-methods.md-->

## Methods {#methods}

<!--@include: @/_parts/uow/methods.md-->

### DML.Record {#dml-record}

`DML.Record` comes from DML Lib, which ships with Trigger Lib. Build one from a record or an Id:

| Member | Does |
|---|---|
| `DML.Record(SObject record)` | wraps a record you built |
| `DML.Record(Id recordId)` | starts an update from an Id alone |
| `with(SObjectField field, Object value)` | sets a field |
| `withRelationship(SObjectField lookupField, SObject parent)` | fills the lookup with the Id of `parent` once `parent` is inserted |
| `withRelationship(SObjectField lookupField, SObjectField externalIdField, Object externalIdValue)` | points the lookup at the parent with that external Id value; the field must be marked External ID |

Each member returns the `DML.Record`, so calls chain:

```apex
unitOfWork.toUpdate(DML.Record(accountId).with(Account.Rating, 'Hot'));
```

### toUpsert {#to-upsert}

`toUpsert(record, externalIdField)` matches existing rows on that external Id field. Pass `null` as the field to match on the record Id instead. A commit runs one upsert statement per object type and per external Id field.

## Beyond the Interface {#not-available}

The interface only registers. Its methods, the missing List overloads and the missing undelete, merge and hard delete are covered above. Two more needs go through an OwnUnitOfWork, whose method returns a `DML.Committable` that you configure:

- **User mode, sharing, partial success or your own statement order.** Configure them on the `DML` you return.
- **The results of the commit, such as new Ids.** Add `commitHook(…)` with a `DML.Hook`, whose `after(DML.Result)` runs once the commit has finished without throwing. Later in the transaction, `DML.retrieveResultFor('<identifier>')` returns the results of every commit of a unit built with that `identifier`; tests can mock it with `DML.mock('<identifier>')`.

OwnUnitOfWork in each after context:

<!--@include: @/_parts/generated/chips/own-unit-of-work.md-->

## Which Unit a Writer Gets {#which-unit}

<!--@include: @/_parts/uow/which-unit.md-->

When each unit commits, statement order, duplicates and failures: [Unit of Work](/guide/unit-of-work).

## In Unit Tests {#test}

Your tests can implement the interface too. Pass a small recording unit to the Writer's action, then assert on what it kept. Nothing reaches the database, because the recording unit never commits.

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

`OpportunityAccountTypeWriter` is the example Writer on [Record API](/api/record#change-detection). Record doubles and fake Ids: [Test API](/api/record#test-api). Running the whole orchestrator with the shared unit mocked works in the same namespace only: [Testing](/guide/testing).

## See Also {#see-also}

- [Unit of Work](/guide/unit-of-work): commit timing, statement order, duplicates, reading results
- [Test API](/api/record#test-api): records, collections and fake Ids for unit tests

The Writer in each after context:

<!--@include: @/_parts/generated/chips/writer.md-->
