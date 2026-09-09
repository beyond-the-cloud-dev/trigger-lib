---
outline: deep
---

# Design Principles

Trigger Lib encodes a small set of rules about how trigger code should be written. They are the reason the API looks the way it does.

## One orchestrator per object, one handler per concern

Every object has exactly one trigger and one orchestrator. The orchestrator is the only place where the order of handlers is defined, and it is plain Apex, so the wiring is visible in code review and covered by version control.

A handler does one thing: populate a field, validate a rule, create related records. Small handlers are easy to name, test and bypass.

## No loops in handlers

The framework iterates over trigger records. A handler gets one `TriggerHandler.Record` at a time, so it reads like business logic and not like a bulk-processing routine. Work that must be bulk, like DML, is collected per record and executed once in a [finalizer](/guide/finalizers).

## No SOQL in handlers

Parent data is declared, not queried. A handler lists the lookup fields and parent fields it needs and the framework pulls them in a single query per lookup, shared by all handlers of the same context. This keeps the query count predictable regardless of how many handlers an object has.

## Before context populates, after context acts

Before insert and before update handlers exist to populate and validate the triggering records. They must not perform DML, and the framework throws when they do. Creating or updating other records belongs in an after context.

## Qualification is explicit

Every handler declares which records it wants. A handler that returns `true` from `qualifiesFor...When` for every record is a deliberate choice, not a default. The framework never runs a handler with an empty record set.

## Safe by default

- Update handlers run at most three times per record in a transaction.
- Parent records are queried in system mode without sharing, so enrichment does not depend on the running user's access.
- Errors are routed to a pluggable logger and rethrown, unless the handler opts in to continue on error.

## No required metadata

The framework works with zero custom metadata records. Bypasses and recursion limits are expressed in code, per handler, and are visible where the handler is defined.
