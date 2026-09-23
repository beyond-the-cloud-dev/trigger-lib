<!-- #region before-delete -->

**DML is allowed here.** Unlike before insert and before update, before delete has no DML guard and no unit of work, so a DML statement in the Finalizer runs at once. Collect Ids in the per-record action and run one bulk statement here, instead of one statement per record. With ContinueOnError, a failing statement is logged and swallowed, and the delete proceeds.

<!-- #region before -->

- **After this handler, before the next.** The Finalizer runs once the handler has processed every record in the chunk, before the next handler in the list starts.
- **Only qualified records.** It runs only when at least one record qualified, and it receives only those records.
- **Once per chunk.** It runs once per chunk of up to 200 records. It is not a hook that runs once after the whole DML statement.

<!-- #endregion before-delete -->

**The DML guard covers it.** A DML statement or an immediately published event in the Finalizer fails the save with a `TriggerOrchestratorException`, even with ContinueOnError. See [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).

<!-- #endregion before -->

<!-- #region after -->

- **After the records, before the commits.** A Writer's Finalizer runs after its per-record loop and before the Writer's own or private unit commits. A Dispatcher's Finalizer runs after dispatch. Both run before the shared unit commits.
- **Only qualified records, once per chunk.** It runs only when at least one record qualified, receives only those records, and runs once per chunk of up to 200 records. It is not a hook that runs once after the whole DML statement. In after update, records skipped by the recursion guard are not among them.
- **No unit of work.** The Finalizer receives only the records. To register writes from a Writer's Finalizer, keep the `unitOfWork` from the action in an instance field. The Finalizer runs only when at least one record qualified, so the action has already run and the field is set. Those registrations commit with the rest: an own or private unit right after the Finalizer, the shared unit after the last handler.
- **Direct DML runs at once.** After contexts have no DML guard. A Dispatcher has no unit, so DML in its Finalizer is direct DML: it runs immediately and is not merged with any unit.

<!-- #endregion after -->
