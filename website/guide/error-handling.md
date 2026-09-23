---
description: What happens when a Trigger Lib handler throws - the TriggerOrchestrator.Logger and its Error payload, ContinueOnError, what is never logged, the library exceptions, failing one record instead of the whole save, the before-context DML guard and read-only rows in after contexts.
---

# Errors & Logging

What happens when a handler throws: which exceptions reach your `TriggerOrchestrator.Logger`, which ones ContinueOnError can swallow, which ones always fail the save, and how to reject one record instead of the whole DML statement.

## What Happens to an Exception {#exceptions}

An exception thrown during a handler's work follows these steps. The handler's work is its RelatedQuery method and providers, every predicate and action, a Dispatcher's dispatch, the Finalizer, and the commit of a Writer's own or private unit of work.

1. **It is logged.** The org's Logger, if there is one, receives it through `log(…)`, under the handler's name.
2. **It is rethrown, unless the handler implements ContinueOnError.** A rethrown exception leaves `TriggerOrchestrator.run()` and fails the trigger: every record in the chunk fails, and with all-or-none DML, the default for `insert` and `update`, the whole statement fails.
3. **Library exceptions are always rethrown.** `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` fail the save even with ContinueOnError. See [Library Exceptions](#library-exceptions).

Code that runs outside every handler's work is never logged: see [Never Logged](#never-logged). Salesforce also has exceptions that no code can catch, such as `System.LimitException` and the `System.FinalException` of a write to a read-only row. They fail the save whatever the handler implements, and the Logger never sees them.

## Logger {#logger}

Implement `TriggerOrchestrator.Logger` once in the org. The library finds the implementation itself, so nothing is registered:

```apex
public interface Logger {
    void log(TriggerOrchestrator.Error error);
    void finalize();
}
```

This Logger collects the errors and publishes them as a platform event of your own, `TriggerError__e`, with Publish Behavior set to Publish Immediately, so the log survives the rollback of a failed save. A subscriber, such as a platform event trigger or a Flow, then stores the rows:

```apex
public with sharing class TriggerErrorLogger implements TriggerOrchestrator.Logger {
    private List<TriggerError__e> events = new List<TriggerError__e>();

    public void log(TriggerOrchestrator.Error error) {
        this.events.add(
            new TriggerError__e(
                Handler__c = error.getHandlerName(),
                Operation__c = String.valueOf(error.getOperation()),
                Object__c = String.valueOf(error.getSObjectType()),
                RecordIds__c = String.join(new List<Id>(error.getRecordIds()), ','),
                Message__c = error.getException().getMessage(),
                StackTrace__c = error.getException().getStackTraceString()
            )
        );
    }

    public void finalize() {
        if (this.events.isEmpty()) {
            return;
        }

        EventBus.publish(this.events);
        this.events.clear();
    }
}
```

### Discovery {#discovery}

- **One class, found once per transaction.** The first time a transaction uses `TriggerOrchestrator`, one query on `ApexTypeImplementor` looks for concrete classes that implement `TriggerOrchestrator.Logger`. It runs even when there is none. The class found is created with its no-argument constructor, and that one instance serves the whole transaction.
- **None.** Errors are rethrown or swallowed as usual, and nothing else changes.
- **More than one.** The first use of `TriggerOrchestrator` in any transaction throws a `TriggerOrchestratorException`: "Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed." Every Trigger Lib trigger in the org then fails, so keep exactly one implementation.

### When It Is Called {#lifecycle}

- **`log(error)`** runs for every exception from a handler's work, before the library decides whether to rethrow or swallow it. That includes a swallowed ContinueOnError failure, the DML guard's exception and the Validator's "attached no error" exception.
- **`finalize()`** runs at the end of every outermost Trigger Lib run, in `run()`'s `finally` block, so also when the run failed. A run is one context of one chunk of up to 200 records. An insert of 201 records therefore calls it four times: before insert and after insert for the first 200, then again for the last one. A run nested inside another, fired by a commit or by direct DML in a handler, does not call it; the outer run does, once it ends.
- **Not called** when a run ends at a run-level switch (`TriggerOrchestrator.bypass()` or `TriggerObject__mdt.Bypass__c`), when the orchestrator does not implement the context, or when `run()` is called outside a trigger.
- **Clear what you flushed.** The same instance lives for the whole transaction, so a Logger that buffers must empty its buffer in `finalize()`, as above.

::: warning A Logger must not throw
An exception from `log(…)` replaces the handler's exception and fails the save, even for a handler that implements ContinueOnError. An exception from `finalize()` leaves the `finally` block, replaces any exception already on its way out, and fails the save.
:::

::: warning Rollback
A failed save rolls back everything its transaction did, including records that `finalize()` inserted. Publish a Publish Immediately platform event, as above, to keep the log. It counts toward `Limits.getPublishImmediateDML()`, not toward the DML statement limit.
:::

To test code that uses a Logger, see [Testing](/guide/testing#mock-metadata).

## Error {#error}

`log(…)` receives a `TriggerOrchestrator.Error`:

| Method | Returns |
|---|---|
| `getHandlerName()` | The handler's simple class name: the text before the first `:` of its `toString()`. An inner class `Outer.Inner` is `Inner`. Always set, because only handler failures are logged. |
| `getException()` | The exception that was thrown |
| `getOperation()` | The `System.TriggerOperation` of the run, such as `AFTER_UPDATE` |
| `getSObjectType()` | The object the trigger runs on |
| `getRecordIds()` | The Ids of every record in the chunk, qualified or not. In before insert the records have no Id yet, so it is an empty set, not null. |

## ContinueOnError {#continue-on-error}

A handler that implements its context's ContinueOnError add-on lets the save go on when it fails:

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

<!--@include: @/_parts/add-ons/continue-on-error.md#writer-->

Use it for work that is nice to have, such as a notification or a follow-up task, never for work whose failure leaves data inconsistent. Without a Logger, a swallowed failure leaves no trace.

### What Still Throws {#still-throws}

- `TriggerOrchestratorException`: the DML guard in before insert and before update, and a Validator that qualified a record but attached no error.
- `TriggerHandler.TriggerHandlerException`: `isRecordTypeEqual` on an object without record types, and `getRelated` with an unknown provider name.
- Everything in [Never Logged](#never-logged), because it runs outside the handler's work.
- Exceptions no code can catch, such as `System.LimitException`.

Each context's ContinueOnError page lists what still throws there:

<!--@include: @/_parts/generated/chips/continue-on-error/still-throws.md-->

## Never Logged {#never-logged}

<!--@include: @/_parts/notes/never-logged.md-->

Two more exceptions stop a run before any handler, and neither is logged: `run()` called outside a trigger, and a second Logger implementation in the org.

## Library Exceptions {#library-exceptions}

**`TriggerOrchestratorException`** is private to `TriggerOrchestrator`, so it cannot be caught by type. Catch `Exception` and check the message. Its messages:

- `Called outside of a trigger context, or the trigger operation is not supported.`
- `Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.`
- `<Handler> performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.`
- `<Handler> qualified a record in errorShouldBeAttachedOn<Ctx>When but attached no error in addErrorOn<Ctx>.`

**`TriggerHandler.TriggerHandlerException`** is public and can be caught by type around a direct call, for example in a unit test that calls a predicate. Its messages:

- `<Object> has no record types, so isRecordTypeEqual cannot be used on it.` (or `isRecordTypeNotEqual`)
- `No related records provider is registered under <name>. Return it from the RelatedQuery method of the context first.`

Catching by type works only around a direct call. Code that fires the trigger through DML gets a `DmlException`, or a failed `Database.SaveResult` with partial success, whose message contains the original message.

Reference: [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception) · [TriggerHandlerException](/api/record#triggerhandlerexception)

## Fail One Record, Not the Whole Save {#one-record}

An uncaught exception fails every record in the chunk, and with all-or-none DML the whole statement. To fail only the record that caused it, catch the exception in the handler and add an error to that record:

```apex
public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
    try {
        unitOfWork.toInsert(this.onboardingTaskFor(record));
    } catch (Exception e) {
        record.getNewSObject().addError('No onboarding task could be created: ' + e.getMessage());
    }
}
```

- **Which row takes the error.** Call `record.getNewSObject().addError(message)`, or `record.getOldSObject().addError(message)` in before delete and after delete. Only a Validator's error method receives a record that has `addError` itself.
- **In after contexts** the error reverts that record's save, delete or restore.
- **All-or-none DML still fails the statement,** but the error now names the record that caused it. With partial success, as with Data Loader, the Bulk API or `Database.insert(records, false)`, the other records are saved.
- **A partial save runs the handlers again.** The platform rolls back the first attempt and runs the triggers a second time for the records that remain, so every handler runs twice for them. See [Execution Order & Cost](/guide/execution-order#partial-save).

To reject a record on purpose in before insert or before update, use a Validator instead of an exception: [BeforeInsert](/before-insert/validator) · [BeforeUpdate](/before-update/validator).

## Before-Context DML Guard {#dml-guard}

<!--@include: @/_parts/roles/dml-guard.md-->

## Read-Only Rows in After Contexts {#read-only}

In after insert and after update, the record types still declare `put`, but the trigger rows are read-only there. `record.put(…)` throws `System.FinalException: Record is read-only`, which no code can catch, so neither a `try` block nor ContinueOnError stops it, and the save fails. Register an update on a new instance instead, from a Writer:

```apex
unitOfWork.toUpdate(new Account(Id = record.getId(), Rating = 'Hot'));
```

Details per context: [AfterInsert Record API](/after-insert/record-api#accessors) · [AfterUpdate Record API](/after-update/record-api#accessors)

## See Also {#see-also}

- [TriggerOrchestrator](/api/trigger-orchestrator): the `Logger` and `Error` interfaces
- [Execution Order & Cost](/guide/execution-order): where each hook runs
- [Unit of Work](/guide/unit-of-work#when-it-commits): commit failures
- [Testing](/guide/testing): a purpose-built Logger in tests
