---
description: 'TriggerTypes.UnitOfWork reference: the seven registration methods a Writer uses to insert, update, upsert, delete and publish in before delete and the after contexts, and DML.Record lookups to records inserted in the same unit.'
---

# TriggerTypes.UnitOfWork

A Writer registers its DML here, in `writeOn<Ctx>(record, unitOfWork)`. The library commits it later, in bulk: [Unit of Work](/guide/unit-of-work#which-unit).

**Signature**

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

**Example**

```apex
unitOfWork
    .toInsert(new Task(WhatId = accountId, Subject = 'Welcome call'))
    .toUpdate(new Account(Id = accountId, Rating = 'Hot'))
    .toPublish(new AccountSync__e(AccountId__c = accountId));
```

## Rules {#rules}

- **One record per call.** There are no List overloads.
- **New instances only.** Build a record with the Id and the changed fields. A commit that includes a trigger row throws.
- **Ids are checked at commit.** `toInsert` of a record with an Id, or `toUpdate` and `toDelete` of a record without one, throw a `DmlException` then.
- **`toUpsert` with a `null` field** matches on the record Id.
- **No undelete, merge, hard delete or commit.** Run direct DML for those operations.

## DML.Record {#dml-record}

`DML.Record` comes from DML Lib, which ships with Trigger Lib. Use it to point a lookup at a record inserted in the same unit.

**Example**

```apex
Account branch = new Account(Name = 'Acme Branch');

unitOfWork
    .toInsert(branch)
    .toInsert(DML.Record(new Contact(LastName = 'Doe')).withRelationship(Contact.AccountId, branch));
```

- **The parent goes first.** The unit inserts it, then fills the lookup with its new Id.
- **Register the parent in the same unit,** with `toInsert` or `toUpsert`, or give it an Id. Otherwise a `toInsert` child makes the commit throw.
- **Other members.** `DML.Record(recordId)` starts an update from an Id. `with(field, value)` sets a field. `withRelationship(lookupField, externalIdField, externalIdValue)` links by external Id.
