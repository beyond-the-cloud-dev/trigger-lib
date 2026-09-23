A Writer changes other records, never the trigger rows.

- **The trigger rows are read-only.** Setting a field on `getNewSObject()` or `getOldSObject()`, or calling `put` where the record type has it, throws `System.FinalException`. No `catch` inside the trigger stops it, ContinueOnError included, and the DML statement fails.
- **No results inside the handler.** The unit commits after the action returns and after the Finalizer, so a record registered with `toInsert` has no Id yet while the action or the Finalizer runs.
- **Direct DML runs at once.** After contexts have no DML guard. A direct `insert` or `update` in the action runs immediately and bypasses the unit of work: it is not merged with other registrations, it costs its own DML statement, and it is not discarded when a ContinueOnError Writer fails later.
- **Rejecting a record from here.** `addError(message)` on the trigger row (`getNewSObject()`, or `getOldSObject()` after a delete) rejects that record, and the platform reverts its insert, update, delete or restore. By then every earlier handler has done its work, so reject in a before context when the operation has one.
