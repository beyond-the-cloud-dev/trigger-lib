A Writer gets one unit per run, that is, per trigger invocation. Which unit depends on the add-ons the Writer implements, checked in this order:

| The Writer implements | Its `unitOfWork` is | Configured |
|---|---|---|
| OwnUnitOfWork, with or without ContinueOnError | the unit its `ownUnitOfWorkOn<Ctx>()` method returns | by you: user mode, sharing, partial success, statement order, identifier, commit hook |
| ContinueOnError, without OwnUnitOfWork | a private unit for this Writer alone | like the shared unit, including the `'triggerUow'` identifier |
| neither | the shared unit, one per run, shared by every Writer that implements neither | `new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow')` |

- **Chosen before the handler bypass checks.** The unit is picked when the handler list is built, so `ownUnitOfWorkOn<Ctx>()` runs even for a Writer that is then skipped by its `bypassOn<Ctx>When()`, by a `TriggerHandler__mdt` row or by `TriggerOrchestrator.bypass().handler(…)`.
- **An own unit is yours.** The library passes your registrations through to it and calls `commitWork()` once, after this Writer's Finalizer, when at least one record qualified. Everything else, from user mode to partial success, is the configuration you built.
- **Why a private unit.** A ContinueOnError Writer that fails loses only its own registrations: its private unit is never committed, and nothing reached the shared unit.
- **Same identifier.** A private unit also uses `'triggerUow'`, so `DML.mock('triggerUow')` and `DML.retrieveResultFor('triggerUow')` cover the shared and private units together.
- **Only Writers get a unit.** A Dispatcher receives none, and OwnUnitOfWork on a Dispatcher is ignored.
