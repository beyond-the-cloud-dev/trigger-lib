---
description: 'Record API reference: InsertRecord, UpdateRecord, DeleteRecord, UndeleteRecord and the Rejectable records of Validators, with accessors, put and addError, value predicates, change detection (isChanged), record type checks, TriggerHandlerException and the helpers for unit tests.'
---

# Record API

Every handler method that takes one record receives it as a `TriggerHandler` record type. It wraps the new and old rows (`Trigger.new`, `Trigger.old`), the parent (lookup) records the handler declared, and its related records, and it offers value predicates and change detection. This page lists every record type and member; each context's Record API page shows what applies there.

<!--@include: @/_parts/generated/chips/record-api.md-->

## Record Types {#record-types}

| Context | Predicates and actions receive | A Validator's error method receives | Collections |
|---|---|---|---|
| BeforeInsert | `InsertRecord` | `RejectableInsertRecord` | `InsertRecords` |
| AfterInsert | `InsertRecord` | — | `InsertRecords` |
| BeforeUpdate | `UpdateRecord` | `RejectableUpdateRecord` | `UpdateRecords` |
| AfterUpdate | `UpdateRecord` | — | `UpdateRecords` |
| BeforeDelete | `DeleteRecord` | — | `DeleteRecords` |
| AfterDelete | `DeleteRecord` | — | `DeleteRecords` |
| AfterUndelete | `UndeleteRecord` | — | `UndeleteRecords` |

All types are nested in `TriggerHandler`, so a method declares `TriggerHandler.InsertRecord record`. The collections are on [Record Collections](/api/record-collections).

- **The interface decides what compiles.** Each context's methods declare the type that matches what the context has: a delete handler cannot call `getNewSObject()`, because `DeleteRecord` does not declare it.
- **The Rejectable types are for rejecting.** `RejectableInsertRecord` and `RejectableUpdateRecord` have everything `InsertRecord` and `UpdateRecord` have except `put`, plus `addError`. Only a Validator's error method, `addErrorOnBeforeInsert` or `addErrorOnBeforeUpdate`, receives one.

## Method Availability {#method-availability}

| Member | `InsertRecord` | `RejectableInsertRecord` | `UpdateRecord` | `RejectableUpdateRecord` | `DeleteRecord` | `UndeleteRecord` |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `getId()` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `getNewSObject()` | ✓ | ✓ | ✓ | ✓ | | ✓ |
| `getOldSObject()` | | | ✓ | ✓ | ✓ | |
| `getNewParent(relationshipName)` | ✓ | ✓ | ✓ | ✓ | | ✓ |
| `getOldParent(relationshipName)` | | | ✓ | ✓ | ✓ | |
| `getRelated(providerName)` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `put(field, value)` | ✓ | | ✓ | | | |
| `addError(error)`, `addError(field, error)` | | ✓ | | ✓ | | |
| value predicates: `equals` … `lessThanOrEqualTo` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| change detection: `isChanged` … `isChangedFromTo` | | | ✓ | ✓ | | |
| `isRecordTypeEqual`, `isRecordTypeNotEqual` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

A member that a type lacks is a compile error, not a null at runtime: `isChanged` in an insert handler, or `getOldParent` in an undelete handler, does not compile.

## Accessors {#accessors}

### getId {#getid}

```apex
Id getId()
```

The record Id. It is null in before insert, where nothing is saved yet. In before delete and after delete it comes from the old row.

### getNewSObject {#getnewsobject}

```apex
SObject getNewSObject()
```

The `Trigger.new` row of this record. Cast it to read fields: `Contact contactRecord = (Contact) record.getNewSObject();`

- **Before insert and before update:** the live row. Later handlers see what you change, and it is saved with the record, without DML.
- **After insert, after update and after undelete:** the saved row, read-only. Writing to it throws a `FinalException` that nothing in the trigger can catch.
- **Relationship fields are empty.** The row carries lookup Ids only: `getNewSObject().Account` is null. Read parents with `getNewParent`.

### getOldSObject {#getoldsobject}

```apex
SObject getOldSObject()
```

The `Trigger.old` row, the values before this save. It is read-only: writing to it throws a `FinalException`.

- **Update contexts:** `addError` on the old row also throws a `FinalException`. Reject the record through the new row.
- **Delete contexts:** the old row is the only row, and `getOldSObject().addError(…)` is how a handler stops a delete. See [BeforeDelete.Handler](/before-delete/handler).

### getNewParent {#getnewparent}

```apex
SObject getNewParent(String relationshipName)
```

