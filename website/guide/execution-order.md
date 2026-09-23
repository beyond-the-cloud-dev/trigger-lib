---
description: The order in which Trigger Lib runs switches, handlers, parent queries, providers, Finalizers and unit-of-work commits, and what one run costs in SOQL queries and DML statements.
---

# Execution Order & Cost

What one `TriggerOrchestrator.run(…)` does, in order, and what it costs.

## One Run per Chunk {#run}

The platform fires a trigger once per context for each chunk of up to 200 records. Each firing is one run. An insert of 201 records makes four runs: before insert and after insert for the first 200 records, then both again for the last one.

Every run starts over:

- It calls `<ctx>Handlers()` again. Handlers created there start with empty instance fields.
- It queries parents and runs providers again.
- It commits its own unit of work.

Static fields, `TriggerOrchestrator.bypass()` switches and recursion counts last the whole transaction.

## Order of a Run {#order}

1. **Run switches.** `TriggerOrchestrator.bypass()` (`all()`, `sObject(…)`, `orchestrator(…)`) or a checked `TriggerObject__mdt.Bypass__c` ends the run before any of your code. So does an orchestrator that does not implement the context.
2. **Handler list.** `<ctx>Handlers()` runs. A class that implements two roles runs only as the first: Populator over Validator, Writer over Dispatcher.
3. **Handler switches.** `bypass().handler(…)`, then `TriggerHandler__mdt.Bypass__c`, then `bypassOn<Ctx>When()`. A skipped handler declares no parents.
4. **Parents load.** One load for all remaining handlers, before the first handler runs.
5. **Each handler runs, in list order.**
   - Its RelatedQuery providers run over all records.
   - Per record, the predicate decides and the action runs. A Dispatcher collects the records and dispatches once.
   - The Finalizer runs when at least one record qualified.
   - An own or private unit of work commits.
   - In before insert and before update, DML or an event publish throws. After a Populator, parents it re-pointed are loaded.
6. **Shared commit.** In after contexts, the shared unit of work commits once.
7. **Logger.** The outermost run calls `finalize()` on the org's Logger.

## Query Cost {#query-cost}

| Source | SOQL queries |
|---|---|
| Bypass metadata | 0: custom metadata, once per transaction |
| Logger discovery | 1, once per transaction |
| Parents, before contexts and after delete | 1 per declared lookup, per run |
| Parents, after insert, update and undelete | 1 on the trigger object, plus 1 per lookup it did not return; after update adds previous parents |
| Parents after a Populator | 1 per lookup pointed at a parent not loaded yet |
| RelatedQuery providers | what each `query` runs, once per provider per handler per run |

- **Declarations merge.** Handlers that declare the same lookup share one query.
- **Parents and providers run before the first predicate,** even when no record qualifies.
- **Never query in a predicate or an action.** They run once per record. Declare a ParentQuery or a RelatedQuery, or query once in a Finalizer.

## DML Cost {#dml-cost}

- **Before insert and before update:** none. DML or an event publish throws.
- **Shared unit:** one commit per run. It costs one statement per operation and object type. An empty unit costs nothing.
- **Own or private unit:** one commit per Writer per run, when a record qualified.
- **Direct DML** in a Dispatcher, a before delete handler or a Finalizer costs what it runs.
- **Events:** a Publish After Commit event counts as a DML statement. A Publish Immediately event counts toward `Limits.getPublishImmediateDML()`.

See [Unit of Work](/guide/unit-of-work#when-it-commits).

## Nested Runs {#nested}

A commit or direct DML fires the triggers of the saved records at once. Each fires a full nested run with its own parents, providers and commit.

- **Recursion counts are shared.** In the update contexts, a Populator, Writer or Dispatcher skips a record after acting on it 3 times in the transaction. Change the limit with a [RecursionGuard](/after-update/add-ons/recursion-guard).
- **Only the outermost run calls `finalize()`.**
- **Salesforce allows 16 levels.** The next one fails with "maximum trigger depth exceeded".
