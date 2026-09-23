---
description: 'TriggerOrchestrator reference: run() from the trigger, the seven registration interfaces, the bypass() builder that switches off objects, orchestrators and handlers from Apex, the Logger and Error interfaces, and TriggerOrchestratorException.'
---

# TriggerOrchestrator

The class your trigger calls. `TriggerOrchestrator.run(…)` runs the handlers of the current trigger context, your orchestrator implements one registration interface per context, `TriggerOrchestrator.bypass()` switches off (skips, disables) objects, orchestrators and handlers from Apex, and the `Logger` and `Error` interfaces receive the errors of handlers.

## run {#run}

```apex
public static void run(Object orchestrator)
```

The trigger body is one line. List every event the object needs; the library runs only the contexts your orchestrator registers.

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

One call does this, in order:

1. Throws `TriggerOrchestratorException` when no trigger is running, for example from anonymous Apex.
2. Returns at once when `TriggerOrchestrator.bypass()` has switched off everything, this object or this orchestrator.
3. Returns at once when a `TriggerObject__mdt` record switches off this object.
4. Returns at once when the orchestrator does not implement the registration interface for `Trigger.operationType`. Nothing is reported.
5. Calls the orchestrator's handler method, such as `beforeInsertHandlers()`, and drops the handlers that are switched off: by `TriggerOrchestrator.bypass().handler(…)`, by a `TriggerHandler__mdt` record, or by their own Bypassable add-on.
6. Loads the parent records that the remaining handlers declare, with one set of queries for all of them. Before insert and before update load them again for records whose lookup a Populator changed.
7. Runs each handler in list order, one handler at a time over every record of the chunk.
8. In an after context, commits the shared unit of work.
9. When this is the outermost run, calls `Logger.finalize()`, also when the run failed.

