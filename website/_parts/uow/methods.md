A Writer registers records on the `unitOfWork` its action receives, `writeOn<Ctx>(record, unitOfWork)`, instead of running DML. The library commits them later, grouped by operation and object type. Registering costs no DML statement.

| Method | Registers |
|---|---|
| `toInsert(SObject)`, `toInsert(DML.Record)` | an insert of a record without an Id |
| `toUpdate(SObject)`, `toUpdate(DML.Record)` | an update of a record that has an Id |
| `toUpsert(SObject, SObjectField externalIdField)` | an upsert matched on that external Id field |
| `toDelete(SObject)` | a delete of a record that has an Id |
| `toPublish(SObject)` | a platform event publish |

Every method returns the unit, so calls chain:

```apex
unitOfWork
    .toInsert(new Task(WhatId = accountId, Subject = 'Welcome call'))
    .toUpdate(new Account(Id = accountId, Rating = 'Hot'))
    .toPublish(new AccountSync__e(AccountId__c = accountId));
```

- **One record per call.** There are no List overloads. Register inside the per-record action, or loop over the records in the Finalizer.
- **Registration only.** The unit has no undelete, merge, hard delete or commit method, because the library commits it for you. For those operations use direct DML. It runs at once and bypasses the unit.
- **New instances, never the trigger row.** Build a new record with the Id and only the fields to change, such as `new Account(Id = accountId, Rating = 'Hot')`. The platform refuses DML on the trigger rows themselves, so a commit that includes one of them throws.
- **Ids are checked at commit.** `toInsert` of a record that has an Id, and `toUpdate` or `toDelete` of a record without one, throw a `DmlException` when the unit commits.
- **The Finalizer gets no unit.** To register from `finalize<Ctx>(records)`, keep the unit from the action in an instance field.

`toInsert` and `toUpdate` also take a `DML.Record`, which can point a lookup at a record inserted in the same unit. The unit inserts the parent first, then fills the lookup with the parent's new Id:

```apex
Account branch = new Account(Name = 'Acme Branch');

unitOfWork
    .toInsert(branch)
    .toInsert(DML.Record(new Contact(LastName = 'Doe')).withRelationship(Contact.AccountId, branch));
```

The parent must be registered with `toInsert` or `toUpsert` in the same unit, or already have an Id. For a `toInsert` child, anything else makes the commit throw "Related record has no Id and is not registered in the unit of work." For a `toUpdate` child, the lookup is left unchanged without an error. To link by an external Id instead, use `withRelationship(lookupField, externalIdField, externalIdValue)`.
