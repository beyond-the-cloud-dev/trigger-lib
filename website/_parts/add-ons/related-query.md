<!-- #region core -->

- **At the handler's turn.** When the handler's turn in the list comes, the library calls its RelatedQuery method and runs each provider once, before the handler's first predicate. That is once per handler per run.
- **All records.** `query(records)` receives every record in the chunk, qualified or not, because no predicate has run yet.
- **Indexed by key.** Each returned row is indexed under `keyOf(row)`. A null key leaves the row out of the index, but it still appears in `getRecords()`. A null list from `query` counts as empty, and a null map from the RelatedQuery method means no providers.
- **Exact keys.** `getFirstWhereKeyEquals(key)` and `getAllWhereKeyEquals(key)` compare `String.valueOf(key)` with the stored keys exactly, case included. Normalize text keys the same way on both sides.
- **Private to the handler.** A handler reads only its own providers, by the name it gave them: `record.getRelated('<provider name>')`. Every method that receives the records can read them, the Finalizer included.
- **Parents first.** Parents are already loaded when providers run, so a provider can collect declared parent values in bulk, for example with `records.getIdsOf('Account', Account.OwnerId)`.
- **The provider's own sharing.** A provider's SOQL runs under its own class's sharing keyword. Declare one on every provider class, inner classes included: an inner class does not take its outer class's keyword.
- **Inside the error handling.** Providers run inside the handler's try block. An exception there is logged, and with ContinueOnError it is swallowed like any other failure of the handler, which then processes no record in that chunk.

<!-- #endregion core -->

<!-- #region ids-before-insert -->

- **No Ids yet.** `records.getIds()` is empty and `record.getId()` is null. Key providers by field values, `records.getValuesOf(Contact.Email)`, or by lookups, `records.getIdsOf(Contact.AccountId)`.
- **Invisible to SOQL.** The records being inserted are not in the database, so a query never finds clashes between records of the same chunk, such as two new contacts with one email. Compare those in memory, for example in a Populator's Finalizer.

<!-- #endregion ids-before-insert -->

<!-- #region ids-before-update -->

- **Ids work.** `records.getIds()` returns the Ids of the records being updated.
- **SOQL sees the saved values.** A query on the trigger object returns the values from before this update, and formula fields computed from them. Read a record's own pending values from the record, not from a query.
- **Exclude the records themselves.** To look at other records of the same object, add `Id NOT IN :records.getIds()`. Clashes between records of the same chunk are invisible to SOQL; compare them in memory.
- **Both sides.** `records.getValuesOf(...)` reads the pending values, including values that earlier handlers set with `put`. `records.getOldIdsOf(...)` and `records.getOldValuesOf(...)` read the previous values, for example to load the children of the previous parent.

<!-- #endregion ids-before-update -->

<!-- #region ids-after -->

- **Ids work.** `records.getIds()` returns the Ids of the trigger records.
- **SOQL sees the new values.** The records are saved but not committed. Queries in this transaction return them with their new values, and formula fields are recalculated when queried.
- **Exclude the records themselves.** To look at other records of the same object, add `Id NOT IN :records.getIds()`.

<!-- #endregion ids-after -->

<!-- #region ids-before-delete -->

- **Ids work.** `records.getIds()` returns the Ids of the records being deleted.
- **Still in the database.** The records are still present and still linked: their children and the records that look up to them can be queried. This is the last point at which they can be read that way.
- **Old values.** `records.getIdsOf(...)` and `records.getValuesOf(...)` read the old rows.
- **Exclude the records themselves.** To look at other records of the same object, add `Id NOT IN :records.getIds()`.

<!-- #endregion ids-before-delete -->

<!-- #region ids-after-delete -->

- **Deleted rows are invisible.** `records.getIds()` returns the deleted Ids, but SOQL no longer returns those rows. A provider that queries the trigger object by `records.getIds()` gets nothing, and `Id NOT IN :records.getIds()` on a sibling query changes nothing.
- **Key by the old lookups.** `records.getIdsOf(Contact.AccountId)` reads the old rows, whose lookup fields are still set.
- **Stale inbound lookups.** Records that looked up to a deleted row may still point at it during this trigger. When you recompute from such records, add `AND <lookup> NOT IN :records.getIds()`.

<!-- #endregion ids-after-delete -->

<!-- #region gotchas -->

- **Providers run even when nothing qualifies.** They run before the first predicate, so they cost their SOQL on every run. To skip the query, return an empty list from `query` when no record in `records` can qualify.
- **Unknown names throw.** `getRelated` with a name the handler did not return throws `TriggerHandler.TriggerHandlerException`. It is rethrown even with ContinueOnError. See [TriggerHandlerException](/api/record#triggerhandlerexception).
- **Sharing can hide rows.** A `with sharing` provider sees only the rows the running user can see, so a duplicate check can miss records that the user cannot see. Use `without sharing` when the check must see every record.
- **No DML in a provider.** In before insert and before update the DML guard fails the save. In the other contexts the DML runs at once, outside any unit of work.
- **One query per provider per run.** Every 200-record chunk queries again, and two handlers that use the same provider query twice.

<!-- #endregion gotchas -->
