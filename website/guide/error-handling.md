---
description: What happens when a Trigger Lib handler throws - the TriggerOrchestrator.Logger, ContinueOnError, what is never logged, the library exceptions, and failing one record instead of the whole save.
---

# Errors & Logging

An exception in a handler is logged, then rethrown, and the save fails. With ContinueOnError it is logged and swallowed instead.

## What Happens to an Exception {#exceptions}

A handler's work is its providers, predicates, actions, dispatch, Finalizer and its own unit of work's commit. An exception there:

1. **Is logged.** The org's Logger gets it under the handler's name.
2. **Is rethrown,** unless the handler implements ContinueOnError. Every record in the chunk fails. With all-or-none DML, the whole statement fails.
3. **Is always rethrown** when it is the library's own [`TriggerTypes.TriggerLibException`](/api/trigger-orchestrator#triggerlibexception), such as DML in a before insert handler, or an `EventBus.RetryableException`.

Platform exceptions such as `System.LimitException` cannot be caught. They end the transaction at once: the save fails, and neither `log()` nor `flush()` runs.

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

    public void flush() {
        if (this.events.isEmpty()) {
            return;
        }

        EventBus.publish(this.events);
        this.events.clear();
    }
}
```

- **One instance per transaction.** `flush()` runs at the end of each outermost run, also when the run fails, except after a [`maximum trigger depth exceeded`](#recursion) failure. Clear your buffer there.
- **Only buffer in `log()`.** A recursion error is logged inside the record loop, where SOQL or DML trips the library's guards. Write in `flush()`.
- **Exactly one class.** With two implementations, every Trigger Lib trigger in the org throws.
- **Never throw from a Logger.** Its exception replaces the handler's and fails the save.

## ContinueOnError {#continue-on-error}

Implement the context's ContinueOnError to let the save go on when the handler fails.

- **The failed handler stops.** Its remaining records and its Finalizer are skipped. Later handlers still run.
- **A Writer that throws before its commit saves nothing.** Its registrations go to its own unit of work, not the shared one, and that commit is skipped after a failure. If the commit itself fails, statements that already ran stay: there is no savepoint.
- **Use it for nice-to-have work,** such as a notification. Without a Logger, a swallowed failure leaves no trace.

## Recursion {#recursion}

In the update contexts, when a record comes back to a Populator, Writer or Dispatcher that already acted on it 3 times in the transaction, the library logs one `TriggerTypes.TriggerLibException` for that record, throws nothing, and the handler keeps running. Without a Logger, the error leaves no trace.

- **Fix the cause.** Gate the predicate on a change, such as `isChanged`, so a nested update does not qualify the record again.
- **Or cap it.** A [RecursionGuard](/after-update/add-ons/recursion-guard) sets the depth and skips the record there. The error is logged too.
- **An endless loop fails the save** with `maximum trigger depth exceeded` at the platform's limit of 16 nested triggers. `flush()` does not run for that save or for any later one in the transaction, so a Logger that writes only in `flush()` loses these errors.

## Never Logged {#never-logged}

This code runs outside every handler. An exception there is not logged, ContinueOnError does not apply, and the save fails:

- `<ctx>Handlers()`, and under `runFromMetadata()`, creating the registered classes;
- `bypassOn<Ctx>When()`, `ownUnitOfWorkOn<Ctx>()` and `maxRunsPerRecordOn<Ctx>()`;
- the ParentQuery and PriorParentQuery methods, and the parent query after a Populator changes a lookup;
- the shared unit of work's commit.

## Fail One Record, Not the Whole Save {#one-record}

Catch the exception and add an error to the record that caused it:

```apex
public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
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
