<!-- #region common -->

An exception thrown by this handler (provider, predicate, action, dispatch or Finalizer) is logged and swallowed; the rest of this handler's records and its Finalizer are skipped; later handlers still run and the DML statement proceeds.

The exceptions listed under What Still Throws are not swallowed.

<!-- #endregion common -->

<!-- #region writer -->

**On a Writer it also changes the unit.** Unless the Writer implements OwnUnitOfWork, it gets a private unit, configured like the shared unit and with the same `'triggerUow'` identifier. The unit commits right after the Writer's Finalizer, inside the same try block:

- when the Writer throws, the commit is skipped and its registrations are discarded, and nothing it registered reaches the shared unit;
- when the commit itself fails, the failure is logged and swallowed, and statements of that commit that already succeeded stay.

<!-- #endregion writer -->
