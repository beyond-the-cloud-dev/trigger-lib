---
description: The order in which Trigger Lib runs switches, handlers, parent queries, providers, Finalizers and unit-of-work commits in each trigger context, what never reaches the Logger, and what one invocation costs in SOQL queries and DML statements, including chunking, nested runs and partial saves.
---

# Execution Order & Cost

What happens, in order, when a trigger calls `TriggerOrchestrator.run(…)`, and what it costs: SOQL queries, DML statements, and what the platform's 200-record chunks, nested saves and partial saves multiply.

## One Run per Trigger Invocation {#run}

The platform fires a trigger once per context for each chunk of up to 200 records. Each of those invocations is one **run**: `run(…)` builds a new `TriggerOrchestrator`, with its own parent cache and its own shared unit of work, and calls your orchestrator's handler method for that context.

An Apex `insert` of 201 records makes four runs, in this order: before insert and after insert for the first 200 records, then before insert and after insert for the last one. Static values survive from one run to the next; everything else starts over.

## Once per Transaction {#once-per-transaction}

The first time a transaction uses `TriggerOrchestrator`, two queries run and their results are kept in statics for the rest of the transaction:

- **Bypass metadata.** One query reads `TriggerObject__mdt` with its `TriggerHandler__mdt` records. Custom metadata queries do not count against the SOQL limit.
- **Logger discovery.** One query on `ApexTypeImplementor` looks for the class that implements `TriggerOrchestrator.Logger`. It runs even when the org has no Logger. Whether it counts against the SOQL limit has not been measured, so budget one query for it.

`TriggerOrchestrator.bypass()` switches and the recursion counts of the update contexts are statics too, and they also last for the transaction.

## Before Insert and Before Update {#before-insert-update}

<!--@include: @/_parts/run-order/before-insert-update.md-->

- **Parents in before insert:** one query per declared lookup, on the lookup's object, for the parent Ids the records hold.
- **Parents in before update:** one query per declared lookup, which loads the new parents (ParentQuery) and the previous parents (PriorParentQuery) together.
- **Recursion in before update:** a Populator skips a record whose count has reached its limit before calling its predicate, and the count goes up when the predicate returns true. Validators have no count.

## Before Delete {#before-delete}

<!--@include: @/_parts/run-order/before-delete.md-->

- **Parents:** one query per declared lookup, for the parents the deleted records point at. The PriorParentQuery method here is named `queryParentsOnBeforeDelete()`.

## After Insert, Update, Delete and Undelete {#after}

<!--@include: @/_parts/run-order/after.md-->

- **Own and private units:** a Writer that implements OwnUnitOfWork or ContinueOnError commits its own unit right after its Finalizer, or after its last record when it has none, inside its error handling, and only when at least one record qualified. Those writes are saved before the next handler runs.
- **Parents in after insert and after undelete:** one query on the trigger object reads the new parents through relationship paths, such as `Account.Name` on Contact. A lookup whose parent that query did not return gets one more query of its own.
- **Parents in after update:** the same trigger-object query for the new parents, plus one query per PriorParentQuery lookup for previous parents that are not loaded yet.
- **Parents in after delete:** one query per declared lookup, for the parents the deleted records pointed at. The PriorParentQuery method here is named `queryParentsOnAfterDelete()`.
- **Recursion in after update:** Writers and Dispatchers skip a record whose count has reached its limit before calling their predicate.

## Never Logged {#never-logged}

<!--@include: @/_parts/notes/never-logged.md-->

