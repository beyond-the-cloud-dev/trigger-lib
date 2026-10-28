---
description: Wire a Salesforce trigger to Trigger Lib - the one-line trigger, the orchestrator and its handler lists, handlers registered in custom metadata, run order, one class in several contexts, handler instances per chunk and the before to after handoff.
---

# Trigger & Orchestrator

The trigger passes an orchestrator to `TriggerOrchestrator.run(…)`. The orchestrator lists the handlers of each context in run order. A trigger can instead call `TriggerOrchestrator.runFromMetadata()` and take its handlers from [custom metadata](#from-metadata).

## Trigger {#trigger}

<<< @/../examples/main/default/triggers/AccountTrigger.trigger

- **List all seven events.** A context the orchestrator does not implement does nothing. Add handlers later without touching the trigger.
- **Put nothing else in the body.** Code next to `run(…)` ignores bypasses, and its errors never reach the Logger.
- **One trigger per object.** Salesforce does not guarantee the order of several triggers on one object.
- **Only inside a trigger.** Called anywhere else, `run(…)` throws a `TriggerTypes.TriggerLibException`.

## Orchestrator {#orchestrator}

Implement one registration interface per context, such as `TriggerOrchestrator.BeforeInsert`. Its method, such as `beforeInsertHandlers()`, returns the handlers.

<<< @/../examples/main/default/classes/account/AccountTriggerOrchestrator.cls

- **List classes that implement a role.** A class that implements only the context's `Handler` interface compiles and never runs.
- **One role per class.** A class that implements both roles of a context runs only as the first: Populator over Validator, Validator over Writer, Writer over Dispatcher.

## Handlers in Custom Metadata {#from-metadata}

When the trigger's package can't compile against every handler, call `runFromMetadata()` instead of `run(…)`. A core package, for example, can't refer to handlers that live in packages that depend on it:

```apex
trigger AccountTrigger on Account(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerOrchestrator.runFromMetadata();
}
```

Each [`TriggerHandler__mdt`](/api/custom-metadata#trigger-handler) record registers one class in one context: the one whose field, such as `BeforeInsert__c`, names the object's `TriggerObject__mdt` record.

- **No orchestrator class.** The trigger's package never refers to the handlers.
- **The record decides the context.** The class runs only in the context its record names, and must implement it. A class that runs in several contexts has a record per context.
- **`Order__c` is the list order,** as below.
- **A record whose class can't run fails the save.** Test that every record resolves: see [Registration Tests](/guide/testing#registration).

## Handler Order {#order}

- **List order is run order**, whatever the role. Each handler finishes before the next one starts.
- **Under `runFromMetadata()`, `Order__c` is the list order** of each context. It is required. Lowest runs first, and ties run in class name order.
- **Later handlers see earlier changes.** List Populators before Validators.
- **Writers commit last.** By default, the Writers' DML commits once, after the last handler.

## One Class in Several Contexts {#one-class-several-contexts}

```apex
public with sharing class ContactBirthdateRangeValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
    private static final String MESSAGE = 'Birthdate must be in the past.';

    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateRangeValidator.MESSAGE);
    }

    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Contact.Birthdate) && this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateRangeValidator.MESSAGE);
    }

    private Boolean isInFuture(Contact contactRecord) {
        return contactRecord.Birthdate != null && contactRecord.Birthdate > Date.today();
    }
}
```

- **Method names carry the context**, so they never clash.
- **Register the class in each context's list.** Under `runFromMetadata()`, create a record per context, such as `ContactBirthdateRange_BeforeInsert` and `ContactBirthdateRange_BeforeUpdate`, each with its own `Order__c`.
- **Add-ons are per context too**, such as `BeforeInsert.ParentQuery` and `BeforeUpdate.ParentQuery`.
- **`bypass().handler(…)` covers every context.** A `TriggerHandler__mdt` record switches the class off only in its context. To skip one context on a condition, use that context's Bypassable.

## Instances per Chunk {#instances-per-chunk}

The library calls the handler list method on every run: per context, per chunk and per nested run.

- **Instance fields reset** on every run when the list returns `new` handlers.
- **Static fields last the whole transaction.**
- **A static "already ran" flag skips later chunks.** Gate the predicate on a change such as `isChanged` instead, or use RecursionGuard in the update contexts.
- **Constructor arguments are allowed.** They are evaluated on every run, so keep SOQL out of them.
- **Under `runFromMetadata()`, there are no constructor arguments.** The library creates each registered class with its public no-argument constructor, on every run of the context its record names, so keep that constructor cheap.

## Before to After Handoff {#before-after-handoff}

Stamp a decision on the record in a BeforeUpdate Populator. Let an AfterUpdate Writer or Dispatcher qualify on the stamp:

::: code-group

```apex [AccountHotRatingUpdatePopulator.cls]
public with sharing class AccountHotRatingUpdatePopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Account.AnnualRevenue) && record.greaterThanOrEqualTo(Account.AnnualRevenue, 1000000);
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        record.put(Account.Rating, 'Hot');
    }
}
```

```apex [AccountHotRatingTaskWriter.cls]
public with sharing class AccountHotRatingTaskWriter implements AfterUpdate.Writer {
    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Account.Rating, 'Hot');
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        unitOfWork.toInsert(new Task(WhatId = record.getId(), Subject = 'Call the account: its rating is now Hot'));
    }
}
```

:::

- **The stamp is saved with the record**, so `isChangedTo` sees it after the save.
- **Manual edits count too.** When only the Populator's decision should count, stamp a field users cannot edit.