- **`Object`, not an interface.** One orchestrator class implements any combination of the registration interfaces below, so `run` takes it as `Object`.
- **One run per trigger invocation.** Every context and every 200-record chunk is a separate run that calls the handler method again. See [Instances per Chunk](/guide/orchestrator#instances-per-chunk).
- **An empty list runs nothing.** Return an empty list, never `null`: iterating a null list throws a `NullPointerException` before any handler starts, and the save fails.
- **Nested runs.** DML inside a handler that fires another trigger starts a nested run. It finishes before the outer handler continues.

Each phase step by step, and what each step costs in SOQL: [Execution Order & Cost](/guide/execution-order).

## Registration Interfaces {#registration}

Your orchestrator implements one interface per context it handles. Each returns the handlers of that context in run order.

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

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

- **One role per entry.** The list type is the context's `Handler` interface. Each entry implements one role of that context: Populator or Validator in before insert and before update, Writer or Dispatcher in the after contexts, and `BeforeDelete.Handler` in before delete.
- **Two roles in one class.** Only the first runs: Populator over Validator, Writer over Dispatcher. Nothing throws.
- **Only the marker.** Outside before delete, `Handler` is an empty marker. A class that implements only the marker compiles, fits in the list and never runs.
- **No BeforeUndelete.** Salesforce has no `before undelete` trigger event. See [There Is No BeforeUndelete](/after-undelete/#no-before-undelete).

Every context's roles and method names: [Contexts at a Glance](/contexts#method-names).

## bypass {#bypass}

```apex
public static TriggerOrchestrator.Bypassable bypass()

public interface Bypassable {
    Bypassable sObject(SObjectType sObjectType);
    Bypassable orchestrator(System.Type orchestrator);
    Bypassable handler(System.Type handler);
    void all();
    void clear();
}
```

`TriggerOrchestrator.bypass()` returns the transaction's one switch board. It is a builder, not the handler add-on of the same name.

| Method | Switches off |
|---|---|
| `sObject(Account.SObjectType)` | every run on that object |
| `orchestrator(X.class)` | every run of that orchestrator class; top-level classes only |
| `handler(X.class)` | that handler class in every context; top-level classes only |
| `all()` | every run |
| `clear()` | removes every switch, `all()` included |

```apex
TriggerOrchestrator.bypass().sObject(Account.SObjectType).handler(ContactFollowUpTaskWriter.class);
try {
    insert contacts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- **Chaining.** `sObject`, `orchestrator` and `handler` return the builder. `all()` and `clear()` return nothing.
- **Lasts for the transaction.** A switch stays on until `clear()` or the end of the transaction, nested saves included. There is no method that removes a single switch, so call `clear()` in a `finally` block.
- **When it is checked.** `all()`, `sObject(…)` and `orchestrator(…)` are checked at the start of every run, before the `TriggerObject__mdt` record. `handler(…)` is checked for each handler before its `TriggerHandler__mdt` record and its Bypassable method.
- **By class: top-level classes only.** `handler(X.class)` and `orchestrator(X.class)` store the name that `X.class` reports, which for an inner class is `Outer.Inner`, but compare it with the running class's simple name, `Inner`. An inner class therefore never matches. For an inner handler class, use its [`TriggerHandler__mdt` record](/api/custom-metadata#trigger-handler) or its Bypassable add-on; for an inner orchestrator class, use `sObject(…)`. In a namespaced installation this matching has not been verified.
- **Only Trigger Lib handlers.** Flows, validation rules, duplicate rules and triggers not built on Trigger Lib still run.

Every way to switch handlers off, in the order the library checks them: [Bypassing](/guide/bypasses).

## Logger {#logger}

```apex
public interface Logger {
    void log(TriggerOrchestrator.Error error);
    void finalize();
}
```

Implement it in one class to receive handler errors. The library finds the class itself, so nothing is registered.

| Method | Called |
|---|---|
| `log(error)` | for every exception thrown inside a handler's turn (providers, predicates, actions, dispatch, Finalizer, the commit of an own or private unit of work), before it is rethrown or swallowed by ContinueOnError; also for the before-context DML guard and for a Validator that attached no error |
| `finalize()` | once when the outermost run ends, also when it failed; nested runs do not call it. Not called when the run was skipped or the orchestrator does not handle the context. |

- **Discovery.** The first call to `run` or `bypass()` in a transaction queries `ApexTypeImplementor` once for concrete classes that implement `TriggerOrchestrator.Logger`, and creates the class with its no-argument constructor.
- **One implementation.** With two or more, that first call throws `TriggerOrchestratorException`, so every trigger that uses the library fails until one is removed.
- **None is fine.** Without an implementation, errors are only thrown, never logged.

A complete Logger and its lifecycle: [Errors & Logging](/guide/error-handling#logger).

### What Is Never Logged {#never-logged}

<!--@include: @/_parts/notes/never-logged.md-->

## Error {#error}

`Logger.log` receives one `Error` per exception.

```apex
public interface Error {
    String getHandlerName();
    SObjectType getSObjectType();
    System.Exception getException();
    System.TriggerOperation getOperation();
    Set<Id> getRecordIds();
}
```

| Method | Returns |
|---|---|
| `getHandlerName()` | the handler's simple class name, without the outer class; never null |
| `getSObjectType()` | the object of the trigger |
| `getException()` | the exception |
| `getOperation()` | the trigger operation, such as `AFTER_UPDATE` |
| `getRecordIds()` | the Ids of every record in the chunk, not only the qualified ones; an empty set in before insert |

## Exceptions {#exceptions}

The library throws two exception types of its own. Both are rethrown even when the handler implements ContinueOnError.

### TriggerOrchestratorException {#triggerorchestratorexception}

The class is private to `TriggerOrchestrator`, so it cannot be named in a `catch`. Catch `Exception` and match on `getMessage()`.

| Message | Thrown |
|---|---|
| `Called outside of a trigger context, or the trigger operation is not supported.` | by `run` when no trigger is running; never logged |
| `Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.` | by the first call to `run` or `bypass()` in the transaction; never logged |
| `<Handler> performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.` | after a before insert or before update handler's turn that ran DML or published an immediate event; logged, then thrown |
| `<Handler> qualified a record in errorShouldBeAttachedOnBeforeInsertWhen but attached no error in addErrorOnBeforeInsert.` | by a Validator's turn when its predicate returned true and its error method attached no error; in before update the message names `errorShouldBeAttachedOnBeforeUpdateWhen` and `addErrorOnBeforeUpdate`; logged, then thrown |

`<Handler>` is the handler's simple class name.

- **Around a direct call only.** Catching works around your own call to `run` or `bypass()`. Code that fires the trigger through DML gets a `DmlException` instead, or a `Database.Error` with partial success, and its message contains the original message.
- **The other library exception** is public and can be caught by type: [TriggerHandler.TriggerHandlerException](/api/record#triggerhandlerexception).

## Names That Look Alike {#name-collisions}

<!--@include: @/_parts/notes/name-collisions.md-->

## See Also {#see-also}

- [Trigger & Orchestrator](/guide/orchestrator): wiring, handler order, one class in several contexts
- [Bypassing](/guide/bypasses) and [Custom Metadata](/api/custom-metadata)
- [Errors & Logging](/guide/error-handling)
- [Contexts at a Glance](/contexts)
