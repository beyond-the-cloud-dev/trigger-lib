---
outline: deep
---

# TriggerOrchestrator

Entry point of the framework. A trigger calls `TriggerOrchestrator.run` with an orchestrator instance, and the class runs the handlers for the current trigger context.

## Methods

### run

Executes the handlers for `Trigger.operationType`.

**Signature**

```apex
public static void run(Object orchestrator)
```

**Example**

```apex
trigger AccountTrigger on Account(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  TriggerOrchestrator.run(new AccountTriggerOrchestrator());
}
```

The `orchestrator` argument is typed as `Object` so a single class can implement any combination of the context interfaces below. When the orchestrator does not implement the interface for the current context, the call is a no-op.

Throws `TriggerOrchestratorException` when called outside a trigger.

## Orchestrator Interfaces

Each interface returns the ordered handler list of one context.

```apex
public interface BeforeInsert {
    List<BeforeInsert.Handler> beforeInsertHandlers();
}

public interface AfterInsert {
    List<AfterInsert.Handler> afterInsertHandlers();
}

public interface BeforeUpdate {
    List<BeforeUpdate.Handler> beforeUpdateHandlers();
}

public interface AfterUpdate {
    List<AfterUpdate.Handler> afterUpdateHandlers();
}

public interface BeforeDelete {
    List<BeforeDelete.Handler> beforeDeleteHandlers();
}

public interface AfterDelete {
    List<AfterDelete.Handler> afterDeleteHandlers();
}

public interface AfterUndelete {
    List<AfterUndelete.Handler> afterUndeleteHandlers();
}
```

**Example**

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterUpdate {
  public List<BeforeInsert.Handler> beforeInsertHandlers() {
    return new List<BeforeInsert.Handler>{ new AccountDefaultsHandler() };
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new AccountOwnerChangeHandler() };
  }
}
```

## Logger

Optional. Implement once per org to receive handler and framework errors. See [Error Handling](/guide/error-handling).

```apex
public interface Logger {
  void log(Error error);
  void finalize();
}
```

| Method     | Called                                                 |
| ---------- | ------------------------------------------------------ |
| `log`      | For every exception raised during `run`                |
| `finalize` | Once, when the outermost `run` of the transaction ends |

## Error

Passed to `Logger.log`.

```apex
public interface Error {
  Exception getException();
  String getHandlerName();
  System.TriggerOperation getOperation();
  SObjectType getSObjectType();
  Set<Id> getRecordIds();
}
```

| Method             | Returns                                              |
| ------------------ | ---------------------------------------------------- |
| `getException()`   | The exception that was thrown                        |
| `getHandlerName()` | Class name of the handler being processed, or `null` |
| `getOperation()`   | `Trigger.operationType` of the invocation            |
| `getSObjectType()` | SObject type of the trigger records                  |
| `getRecordIds()`   | Keys of `Trigger.newMap` or `Trigger.oldMap`         |

## Exceptions

`TriggerOrchestratorException` is thrown for:

- `run` called outside a trigger context,
- more than one `TriggerOrchestrator.Logger` implementation in the org,
- DML performed by a before insert or before update handler that does not implement `AllowDmls`.

It is never swallowed by `ContinueOnError`.
