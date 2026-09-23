A Dispatcher hands work to something outside the save: a Queueable, a platform event, an email, an approval.

- **It never receives a unit of work.** OwnUnitOfWork on a Dispatcher is ignored; its method is never called. Record DML here is direct DML: after contexts have no DML guard, so it runs at once, is not merged with the Writers' registrations, and costs its own statement. For record writes that should commit with the save, use a Writer.
- **The dispatch method gets the qualified records only.** They arrive as a `<X>Records` collection with `getIds()`, `getIdsOf(…)`, `getValuesOf(…)`, `size()` and `getRecords()`, among others. `getRecords()` returns the library's own list, not a copy, so removing items from it also removes them from what the Finalizer receives.
- **Pass Ids to async work.** Enqueue one job with `records.getIds()` and let the job query what it needs, instead of passing the rows. After a delete the rows can no longer be queried, so pass the values the job needs instead.
- **No synchronous callouts.** A callout from a trigger throws a `System.CalloutException`. Enqueue a Queueable that implements `Database.AllowsCallouts` and call out from there.
