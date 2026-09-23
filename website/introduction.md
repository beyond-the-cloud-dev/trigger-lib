---
description: What Trigger Lib is, which roles it gives each Salesforce trigger context, and why it is built the way it is.
---

# Introduction

Trigger Lib is an Apex trigger framework for Salesforce. You write one small class per concern, give it a role in a trigger context such as before insert or after update, and the library runs it only for the records that qualify, with parent fields already loaded, DML collected in a unit of work, and bypass and recursion switches built in.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of production-ready Salesforce libraries by [Beyond the Cloud](https://beyondthecloud.dev).

## How It Fits Together {#how-it-fits}

<<< @/../examples/main/default/triggers/AccountTrigger.trigger

1. **The trigger** lists the events and passes an orchestrator to `TriggerOrchestrator.run(…)`. Nothing else goes in it.
2. **The orchestrator** implements `TriggerOrchestrator.<Ctx>` for each context it handles, and returns that context's handlers in run order.
3. **Each handler** implements one role of the context, such as `BeforeInsert.Populator`, plus any add-ons it needs, such as `BeforeInsert.ParentQuery`.
4. **The library** loads the parents the handlers declared, then runs the handlers in list order. Each handler acts only on the records its predicate accepts.

[Trigger & Orchestrator](/guide/orchestrator) covers the wiring, and [Your First Handler](/guide/first-handler) builds it step by step.

## Roles per Context {#roles}

| Context | Roles | Typical job |
|---|---|---|
| [BeforeInsert](/before-insert/) | [Populator](/before-insert/populator), [Validator](/before-insert/validator) | Set defaults and derived fields, reject bad input |
| [AfterInsert](/after-insert/) | [Writer](/after-insert/writer), [Dispatcher](/after-insert/dispatcher) | Create related records, publish events, start async work |
| [BeforeUpdate](/before-update/) | [Populator](/before-update/populator), [Validator](/before-update/validator) | Recalculate fields on change, block invalid changes |
| [AfterUpdate](/after-update/) | [Writer](/after-update/writer), [Dispatcher](/after-update/dispatcher) | Cascade changes to related records, sync to other systems |
| [BeforeDelete](/before-delete/) | [Handler](/before-delete/handler) | Block a delete, clean up while the rows still exist |
| [AfterDelete](/after-delete/) | [Writer](/after-delete/writer), [Dispatcher](/after-delete/dispatcher) | Update parents and related records, notify |
| [AfterUndelete](/after-undelete/) | [Writer](/after-undelete/writer), [Dispatcher](/after-undelete/dispatcher) | Restore related data, notify |

Salesforce has no before undelete event, so there is no BeforeUndelete context: see [There Is No BeforeUndelete](/before-undelete).

- **Populator** changes the record being saved with `put`. **Validator** attaches an error to it. Neither may run DML.
- **Writer** registers inserts, updates, upserts, deletes and platform events on a unit of work that the library commits for it, by default once after the last handler.
- **Dispatcher** receives all the qualified records at once, to enqueue a job, publish an event or send an email.
- **Handler** exists only in before delete. It acts per record, and can reject the delete with `addError` on the old row.

Next to its role, a handler can implement **add-ons**: ParentQuery, PriorParentQuery, RelatedQuery, OwnUnitOfWork, Bypassable, RecursionGuard, Finalizer and ContinueOnError. Each context declares only the add-ons that make sense there. Every method name, context by context, is on [Contexts at a Glance](/contexts#method-names).

## Features {#features}

- **Orchestrator and handlers.** One orchestrator per object lists the handlers of each context in run order, in plain Apex. [Trigger & Orchestrator](/guide/orchestrator)
- **Record filtering.** Every role has a predicate that decides which records the handler acts on. The record API is fluent and null-safe: `isChangedTo`, `isRecordTypeEqual`, `isBlank`, `greaterThan` and more. [Record API](/api/record)
- **Parent queries.** ParentQuery and PriorParentQuery declare lookups and parent fields. The library queries them in system mode without sharing and attaches them to each record, read with `getNewParent('Account')` or `getOldParent('Account')`. [TriggerHandler.ParentFields](/api/field-selection)
- **Related records.** A RelatedQuery provider loads children, siblings or configuration records for its handler, which reads them by key: `record.getRelated('contacts').getAllWhereKeyEquals(record.getId())`. [RelatedQuery Recipes](/guide/related-records)
- **Unit of work.** Writers register DML on a DML Lib unit of work that commits once, after the last handler. OwnUnitOfWork gives one Writer its own unit, for user mode or partial success. [Unit of Work](/guide/unit-of-work)
- **Bypasses.** `TriggerOrchestrator.bypass()` switches objects, orchestrators or handlers off for one transaction, custom metadata switches an object or a handler off org-wide without a deploy, and Bypassable switches one handler off on a condition. [Bypassing](/guide/bypasses)
- **Recursion guard.** In before update and after update, a Populator, Writer or Dispatcher acts on the same record at most three times per transaction by default, and each handler can set its own limit. [AfterUpdate.RecursionGuard](/after-update/add-ons/recursion-guard)
- **Errors and logging.** An exception thrown while a handler runs is passed to the org's `TriggerOrchestrator.Logger` implementation, then rethrown unless the handler implements ContinueOnError. [Errors & Logging](/guide/error-handling)
- **No required metadata.** Everything works with zero custom metadata records. [Custom Metadata](/api/custom-metadata)

## Why Trigger Lib? {#why}

### Handlers Work on One Record {#one-record}

The library loops over the trigger rows for you. A predicate and a per-record action receive one record at a time, typed for the context: `TriggerHandler.InsertRecord`, `UpdateRecord`, `DeleteRecord` or `UndeleteRecord`. Each type offers only what its context can answer: a delete record has no new row, an insert record cannot report a change, and only the insert and update types have `put`. The types are shared by the before and after phase, so `put` still compiles in after insert and after update, where it throws: see [Record API in AfterInsert](/after-insert/record-api#accessors).

A Dispatcher, a Finalizer and a RelatedQuery provider receive the records as one collection instead, for work that has to be bulk.

### Method Names Carry the Context {#method-names}

`populateOnBeforeInsert`, `writeOnAfterUpdate`, `finalizeAfterDelete`: every method name says where it runs. One class can therefore implement several contexts without a clash, and a search for a method name lands on the page of its context. See [One Class in Several Contexts](/guide/orchestrator#one-class-several-contexts).

### Queries Are Declared, Not Written {#declared-queries}

A handler declares the parent fields it reads (ParentQuery, PriorParentQuery) and the other records it needs (RelatedQuery). The parents that all active handlers declared are loaded together before the first handler runs, and a provider runs once for its handler, before that handler's first predicate. Predicates and actions then read from memory, so no query runs per record. What each path costs is on [Execution Order & Cost](/guide/execution-order#query-cost).

### Writes Go Through a Unit of Work {#unit-of-work}

In the after contexts, a Writer's action receives a `TriggerHandler.UnitOfWork`. It registers records with `toInsert`, `toUpdate`, `toUpsert`, `toDelete` and `toPublish`. The unit shared by the Writers of the run commits them once, after the last handler, grouped by operation and object type, and it merges a second update of the same record into the first. See [Unit of Work](/guide/unit-of-work).

### Guard Rails Are Built In {#guard-rails}

- **DML guard.** In before insert and before update, a Populator or Validator that runs DML or publishes an immediate platform event fails the save with a `TriggerOrchestratorException` that names the handler.
- **Validators must attach an error.** A Validator whose predicate accepts a record but whose error method attaches no error fails the save.
- **Recursion limits.** A record past a handler's recursion budget is skipped for that handler, silently.
- **Library errors always surface.** ContinueOnError lets a handler fail without failing the save, but `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are always rethrown. See [Errors & Logging](/guide/error-handling).

## Next Steps {#next-steps}

- [Installation](/installation)
- [Your First Handler](/guide/first-handler)
- [Trigger & Orchestrator](/guide/orchestrator)
- [Contexts at a Glance](/contexts)
- [How do I…](/how-do-i)
- [Design Principles](/introduction/design-principles)
