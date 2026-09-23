---
description: How after-context Writers insert, update, upsert, delete and publish platform events through TriggerHandler.UnitOfWork - the seven registration methods, which unit a Writer gets, when and in what order it commits, configuring your own unit with DML Lib (user mode, partial success, statement order) and reading commit results.
---

# Unit of Work

In after insert, after update, after delete and after undelete, a Writer does not run DML itself. It registers inserts, updates, upserts, deletes and platform events on a unit of work, `TriggerHandler.UnitOfWork`, and the library commits them in bulk: one statement per operation and object type instead of one per record.

Each context's Writer page shows the unit in its context:

<!--@include: @/_parts/generated/chips/writer.md-->

## Registering Writes {#methods}

<!--@include: @/_parts/uow/methods.md-->

The interface, method by method: [TriggerHandler.UnitOfWork](/api/unit-of-work).

## Which Unit a Writer Gets {#which-unit}

<!--@include: @/_parts/uow/which-unit.md-->

## When It Commits {#when-it-commits}

<!--@include: @/_parts/uow/commit-timing.md-->

## Your Own Unit {#own-unit}

A Writer that implements its context's OwnUnitOfWork add-on builds the unit itself, for example to respect the running user's permissions or to save what can be saved:

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

The action still registers through the `unitOfWork` parameter. The library forwards the registrations to the unit the method returned and commits it right after this Writer.

<!--@include: @/_parts/add-ons/configuring-unit.md-->

The add-on in each context:

<!--@include: @/_parts/generated/chips/own-unit-of-work.md-->

## Statement Order {#statement-order}

The default order is described under [When It Commits](#when-it-commits); neither the handler list nor the order of registrations changes it. To choose the order, return a unit built with `new DML(List<DML.OperationType>)`. This one deletes before it inserts, for a Writer that replaces records:

```apex
public DML.Committable ownUnitOfWorkOnAfterUpdate() {
    return new DML(new List<DML.OperationType>{ DML.OperationType.DELETE_DML, DML.OperationType.INSERT_DML })
        .systemMode()
        .withoutSharing()
        .identifier('ContactRoleReplaceWriter');
}
```

The operation types are `INSERT_DML`, `UPSERT_DML`, `UPDATE_DML`, `MERGE_DML`, `DELETE_DML`, `UNDELETE_DML` and `PUBLISH_DML`. List every operation the Writer registers: any other one throws at registration.

## Reading Results {#results}

A commit's results are a `DML.Result`: per operation and object type, the records that succeeded and failed and the errors of each row. There are two ways to read them.

**By identifier, later in the transaction.** A unit with `identifier('<name>')` stores the results of each commit that completes. `DML.retrieveResultFor('<name>')` returns everything stored under that name so far in the transaction:

```apex
DML.OperationResult taskInserts = DML.retrieveResultFor('OpportunityLossReviewWriter').insertsOf(Task.SObjectType);

for (SObject failedTask : taskInserts.failures()) {
    System.debug(LoggingLevel.WARN, 'Task not created: ' + failedTask);
}
```

The shared unit and every private unit use `'triggerUow'`, so `DML.retrieveResultFor('triggerUow')` collects the commits of every Trigger Lib run in the transaction, on every object. A commit that throws stores nothing.

**Inside the commit, with a hook.** `commitHook(DML.Hook)` runs your class around the commit: `before()` before the first statement, `after(DML.Result)` after the last one. `after` does not run when a statement throws.

```apex
private class LossReviewResults implements DML.Hook {
    public Integer failedTasks = 0;

    public void before() {
    }

    public void after(DML.Result result) {
        this.failedTasks += result.insertsOf(Task.SObjectType).failures().size();
    }
}
```

**Failures across the org.** DML Lib has its own logger interface, `DML.Logger`, with one method, `log(DML.OperationResult)`. If the org has an implementation, it receives every failed operation of every DML Lib unit, the shared unit included, and the failed rows of a partial-success commit. `TriggerOrchestrator.Logger` never sees a failed shared commit: see [Errors & Logging](/guide/error-handling#never-logged).

## Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Direct DML Instead {#direct-dml}

Some handlers get no unit, and some operations have no registration method:

- **Before insert and before update** allow no DML at all: the DML guard fails the save. Set fields on the trigger record with `put` in a Populator instead.
- **Before delete** has no unit and no DML guard. DML in the handler or its Finalizer runs at once. Collect Ids per record and run one statement in the Finalizer: [BeforeDelete.Finalizer](/before-delete/add-ons/finalizer).
- **A Dispatcher** gets no unit. DML it runs is direct DML, at its position in the list, before the shared commit. Build it with `new DML().identifier('<name>')` when a test should mock it.
- **Undelete, merge and hard delete** have no registration method. Run them as direct DML, once per chunk, from a Dispatcher or a Finalizer.

Direct DML is not merged with any unit, and it fires the triggers of the records it saves at once.

## Testing {#testing}

**What a Writer registers.** Call the action with a small class of your own that implements `TriggerHandler.UnitOfWork` and keeps what it receives. Nothing is saved, because that class never commits: [Testing](/guide/testing#writers).

**The unit you return.** Mock its identifier and commit it directly:

<!--@include: @/_parts/add-ons/test-techniques.md#uow-->

**The shared unit.** Running the whole orchestrator in a test, with `DML.mock('triggerUow').allDmls()` and `DML.retrieveResultFor('triggerUow')`, works in the same namespace only: [Testing](/guide/testing#orchestrator).

## See Also {#see-also}

- [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [Execution Order & Cost](/guide/execution-order#dml-cost): DML statements per run
- [Errors & Logging](/guide/error-handling#continue-on-error): ContinueOnError and the private unit
- [DML Lib](https://dml.beyondthecloud.dev): the full `DML` API
