<!-- #region before-insert -->
**No Id yet.** `getId()` is null and `records.getIds()` is empty, because nothing is saved. Never key a map or a provider by the record Id here. Key by a lookup or a field value, and filter a provider's query with `getIdsOf` or `getValuesOf`.

**No parent records on the row.** The row carries lookup Ids only: `getNewSObject().Account` and other relationship fields are empty. Declare a ParentQuery and read `getNewParent('Account')` instead.

<!-- #region before-update -->
**Only the Validator's error method can call `addError` on the record.** It receives a `TriggerHandler.Rejectable<X>Record`, which has `addError(String)` and `addError(SObjectField, String)` but no `put`. Every other method that receives a record gets one with `put` and no `addError`. To reject a record from there, call `getNewSObject().addError(…)`.

**Field errors on Name and address fields show at record level.** `addError(SObjectField, String)` uses the dynamic field form, which loses the field attribution on `Name` and on compound address fields (proven on `Name`, `BillingStreet` and `BillingCity`). The save is still blocked and the message still shows, but not next to the field.

<!-- #endregion before-insert -->
<!-- #region after-update -->
**The old row is read-only.** Writing to `getOldSObject()`, or calling `addError` on it, throws a `FinalException` that cannot be caught inside the trigger, not even with ContinueOnError. The update fails.

<!-- #endregion before-update -->
<!-- #region after-insert -->
**`put` throws here.** It compiles, because the record interface declares it, but the row is read-only after the save. `put`, like any write to `getNewSObject()`, throws a `FinalException` ("Record is read-only") that cannot be caught inside the trigger, not even with ContinueOnError. The caller's DML fails with a catchable `DmlException` (`CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY`). To change the saved records, set the value in the matching before context, or register a new instance with the record Id through a Writer's `toUpdate`, which fires the update triggers again.

<!-- #region after-undelete -->
**Rejecting a record after the save.** `getNewSObject().addError(…)` still works here and fails that record like a validation error. With all-or-none DML the whole statement fails. With partial success (`allOrNone` set to false), the platform re-runs the handlers for the other records and saves them.

<!-- #endregion after-update -->
<!-- #endregion after-insert -->
**`UndeleteRecord` has no `put`.** The restored row is read-only: writing to `getNewSObject()` throws a `FinalException`, as in the other after contexts. There is no old row, so `getOldSObject()` does not exist here. An error attached with `getNewSObject().addError(…)` leaves that record in the Recycle Bin.
<!-- #endregion after-undelete -->

<!-- #region before-delete -->
**Merges arrive as deletes.** The records that lose a merge fire the delete triggers, but `MasterRecordId` is set only in after delete, so a before delete handler cannot tell a merge from a plain delete.

<!-- #region after-delete -->
**The old row is read-only but takes errors.** Writing to `getOldSObject()` throws a `FinalException` that cannot be caught inside the trigger. `getOldSObject().addError(…)` is allowed and is how you stop a record: it blocks the delete in before delete and rolls it back in after delete.

<!-- #endregion before-delete -->
**Merge losers carry `MasterRecordId`.** A record deleted because it lost a merge has `MasterRecordId` set to the winning record's Id, and a plain delete leaves it null. Check it only on objects that have the field, such as Account, Contact, Lead and Case.

**The row is gone from the database.** An ordinary SOQL query no longer finds the deleted records, but `getOldSObject()` still holds their field values, lookup Ids included.
<!-- #endregion after-delete -->
