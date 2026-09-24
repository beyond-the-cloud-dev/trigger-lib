---
description: What happens when a Trigger Lib handler throws - the TriggerOrchestrator.Logger, ContinueOnError, what is never logged, the library exceptions, and failing one record instead of the whole save.
---

# Errors & Logging

An exception in a handler is logged, then rethrown, and the save fails. With ContinueOnError it is logged and swallowed instead.

## What Happens to an Exception {#exceptions}

A handler's work is its providers, predicates, actions, dispatch, Finalizer and its own unit of work's commit. An exception there:

1. **Is logged.** The org's Logger gets it under the handler's name.
2. **Is rethrown,** unless the handler implements ContinueOnError. Every record in the chunk fails. With all-or-none DML, the whole statement fails.
3. **Is always rethrown** when it is a library exception: a [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception), such as DML in a before context, or a [TriggerHandlerException](/api/record#triggerhandlerexception).

Platform exceptions such as `System.LimitException` cannot be caught. They fail the save, and the Logger never sees them.

## Logger {#logger}

Implement [`TriggerOrchestrator.Logger`](/api/trigger-orchestrator#logger). The library finds it; nothing is registered. This Logger publishes a Publish Immediately platform event of your own, so the log survives a failed save:

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

- **One instance per transaction.** Clear your buffer in `finalize()`.
- **Exactly one class.** With two implementations, every Trigger Lib trigger in the org throws.
- **Never throw from a Logger.** Its exception replaces the handler's and fails the save.

## ContinueOnError {#continue-on-error}

Implement the context's ContinueOnError to let the save go on when the handler fails.

- **The failed handler stops.** Its remaining records and its Finalizer are skipped. Later handlers still run.
- **A Writer that throws before its commit saves nothing.** Its registrations go to a separate unit of work, which is skipped after a failure. If the commit itself fails, statements that already ran stay: there is no savepoint.
- **Use it for nice-to-have work,** such as a notification. Without a Logger, a swallowed failure leaves no trace.

## Never Logged {#never-logged}

This code runs outside every handler. An exception there is not logged, ContinueOnError does not apply, and the save fails:

- `<ctx>Handlers()`;
- `bypassOn<Ctx>When()`, `ownUnitOfWorkOn<Ctx>()` and `maxRecursionDepthOn<Ctx>()`;
- the ParentQuery and PriorParentQuery methods and their parent queries;
- the default unit of work's commit.

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
