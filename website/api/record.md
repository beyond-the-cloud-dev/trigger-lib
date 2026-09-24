---
description: 'Record API reference: InsertRecord, UpdateRecord, DeleteRecord, UndeleteRecord and the Rejectable records of Validators, with accessors, put and addError, value predicates, change detection, record type checks and TriggerHandlerException.'
---

# Record API

Every handler method that takes one record gets a `TriggerHandler` record type. It wraps the new and old rows, the declared parents and the related records.

## Record Types {#record-types}

| Context | Record | Validator error method gets | Collection |
|---|---|---|---|
| BeforeInsert | `InsertRecord` | `RejectableInsertRecord` | `InsertRecords` |
| AfterInsert | `InsertRecord` | | `InsertRecords` |
| BeforeUpdate | `UpdateRecord` | `RejectableUpdateRecord` | `UpdateRecords` |
| AfterUpdate | `UpdateRecord` | | `UpdateRecords` |
| BeforeDelete, AfterDelete | `DeleteRecord` | | `DeleteRecords` |
| AfterUndelete | `UndeleteRecord` | | `UndeleteRecords` |

All types are nested in `TriggerHandler`.

## Methods {#methods}

| Member | Insert | Rejectable Insert | Update | Rejectable Update | Delete | Undelete |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `getId()`, `getRelated(providerName)` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `getNewSObject()`, `getNewParent(relationshipName)` | ✓ | ✓ | ✓ | ✓ | | ✓ |
| `getOldSObject()`, `getOldParent(relationshipName)` | | | ✓ | ✓ | ✓ | |
| `put(field, value)` | ✓ | | ✓ | | | |
| `addError(error)`, `addError(field, error)` | | ✓ | | ✓ | | |
| value predicates and record type checks | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| change detection | | | ✓ | ✓ | | |

A missing member is a compile error, such as `isChanged` in an insert handler.

- **`getId()`** is null in before insert.
- **`getNewSObject()`** is the live row in before insert and before update. In the after contexts it is read-only.
- **`getOldSObject()`** is read-only. Stop a delete with `getOldSObject().addError(…)` in [BeforeDelete](/before-delete/handler).
- **`getNewParent('Account')`** returns the parent a [ParentQuery](/api/field-selection) loaded, or null. `getOldParent` reads PriorParentQuery. The name is case-sensitive. The row itself holds only the lookup Id: `getNewSObject().Account` is null.
- **`put`** works only in before insert and before update. In after insert and after update it compiles but throws a `FinalException` that nothing can catch. Change saved records with a [Writer](/api/unit-of-work).
- **`addError(field, error)`** shows the error at record level on `Name` and address fields. The save is still blocked.

## Value Predicates {#value-predicates}

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

`isRecordTypeEqual(developerName)` and `isRecordTypeNotEqual(developerName)` compare by developer name, not label. They cost no SOQL.

- **Objects without record types throw** a `TriggerHandlerException`.
- **A misspelled name is not caught.** An unknown name resolves to no Id, so `isRecordTypeEqual` is true for rows without a `RecordTypeId`, such as in-memory test rows, and false for all others.

## TriggerHandlerException {#triggerhandlerexception}

`TriggerHandler.TriggerHandlerException` is public, so you can catch it by type. The library rethrows it even with ContinueOnError.

| Message | Thrown by |
|---|---|
| `<Object> has no record types, so isRecordTypeEqual cannot be used on it.` | the record type checks on an object without record types |
| `No related records provider is registered under <name>. …` | `getRelated` with a name the handler's RelatedQuery did not return |
