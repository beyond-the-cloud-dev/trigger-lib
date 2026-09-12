---
outline: deep
---

# Design Principles

Trigger Lib encodes a small set of rules about how trigger code should be written. They are the reason the API looks the way it does.

## One orchestrator per object, one handler per concern

Every object has exactly one trigger and one orchestrator. The orchestrator is the only place where the order of handlers is defined, and it is plain Apex, so the wiring is visible in code review and covered by version control.

A handler does one thing: populate a field, validate a rule, create related records. Small handlers are easy to name, test and bypass.

## One role per context

In the before contexts a handler class declares what kind of handler it is. `BeforeInsert.Populator` and `BeforeUpdate.Populator` write to the triggering record. `BeforeInsert.Validator` and `BeforeUpdate.Validator` return a message and let the framework attach the error. A class implements exactly one of them per context.

Implementing both, or neither, is not a warning. The orchestrator throws a `TriggerOrchestratorException` naming the class and both interfaces it could have implemented. A handler that populates and validates in one method hides one of the two, so the framework refuses to run it.

The same class may take a different role in a different context: `BeforeInsert.Populator` on one side and `BeforeUpdate.Validator` on the other is allowed, and each context runs its own methods.

## Registration order is the dependency declaration

Handlers run in the order the orchestrator's list returns them, whatever role they have. Qualification is not a global pass up front: each handler's predicate is evaluated at that handler's own turn, immediately before it runs.

A handler therefore observes the field values written by handlers registered before it. Moving a handler in the list can change which records qualify for the handlers below it. The list is where cross-handler dependencies are stated, so keep it ordered deliberately and keep it short.

## No loops in handlers

The framework iterates over trigger records. A handler gets one context record at a time - `TriggerHandler.InsertRecord`, `UpdateRecord`, `DeleteRecord` or `UndeleteRecord` - so it reads like business logic and not like a bulk-processing routine. Work that must be bulk, like DML, is collected per record and executed once in a [finalizer](/guide/finalizers).

Each interface exposes only what its context can answer. A delete handler cannot reach a new record, an insert handler cannot ask what changed. The compiler enforces most of the context rules that a single generic record type would leave to a runtime null.

## No SOQL in handlers

Parent data is declared, not queried. A handler lists the lookup fields and parent fields it needs and the framework pulls them in a single query per lookup, shared by all handlers of the same context. This keeps the query count predictable regardless of how many handlers an object has.

Enrichment runs once per invocation, before any handler does, so qualification predicates can read `getNewRelated` and `getOldRelated` as freely as the action methods can. A relationship a handler never declared is not queried, and `getNewRelated` returns `null` for it.

## Before context populates, after context acts

Before insert and before update handlers exist to populate and validate the triggering records. DML there is not merely discouraged, it is detected: the framework compares the DML and immediate-platform-event counters around the handler and throws a `TriggerOrchestratorException` naming it, so nothing is committed. Creating or updating other records belongs in an after context.

## Qualification is explicit

Every handler declares which records it wants. A handler that returns `true` for every record is a deliberate choice, not a default. The framework never runs a handler with an empty record set, and a handler that qualifies nothing does not run its finalizer either.

## Framework contract violations are never suppressible

`ContinueOnError` is an opt-in for a handler's own failures: the handler's exception is logged, the remaining handlers still run and the DML succeeds.

It does not cover the framework's own contract. A `TriggerOrchestratorException` - DML in a before context, a class with two roles or none, two loggers - is logged and then rethrown, and the DML is aborted, even for a handler that implements `ContinueOnError`. A broken contract is a bug in the code, not a runtime condition to absorb.

Platform exceptions are not translated either. An invalid field or a bad cast reaches the caller with its original Salesforce type and message.

## Safe by default

- Update handlers run at most three times per record. The default is three, an orchestrator can change it for all of its handlers with `TriggerOrchestrator.RecursionGuard`, and a handler's own context `RecursionGuard` overrides both.
- A record that exhausts its budget is skipped silently for that handler. The DML succeeds and nothing is logged, so a guard is a limit, not an error channel.
- Parent records are queried in system mode without sharing, so enrichment does not depend on the running user's access.
- Errors are routed to a pluggable logger and rethrown, unless the handler opts in to continue on error.

## No required metadata

The framework works with zero custom metadata records. With no `TriggerObject__mdt` rows present, every handler runs and nothing changes.

Metadata exists only to override the default behaviour from outside the code: `TriggerObject__mdt` turns off every handler for an object, and `TriggerHandler__mdt` turns off one handler class. It is read as custom metadata, so it consumes no SOQL queries against the governor limit. Everything else - bypass conditions, recursion depth, ordering - is expressed in Apex, per handler, and is visible where the handler is defined.
