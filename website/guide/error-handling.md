---
outline: deep
---

# Error Handling

By default an exception thrown by a handler stops the trigger and rolls back the DML, which is what Salesforce does with any unhandled exception. Trigger Lib adds two things on top: every error is reported to a logger before it propagates, and a handler can opt in to continue on error.

## Logger

Implement `TriggerOrchestrator.Logger` once in your org. The framework discovers the implementation at runtime through `ApexTypeImplementor`, so no registration is needed.

```apex
public with sharing class TriggerLogger implements TriggerOrchestrator.Logger {
  private List<Log__c> logs = new List<Log__c>();

  public void log(TriggerOrchestrator.Error error) {
    logs.add(
      new Log__c(
        Handler__c = error.getHandlerName(),
        Operation__c = String.valueOf(error.getOperation()),
        SObject__c = String.valueOf(error.getSObjectType()),
        Record_Ids__c = String.join(
          new List<Id>(error.getRecordIds() ?? new Set<Id>()),
          ','
        ),
        Message__c = error.getException().getMessage(),
        Stack_Trace__c = error.getException().getStackTraceString()
      )
    );
  }

  public void finalize() {
    // persist the logs, for example by publishing a platform event
  }
}
```

### Lifecycle

- `log(Error)` is called for every exception the framework sees: an exception thrown from a handler, and an exception from the orchestrator itself.
- `finalize()` is called once, when the outermost `TriggerOrchestrator.run` in the transaction finishes, whether it succeeded or failed. Nested trigger invocations do not finalize the logger.

::: warning Rollback
When an exception propagates out of the trigger, the whole transaction is rolled back, including any DML done in `finalize()`. Persist logs through a platform event with `PublishImmediately` behavior or another mechanism that survives a rollback.
:::

### Rules

- Exactly one concrete class may implement `TriggerOrchestrator.Logger`. Two implementations throw `TriggerOrchestratorException`.
- No implementation means errors are simply rethrown.
- The implementor is resolved once per transaction and cached.

## Error

`TriggerOrchestrator.Error` describes a failure:

| Method             | Returns                                                                 |
| ------------------ | ----------------------------------------------------------------------- |
| `getException()`   | The thrown exception                                                    |
| `getHandlerName()` | Class name of the handler being processed, `null` when none was running |
| `getOperation()`   | `System.TriggerOperation` of the invocation                             |
| `getSObjectType()` | The triggering object                                                   |
| `getRecordIds()`   | Ids of all records in the trigger batch                                 |

## Continue On Error

A handler that implements `ContinueOnError` does not stop the trigger. Its exception is passed to the logger and the orchestrator moves on to the next handler.

```apex
public with sharing class AccountEnrichmentCalloutHandler implements AfterInsert.Handler, AfterInsert.Finalizer, AfterInsert.ContinueOnError {
  // a failure here should not block the insert
}
```

Use it for side effects that are nice to have: notifications, analytics, non-critical integrations. Do not use it for handlers whose failure leaves data in an inconsistent state.

::: tip
`ContinueOnError` does not swallow `TriggerOrchestratorException`. Framework errors such as DML in a before context always propagate.
:::

## Before Context DML Guard

Before insert and before update handlers that perform DML throw:

```
ContactDefaultsHandler performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.
```

See [Handlers](/guide/handlers#before-context-dml) for the `AllowDmls` opt-out.

## Outside a Trigger

Calling `TriggerOrchestrator.run` outside a trigger throws:

```
Called outside of trigger context, or not supported operation type
```
