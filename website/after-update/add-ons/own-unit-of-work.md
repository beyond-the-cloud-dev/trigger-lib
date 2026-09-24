---
template: add-on
context: AfterUpdate
interface: OwnUnitOfWork
description: Give an after update Writer its own DML Lib unit of work, for user mode, sharing, partial success, a commit hook or your own statement order.
---

# AfterUpdate.OwnUnitOfWork

Give a Writer its own DML Lib unit of work, for user mode, sharing, partial success or your own statement order.

**Signature**

<!--@include: @/_parts/generated/after-update/own-unit-of-work/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/own-unit-of-work/skeleton.md-->

```apex [Partial success with a hook]
public with sharing class OpportunityLossReviewTaskWriter implements AfterUpdate.Writer, AfterUpdate.OwnUnitOfWork {
    public DML.Committable ownUnitOfWorkOnAfterUpdate() {
        return new DML().userMode().allowPartialSuccess().commitHook(new FailedTasks()).identifier('OpportunityLossReviewTaskWriter');
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Lost');
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
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

## Rules {#rules}

- **It commits right after this Writer, if a record qualified.** Later handlers see its rows.
- **`new DML()` runs in user mode.** The running user's object permissions, field-level security and sharing apply.
- **Failed rows are not logged.** With `allowPartialSuccess()`, read the failures in a `commitHook`, as the example does, or with `DML.retrieveResultFor('<identifier>')`.
- **Failed commits fail the update.** The error is logged under the Writer's name. Add [ContinueOnError](/after-update/add-ons/continue-on-error) to swallow it; the Writer still uses this unit.

::: warning
Without `combineOnDuplicate()`, a second `toUpdate` or `toDelete` of the same Id throws at registration.
:::
