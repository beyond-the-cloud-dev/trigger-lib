---
outline: deep
---

# Error Handling

By default an exception thrown by a handler stops the trigger and rolls back the DML, which is what Salesforce does with any unhandled exception. Trigger Lib adds two things on top: every error raised while a handler runs is reported to a logger before it propagates, and a handler can opt in to continue on error.

Rejecting a record is not an error. To block a record with a message, register a `Validator` in a before context instead of throwing. See [Handlers](/guide/handlers).

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

`log(Error)` is called for every exception raised while a handler runs, before that exception propagates. That covers:

- an exception thrown by the handler's own code, including its `...When` predicate, its action method and its finalizer,
- a `TriggerOrchestratorException` the framework raises against that handler, such as the [before context DML guard](#before-context-dml-guard),
- a `TriggerHandler.TriggerHandlerException` from the [record API](#record-api-exceptions).

Errors raised before handler execution begins are not attributed to a handler: `run` called outside a trigger, a role violation in a handler list, and the multiple-logger error all abort the invocation on their own.

`finalize()` runs once per top-level invocation of `TriggerOrchestrator.run`, which means **once per trigger phase, per chunk of 200 records** — not once per transaction:

- an insert of 201 records calls `finalize` twice for `before insert` and twice for `after insert`,
- a handler whose DML fires another trigger through the orchestrator produces a nested invocation, and a nested invocation does not call `finalize`. Only the outermost one does,
- it runs whether the invocation succeeded or failed.

A logger that buffers records, like the sample above, must therefore flush and clear its buffer on every `finalize` call, not only on the last one.

::: warning Rollback
When an exception propagates out of the trigger, the whole transaction is rolled back, including any DML done in `finalize()`. Persist logs through a platform event with `PublishImmediately` behavior or another mechanism that survives a rollback.
:::

### Rules

- Exactly one concrete class may implement `TriggerOrchestrator.Logger`. Two implementations raise `TriggerOrchestratorException` stating that only one implementation is allowed.
- No implementation means errors are simply rethrown, and nothing else changes.
- The implementor is resolved through a single `ApexTypeImplementor` query, once per transaction, and cached for the rest of it.

## Error

`TriggerOrchestrator.Error` describes a failure:

| Method             | Returns                                                                                                                            |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `getException()`   | The thrown exception                                                                                                               |
| `getHandlerName()` | Class name of the handler being processed, `null` when none was running                                                            |
| `getOperation()`   | `System.TriggerOperation` of the invocation                                                                                        |
| `getSObjectType()` | The triggering object                                                                                                              |
| `getRecordIds()`   | Ids of all records in the trigger chunk, not only the qualified ones, and `null` in before insert where the records have no Id yet |

## Continue On Error

Without `ContinueOnError`, the first exception a handler raises ends the invocation: it reaches the logger, then propagates, no later handler in the list runs, and the DML is rolled back.

A handler that implements the `ContinueOnError` marker of its context does not stop the trigger. Its exception is passed to the logger, the orchestrator moves on to the next handler in the list, and the DML succeeds.

```apex
public with sharing class AccountWelcomeTaskWriter implements AfterInsert.Writer, AfterInsert.ContinueOnError {
  public Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
    return record.isNotBlank(Account.Website);
  }

  public void writeOnAfterInsert(
    TriggerHandler.InsertRecord record,
    TriggerHandler.UnitOfWork unitOfWork
  ) {
    unitOfWork.toInsert(
      new Task(WhatId = record.getId(), Subject = 'Send the welcome pack')
    );
  }
}
```

Use it for side effects that are nice to have: notifications, analytics, non-critical integrations. Do not use it for handlers whose failure leaves data in an inconsistent state.

### Writers Get Their Own Unit Of Work

A writer normally registers its records in the unit of work shared by every writer of the invocation. That unit commits once, after the last handler, and a failure there fails the whole save. It cannot be skipped for one writer.

A writer that implements `ContinueOnError` therefore gets a unit of work of its own, automatically. The framework commits it right after the writer's finalizer, inside the writer's error handling:

- a failed commit is logged with the writer's name and swallowed, and the save goes on,
- the shared writes of the other writers are not affected,
- when the writer throws before its commit, nothing it registered is written.

The unit is configured like the shared one: system mode, without sharing, and duplicate updates of one record combined. A writer that also implements `OwnUnitOfWork` keeps the unit it returns, and `ContinueOnError` only decides what happens when it fails.

What changes compared to the shared unit:

- The writes happen at the writer's position in the handler list, not after the last handler.
- They are not pooled with the other writers, so the writer spends its own DML statements.
- The commit is not atomic. When an insert succeeds and a later update in the same unit fails, the insert stays.

::: danger ContinueOnError covers the handler's own exceptions only
It never suppresses a framework contract violation. A `TriggerOrchestratorException` and a `TriggerHandler.TriggerHandlerException` are logged and then rethrown even for a handler that implements `ContinueOnError`, and the DML is aborted.
:::

## Framework Exceptions

Every contract violation the framework itself detects is raised as `TriggerOrchestratorException`, never as a bare platform exception. It is raised for:

- `TriggerOrchestrator.run` called outside a trigger context,
- a handler list entry that implements neither or both of the main interfaces of a context with roles, `Populator` and `Validator`,
- DML, or an immediate platform event published, by a before insert or before update handler,
- more than one `TriggerOrchestrator.Logger` implementation in the org.

The exception type is declared inside `TriggerOrchestrator` and is not public, so your own code cannot catch it by type. The message identifies the violation and, where a handler is at fault, names the class.

### Before Context DML Guard

Before insert and before update handlers must not perform DML. The framework measures DML statements and immediate platform event publishes across the handler's execution, from its first qualified record through its finalizer, and raises:

```
ContactDefaultsHandler performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.
```

The sharp edges:

- The guard counts DML performed anywhere below the handler, including inside a service class it calls.
- Publishing a platform event configured to publish immediately counts as DML and is rejected the same way.
- The guard covers the handler's finalizer too, because the finalizer runs inside the same measured span.
- It applies to a `Populator` and a `Validator` alike.
- **Throwing is not a way past it.** The check runs in a `finally`, so a handler that performs DML and then throws still trips the guard. The guard's exception replaces the handler's own, so the guard error is what reaches the logger and what propagates.
- `ContinueOnError` does not suppress it. The DML is aborted and nothing is committed.
- A handler that throws without having done DML is unaffected: the guard stays silent, and with `ContinueOnError` the error is swallowed and the DML succeeds.

There is no opt-out. Populate the trigger record with `put` instead, or move the work to an after context, where DML on other records is allowed.

### One Main Interface Per Context

Before insert and before update have two roles. A class in `beforeInsertHandlers()` or `beforeUpdateHandlers()` must implement exactly one of them. Implementing both, or neither, aborts the invocation before any handler runs, with a message naming the class and both interfaces:

```
ContactDefaultsHandler implements both BeforeInsert.Populator and BeforeInsert.Validator. A class can implement only one main interface per context.
```

```
ContactDefaultsHandler implements neither BeforeInsert.Populator nor BeforeInsert.Validator. A class must implement one main interface per context.
```

A class may still hold a different role in a different context, for example `BeforeInsert.Populator` and `BeforeUpdate.Validator`.

### Outside a Trigger

Calling `TriggerOrchestrator.run` from anonymous Apex or a service class throws:

```
Called outside of trigger context, or not supported operation type
```

## Record API Exceptions

`isRecordTypeEqual` and `isRecordTypeNotEqual` throw `TriggerHandler.TriggerHandlerException` when the SObject has no record types beyond Master:

```
Invoice__c has no record types, so isRecordTypeEqual cannot be used on it.
```

This replaces the raw `SObjectException: Invalid field RecordTypeId` the platform would otherwise produce, so the message names the object and the helper. Like a framework exception, it is logged and rethrown even under `ContinueOnError`.

## Platform Exceptions

A platform error a handler causes — an invalid field, a bad cast, a failed DML in an after context — propagates unchanged. The framework never wraps or translates it, so the original Salesforce type and message reach the caller. The logger sees it first if one is implemented, and `ContinueOnError` applies to it like any other exception the handler raises.

### Read-only Records In After Contexts

`TriggerHandler.InsertRecord` and `TriggerHandler.UpdateRecord` serve both the before and the after phase of their operation, so nothing in the type system stops an after insert or after update handler from calling `put`. At run time the platform raises:

```
System.FinalException: Record is read-only
```

That exception is uncatchable. The handler's own `try` and `catch` cannot stop it, `ContinueOnError` cannot stop it, and the whole transaction is lost. In an after context, build your own SObject instance and DML that instead of writing to the trigger record.
