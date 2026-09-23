1. **Run-level switches.** Called outside a trigger, `run()` throws. Otherwise the run ends at once, before any handler code, when `TriggerOrchestrator.bypass()` covers it (`all()`, `sObject(…)` or `orchestrator(…)`) or the object's `TriggerObject__mdt` row has `Bypass__c` checked. It also ends, silently, when the orchestrator does not implement `TriggerOrchestrator.<Ctx>`.
2. **Handlers are adapted.** `<ctx>Handlers()` is called, and each handler in the list is adapted by its role. A class with both roles becomes a Writer; a class with neither is dropped.
3. **Per-handler switches.** For each handler, in this order: `TriggerOrchestrator.bypass().handler(…)`, the handler's `TriggerHandler__mdt` row, then `bypassOn<Ctx>When()`, which runs once per handler, not per record. The first one that applies switches the handler off for this run: it declares no parents and runs no providers, predicates, dispatch or Finalizer.
4. **Parents load.** The lookups that the remaining handlers declared are loaded once, before the first handler runs, in system mode without sharing, whether or not any record qualifies later.
5. **Each handler runs, in list order.**
   - Its RelatedQuery providers run over all records.
   - Writer: per record, the predicate decides, and when it returns true the action runs at once and registers its writes.
   - Dispatcher: the predicate collects the qualifying records, then the dispatch method runs once with them, if there are any.
   - The Finalizer runs if at least one record qualified, after the dispatch for a Dispatcher.
   - An exception is passed to the Logger, then rethrown unless the handler implements ContinueOnError. `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are always rethrown.
   - There is no DML guard: direct DML runs at once.
6. **The shared unit commits.** After the last handler, the shared unit of work saves everything registered on it, once, in system mode without sharing. Its DML fires the triggers of the objects it writes, and those triggers run before this run ends. The commit runs outside every handler's `try` block: a failure fails the DML statement, ContinueOnError does not apply, and the error is not passed to `TriggerOrchestrator.Logger`. A DML Lib `DML.Logger` implementation, if the org has one, still records the failed operation.
7. **Logger.** In `run()`'s `finally` block, when this is the outermost Trigger Lib run, the org's `TriggerOrchestrator.Logger` implementation, if there is one, gets its `finalize()` call.

The transaction commits later, when the whole request succeeds. All of this happens once per trigger run, and the platform runs a trigger once per chunk of up to 200 records.
