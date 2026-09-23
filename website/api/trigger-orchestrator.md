---
description: 'TriggerOrchestrator reference: run() from the trigger, the seven registration interfaces, the bypass() builder, the Logger and Error interfaces, and TriggerOrchestratorException.'
---

# TriggerOrchestrator

The class your trigger calls. It runs the handlers your orchestrator registers, switches handlers off from Apex, and sends handler errors to your Logger.

## run {#run}

```apex
public static void run(Object orchestrator)
```

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

- **List every event in the trigger.** `run` handles only the contexts your orchestrator registers. In any other context it does nothing.
- **Once per chunk.** Every context and every chunk of up to 200 records is a separate run. Each run calls your handler method again.
- **Handlers run in list order.** Each handler goes through every record of the chunk before the next handler starts.
- **Switched off, it returns at once.** `bypass()` or a [`TriggerObject__mdt`](/api/custom-metadata) record can switch off the object or the orchestrator.
- **Outside a trigger it throws.** For example, when you call it from anonymous Apex.

## Registration Interfaces {#registration}

Your orchestrator implements one interface per context. Each method returns the handlers of that context in run order.

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

- **Two types per context name.** `TriggerOrchestrator.BeforeInsert` is the registration interface. `BeforeInsert` alone holds the role and add-on interfaces for handlers.
- **Return an empty list, never `null`.** A `null` list throws before any handler runs, and the save fails.
- **One role per class.** A class that implements two roles runs only as the first: Populator over Validator, Writer over Dispatcher.
- **The marker alone never runs.** Outside BeforeDelete, `Handler` has no methods. A class that implements only `Handler` compiles and does nothing.

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

| Method | Switches off |
|---|---|
| `sObject(Account.SObjectType)` | every run on that object |
| `orchestrator(X.class)` | every run of that orchestrator |
| `handler(X.class)` | that handler in every context |
| `all()` | every run |
| `clear()` | nothing: it removes every switch |

```apex
TriggerOrchestrator.bypass().sObject(Account.SObjectType).handler(ContactFollowUpTaskWriter.class);
try {
    insert contacts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- **Lasts for the transaction.** A switch stays on until `clear()`. No method removes a single switch, so call `clear()` in a `finally` block.
- **Top-level classes only.** `handler(X.class)` and `orchestrator(X.class)` never match an inner class. For an inner handler, use a [`TriggerHandler__mdt`](/api/custom-metadata#trigger-handler) record or the Bypassable add-on. For an inner orchestrator, use `sObject(…)`.
- **Only Trigger Lib handlers.** Flows, validation rules and other triggers still run.

## Logger {#logger}

```apex
public interface Logger {
    void log(TriggerOrchestrator.Error error);
    void finalize();
}
```

- **`log(error)`** runs for every exception in a handler's turn, before the library rethrows it or ContinueOnError swallows it.
- **`finalize()`** runs once when the outermost run ends, also when it failed.
- **Found automatically.** Implement it in one class and register nothing. With two implementations, the first call to `run` or `bypass()` throws.
- **Some exceptions are never logged.** An exception outside a handler's turn goes straight to the caller. This covers `<ctx>Handlers()`, `bypassOn<Ctx>When()`, the parent queries, and the commit of the default unit of work.

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

- **`getHandlerName()`** is the handler's class name without the outer class.
- **`getRecordIds()`** holds every record of the chunk, not only the qualified ones. It is empty in before insert.

## TriggerOrchestratorException {#triggerorchestratorexception}

The class is private, so you cannot catch it by type. Catch `Exception` and match the message. The library rethrows it even when the handler implements ContinueOnError.

| Message | Thrown when |
|---|---|
| `Called outside of a trigger context, or the trigger operation is not supported.` | `run` is called outside a trigger |
| `Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.` | the org has two Logger classes |
| `<Handler> performed DML in a before context. …` | a before insert or before update handler ran DML or published an immediate event |
| `<Handler> qualified a record in errorShouldBeAttachedOn<Ctx>When but attached no error in addErrorOn<Ctx>.` | a Validator's predicate returned true and its error method attached no error |

Code that fires the trigger through DML gets a `DmlException` instead. Its message contains the original message.
