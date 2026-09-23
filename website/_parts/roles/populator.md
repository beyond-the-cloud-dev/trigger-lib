A Populator changes the record being saved, and only that record.

- **Write with `put`.** `record.put(field, value)` sets the field on the trigger row, and the platform saves it with the record: no DML, no second save, nothing to commit. Assigning the field on the cast row, such as `((Account) record.getNewSObject()).Rating = 'Hot'`, writes the same row; `put` does it without the cast.
- **Later handlers see the value.** Every handler reads the same rows, so a value put here is visible to the handlers listed after this one, in their predicates, actions and Finalizers. Handlers listed before it have already run.
- **Re-pointing a lookup loads the new parent.** When this Populator points a lookup that an active handler declared in a ParentQuery at a parent that is not loaded yet, that parent is queried after this Populator's Finalizer and before the next handler starts, for the records this Populator qualified. A parent already loaded in this run is not read again.
