---
outline: deep
---

# Orchestrator

An orchestrator is a class that lists the handlers of one object, grouped by trigger context. The trigger passes it to [`TriggerOrchestrator.run`](/api/trigger-orchestrator#run).

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

| Interface                           | Method                    | List element type       |
| ----------------------------------- | ------------------------- | ----------------------- |
| `TriggerOrchestrator.BeforeInsert`  | `beforeInsertHandlers()`  | `BeforeInsert.Handler`  |
| `TriggerOrchestrator.AfterInsert`   | `afterInsertHandlers()`   | `AfterInsert.Handler`   |
| `TriggerOrchestrator.BeforeUpdate`  | `beforeUpdateHandlers()`  | `BeforeUpdate.Handler`  |
| `TriggerOrchestrator.AfterUpdate`   | `afterUpdateHandlers()`   | `AfterUpdate.Handler`   |
| `TriggerOrchestrator.BeforeDelete`  | `beforeDeleteHandlers()`  | `BeforeDelete.Handler`  |
| `TriggerOrchestrator.AfterDelete`   | `afterDeleteHandlers()`   | `AfterDelete.Handler`   |
| `TriggerOrchestrator.AfterUndelete` | `afterUndeleteHandlers()` | `AfterUndelete.Handler` |

These seven are the whole set. Salesforce has no `before undelete` event, so there is no orchestrator interface for one.

In the five after-and-delete contexts, `Handler` is the interface a handler implements directly. In before insert and before update, `BeforeInsert.Handler` and `BeforeUpdate.Handler` are empty markers that only give the list a type. The classes you put in those lists implement `Populator` or `Validator`, which extend the marker. See [Handlers](/guide/handlers).

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
  public List<BeforeInsert.Handler> beforeInsertHandlers() {
    return new List<BeforeInsert.Handler>{
      new AccountDefaultsPopulator(),
      new AccountNameFormatPopulator(),
      new AccountIndustryValidator()
    };
  }

  public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
    return new List<BeforeUpdate.Handler>{ new AccountNameFormatPopulator() };
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{
      new AccountOwnerChangeHandler(),
      new AccountContactsSyncHandler()
    };
  }
}
```

## Unimplemented Contexts

Implement only the interfaces you need. When the trigger fires for a context the orchestrator does not implement, nothing runs and the DML succeeds. There is no error and no log entry. A trigger that declares all seven events with an orchestrator that implements two is a supported, ordinary setup.

An empty list behaves the same way. `return new List<AfterInsert.Handler>();` is a valid answer and nothing runs for that context.

## Handler Order

Handlers run in the order they appear in the list. All qualified records go through the first handler, then its finalizer runs, and only then does the second handler start. This holds across roles too: in a before context a validator registered after a populator runs after it, and sees the fields the populator wrote.

Order is not cosmetic. A handler's qualification predicate is evaluated at that handler's own turn, so moving a handler up or down the list changes what later handlers observe. See [Record Qualification](/guide/qualification#evaluation-order).

A handler class can appear in more than one list. The same `AccountNameFormatPopulator` above implements both `BeforeInsert.Populator` and `BeforeUpdate.Populator`, and each context calls its own pair of methods.

## Recursion Depth

The orchestrator can set the default recursion depth for all of its handlers by implementing `TriggerOrchestrator.RecursionGuard`.

```apex
public interface RecursionGuard {
  Integer maxRecursionDepth();
}
```

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursionGuard {
  public Integer maxRecursionDepth() {
    return 5;
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new AccountOwnerChangeHandler() };
  }
}
```

The depth used for a handler is resolved in three steps, each overriding the one before it:

1. The framework default of three passes per record.
2. `TriggerOrchestrator.RecursionGuard` on the orchestrator, when it implements it.
3. The context `RecursionGuard` on the handler itself, which always wins.

So an orchestrator returning five and one handler returning two means that handler stops after two passes per record and every other handler of the orchestrator stops after five.

Passes are counted in before update and after update, the contexts where a handler can re-enter through its own DML. [Recursion Control](/guide/recursion-control) covers the counting rules.

## Execution Pipeline

For every trigger invocation `TriggerOrchestrator.run` performs these steps in order:

1. **Guard** - throws a `TriggerOrchestratorException` when there is no trigger context.
2. **Object bypass** - returns immediately when `TriggerObject__mdt` bypasses the object. No handler runs, the DML succeeds.
3. **Select context** - picks the orchestrator method for the current `Trigger.operationType`, and returns without doing anything when the orchestrator does not implement that context.
4. **Collect handlers** - calls the orchestrator method. In before insert and before update this is where the one-role-per-context rule is enforced, and a class implementing both roles or neither is rejected here with a `TriggerOrchestratorException`.
5. **Bypass** - drops handlers bypassed by [metadata or by `Bypassable`](/guide/bypasses). Dropped handlers take no further part, so their enrichment is not queried either.
6. **Enrich** - queries the [parent records](/guide/enrichment) declared by the surviving handlers. One query per declared parent field, once for the whole invocation.
7. **Run handlers, in list order** - for each handler: skip records over the [recursion depth](/guide/recursion-control), evaluate the qualification predicate on the rest, and when at least one record qualified run the action once per qualified record followed by the [finalizer](/guide/finalizers). A handler with no qualified records is skipped and its finalizer does not fire.
8. **Report** - exceptions go to the [logger](/guide/error-handling) and are rethrown, unless the handler implements `ContinueOnError` and the exception is the handler's own.

Enrichment is the only step that happens once, up front, for every handler. Qualification is not: each handler's predicate runs at that handler's turn, after the handlers before it have already finished.

## Outside a Trigger

`TriggerOrchestrator.run` is only valid inside a trigger. Called from anonymous Apex, a service class or a test method with no DML behind it, it throws:

```
TriggerOrchestratorException: Called outside of trigger context, or not supported operation type
```

To exercise handlers in a test, perform the DML and let the trigger call `run` for you.

## Nested Triggers

DML in an after handler can fire another trigger that also uses `TriggerOrchestrator.run`. The framework keeps an invocation stack, so nested runs are isolated and the logger is finalized once, when the outermost invocation ends. A nested invocation never calls `finalize`.
