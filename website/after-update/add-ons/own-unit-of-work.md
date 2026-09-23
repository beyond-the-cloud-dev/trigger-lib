---
template: add-on
context: AfterUpdate
interface: OwnUnitOfWork
description: 'Give an after update Writer its own DML Lib unit of work, for user mode, sharing, partial success, a commit hook or a custom statement order.'
---

# AfterUpdate.OwnUnitOfWork

Give an **after update** Writer its own DML Lib unit of work instead of the shared one: user mode, with sharing, partial success, a commit hook to read results, or your own statement order. It commits right after this Writer.

<!--@include: @/_parts/generated/after-update/own-unit-of-work/available-in.md-->

## When to Use {#when-to-use}

- The writes must respect the running user's permissions, field-level security or sharing (user mode, `withSharing()`).
- Some rows may fail without failing the update (`allowPartialSuccess()`), and you want to read which ones.
- The statements must run in an order you choose, such as deletes before inserts.
- A later handler must query what this Writer wrote: the own unit commits before the next handler runs.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/own-unit-of-work/signature.md-->

<!--@include: @/_parts/generated/after-update/own-unit-of-work/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/own-unit-of-work/skeleton.md-->

```apex [Partial success with a hook]
public with sharing class OpportunityLossReviewTaskWriter implements AfterUpdate.Writer, AfterUpdate.OwnUnitOfWork {
    public DML.Committable ownUnitOfWorkOnAfterUpdate() {
        return new DML().userMode().allowPartialSuccess().commitHook(new FailedTasks()).identifier('OpportunityLossReviewTaskWriter');
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Lost');
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        unitOfWork.toInsert(new Task(WhatId = record.getId(), Subject = 'Loss review'));
    }

    private class FailedTasks implements DML.Hook {
        public void before() {
        }

        public void after(DML.Result result) {
            for (DML.Error error : result.insertsOf(Task.SObjectType).errors()) {
                System.debug(LoggingLevel.ERROR, error.message());
            }
        }
    }
}
```

:::

With `allowPartialSuccess()`, a Task that fails does not throw, so the hook is where the failures become visible. Replace the `System.debug` with your own logging.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/own-unit-of-work.md-->

### Configuring the Unit {#configuring}

<!--@include: @/_parts/add-ons/configuring-unit.md-->

## Records Here {#records}

`ownUnitOfWorkOnAfterUpdate()` takes no records. The Writer's action receives the unit as its `unitOfWork` parameter, per qualified record, as with the shared unit.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/own-unit-of-work/works-with.md-->

## Gotchas {#gotchas}

- **Failed rows are not logged by the library.** With `allowPartialSuccess()`, the library discards the `DML.Result` of the commit, so failed rows never reach `TriggerOrchestrator.Logger`. A DML Lib `DML.Logger` implementation, if the org has one, records them. Read them in a `commitHook`, as the example does, or later in the transaction with `DML.retrieveResultFor('<your identifier>')`.
- **User mode is the default of `new DML()`.** The running user's object permissions, field-level security and sharing apply, so a user who may not create the object or edit a field makes rows fail. When the commit throws, the error is logged under the Writer's name and fails the update, unless the Writer implements ContinueOnError.
- **Duplicates.** Without `combineOnDuplicate()`, a second `toUpdate` or `toDelete` of the same Id throws at registration. With the default statement order, the same record registered twice with `toInsert` or `toUpsert` throws at commit, with or without it.
- **Extra statements.** The unit commits its own statements, on top of the shared unit's: at least one per operation and object type it registered, in every 200-record chunk.
- **Called for bypassed Writers too.** `ownUnitOfWorkOnAfterUpdate()` runs while the handler list is built, before the bypass checks, so keep it free of queries and side effects.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#uow-->

The Skeleton's identifier is `'ContactWriter'`; the example's is `'OpportunityLossReviewTaskWriter'`. For the action itself, pass the small recording class shown under [AfterUpdate.Writer](/after-update/writer#test).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/own-unit-of-work/other-contexts.md-->

## See Also {#see-also}

- [Which unit a Writer gets](/after-update/writer#which-unit) and [when it commits](/after-update/writer#when-it-commits)
- [Unit of Work](/guide/unit-of-work) and [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [AfterUpdate.ContinueOnError](/after-update/add-ons/continue-on-error): a private unit with the shared configuration.