What the Logger receives, and when: [Errors & Logging](/guide/error-handling#logger).

## Query Cost {#query-cost}

SOQL queries that one run can spend, apart from what your own code runs:

| Source | Queries | When |
|---|---|---|
| Bypass metadata | 0 against the limit | once per transaction |
| Logger discovery | 1; may count against the limit (not verified), so budget one | once per transaction |
| Parents, before insert, before update, before delete, after delete | 1 per declared lookup that holds at least one Id | every run with a declared lookup |
| Parents, after insert, after update, after undelete | 1 on the trigger object, plus 1 per lookup for parents it did not return or, in after update, for previous parents | every run with a declared lookup |
| Parents again after a Populator | 1 per lookup that the Populator pointed at a parent not loaded yet | before insert and before update |
| RelatedQuery providers | whatever each provider's `query` runs, usually 1 | once per provider per handler per run |

- **Declarations are merged.** Handlers that declare the same lookup share one query, which selects the union of their fields. ParentQuery and PriorParentQuery on the same lookup share it too, where the context loads both sides in one query.
- **Parents load before the first handler,** whether or not any record qualifies later. A handler that is switched off declares nothing.
- **Providers run before the first predicate,** so they spend their query even when no record qualifies. Two handlers that use the same provider class query twice.
- **Queries in a predicate or an action run once per record.** Across the chunks of a statement they reach the 100-query limit quickly, and the `LimitException` cannot be caught. Declare a ParentQuery or a RelatedQuery instead, or query once in a Finalizer.

A worked example: an Apex `insert` of 1,000 Contacts that all have an Account, with one Populator that declares `Contact.AccountId` in before insert and one Writer with one provider in after insert, runs 5 chunks. That is 5 parent queries and 5 provider queries, plus the Logger discovery query once.

## Parents Are Cached for One Run {#parent-cache}

The parent cache lives for one run. Each trigger invocation builds a new `TriggerOrchestrator` and a new cache, so parents are queried again:

- in every 200-record chunk of the same statement;
- in every context of the same save: before insert and after insert each run their own parent queries;
- in every nested run.

Within one run, each parent is queried once. The query after a Populator loads only parents that are not in the cache yet.

## DML Cost {#dml-cost}

- **Before insert and before update spend none.** The DML guard fails the save if a handler runs DML or publishes an event.
- **The shared unit commits once per run,** after the last handler. DML Lib runs one statement per operation and object type, per external Id field for upserts, and for inserts and upserts once per dependency wave. A unit with nothing registered costs nothing.
- **An own or private unit commits once per Writer per run,** when at least one record qualified, with the same statement rules. Its statements are not merged with the shared unit's.
- **Direct DML** in a Dispatcher, a before delete handler or an after-context Finalizer costs what it runs, when it runs.
- **Events.** A Publish After Commit event counts as a DML statement. A Publish Immediately event counts toward `Limits.getPublishImmediateDML()` instead.

For the full commit rules, see [Unit of Work](/guide/unit-of-work#when-it-commits).

## What Chunking Multiplies {#chunking}

Everything that happens per run happens once per chunk, and once per context:

- the orchestrator's `<ctx>Handlers()` call, and with it new handler instances when the orchestrator builds them there, so instance fields start empty in every chunk ([Instances per Chunk](/guide/orchestrator#instances-per-chunk));
- the bypass methods and the getters `ownUnitOfWorkOn<Ctx>()` and `maxRecursionDepthOn<Ctx>()`;
- parent queries and provider queries;
- each handler's Finalizer and each Dispatcher's dispatch, and with it every job it enqueues or email it sends;
- every unit-of-work commit;
- the Logger's `finalize()`, for outermost runs.

What stays once per transaction: the metadata and Logger queries, `TriggerOrchestrator.bypass()` switches, recursion counts and your own static fields.

An Apex `update` of 1,000 Accounts with one after update Writer that registers a Contact update per Account makes 5 runs, and each commits once: 5 update statements on Contact, plus whatever the Contact triggers they fire spend.

## Nested Runs {#nested}

A commit, or direct DML in a handler, saves other records and fires their triggers at once. Each of those triggers makes a complete run of its own, nested inside the run that caused it, with its own parent queries, providers and shared commit. The outer run continues when they finish.

- **Recursion counts are shared.** The update contexts count per record, handler and context across nested runs, so a guard stops a handler that updates its own records again and again. See [BeforeUpdate.RecursionGuard](/before-update/add-ons/recursion-guard) and [AfterUpdate.RecursionGuard](/after-update/add-ons/recursion-guard).
- **Only the outermost run calls the Logger's `finalize()`.**
- **Salesforce allows 16 levels** of triggers firing triggers. The next level fails with "maximum trigger depth exceeded".

## Partial Saves {#partial-save}

With partial success, as in `Database.update(records, false)`, Data Loader or the Bulk API, a record that fails makes the platform roll back the first attempt and run the triggers again for the records that remain. Every handler therefore runs twice for those records:

- DML from the first attempt, own and shared commits included, is rolled back and done again.
- A Publish Immediately event from the first attempt is not rolled back, so it may be published twice.
- Static values set in the first attempt stay. Each remaining record spends two passes of its recursion budget in the update contexts.

## See Also {#see-also}

- [Contexts at a Glance](/contexts#facts): the facts per context in one table
- [Trigger & Orchestrator](/guide/orchestrator#order): handler order and nested triggers
- [Bypassing](/guide/bypasses#order): the order of checks
- [Unit of Work](/guide/unit-of-work): registration and commits
- [Errors & Logging](/guide/error-handling): what reaches the Logger
