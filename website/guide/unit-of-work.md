---
description: How Writers insert, update, upsert, delete and publish platform events through TriggerTypes.UnitOfWork - registration, which unit a Writer gets, when it commits, and your own unit with DML Lib.
---

# Unit of Work

A Writer, in before delete and in the after contexts, does not run DML. It registers writes on [`TriggerTypes.UnitOfWork`](/api/unit-of-work), and the library commits them in bulk: one statement per operation and object type.

## Which Unit a Writer Gets {#which-unit}

| The Writer implements | Its unit |
|---|---|
| OwnUnitOfWork | the unit its `ownUnitOfWorkOn<Ctx>()` returns |
| ContinueOnError, without OwnUnitOfWork | the automatic unit of work, set up like the shared one |
| neither | the shared unit of work of the run |

The shared unit of work is `new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow')`. Only Writers get a unit. A Dispatcher gets none.

## When It Commits {#when-it-commits}

- **The shared unit of work commits once per run,** after the last handler.
- **Any other unit commits right after its Writer,** when at least one record qualified. Later handlers can query its writes.
- **A failed shared commit fails the save.** ContinueOnError does not apply, and `TriggerOrchestrator.Logger` never sees it.
- **Statement order is fixed.** Inserts and upserts first, parents before children, then updates, deletes and event publishes. The handler list does not change it.
- **Duplicates merge.** In the shared and automatic units, a second `toUpdate` or `toDelete` of the same Id merges into the first. Later fields win.

## Your Own Unit {#own-unit}

Implement OwnUnitOfWork to choose user mode, sharing, partial success or statement order:

```apex
public with sharing class OpportunityLossReviewWriter implements AfterUpdate.Writer, AfterUpdate.OwnUnitOfWork {
    public DML.Committable ownUnitOfWorkOnAfterUpdate() {
        return new DML().userMode().allowPartialSuccess().identifier('OpportunityLossReviewWriter');
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Lost');
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Opportunity lostOpportunity = (Opportunity) record.getNewSObject();

        unitOfWork.toInsert(new Task(WhatId = lostOpportunity.Id, OwnerId = lostOpportunity.OwnerId, Subject = 'Loss review'));
    }
}
```

- **Register as usual.** The action still gets the `unitOfWork` parameter.
- **A plain `new DML()` differs from the shared unit of work.** It runs in user mode and throws on a duplicate registration.
- **Your own order.** `new DML(List<DML.OperationType>)` runs operations in the listed order. Registering an operation the list leaves out throws.
- **Read results.** `DML.retrieveResultFor('<identifier>')` returns the results of every commit under that identifier in the transaction. With `allowPartialSuccess()`, failed rows do not throw, so read them there.

All settings: [DML Lib](https://dml.beyondthecloud.dev).

## Platform Events {#platform-events}

- **A Writer** calls `unitOfWork.toPublish(event)`. The publish runs inside the commit.
- **A Dispatcher** calls `EventBus.publish(events)`. It runs at once.
- **Publish Behavior decides delivery.** A Publish After Commit event rolls back with a failed save. A Publish Immediately event goes out even if the save fails.

## Without a Unit {#direct-dml}

- **Before insert and before update** allow no DML. Set fields with `put` in a Populator.
- **A Dispatcher** runs direct DML at its turn, before the commit after the last handler.
