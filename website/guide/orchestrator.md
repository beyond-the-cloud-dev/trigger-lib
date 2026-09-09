---
outline: deep
---

# Orchestrator

An orchestrator is a class that lists the handlers of one object, grouped by trigger context. The trigger passes it to `TriggerOrchestrator.run`.

## Trigger

Keep the trigger to a single line. Declare all contexts you need now or later, the orchestrator decides which ones do work.

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

## Context Interfaces

The orchestrator implements one `TriggerOrchestrator` interface per context it handles. Each interface has a single method returning the ordered list of handlers.

| Interface                           | Method                    | Handler type            |
| ----------------------------------- | ------------------------- | ----------------------- |
| `TriggerOrchestrator.BeforeInsert`  | `beforeInsertHandlers()`  | `BeforeInsert.Handler`  |
| `TriggerOrchestrator.AfterInsert`   | `afterInsertHandlers()`   | `AfterInsert.Handler`   |
| `TriggerOrchestrator.BeforeUpdate`  | `beforeUpdateHandlers()`  | `BeforeUpdate.Handler`  |
| `TriggerOrchestrator.AfterUpdate`   | `afterUpdateHandlers()`   | `AfterUpdate.Handler`   |
| `TriggerOrchestrator.BeforeDelete`  | `beforeDeleteHandlers()`  | `BeforeDelete.Handler`  |
| `TriggerOrchestrator.AfterDelete`   | `afterDeleteHandlers()`   | `AfterDelete.Handler`   |
| `TriggerOrchestrator.AfterUndelete` | `afterUndeleteHandlers()` | `AfterUndelete.Handler` |

Implement only the interfaces you need. When the trigger fires for a context the orchestrator does not implement, nothing runs.

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
  public List<BeforeInsert.Handler> beforeInsertHandlers() {
    return new List<BeforeInsert.Handler>{
      new AccountDefaultsHandler(),
      new AccountNameFormatHandler()
    };
  }

  public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
    return new List<BeforeUpdate.Handler>{ new AccountNameFormatHandler() };
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{
      new AccountOwnerChangeHandler(),
      new AccountContactsSyncHandler()
    };
  }
}
```

## Handler Order

Handlers run in the order they appear in the list. All qualified records go through the first handler, then its finalizer runs, and only then the second handler starts.

A handler class can implement more than one context. The same `AccountNameFormatHandler` above implements both `BeforeInsert.Handler` and `BeforeUpdate.Handler`.

## Execution Pipeline

For every trigger invocation `TriggerOrchestrator.run` performs these steps in order:

1. **Guard** - throws `TriggerOrchestratorException` when called outside a trigger.
2. **Collect handlers** - calls the orchestrator method for the current `Trigger.operationType`.
3. **Bypass** - drops handlers whose [bypass](/guide/bypasses) method returns `true`.
4. **Enrich** - queries [parent records](/guide/enrichment) declared by the remaining handlers.
5. **Qualify** - for each handler, skips records over the [recursion depth](/guide/recursion-control), then keeps the ones passing `qualifiesFor...When`.
6. **Execute** - runs `on...` per qualified record and then the [finalizer](/guide/finalizers). Handlers with no qualified records are skipped.
7. **Report** - exceptions are passed to the [logger](/guide/error-handling) and rethrown.

## Nested Triggers

DML in an after handler can fire another trigger that also uses `TriggerOrchestrator.run`. The framework keeps an invocation stack, so nested runs are isolated and the logger is finalized once, when the outermost invocation ends.
