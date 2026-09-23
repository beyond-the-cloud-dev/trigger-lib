---
description: The rules behind Trigger Lib's API - one handler per concern, one role per context, declared queries instead of SOQL, a unit of work for DML, explicit qualification and guard rails that cannot be switched off.
---

# Design Principles

Trigger Lib encodes a small set of rules about how trigger code should be written. They are the reason the API looks the way it does.

## One Orchestrator per Object, One Handler per Concern {#one-handler-per-concern}

Every object has exactly one trigger and one orchestrator. The orchestrator is the only place where the order of handlers is defined, and it is plain Apex, so the wiring is visible in code review and covered by version control.

A handler does one thing: populate a field, validate a rule, create related records. Small handlers are easy to name, test and switch off.

## One Role per Context {#one-role-per-context}

In each context, a handler class takes a role that says what kind of work it does: Populator or Validator in before insert and before update, Writer or Dispatcher in the after contexts, Handler in before delete. A Populator writes to the record being saved. A Validator attaches its own error to it, at record level or on a field; its error method has no `put`, so writes stay in Populators.

A class takes one role per context. Implementing both roles of a context does not fail: the class runs only as the first one, Populator over Validator and Writer over Dispatcher, and nothing warns you. A class that implements only the context's `Handler` marker compiles and never runs. So keep populating and validating, or writing and dispatching, in separate classes: each role then says exactly what its class does.

The same class may take a different role in a different context: `BeforeInsert.Populator` on one side and `BeforeUpdate.Validator` on the other is allowed, and each context runs its own methods. See [One Class in Several Contexts](/guide/orchestrator#one-class-several-contexts).

## Registration Order Is the Dependency Declaration {#registration-order}

Handlers run in the order the orchestrator's list returns them, whatever role they have. Qualification is not a global pass up front: a handler's predicate is evaluated at that handler's own turn, record by record, right before the action for that record.

A handler therefore observes the field values written by handlers registered before it. Moving a handler in the list can change which records qualify for the handlers below it. The list is where cross-handler dependencies are stated, so keep it ordered deliberately and keep it short.

## No Loops in Handlers {#no-loops}

The library iterates over the trigger records. A predicate and a per-record action get one record at a time, typed for the context: `TriggerHandler.InsertRecord`, `UpdateRecord`, `DeleteRecord` or `UndeleteRecord`. They read like business logic, not like a bulk-processing routine.

Work that must be bulk has its own place. A Writer registers DML on a [unit of work](/guide/unit-of-work) that commits once, after the last handler. A Dispatcher receives all the qualified records at once, to enqueue a job, publish an event or send an email. A Finalizer receives the qualified records once, after the last of them.

Each record type exposes only what its context can answer. A delete record has no new row, and an insert record cannot report a change. The compiler enforces most of the context rules that a single generic record type would leave to a runtime null. One gap remains: the insert and update types serve the before and the after phase alike, so `put` compiles in after insert and after update, where the platform has made the rows read-only and the call throws.

## No SOQL per Record {#no-soql-per-record}

Parent data is declared, not queried. A handler lists the lookup fields and parent fields it needs with ParentQuery or PriorParentQuery. The library merges the declarations of all active handlers and loads the parents once, before the first handler runs, in system mode without sharing. Which query that takes depends on the context, as [Execution Order & Cost](/guide/execution-order#query-cost) shows. When a Populator points a lookup at a parent that is not loaded yet, that parent is queried before the next handler starts.

Everything else is a provider. A RelatedQuery provider is one class with one query, run for its handler before that handler's first predicate, and read by key from memory after that. Predicates can therefore read `getNewParent` and `getRelated` as freely as the actions can.

What a handler never does is query inside a predicate or an action, which run once per record, while the query limit counts for the whole transaction. A relationship that no active handler declared is not loaded, and `getNewParent` returns `null` for it. A provider name that the handler's own RelatedQuery did not return makes `getRelated` throw.

## Before Contexts Populate, After Contexts Act {#before-populates-after-acts}

Before insert and before update handlers exist to populate and validate the records being saved. DML there is not merely discouraged, it is detected: the library compares the DML statement and immediate platform event counters around each Populator and Validator, and throws a `TriggerOrchestratorException` that names the handler, which fails the save. Creating or updating other records belongs in an after context, in a Writer.

Before delete has no such guard. Its Handler may run DML directly, for example from its Finalizer, while the records to be deleted still exist.

## Qualification Is Explicit {#qualification-is-explicit}

Every role declares which records it wants. A predicate that returns `true` for every record is a deliberate choice, not a default. An action never runs for a record its predicate rejected, and a Dispatcher's dispatch method and a Finalizer run only when at least one record qualified.

## Library Errors Are Never Suppressible {#library-errors}

ContinueOnError is an opt-in for a handler's own failures: the handler's exception is logged and swallowed, the rest of its records and its Finalizer are skipped, the handlers after it still run and the save goes on.

It does not cover the library's own contract. These are rethrown even for a handler that implements ContinueOnError:

- a `TriggerOrchestratorException`, such as DML in a before insert or before update handler, or a Validator that accepted a record but attached no error;
- a `TriggerHandler.TriggerHandlerException`, such as `isRecordTypeEqual` on an object without record types, or `getRelated` with a provider name the handler never returned.

A broken contract is a bug in the code, not a runtime condition to absorb.

Platform exceptions are not translated either. An invalid field or a bad cast reaches the caller with its original Salesforce type and message.

## Safe by Default {#safe-by-default}

- **Recursion is limited in the update contexts.** In before update and after update, a Populator, Writer or Dispatcher acts on the same record at most three times per transaction. A handler changes its own limit with `BeforeUpdate.RecursionGuard` or `AfterUpdate.RecursionGuard`. There is no limit for the whole orchestrator.
- **A limit is not an error channel.** A record past its budget is skipped silently for that handler. The save goes on and nothing is logged.
- **Parents do not depend on the running user.** Parent records are queried in system mode without sharing.
- **Errors reach one Logger.** An exception thrown while a handler runs is passed to the org's `TriggerOrchestrator.Logger` implementation, then rethrown unless the handler implements ContinueOnError. Code that runs outside a handler, such as the orchestrator's handler list method, is not logged: see [Errors & Logging](/guide/error-handling).

## No Required Metadata {#no-required-metadata}

The library works with zero custom metadata records. With no `TriggerObject__mdt` records, every handler runs.

Metadata exists only to switch things off from outside the code: a `TriggerObject__mdt` record switches off every handler of an object, and a `TriggerHandler__mdt` record under it switches off one handler class. The records are read once per transaction and cost no SOQL against the limit. Everything else, from bypass conditions to recursion limits and ordering, is expressed in Apex, per handler, where the handler is defined. See [Custom Metadata](/api/custom-metadata).