The parent record the lookup points to now, loaded by the context's ParentQuery add-on. `relationshipName` is the relationship name of the lookup: `Account` for `Contact.AccountId`, `Owner` for `OwnerId`, `My_Lookup__r` for `My_Lookup__c`.

```apex
Account parentAccount = (Account) record.getNewParent('Account');
```

- **Null** when the lookup is empty, when no running handler declared that lookup, or when no record has that Id.
- **Case-sensitive.** `'Account'` finds the parent; `'account'` returns null.
- **Only declared fields.** Reading a parent field that no handler declared throws an `SObjectException`. See [TriggerHandler.ParentFields](/api/field-selection).

ParentQuery in each context:

<!--@include: @/_parts/generated/chips/parent-query.md-->

### getOldParent {#getoldparent}

```apex
SObject getOldParent(String relationshipName)
```

The parent record the lookup pointed to before this save, loaded by the context's PriorParentQuery add-on, by the same relationship names as `getNewParent`. It is queried when the trigger runs, so its fields show their current values. When the lookup did not change and both sides are declared, both methods return the same record.

PriorParentQuery in each context:

<!--@include: @/_parts/generated/chips/prior-parent-query.md-->

### getRelated {#getrelated}

```apex
TriggerHandler.RelatedRecords getRelated(String providerName)
```

The rows a RelatedQuery provider returned, indexed by the provider's key. `providerName` is the key of the map the handler's RelatedQuery method returns, not a relationship name.

```apex
List<SObject> openOpportunities = record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId());
```

