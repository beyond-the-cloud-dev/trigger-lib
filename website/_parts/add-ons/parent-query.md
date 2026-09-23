<!-- #region core -->

- **Pooled.** Before the first handler runs, the library collects the parent declarations of every active handler. Fields that different handlers declare for the same lookup are merged into one field list.
- **Loaded up front.** Parents are loaded before the first handler runs, in system mode and without sharing, and attached to every record in the chunk, qualified or not.
- **Keyed by relationship name.** A parent is read by the relationship name of its lookup, the value of `getRelationshipName()`: `Account` for `AccountId`, `Parent` for `ParentId`, `Owner` for `OwnerId`, `Region__r` for `Region__c`.
- **Null when there is nothing to attach.** The parent is null when the lookup is empty, when no active handler declared that lookup, or when no record with that Id exists.

<!-- #endregion core -->

<!-- #region before -->

- **One query per lookup.** Each declared lookup gets one SOQL query against its parent object, selecting the merged fields for every parent Id the chunk needs.
- **Refreshed after each Populator.** When a Populator finishes its records and its Finalizer, the records it qualified get their current parents attached again, so a lookup it re-pointed shows the new parent to every later handler. A parent Id that is not loaded yet costs one more query for that lookup. Nothing is refreshed after a Validator.

<!-- #endregion before -->

<!-- #region after -->

- **One query on the trigger object.** If any active handler declares a current parent, one SOQL query on the saved trigger records reads every declared parent through its relationship path, for example `Account.Name` or `Account.Owner.IsActive`. The library always adds `<relationship>.Id`.
- **Fallback per lookup.** A parent that this query did not return is queried by Id, with one query per lookup.
- **No refresh.** The records are read-only in an after context, so their lookups cannot change and nothing is queried again during the run.

<!-- #endregion after -->

<!-- #region gotchas -->

- **Relationship names are case-sensitive.** `'Account'` finds the parent; `'account'` returns null.
- **Declare what you read.** Declarations are pooled, so a handler can happen to see fields that another handler declared. When that handler is bypassed or removed, the parent comes back null, or reading the field throws an `SObjectException`. Declare every field in the handler that reads it.
- **Outside the error handling.** The declaration method and the parent queries run before any handler, outside the handler's try block. An exception there is not logged, ContinueOnError does not apply, and the save fails. Return an empty map, never null, and never a null value: both throw a `NullPointerException`. Every key must be a lookup or master-detail field of the trigger object, such as `Contact.AccountId`.
- **It runs even when nothing qualifies.** Parents are loaded before any predicate runs, so the query costs its SOQL even if no record qualifies.
- **No sharing and no field-level security.** Parents are read in system mode without sharing, so a handler can see parent records and fields that the running user cannot.
- **One run only.** Loaded parents are kept for one run. Every 200-record chunk, every context and every nested save loads them again.
- **Polymorphic lookups** (`WhatId`, `WhoId`, an `OwnerId` that can hold a queue). Where a lookup is queried on its own, the query runs against the first object the field can reference (`getReferenceTo()[0]`), so parents of any other type come back null. Where the current parent is read through the trigger object (after insert, after update and after undelete), a polymorphic path allows only fields of the `Name` object: `What.Name` works, but a field such as `What.Industry` makes the query fail with "No such column 'Industry' on entity 'Name'", and the save fails.

<!-- #endregion gotchas -->
