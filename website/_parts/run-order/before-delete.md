1. **Run-level switches.** Called outside a trigger, `run()` throws. Otherwise the run ends at once, before any handler code, when `TriggerOrchestrator.bypass()` covers it (`all()`, `sObject(…)` or `orchestrator(…)`) or the object's `TriggerObject__mdt` row has `Bypass__c` checked. It also ends, silently, when the orchestrator does not implement `TriggerOrchestrator.<Ctx>`.
2. **Handlers are adapted.** `<ctx>Handlers()` is called. This context has a single role, so every handler in the list is adapted.
3. **Per-handler switches.** For each handler, in this order: `TriggerOrchestrator.bypass().handler(…)`, the handler's `TriggerHandler__mdt` row, then `bypassOn<Ctx>When()`, which runs once per handler, not per record. The first one that applies switches the handler off for this run: it declares no parents and runs no providers, predicates or Finalizer.
4. **Parents load.** The lookups that the remaining handlers declared are loaded once, before the first handler runs, in system mode without sharing, whether or not any record qualifies later.
5. **Each handler runs, in list order.**
   - Its RelatedQuery providers run over all records.
   - Per record, the predicate decides, and when it returns true the action runs at once.
   - The Finalizer runs if at least one record qualified.
   - An exception is passed to the Logger, then rethrown unless the handler implements ContinueOnError. `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are always rethrown.
   - There is no DML guard: DML in a provider, the action or the Finalizer runs at once. Nothing is queried again after a handler.
6. **Nothing to commit.** The shared unit of work is committed, but it is always empty here: no handler in this context receives a unit.
7. **Logger.** In `run()`'s `finally` block, when this is the outermost Trigger Lib run, the org's `TriggerOrchestrator.Logger` implementation, if there is one, gets its `finalize()` call.

The platform then deletes the records. All of this happens once per trigger run, and the platform runs a trigger once per chunk of up to 200 records.
