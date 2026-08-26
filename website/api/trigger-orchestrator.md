# TriggerOrchestrator

**Path**: `force-app/main/default/classes/TriggerOrchestrator.cls`

The entry point every trigger calls. It resolves which handlers apply to the current context, filters the records each one receives, enriches parent relationships, and tracks the execution stack.

```apex
trigger AccountTrigger on Account(before update, after update) {
    TriggerOrchestrator.run(new AccountTriggerOrchestrator());
}
```

## run(Object orchestrator)

Runs the handlers your orchestrator declares for the current trigger context.

**Throws** `TriggerOrchestratorException` when called outside a trigger, or when a record exceeds the recursion limit.

Handler exceptions are logged and rethrown, never swallowed — a broken derivation must fail the save rather than commit half of it.

## Static methods

### getStack()

**Returns** `List<Invocation>` — the invocations currently executing, outermost first. The list is a snapshot; invocations are immutable.

### getDepth()

**Returns** `Integer` — the current nesting depth. `1` is a top-level DML statement; deeper values mean a handler's DML re-entered a trigger.

### isChainEnding()

**Returns** `Boolean` — true while the executing invocation is the final chunk of its chain — its top-level DML statement plus everything that statement caused.

True only at depth 1, and only for the current invocation — handlers registered after yours still run. For a genuine end-of-work hook use [`Logger.flush()`](#logger). See [Transaction Lifecycle](/guide/transaction-lifecycle#ischainending).

### getChainTree()

**Returns** `List<Invocation>` — the current chain's root invocations, each carrying its `getChildren()` subtree: the full map of everything the chain has run so far, not just the live path. Read it inside `Logger.flush()` to persist a complete cascade map per chain. Reruns of a chunk by additional triggers appear as siblings.

### getRequestId()

**Returns** `String` — the platform request id, constant for the whole transaction. Combine with `Invocation.getChainSequence()` to correlate log entries.

## Invocation

One entry into an after-context trigger: one operation, one object, at most 200 records. Before contexts create no invocation. See [Transaction Lifecycle](/guide/transaction-lifecycle#invocations-and-the-stack).

| Method               | Returns                   | Description                                                                 |
| -------------------- | ------------------------- | --------------------------------------------------------------------------- |
| `getOperation()`     | `System.TriggerOperation` | The trigger context this invocation is running                              |
| `getSObjectType()`   | `SObjectType`             | The object whose trigger fired                                              |
| `getRecordCount()`   | `Integer`                 | Records it received — at most 200, the platform chunk size                  |
| `getDepth()`         | `Integer`                 | Nesting depth; `1` is top-level                                             |
| `isRoot()`           | `Boolean`                 | Whether this invocation is a top-level DML statement                        |
| `getChainSequence()` | `Integer`                 | The chain this invocation belongs to; nested ones carry their root's number |
| `isChainEnding()`    | `Boolean`                 | Whether this invocation is the final chunk of its chain                     |
| `getChildren()`      | `List<Invocation>`        | Invocations this one caused — nested chunks in the order they ran           |

## Interfaces

### Context interfaces

An orchestrator implements one interface per trigger context it handles. A context with no matching interface is skipped.

| Interface                           | Method                                                       |
| ----------------------------------- | ------------------------------------------------------------ |
| `TriggerOrchestrator.BeforeInsert`  | `List<TriggerHandler.BeforeInsert> beforeInsertHandlers()`   |
| `TriggerOrchestrator.AfterInsert`   | `List<TriggerHandler.AfterInsert> afterInsertHandlers()`     |
| `TriggerOrchestrator.BeforeUpdate`  | `List<TriggerHandler.BeforeUpdate> beforeUpdateHandlers()`   |
| `TriggerOrchestrator.AfterUpdate`   | `List<TriggerHandler.AfterUpdate> afterUpdateHandlers()`     |
| `TriggerOrchestrator.BeforeDelete`  | `List<TriggerHandler.BeforeDelete> beforeDeleteHandlers()`   |
| `TriggerOrchestrator.AfterDelete`   | `List<TriggerHandler.AfterDelete> afterDeleteHandlers()`     |
| `TriggerOrchestrator.AfterUndelete` | `List<TriggerHandler.AfterUndelete> afterUndeleteHandlers()` |

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
    public List<TriggerHandler.BeforeUpdate> beforeUpdateHandlers() {
        return new List<TriggerHandler.BeforeUpdate>{ new AccountNameFormatter() };
    }

    public List<TriggerHandler.AfterUpdate> afterUpdateHandlers() {
        return new List<TriggerHandler.AfterUpdate>{ new AccountRatingSync() };
    }
}
```

::: warning
Undelete has only an after context. Salesforce does not support `before undelete` and a trigger declaring it will not compile.
:::

### RecursiveUpdateGuard

Optional. Caps how many times one record may be reprocessed in the same update context. Without it the limit is **3**.

```apex
public Integer maxRecursionDepth() {
    return 5;
}

public Boolean muteRecursionDepthExceededException() {
    return false;
}
```

The count is per record, per operation, per transaction, and is not consumed twice when an object has more than one trigger. Exceeding it throws `TriggerOrchestratorException`.

### Logger

Optional. The orchestrator discovers a concrete implementation through `ApexTypeImplementor` — you do not register it. Only one is used.

```apex
public interface Logger {
    void log(Error error);
    void flush();
}
```

`log()` is called for each exception as it passes through an invocation. `flush()` writes them out, and is called at least once per chain.

Read [Transaction Lifecycle](/guide/transaction-lifecycle#knowing-when-the-work-is-finished) before implementing it — `flush()` must be idempotent, and there are cases where it cannot fire.

A logger that throws cannot break a save: exceptions from `log()` and `flush()` are caught and written to the debug log, and never mask the original error.

### Error

Passed to `Logger.log()`.

| Method             | Returns                   | Description                                                                                        |
| ------------------ | ------------------------- | -------------------------------------------------------------------------------------------------- |
| `getException()`   | `Exception`               | The exception that was caught                                                                      |
| `getOperation()`   | `System.TriggerOperation` | Context where it surfaced                                                                          |
| `getSObjectType()` | `SObjectType`             | Object being processed                                                                             |
| `getRecordIds()`   | `Set<Id>`                 | Records in the failing invocation; null in before insert                                           |
| `getStack()`       | `List<Invocation>`        | Invocation stack snapshot taken where the exception was caught; empty for a before-context handler |

One exception is reported by every invocation it propagates through, so a deep failure produces several entries for one cause. Deduplicate in your logger if you only want the origin — see [Errors and the stack](/guide/transaction-lifecycle#errors-and-the-stack).