A name the handler did not return throws [`TriggerHandlerException`](#triggerhandlerexception). Each handler reads only its own providers. See [RelatedRecords & RecordsProvider](/api/related-records).

### put {#put}

```apex
void put(SObjectField field, Object value)
```

Sets a field on the new row. It returns nothing, so write one statement per field.

- **Before insert and before update:** works. Every later handler sees the value, in its predicates too, and in before update change detection counts it as a change.
- **After insert and after update:** compiles, because `InsertRecord` and `UpdateRecord` serve both phases, but throws a `FinalException` ("Record is read-only") that no catch in the trigger stops, not even ContinueOnError. The caller's DML fails with a `DmlException`. To change saved records, register a new instance with `toUpdate` in a [Writer](/api/unit-of-work).

### addError {#adderror}

```apex
void addError(String error)
void addError(SObjectField field, String error)
```

On `RejectableInsertRecord` and `RejectableUpdateRecord` only. `addError(error)` attaches a record-level error to the new row; `addError(field, error)` attaches it to a field. Either one blocks the save of that record.

<<< @/../examples/main/default/classes/account/before-update/validator/AccountBillingCountryValidator.cls

- **Field attribution is lost on Name and address fields.** `addError(field, error)` uses the dynamic field form, which shows the error at record level, not next to the field, on `Name` and on compound address fields (proven on `Name`, `BillingStreet` and `BillingCity`; `BillingCountry`, used above, belongs to the same compound billing address). The save is still blocked and the message still shows.
- **A qualified record must get an error.** When the Validator's predicate returned true and its error method attached none, the library throws [`TriggerOrchestratorException`](/api/trigger-orchestrator#triggerorchestratorexception).
- **Other methods** reject a record with `getNewSObject().addError(…)`, or `getOldSObject().addError(…)` in the delete contexts.

## Value Predicates {#value-predicates}

```apex
Boolean equals(SObjectField field, Object value)
Boolean doesNotEqual(SObjectField field, Object value)
Boolean contains(SObjectField field, String value)
Boolean doesNotContain(SObjectField field, String value)
Boolean startsWith(SObjectField field, String value)
Boolean endsWith(SObjectField field, String value)
Boolean isNull(SObjectField field)
Boolean isNotNull(SObjectField field)
Boolean isEmpty(SObjectField field)
Boolean isNotEmpty(SObjectField field)
Boolean isBlank(SObjectField field)
Boolean isNotBlank(SObjectField field)
Boolean isTrue(SObjectField field)
Boolean isFalse(SObjectField field)
Boolean greaterThan(SObjectField field, Integer value)
Boolean greaterThan(SObjectField field, Long value)
Boolean greaterThan(SObjectField field, Double value)
Boolean greaterThan(SObjectField field, Decimal value)
Boolean greaterThan(SObjectField field, Date value)
Boolean greaterThan(SObjectField field, DateTime value)
```

`greaterThanOrEqualTo`, `lessThan` and `lessThanOrEqualTo` have the same six overloads as `greaterThan`.

- **Which row.** Value predicates read the new row. Before delete and after delete have no new row, so there they read the old row.
- **The live row in before contexts.** A value an earlier handler set with `put` counts.
- **Old values in an update.** Value predicates never read the old row; use change detection or `getOldSObject()`.

<!--@include: @/_parts/records/comparisons.md-->

## Change Detection {#change-detection}

```apex
Boolean isChanged(SObjectField field)
Boolean isAnyChanged(SObjectField field1, SObjectField field2)
Boolean isAnyChanged(Iterable<SObjectField> fields)
Boolean areAllChanged(SObjectField field1, SObjectField field2)
Boolean areAllChanged(Iterable<SObjectField> fields)
Boolean isChangedTo(SObjectField field, Object expectedValue)
Boolean isChangedFrom(SObjectField field, Object priorValue)
Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue)
```

`isAnyChanged` and `areAllChanged` also take 3, 4 or 5 fields. On `UpdateRecord` and `RejectableUpdateRecord` only, so in before update and after update.

<!--@include: @/_parts/records/change-detection.md-->

An after update Writer that acts when an opportunity is won, reading its parent account in the predicate:

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls

## Record Type {#record-type}

```apex
Boolean isRecordTypeEqual(String recordTypeDeveloperName)
Boolean isRecordTypeNotEqual(String recordTypeDeveloperName)
```

<!--@include: @/_parts/records/record-type.md-->

## Exceptions {#exceptions}

### TriggerHandlerException {#triggerhandlerexception}

`TriggerHandler.TriggerHandlerException` is public, so it can be caught by type.

| Message | Thrown by |
|---|---|
| `<Object> has no record types, so isRecordTypeEqual cannot be used on it.` (or `isRecordTypeNotEqual`) | `isRecordTypeEqual` and `isRecordTypeNotEqual` on an object that has only the master record type |
| `No related records provider is registered under <name>. Return it from the RelatedQuery method of the context first.` | `getRelated` with a name the handler's RelatedQuery method did not return |

- **Rethrown even with ContinueOnError.** When it escapes a handler, the library logs it and rethrows it, and the save fails.
- **Catch it inside the handler** if the handler should go on; the library then never sees it.
- **Callers of the DML** get a `DmlException`, or a `Database.Error` with partial success, whose message contains the original one.

The library's other exception: [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).

## Test API {#test-api}

These public members build records, collections and provider results in memory, so a unit test can call a handler's methods directly, with no DML and no trigger.

| Member | Use |
|---|---|
| `new TriggerHandler.TriggerRecord(SObject newRow, SObject oldRow)` | one record for any context; pass `null` for the side the context does not have: `oldRow` on insert and undelete, `newRow` on delete. It implements every record type above. |
| `new TriggerHandler.InsertTriggerRecords(List<TriggerHandler.TriggerRecord>)`, `UpdateTriggerRecords`, `DeleteTriggerRecords`, `UndeleteTriggerRecords` | the collection that a dispatch method, a Finalizer or a provider's `query` receives |
| `new TriggerHandler.ProvidedRecords(List<SObject>)` and `groupUnderKey(String key, SObject row)` | the `RelatedRecords` a provider would produce: the list is what `getRecords()` returns, and each `groupUnderKey` call indexes one row under its key |
| `new TriggerHandler.RandomIdGenerator().get(SObjectType)`, `get(String keyPrefix)` | a fake Id with the object's key prefix; nothing is saved |

**Public, but marked internal.** `TriggerRecord.enrichNew(relationshipName, parent)`, `enrichOld(relationshipName, parent)` and `setProvidedRecords(Map<String, TriggerHandler.RelatedRecords>)` attach parents and provider results to a record, so `getNewParent`, `getOldParent` and `getRelated` return them. Tests need them, but `TriggerHandler` lists them under an `// Internal use only` comment, so they may change in a later version. See [Testing](/guide/testing).

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

## Internal Members {#internals}

These are public because the library calls them across its own classes. They are not meant for handler or test code and may change without notice:

- `TriggerHandler.getTriggerRecordsFrom(newRows, oldRows)`;
- `TriggerHandler.LookupSelector`, the class behind `TriggerHandler.ParentFields`; start selections from the `TriggerHandler.ParentFields` property;
- `ParentFields.getFields()`;
- `TriggerRecord.getSObject()`, `getParent(relationshipName)`, `getNewParentId(field)` and `getOldParentId(field)`.

## See Also {#see-also}

- [Record Collections](/api/record-collections): the bulk view that providers, dispatch methods and Finalizers receive
- [TriggerHandler.ParentFields](/api/field-selection) and [RelatedRecords & RecordsProvider](/api/related-records)
- [Contexts at a Glance](/contexts#facts): what each context allows
