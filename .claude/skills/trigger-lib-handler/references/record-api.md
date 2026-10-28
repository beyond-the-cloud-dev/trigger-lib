# Trigger Lib record API reference

Every type below is nested in `TriggerTypes`. Prefix it with `btcdev.` when Trigger Lib is installed as the `btcdev` package.

## Contents

- [Record interfaces](#record-interfaces)
- [Methods per record interface](#methods-per-record-interface)
- [Value checks](#value-checks)
- [Change detection](#change-detection)
- [Record collections](#record-collections)
- [RelatedRecords](#relatedrecords)
- [ParentFields](#parentfields)
- [UnitOfWork](#unitofwork)

## Record interfaces

| Context | Predicate and action get | Validator error method gets | Collection |
|---|---|---|---|
| BeforeInsert | `InsertRecord` | `RejectableInsertRecord` | `InsertRecords` |
| AfterInsert | `InsertRecord` | | `InsertRecords` |
| BeforeUpdate | `UpdateRecord` | `RejectableUpdateRecord` | `UpdateRecords` |
| AfterUpdate | `UpdateRecord` | | `UpdateRecords` |
| BeforeDelete | `DeleteRecord` | `RejectableDeleteRecord` | `DeleteRecords` |
| AfterDelete | `DeleteRecord` | | `DeleteRecords` |
| AfterUndelete | `UndeleteRecord` | | `UndeleteRecords` |

## Methods per record interface

| Member | Insert | Rejectable Insert | Update | Rejectable Update | Delete | Rejectable Delete | Undelete |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `getId()`, `getRelated(providerName)` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `getNewSObject()`, `getNewParent(lookupField)` | ✓ | ✓ | ✓ | ✓ | | | ✓ |
| `getOldSObject()`, `getOldParent(lookupField)` | | | ✓ | ✓ | ✓ | ✓ | |
| `put(field, value)` | ✓ | | ✓ | | | | |
| `addError(error)`, `addError(field, error)` | | ✓ | | ✓ | | ✓ | |
| value checks, `isRecordType`, `isNotRecordType` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| change detection | | | ✓ | ✓ | | | |

- `getId()` is `null` in before insert.
- `getNewSObject()` is the live `Trigger.new` row in before insert and before update, and read-only in the after contexts.
- `getOldSObject()` is always read-only. Writing to it throws a `FinalException` that no `catch` stops, and so does calling `addError` on it outside the delete contexts.
- `put` compiles on `InsertRecord` and `UpdateRecord` in every context, but in after insert and after update it throws a `FinalException` that no `catch` stops, and the save fails.
- `getNewParent(lookupField)` returns the parent a ParentQuery loaded, and `getOldParent(lookupField)` the one a PriorParentQuery loaded. Both return `null` when the lookup is empty, when no record has that Id, or when no active handler declared that lookup in this context. No error tells you which.
- `getRelated(providerName)` throws a `TriggerLibException` for a name the handler's RelatedQuery didn't return.

## Value checks

`equals(field, value)`, `doesNotEqual(field, value)`, `isIn(field, values)`, `isNotIn(field, values)`, `contains(field, text)`, `doesNotContain(field, text)`, `startsWith(field, text)`, `endsWith(field, text)`, `isNull(field)`, `isNotNull(field)`, `isEmpty(field)`, `isNotEmpty(field)`, `isBlank(field)`, `isNotBlank(field)`, `isTrue(field)`, `isFalse(field)`, `greaterThan(field, value)`, `greaterThanOrEqualTo(field, value)`, `lessThan(field, value)`, `lessThanOrEqualTo(field, value)`.

- They read the new row. In the delete contexts they read the old row.
- In before contexts they see a value that an earlier handler set with `put`.
- They never throw on `null`. Comparisons such as `lessThan` are false for `null`.
- `isIn` and `isNotIn` take any `Iterable<Object>`, such as a `Set<String>` or a `List<String>`.
- `equals` and `isIn` ignore case for text. `contains`, `startsWith` and `endsWith` are case-sensitive.
- `isEmpty` is true for `null` or `''`. `isBlank` is also true for whitespace. `0` and `false` are values, never null, empty or blank.
- The comparisons take an `Integer`, `Long`, `Double`, `Decimal`, `Date` or `Datetime`.
- `isRecordType(developerName)` and `isNotRecordType(developerName)` compare by developer name and cost no SOQL. On an object without record types they throw a `TriggerLibException`. An unknown name resolves to no Id, so `isRecordType` is true for rows without a `RecordTypeId`, such as in-memory test rows, and false for all others.

## Change detection

Update contexts only: `isChanged(field)`, `isAnyChanged(...)`, `areAllChanged(...)`, `isChangedTo(field, value)`, `isChangedToNotNull(field)`, `isChangedFrom(field, value)`, `isChangedFromTo(field, fromValue, toValue)`.

- `isAnyChanged` and `areAllChanged` take 2 to 5 fields, or an `Iterable<SObjectField>`.
- Text comparison ignores case: `'Doe'` to `'DOE'` is not a change.

## Record collections

A RecordsProvider's `query(records)` gets every record of the chunk. A Dispatcher's `dispatchOn<Ctx>(records)` and a Finalizer's `finalizeOn<Ctx>(records)` get the qualified records.

| Method | Returns |
|---|---|
| `getIds()` | The record Ids. Empty in before insert |
| `getIdsOf(field)` | The values of an Id or lookup field |
| `getValuesOf(field)` | The values of any field, as text |
| `getIdsOf(relationshipName, field)`, `getValuesOf(relationshipName, field)` | The same, read from each record's loaded parent |
| `getOldIdsOf(...)`, `getOldValuesOf(...)` | Update contexts only: the same, read from the old row or from the parent a PriorParentQuery loaded |
| `getRecords()` | The records, as the context's record interface |
| `size()` | The number of records |

- They read the new row. In the delete contexts they read the old row.
- They return no nulls and no duplicates, and each call returns a new set.
- Pass the relationship name of a declared lookup, such as `'Account'` for `Contact.AccountId` or `'Region__r'` for `Invoice__c.Region__c`. The name is case-sensitive. A record without a loaded parent adds nothing.
- `getIdsOf` throws on a field that doesn't hold Ids, such as `Contact.Email`. Use `getValuesOf` there.
- `getRecords()` returns the library's own list. Call `.clone()` before you add or remove elements.

## RelatedRecords

What `record.getRelated('<provider name>')` returns.

| Method | Returns |
|---|---|
| `getFirstWhereKeyEquals(key)` | The first row with that key, or `null` |
| `getAllWhereKeyEquals(key)` | Every row with that key, or an empty list |
| `getRecords()` | Every row `query` returned, rows with a `null` key included |
| `isEmpty()` | True when `query` returned no rows |

- Keys compare as text. An Id matches the same Id returned as a `String` from `keyOf`.
- `keyOf` returning `null` leaves that row out of the index, and `query` returning `null` counts as no rows.
- One index per provider is shared by the whole chunk. Look up by the current record, for example `getAllWhereKeyEquals(record.getId())`.
- The `ORDER BY` of the provider's query decides which row `getFirstWhereKeyEquals` returns.

## ParentFields

A ParentQuery or PriorParentQuery returns a `Map<SObjectField, TriggerTypes.ParentFields>`. The key is a lookup field on the trigger object, and the fields belong to the object it points to.

```apex
Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name, Account.Industry).with('Owner', User.Email)
```

- `with(field, ...)` takes up to five fields or an `Iterable<SObjectField>`. `with(relationshipName, field, ...)` adds grandparent fields, read as `parentAccount.Owner.Email`.
- Every `with` returns the selection, so calls chain.
- The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`.
- Declarations of all handlers in the run merge into one query per lookup, but a handler can lose a field that only a bypassed handler declared. Declare every field in the handler that reads it.
- Parents load at the first read, for every record of the chunk, in system mode without sharing.
- For polymorphic lookups such as `WhatId`, `WhoId` or an `OwnerId` that can hold a queue, some parents come back `null`. In after insert, after update and after undelete, a field outside the `Name` object makes the query fail.

## UnitOfWork

```apex
public interface UnitOfWork {
    UnitOfWork toInsert(SObject record);
    UnitOfWork toInsert(DML.Record record);
    UnitOfWork toUpdate(SObject record);
    UnitOfWork toUpdate(DML.Record record);
    UnitOfWork toUpsert(SObject record, SObjectField externalIdField);
    UnitOfWork toDelete(SObject record);
    UnitOfWork toPublish(SObject event);
}
```

- One record per call, no List overloads.
- Register new instances holding the Id and the changed fields. A commit that includes a trigger row throws.
- Ids are checked at commit: `toInsert` of a record with an Id, or `toUpdate` and `toDelete` of a record without one, throw a `DmlException` then.
- `toUpsert` with a `null` field matches on the record Id.
- No undelete, merge, hard delete or explicit commit. Run direct DML for those.
- `DML.Record` comes from DML Lib, which ships with Trigger Lib. `DML.Record(new Contact(LastName = 'Doe')).withRelationship(Contact.AccountId, branch)` fills the lookup with the Id of `branch` once the unit has inserted it. Register the parent in the same unit, with `toInsert` or `toUpsert`, before the child. `DML.Record(recordId)` starts an update from an Id, `with(field, value)` sets a field, and `withRelationship(lookupField, externalIdField, externalIdValue)` links by external Id.

| The Writer implements | Its unit of work | Commits |
|---|---|---|
| neither OwnUnitOfWork nor ContinueOnError | The shared unit of the run: `new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow')` | Once, after the last handler. A failed commit fails the save, and ContinueOnError doesn't apply |
| ContinueOnError | An automatic unit set up like the shared one | Right after the Writer, when a record qualified |
| OwnUnitOfWork | The unit `ownUnitOfWorkOn<Ctx>()` returns | Right after the Writer, when a record qualified |

`DML.retrieveResultFor('<identifier>')` returns the results of every commit under that identifier in the transaction. With `allowPartialSuccess()`, failed rows don't throw, so read them there.
