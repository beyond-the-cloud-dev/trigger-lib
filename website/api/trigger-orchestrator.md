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

The `orchestrator` argument is typed as `Object` so a single class can implement any combination of the context interfaces below. When the orchestrator does not implement the interface for the current context, the call is a no-op and the DML proceeds. An orchestrator that returns an empty handler list behaves the same way.

**What one invocation does**

1. Throws `TriggerOrchestratorException` when there is no trigger context.
2. Reads the [bypass metadata](/guide/bypasses). When the object is bypassed, nothing runs and the DML succeeds.
3. Selects the context to run from `Trigger.operationType` and the interfaces the orchestrator implements.
4. Adapts the handler list. Before insert and before update reject an entry that implements neither or both of `Populator` and `Validator`, before any handler runs.
5. Drops bypassed handlers, then [enriches](/guide/enrichment) every parent lookup declared by the surviving handlers, once for all of them.
6. Runs the handlers in list order. Each handler takes its full turn before the next one starts: records over the recursion budget are skipped, the remaining ones are qualified, the action runs for each qualified record, then the handler's finalizer fires. A handler with no qualified records does not run at all.
7. Calls `Logger.finalize()` if this invocation is the outermost one, which is once per trigger phase per chunk of 200 records.

**Order matters**

A handler's `...When` predicate is evaluated at that handler's own turn, immediately before the handler runs, not in a single pass up front. A predicate therefore observes field writes made by handlers earlier in the list, so the order of the list is part of the behaviour, not a cosmetic choice. Parent enrichment is the exception: it happens once in step 5, so every predicate can read `getNewParent` and `getOldParent`.

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

In `BeforeInsert` and `BeforeUpdate`, `Handler` is an empty marker that `Populator` and `Validator` extend. It is the list type only. Every entry must implement exactly one of the two roles, and no class implements `Handler` directly. In the other five contexts `Handler` is the working interface, with a `qualifiesFor...When` predicate and an `on...` method. See [Context Interfaces](/api/context-interfaces).

**Example**

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterUpdate {
  public List<BeforeInsert.Handler> beforeInsertHandlers() {
    return new List<BeforeInsert.Handler>{
      new AccountDefaultsPopulator(),
      new AccountNameValidator()
    };
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new AccountOwnerChangeHandler() };
  }
}
```

## RecursionGuard

Optional. Sets the recursion depth for every handler this orchestrator returns, in both update contexts.

```apex
public interface RecursionGuard {
  Integer maxRecursionDepth();
}
```

```apex
public with sharing class OpportunityTriggerOrchestrator implements TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursionGuard {
  public Integer maxRecursionDepth() {
    return 5;
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new OpportunityRollupHandler() };
  }
}
```

The depth is resolved in three steps, each overriding the one before it: the framework default of `3`, then `TriggerOrchestrator.RecursionGuard`, then the context `RecursionGuard` on the handler itself, which always wins. A record over the budget is skipped silently for that handler. See [Recursion Control](/guide/recursion-control).

## Logger

Optional. Implement once per org to receive handler and framework errors. See [Error Handling](/guide/error-handling).

```apex
public interface Logger {
  void log(Error error);
  void finalize();
}
```

| Method     | Called                                                                                                |
| ---------- | ----------------------------------------------------------------------------------------------------- |
| `log`      | For every exception raised while a handler runs, before that exception propagates                     |
| `finalize` | Once per top-level `run`, meaning once per trigger phase per chunk. Nested invocations do not call it |

Only one concrete class in the org may implement it. A second implementation raises `TriggerOrchestratorException`.

## Error

Passed to `Logger.log`.

```apex
public interface Error {
  String getHandlerName();
  SObjectType getSObjectType();
  System.Exception getException();
  System.TriggerOperation getOperation();
  Set<Id> getRecordIds();
}
```

| Method             | Returns                                                               |
| ------------------ | --------------------------------------------------------------------- |
| `getHandlerName()` | Class name of the handler being processed, or `null`                  |
| `getSObjectType()` | SObject type of the trigger records                                   |
| `getException()`   | The exception that was thrown                                         |
| `getOperation()`   | `Trigger.operationType` of the invocation                             |
| `getRecordIds()`   | Keys of `Trigger.newMap` or `Trigger.oldMap`, `null` in before insert |

## Exceptions

`TriggerOrchestratorException` is thrown for:

- `run` called outside a trigger context,
- a before insert or before update handler that implements neither or both of `Populator` and `Validator`,
- DML or an immediate platform event published by a before insert or before update handler,
- more than one `TriggerOrchestrator.Logger` implementation in the org.

When it is raised while a handler runs, such as the DML guard, the logger receives it before it propagates. `ContinueOnError` never suppresses it, and the DML is aborted. The type is declared inside `TriggerOrchestrator` and is not public, so it cannot be caught by type from your own code.
