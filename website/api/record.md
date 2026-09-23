---
description: 'Record API reference: InsertRecord, UpdateRecord, DeleteRecord, UndeleteRecord and the Rejectable records of Validators, with accessors, put and addError, value predicates, change detection, record type checks, TriggerHandlerException and the helpers for unit tests.'
---

# Record API

Every handler method that takes one record gets a `TriggerHandler` record type. It wraps the new and old rows, the declared parents and the related records. Each context's Record API page lists the methods that apply there.

## Record Types {#record-types}

| Context | Record | Validator error method gets | Collection |
|---|---|---|---|
| BeforeInsert | `InsertRecord` | `RejectableInsertRecord` | `InsertRecords` |
| AfterInsert | `InsertRecord` | | `InsertRecords` |
| BeforeUpdate | `UpdateRecord` | `RejectableUpdateRecord` | `UpdateRecords` |
| AfterUpdate | `UpdateRecord` | | `UpdateRecords` |
| BeforeDelete, AfterDelete | `DeleteRecord` | | `DeleteRecords` |
| AfterUndelete | `UndeleteRecord` | | `UndeleteRecords` |

All types are nested in `TriggerHandler`. The collections are on [Record Collections](/api/record-collections).

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

A member that a type lacks does not compile. For example, `isChanged` in an insert handler is a compile error.

- **`getId()`** is null in before insert.
- **`getNewSObject()`** is the live row in before insert and before update. In the after contexts it is read-only: writing to it throws a `FinalException` that nothing can catch.
- **`getOldSObject()`** is always read-only. In the delete contexts it is the only row. Stop a delete with `getOldSObject().addError(…)` in [BeforeDelete](/before-delete/handler).
- **`getNewParent('Account')`** returns the parent a [ParentQuery](/api/field-selection) loaded. `getOldParent` returns the one a PriorParentQuery loaded. The name is case-sensitive. The result is null when the lookup is empty or not declared.
- **Relationship fields on the row are empty.** `getNewSObject().Account` is null. Read parents with `getNewParent`.
- **`put`** works only in before insert and before update. In the after contexts it compiles but throws a `FinalException`. Change saved records with a [Writer](/api/unit-of-work).
- **`addError(field, error)`** shows the error at record level on `Name` and on address fields. The save is still blocked.

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
- **Null is a value.** A change from null to a value, or back, is a change.
- **`isChangedFromTo` does not require a change.** With the same `from` and `to`, it is true for a field that kept that value.

## Record Type {#record-type}

`isRecordTypeEqual(developerName)` and `isRecordTypeNotEqual(developerName)` compare the record type by developer name, not by label. They cost no SOQL.

- **Objects without record types throw** a `TriggerHandlerException`.
- **An unknown name never matches.** `isRecordTypeEqual` is false for every record.

## TriggerHandlerException {#triggerhandlerexception}

`TriggerHandler.TriggerHandlerException` is public, so you can catch it by type. The library rethrows it even with ContinueOnError.

| Message | Thrown by |
|---|---|
| `<Object> has no record types, so isRecordTypeEqual cannot be used on it.` | the record type checks on an object without record types |
| `No related records provider is registered under <name>. …` | `getRelated` with a name the handler's RelatedQuery did not return |

## Test API {#test-api}

These public members build records and results in memory. A test can then call a handler's methods directly, with no DML and no trigger.

| Member | Use |
|---|---|
| `new TriggerHandler.TriggerRecord(newRow, oldRow)` | one record for any context; pass `null` for the side the context lacks |
| `new TriggerHandler.InsertTriggerRecords(records)` and the `Update`, `Delete` and `Undelete` versions | the collection a dispatch method, Finalizer or provider receives |
| `new TriggerHandler.ProvidedRecords(rows)` and `groupUnderKey(key, row)` | the `RelatedRecords` a provider would produce |
| `new TriggerHandler.RandomIdGenerator().get(SObjectType)` | a fake Id with the object's key prefix |

Attach parents and provider results with `enrichNew`, `enrichOld` and `setProvidedRecords` on `TriggerRecord`. These are marked internal and may change. See [Testing](/guide/testing).

```apex
@IsTest
static void writeOnAfterUpdateWhenClosedWon() {
    // Setup
    Id opportunityId = new TriggerHandler.RandomIdGenerator().get(Opportunity.SObjectType);
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Opportunity(Id = opportunityId, StageName = 'Closed Won'), new Opportunity(Id = opportunityId, StageName = 'Prospecting'));
    record.enrichNew('Account', new Account(Type = 'Prospect'));

    // Test
    Boolean qualifies = new OpportunityAccountTypeWriter().writeOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(qualifies, 'The record should qualify.');
}
```
