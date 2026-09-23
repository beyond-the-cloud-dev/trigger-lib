<!-- #region before-insert -->
<!-- #region before-update -->
Value predicates read the new row as it is when they run. Every handler in the list shares that row, so a value that an earlier handler set with `put` counts.

<!-- #endregion before-insert -->
<!-- #region after-update -->
In an update, value predicates never look at the old row. To test a value from before the update, use change detection or read `getOldSObject()`.

<!-- #endregion before-update -->
<!-- #region after-insert -->
<!-- #region after-undelete -->
Value predicates read the new row as it was saved. It is read-only here, so every handler in the list sees the same values.
<!-- #endregion after-undelete -->
<!-- #endregion after-insert -->
<!-- #endregion after-update -->

<!-- #region before-delete -->
<!-- #region after-delete -->
Value predicates read the old row, because a delete has no new row. For example, `record.equals(Contact.LeadSource, 'Web')` tests the value the record has at deletion.
<!-- #endregion after-delete -->
<!-- #endregion before-delete -->
