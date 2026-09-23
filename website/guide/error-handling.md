---
description: What happens when a Trigger Lib handler throws - the TriggerOrchestrator.Logger, ContinueOnError, what is never logged, the library exceptions, and failing one record instead of the whole save.
---

# Errors & Logging

An exception in a handler is logged, then rethrown, and the save fails. With ContinueOnError it is logged and swallowed instead.

## What Happens to an Exception {#exceptions}

A handler's work is its providers, predicates, actions, dispatch, Finalizer and own-unit commit. An exception there:

1. **Is logged.** The org's Logger gets it under the handler's name.
2. **Is rethrown,** unless the handler implements ContinueOnError. Every record in the chunk fails. With all-or-none DML, the whole statement fails.
3. **Is always rethrown** when it is a [library exception](#library-exceptions).

Platform exceptions such as `System.LimitException` cannot be caught. They fail the save, and the Logger never sees them.

## Logger {#logger}

Implement `TriggerOrchestrator.Logger` in one class. The library finds it; nothing is registered:

```apex
public interface Logger {
    void log(TriggerOrchestrator.Error error);
    void finalize();
}
```

This Logger publishes a Publish Immediately platform event of your own, so the log survives a failed save:

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

- **`log(error)`** runs for every exception from a handler's work, swallowed ones included.
- **`finalize()`** runs when the outermost run ends, also when it failed.
- **One instance per transaction.** Clear your buffer in `finalize()`.
- **Exactly one class.** With two implementations, every Trigger Lib trigger in the org throws.
- **Never throw from a Logger.** Its exception replaces the handler's and fails the save.

`log(…)` receives a `TriggerOrchestrator.Error`:

| Method | Returns |
|---|---|
| `getHandlerName()` | the simple class name: `Inner` for `Outer.Inner` |
| `getException()` | the exception |
| `getOperation()` | the `System.TriggerOperation`, such as `AFTER_UPDATE` |
| `getSObjectType()` | the trigger object |
| `getRecordIds()` | every Id in the chunk; empty in before insert |

## ContinueOnError {#continue-on-error}

Implement the context's ContinueOnError to let the save go on when the handler fails.

- **The failed handler stops.** Its remaining records and its Finalizer are skipped. Later handlers still run.
- **A failed Writer saves nothing.** Its registrations go to a separate unit of work, which does not commit after a failure.
- **Some exceptions still throw:** library exceptions, platform exceptions and anything [never logged](#never-logged).
- **Use it for nice-to-have work,** such as a notification. Without a Logger, a swallowed failure leaves no trace.

## Never Logged {#never-logged}

This code runs outside every handler. An exception there is not logged, ContinueOnError does not apply, and the save fails:

- `<ctx>Handlers()`;
- `bypassOn<Ctx>When()`, `ownUnitOfWorkOn<Ctx>()` and `maxRecursionDepthOn<Ctx>()`;
- the ParentQuery and PriorParentQuery methods and their parent queries;
- the shared unit of work's commit.

## Library Exceptions {#library-exceptions}

| Message | Cause |
|---|---|
| `Called outside of a trigger context…` | `run()` outside a trigger |
| `Multiple implementations of TriggerOrchestrator.Logger found…` | two Logger classes |
| `<Handler> performed DML in a before context…` | DML or an event publish in before insert or before update |
| `<Handler> qualified a record … but attached no error…` | a Validator attached no error |
| `<Object> has no record types…` | `isRecordTypeEqual` on an object without record types |
| `No related records provider is registered under <name>…` | `getRelated` with an unknown name |

The first four are a `TriggerOrchestratorException`. It is private, so catch `Exception` and check the message. The last two are a public `TriggerHandler.TriggerHandlerException`.

The before-context DML check also counts `Database.setSavepoint()`, but not `System.enqueueJob` or `Messaging.sendEmail`. ContinueOnError cannot suppress it.

## Fail One Record, Not the Whole Save {#one-record}

Catch the exception and add an error to the record that caused it:

```apex
public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
    try {
        unitOfWork.toInsert(this.onboardingTaskFor(record));
    } catch (Exception e) {
        record.getNewSObject().addError('No onboarding task could be created: ' + e.getMessage());
    }
}
```

- **Delete contexts** use `record.getOldSObject().addError(…)`.
- **All-or-none DML still fails,** but the error names the record. With partial success, the other records save.
- **To reject a record on purpose,** use a [Validator](/before-insert/validator).

## Read-Only Rows {#read-only}

In after insert and after update, `record.put(…)` throws `System.FinalException`, which no code can catch. Register an update on a new instance instead:

```apex
unitOfWork.toUpdate(new Account(Id = record.getId(), Rating = 'Hot'));
```
