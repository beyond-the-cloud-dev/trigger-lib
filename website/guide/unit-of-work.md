---
description: How after-context Writers insert, update, upsert, delete and publish platform events through TriggerHandler.UnitOfWork - registration, which unit a Writer gets, when it commits, and your own unit with DML Lib.
---

# Unit of Work

In after contexts a Writer does not run DML. It registers writes on `TriggerHandler.UnitOfWork`, and the library commits them in bulk: one statement per operation and object type.

## Register Writes {#methods}

| Method | Registers |
|---|---|
| `toInsert(SObject)`, `toInsert(DML.Record)` | an insert of a record without an Id |
| `toUpdate(SObject)`, `toUpdate(DML.Record)` | an update of a record with an Id |
| `toUpsert(SObject, SObjectField externalIdField)` | an upsert on that external Id field |
| `toDelete(SObject)` | a delete of a record with an Id |
| `toPublish(SObject)` | a platform event publish |

Every method returns the unit, so calls chain:

```apex
unitOfWork
    .toInsert(new Task(WhatId = accountId, Subject = 'Welcome call'))
    .toUpdate(new Account(Id = accountId, Rating = 'Hot'))
    .toPublish(new AccountSync__e(AccountId__c = accountId));
```

- **One record per call.** There are no list overloads.
- **New instances only.** Build a record with the Id and the changed fields. A commit that includes a trigger row throws.
- **No undelete, merge or hard delete.** Run those as direct DML from a Dispatcher or a Finalizer.
- **The Finalizer gets no unit.** Keep the unit from the action in an instance field.

To point a lookup at a record inserted in the same unit, wrap the child in `DML.Record`:

```apex
Account branch = new Account(Name = 'Acme Branch');

unitOfWork
    .toInsert(branch)
    .toInsert(DML.Record(new Contact(LastName = 'Doe')).withRelationship(Contact.AccountId, branch));
```

## Which Unit a Writer Gets {#which-unit}

| The Writer implements | Its unit |
|---|---|
| OwnUnitOfWork | the unit its `ownUnitOfWorkOn<Ctx>()` returns |
| ContinueOnError, without OwnUnitOfWork | a private unit, set up like the shared one |
| neither | the shared unit of the run |

The shared unit is `new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow')`. Only Writers get a unit. A Dispatcher gets none.

## When It Commits {#when-it-commits}

- **The shared unit commits once per run,** after the last handler.
- **An own or private unit commits right after its Writer,** when at least one record qualified. Later handlers can query its writes.
- **Registered is not saved.** Later handlers cannot query what an earlier Writer put in the shared unit.
- **A failed shared commit fails the save.** ContinueOnError does not apply, and `TriggerOrchestrator.Logger` never sees it.
- **Statement order is fixed.** Inserts and upserts first, parents before children, then updates, deletes and event publishes. The handler list does not change it.
- **Duplicates merge.** In the shared and private units, a second `toUpdate` or `toDelete` of the same Id merges into the first. Later fields win.

## Your Own Unit {#own-unit}

Implement OwnUnitOfWork to choose user mode, sharing, partial success or statement order:

```apex
public with sharing class OpportunityLossReviewWriter implements AfterUpdate.Writer, AfterUpdate.OwnUnitOfWork {
    public DML.Committable ownUnitOfWorkOnAfterUpdate() {
        return new DML().userMode().allowPartialSuccess().identifier('OpportunityLossReviewWriter');
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Lost');
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Opportunity lostOpportunity = (Opportunity) record.getNewSObject();

        unitOfWork.toInsert(new Task(WhatId = lostOpportunity.Id, OwnerId = lostOpportunity.OwnerId, Subject = 'Loss review'));
    }
}
```

- **Register as usual.** The action still gets the `unitOfWork` parameter.
- **A plain `new DML()` differs from the shared unit.** It runs in user mode and throws on a duplicate registration.
- **Your own order.** `new DML(List<DML.OperationType>)` runs operations in the listed order. Registering an operation the list leaves out throws.
- **Read results.** `DML.retrieveResultFor('<identifier>')` returns the results of every commit under that identifier in the transaction. With `allowPartialSuccess()`, failed rows do not throw, so read them there.

All settings: [DML Lib](https://dml.beyondthecloud.dev).

## Platform Events {#platform-events}

- **A Writer** calls `unitOfWork.toPublish(event)`. The publish runs inside the commit.
- **A Dispatcher** calls `EventBus.publish(events)`. It runs at once.
- **Publish Behavior decides delivery.** A Publish After Commit event rolls back with a failed save. A Publish Immediately event goes out even if the save fails.

## Without a Unit {#direct-dml}

- **Before insert and before update** allow no DML. Set fields with `put` in a Populator.
- **Before delete** has no unit. DML runs at once. Collect Ids per record and run one statement in the [Finalizer](/before-delete/add-ons/finalizer).
- **A Dispatcher** runs direct DML at its turn, before the shared commit.
