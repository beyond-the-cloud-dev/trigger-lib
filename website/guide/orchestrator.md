---
description: Wire a Salesforce trigger to Trigger Lib - the one-line trigger, the orchestrator and its handler lists, run order, one class in several contexts, handler instances per chunk and the before to after handoff.
---

# Trigger & Orchestrator

The trigger passes an orchestrator to `TriggerOrchestrator.run(…)`. The orchestrator lists the handlers of each context in run order.

## Trigger {#trigger}

<<< @/../examples/main/default/triggers/AccountTrigger.trigger

- **List all seven events.** A context the orchestrator does not implement does nothing. Add handlers later without touching the trigger.
- **Put nothing else in the body.** Code next to `run(…)` ignores bypasses, and its errors never reach the Logger.
- **One trigger per object.** Salesforce does not guarantee the order of several triggers on one object.
- **Only inside a trigger.** Called anywhere else, `run(…)` throws a `TriggerOrchestratorException`.

## Orchestrator {#orchestrator}

Implement one registration interface per context, such as `TriggerOrchestrator.BeforeInsert`. Its method, such as `beforeInsertHandlers()`, returns the handlers.

<<< @/../examples/main/default/classes/account/AccountTriggerOrchestrator.cls

- **List classes that implement a role.** A class that implements only the context's `Handler` interface compiles and never runs. `BeforeDelete.Handler` is the exception: it is the role.
- **One role per class.** A class that implements both roles of a context runs only as the first: Populator over Validator, Writer over Dispatcher.

## Handler Order {#order}

- **List order is run order**, whatever the role. Each handler finishes before the next one starts.
- **Later handlers see earlier changes.** List Populators before Validators.
- **Writers commit last.** By default, the Writers' DML commits once, after the last handler.

## One Class in Several Contexts {#one-class-several-contexts}

```apex
public with sharing class ContactBirthdateRangeValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
    private static final String MESSAGE = 'Birthdate must be in the past.';

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateRangeValidator.MESSAGE);
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Contact.Birthdate) && this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateRangeValidator.MESSAGE);
    }

    private Boolean isInFuture(Contact contactRecord) {
        return contactRecord.Birthdate != null && contactRecord.Birthdate > Date.today();
    }
}
```

- **Method names carry the context**, so they never clash.
- **Register the class in each context's list.**
- **Add-ons are per context too**, such as `BeforeInsert.ParentQuery` and `BeforeUpdate.ParentQuery`.
- **Switches cover every context.** A `TriggerHandler__mdt` record switches the class off in every context of its object. To skip one context, use that context's Bypassable.

## Instances per Chunk {#instances-per-chunk}

The library calls the handler list method on every run: per context, per chunk of up to 200 records and per nested run.

- **Instance fields reset** on every run when the list returns `new` handlers.
- **Static fields last the whole transaction.**
- **A static "already ran" flag skips later chunks.** Gate the predicate on a change such as `isChanged` instead, or use RecursionGuard in the update contexts.
- **Constructor arguments are allowed.** They are evaluated on every run, so keep SOQL out of them.

## Before to After Handoff {#before-after-handoff}

Stamp a decision on the record in a BeforeUpdate Populator. Let an AfterUpdate Writer or Dispatcher qualify on the stamp:

::: code-group

```apex [AccountHotRatingUpdatePopulator.cls]
public with sharing class AccountHotRatingUpdatePopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.AnnualRevenue) && record.greaterThanOrEqualTo(Account.AnnualRevenue, 1000000);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        record.put(Account.Rating, 'Hot');
    }
}
```

```apex [AccountHotRatingTaskWriter.cls]
public with sharing class AccountHotRatingTaskWriter implements AfterUpdate.Writer {
    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Account.Rating, 'Hot');
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        unitOfWork.toInsert(new Task(WhatId = record.getId(), Subject = 'Call the account: its rating is now Hot'));
    }
}
```

:::

- **The stamp is saved with the record**, so `isChangedTo` sees it after the save.
- **Manual edits count too.** When only the Populator's decision should count, stamp a field users cannot edit.
