**Code written for an earlier Trigger Lib API.** Older examples show after-context handlers that implement the context's `Handler` marker with `qualifiesFor…When` and `on…` methods. Those methods no longer belong to any interface:

| Earlier API | Current API |
|---|---|
| `implements AfterInsert.Handler`, `AfterUpdate.Handler`, `AfterDelete.Handler` or `AfterUndelete.Handler` | `implements After<Op>.Writer` or `After<Op>.Dispatcher` |
| `qualifiesForAfterInsertWhen`, `qualifiesForAfterUpdateWhen`, `qualifiesForAfterDeleteWhen`, `qualifiesForAfterUndeleteWhen` | `writeOnAfter<Op>When(record)` or `dispatchOnAfter<Op>When(record)` |
| `onAfterInsert`, `onAfterUpdate`, `onAfterDelete`, `onAfterUndelete` | `writeOnAfter<Op>(record, unitOfWork)`, which registers writes per record, or `dispatchOnAfter<Op>(records)`, which runs once with the qualified records |
| `record.getNewRelated('Account')` | `record.getNewParent('Account')` |
| `finalizeAfterInsert()`, `finalizeAfterUpdate()`, `finalizeAfterDelete()` or `finalizeAfterUndelete()` with no parameter | `finalizeAfter<Op>(records)`, which receives the qualified records |
| `TriggerOrchestrator.RecursionGuard` | a per-handler add-on in the update contexts only, `BeforeUpdate.RecursionGuard` or `AfterUpdate.RecursionGuard`; without it the limit is 3 |

- **The marker-only class compiles and never runs.** A class that implements only the `Handler` marker, with the old `qualifiesFor…When` and `on…` methods, fits in the handler list, but the orchestrator runs only Writers and Dispatchers, so nothing calls those methods and nothing warns you.
- **The rest does not compile.** `getNewRelated` does not exist, and a parameterless `finalize…()` does not satisfy the Finalizer interface.
- **DML in the finalizer.** The old examples collected records in the action and ran `update` in the finalizer. A Writer registers each write on its unit of work in the action instead, and the library commits it.
