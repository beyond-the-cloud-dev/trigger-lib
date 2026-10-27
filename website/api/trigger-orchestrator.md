---
description: 'TriggerOrchestrator reference: run() and runFromMetadata() from the trigger, the seven registration interfaces, the bypass() builder, the Logger and Error interfaces, and TriggerLibException.'
---

# TriggerOrchestrator

The class your trigger calls. It runs your handlers, switches them off from Apex, and sends their errors to your Logger.

## run {#run}

**Signature**

```apex
public static void run(Object orchestrator)
```

**Example**

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

- **List every event in the trigger.** `run` does nothing in a context your orchestrator does not register.
- **Once per chunk.** Every context and every chunk of up to 200 records is a separate run. Each run calls your handler method again.
- **Handlers run in list order.** Each handler goes through every record of the chunk before the next handler starts.
- **Switched off, it returns at once.** `bypass()` or a [`TriggerObject__mdt`](/api/custom-metadata) record can switch off the object or the orchestrator.

## runFromMetadata {#run-from-metadata}

Runs the handlers that [`TriggerHandler__mdt`](/api/custom-metadata#trigger-handler) records register for the trigger's object. There is no orchestrator class, so the trigger's package never refers to the handlers, and they can live in packages that depend on it.

**Signature**

```apex
public static void runFromMetadata()
```

**Example**

```apex
trigger AccountTrigger on Account(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerOrchestrator.runFromMetadata();
}
```

- **Every record of the object runs,** unless its `Bypass__c` is checked.
- **`Order__c` is run order,** lowest first. Records without it run last. Ties run in class name order.
- **The class decides the contexts.** It runs in every context whose role it implements, at the same `Order__c`.
- **A new instance per run.** The class needs a public no-argument constructor. Every record's class is created in every context, so keep constructors cheap.
- **A record that cannot run throws.** A class that is not found, cannot be created or implements no handler interface fails the save with a `TriggerTypes.TriggerLibException`.
- **`bypass().orchestrator(…)` does not apply.** Use `sObject(…)`, `handler(…)` or the record's `Bypass__c`.

## Registration Interfaces {#registration}

Your orchestrator implements one interface per context. Its method returns that context's handlers in run order.

**Signature**

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

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

- **Two types per context name.** `TriggerOrchestrator.BeforeInsert` is the registration interface. `BeforeInsert` alone holds the role and add-on interfaces for handlers.
- **Return an empty list, never `null`.** A `null` list throws before any handler runs, and the save fails.
- **One role per class.** A class that implements two roles runs only as the first: Populator over Validator, Validator over Writer, Writer over Dispatcher.
- **The marker alone never runs.** A class that implements only `Handler` compiles and does nothing.

## bypass {#bypass}

**Signature**

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

| Method | Bypasses |
|---|---|
| `sObject(Account.SObjectType)` | every run on that object |
| `orchestrator(X.class)` | every run of that orchestrator |
| `handler(X.class)` | that handler in every context |
| `all()` | every run |

**Example**

```apex
TriggerOrchestrator.bypass().sObject(Account.SObjectType).handler(ContactFollowUpTaskWriter.class);
try {
    insert contacts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- **Lasts for the transaction.** A bypass stays on until `clear()` removes every bypass. Call it in a `finally` block.
- **Top-level classes only.** `handler(X.class)` and `orchestrator(X.class)` never match an inner class. For an inner handler, use a [`TriggerHandler__mdt`](/api/custom-metadata#trigger-handler) record or the Bypassable add-on. For an inner orchestrator, use `sObject(…)`.
- **Only Trigger Lib handlers.** Flows, validation rules and other triggers still run.

## Logger {#logger}

**Signature**

```apex
public interface Logger {
    void log(TriggerOrchestrator.Error error);
    void flush();
}
```

- **`log(error)`** runs for every exception in a handler's turn, before the library rethrows it or ContinueOnError swallows it.
- **`flush()`** runs at the end of each outermost run, also when it failed.
- **Found automatically.** Implement it in one class and register nothing. With two implementations, the first call to `run`, `runFromMetadata` or `bypass()` throws.
- **Not logged:** exceptions outside a handler's turn, listed in [Errors & Logging](/guide/error-handling#never-logged).

## Error {#error}

`Logger.log` receives one `Error` per exception.

**Signature**

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
- **`getRecordIds()`** holds every record of the chunk, not only the qualified ones. It is empty in before insert and for platform events.

## TriggerLibException {#triggerlibexception}

`TriggerTypes.TriggerLibException` is the one exception the library throws, from the record API and from the run. It is public, so you can catch it by type. The library rethrows it even with ContinueOnError.

| Message | Thrown when |
|---|---|
| `Called outside of a trigger context.` | `run` or `runFromMetadata` is called outside a trigger |
| `Multiple implementations of TriggerOrchestrator.Logger found. Only one implementation is allowed.` | the org has two Logger classes |
| `Handler class <Class> was not found.` | a `TriggerHandler__mdt` record of a `runFromMetadata` object names a class that does not exist or is not public |
| `Handler class <Class> could not be instantiated.` | the class has no public no-argument constructor, or its constructor threw; the cause holds the original exception |
| `Handler class <Class> does not implement a handler interface.` | the class implements no context's handler interface |
| `<Handler> performed DML in before insert. Move that work to an after insert Writer.` | a before insert Populator or Validator ran DML or published an immediate event |
| `<Handler> performed DML in before update. Move that work to an after update Writer.` | the same in before update |
| `<Handler> performed DML in <predicate> or <action>. Register that work in the unit of work.` | in before delete or an after context, a Writer's predicate or action ran DML. A Validator or a Dispatcher gets `Move that work to a <context> Writer.` instead, and a Dispatcher's message names only its predicate |
| `<Handler> performed SOQL in <predicate> or <action>. Move that query to a ParentQuery or a RelatedQuery.` | a predicate or a per-record action ran its own SOQL, in any context. A Dispatcher's message names only its predicate. Update contexts add PriorParentQuery, and delete contexts name it instead of ParentQuery. Parents and providers the library loads do not count |
| `<Handler> qualified a record in addErrorOn<Ctx>When but attached no error in addErrorOn<Ctx>.` | a Validator's predicate returned true and its error method attached no error |
| `<Object> has no record types, so isRecordType cannot be used on it.` | `isRecordType` or `isNotRecordType` on an object without record types; the message names the method |
| `No related records provider named <name> is declared. Return it from the queryRelatedOn method of the handler first.` | `getRelated` with a name the handler's RelatedQuery did not return |

Code that fires the trigger through DML gets a `DmlException` that contains the original message.
