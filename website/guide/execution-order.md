---
description: The order in which Trigger Lib runs switches, handlers, parent queries, providers, Finalizers and unit-of-work commits, and what one run costs in SOQL queries and DML statements.
---

# Execution Order & Cost

## One Run per Chunk {#run}

The platform fires a trigger once per context for each chunk of up to 200 records. Each firing is one run. An insert of 201 records makes four runs: before insert and after insert for the first 200 records, then both again for the last one.

Each run calls `<ctx>Handlers()`, loads parents, runs providers and commits again. Handlers created in `<ctx>Handlers()` start with empty instance fields. Static fields, `TriggerOrchestrator.bypass()` switches and recursion counts last the whole transaction.

## Order of a Run {#order}

1. **Run switches.** `TriggerOrchestrator.bypass()` (`all()`, `sObject(…)`, `orchestrator(…)`) or a checked `TriggerObject__mdt.Bypass__c` ends the run before any of your code. So does an orchestrator that does not implement the context.
2. **Handler list.** `<ctx>Handlers()` runs. A class that implements two roles runs only as the first: Populator over Validator, Writer over Dispatcher.
3. **Handler switches.** `bypass().handler(…)`, then `TriggerHandler__mdt.Bypass__c`, then `bypassOn<Ctx>When()`. A skipped handler declares no parents.
4. **Parents load.** One load for all remaining handlers.
5. **Each handler runs, in list order.**
   - Its RelatedQuery providers run over all records.
   - Per record, the predicate decides and the action runs. A Dispatcher collects the records and dispatches once.
   - The Finalizer runs when at least one record qualified.
   - A Writer with OwnUnitOfWork or ContinueOnError commits its own unit of work.
6. **Default commit.** In after contexts, the [default unit of work](/guide/unit-of-work#which-unit) commits once.
7. **Logger.** The outermost run calls `finalize()` on the org's Logger.

## Query Cost {#query-cost}

SOQL queries a run spends outside your code:

| Source | SOQL queries |
|---|---|
| Bypass metadata | 0, once per transaction |
| Logger discovery | 1, once per transaction |
| Parents in before contexts and after delete | 1 per declared lookup |
| Parents in after insert, update and undelete | 1 on the trigger object, plus 1 per lookup it missed and, in after update, per PriorParentQuery lookup |
| Parents after a Populator | 1 per lookup re-pointed to a parent not loaded yet |
| RelatedQuery providers | what each `query` runs, per handler |

- **Declarations merge.** Handlers that declare the same lookup share one query.
- **Parents and providers run before the first predicate,** even when no record qualifies.
- **Never query in a predicate or an action.** They run once per record. Declare a ParentQuery or a RelatedQuery, or query once in a Finalizer.

## DML Cost {#dml-cost}

- **Before insert and before update:** none. DML or an event publish throws.
- **Default unit of work:** one commit per run. It costs one statement per operation and object type. An empty unit costs nothing.
- **A Writer with OwnUnitOfWork or ContinueOnError:** one more commit per run, when a record qualified.
- **Direct DML** in a Dispatcher, a before delete handler or a Finalizer costs what it runs.
- **Events:** a Publish After Commit event counts as a DML statement. A Publish Immediately event counts toward `Limits.getPublishImmediateDML()`.

## Nested Runs {#nested}

A commit or direct DML fires the triggers of the saved records at once. Each is a full nested run with its own parents, providers and commit.

- **Recursion counts are shared.** In the update contexts, a Populator, Writer or Dispatcher skips a record after acting on it 3 times in the transaction. Change the limit with a [RecursionGuard](/after-update/add-ons/recursion-guard).
- **Salesforce allows 16 levels.** The next one fails with "maximum trigger depth exceeded".
