---
description: 'Record API reference: InsertRecord, UpdateRecord, DeleteRecord, UndeleteRecord and the Rejectable records of Validators, with accessors, put and addError, value checks, change detection and record type checks.'
---

# Record API

Every handler method that takes one record gets a `TriggerTypes` record interface. It wraps the new and old rows, the declared parents and the related records.

## Record Interfaces {#record-interfaces}

| Context | Record | Validator error method gets | Collection |
|---|---|---|---|
| BeforeInsert | `InsertRecord` | `RejectableInsertRecord` | `InsertRecords` |
| AfterInsert | `InsertRecord` | | `InsertRecords` |
| BeforeUpdate | `UpdateRecord` | `RejectableUpdateRecord` | `UpdateRecords` |
| AfterUpdate | `UpdateRecord` | | `UpdateRecords` |
| BeforeDelete | `DeleteRecord` | `RejectableDeleteRecord` | `DeleteRecords` |
| AfterDelete | `DeleteRecord` | | `DeleteRecords` |
| AfterUndelete | `UndeleteRecord` | | `UndeleteRecords` |

All interfaces are nested in `TriggerTypes`.

## Methods {#methods}

| Member | Insert | Rejectable Insert | Update | Rejectable Update | Delete | Rejectable Delete | Undelete |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| `getId()`, `getRelated(providerName)` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `getNewSObject()`, `getNewParent(relationshipName)` | ✓ | ✓ | ✓ | ✓ | | | ✓ |
| `getOldSObject()`, `getOldParent(relationshipName)` | | | ✓ | ✓ | ✓ | ✓ | |
| `put(field, value)` | ✓ | | ✓ | | | | |
| `addError(error)`, `addError(field, error)` | | ✓ | | ✓ | | ✓ | |
| value checks and record type checks | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| change detection | | | ✓ | ✓ | | | |

A missing member is a compile error, such as `isChanged` in an insert handler.

- **`getId()`** is null in before insert.
- **`getNewSObject()`** is the live row in before insert and before update. In the after contexts it is read-only.
- **`getOldSObject()`** is read-only. Stop a delete with `record.addError(…)` in a [BeforeDelete.Validator](/before-delete/validator).
- **`getNewParent('Account')`** returns the parent a [ParentQuery](/api/parent-fields) loaded, or null. `getOldParent` reads PriorParentQuery. The name is case-sensitive. The row itself holds only the lookup Id: `getNewSObject().Account` is null.
- **`put`** works only in before insert and before update. In after insert and after update it compiles but throws a `FinalException` that nothing can catch. Change saved records with a [Writer](/api/unit-of-work).
- **`addError(field, error)`** shows the error at record level on `Name` and address fields. The record is still rejected.

## Value Checks {#value-checks}

`equals`, `doesNotEqual`, `contains`, `doesNotContain`, `startsWith`, `endsWith`, `isNull`, `isNotNull`, `isEmpty`, `isNotEmpty`, `isBlank`, `isNotBlank`, `isTrue`, `isFalse`, `greaterThan`, `greaterThanOrEqualTo`, `lessThan`, `lessThanOrEqualTo`.

- **They read the new row.** In the delete contexts they read the old row.
- **They see earlier changes.** In before contexts, a value set by an earlier handler with `put` counts.
- **They never throw on null.** Comparisons such as `lessThan` are false for null.
- **Case.** `equals` ignores case for text. `contains`, `startsWith` and `endsWith` are case-sensitive.
- **`0` and `false` are values.** They are not null, empty or blank.

## Change Detection {#change-detection}

Update contexts only: `isChanged`, `isAnyChanged`, `areAllChanged`, `isChangedTo`, `isChangedFrom`, `isChangedFromTo`.

- **`isAnyChanged` and `areAllChanged`** take 2 to 5 fields or an `Iterable<SObjectField>`.
- **Text comparison ignores case.** `'Doe'` to `'DOE'` is not a change.

## Record Type {#record-type}

`isRecordType(developerName)` and `isNotRecordType(developerName)` compare by developer name, not label. They cost no SOQL.

- **Objects without record types throw** a [`TriggerLibException`](/api/trigger-orchestrator#triggerlibexception).
- **A misspelled name is not caught.** An unknown name resolves to no Id, so `isRecordType` is true for rows without a `RecordTypeId`, such as in-memory test rows, and false for all others.
