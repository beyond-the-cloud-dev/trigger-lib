---
outline: deep
---

# Record Interfaces

Every handler method receives one trigger record, wrapped so the handler never touches `Trigger.new` or `Trigger.old` directly. The wrapper holds the new and old versions of that record together with the parent records declared through [enrichment](/guide/enrichment).

There is no single `Record` type. Each context passes the interface that matches what that context actually has:

| Context        | Interface                      |
| -------------- | ------------------------------ |
| Before Insert  | `TriggerHandler.InsertRecord`  |
| After Insert   | `TriggerHandler.InsertRecord`  |
| Before Update  | `TriggerHandler.UpdateRecord`  |
| After Update   | `TriggerHandler.UpdateRecord`  |
| Before Delete  | `TriggerHandler.DeleteRecord`  |
| After Delete   | `TriggerHandler.DeleteRecord`  |
| After Undelete | `TriggerHandler.UndeleteRecord` |

A handler method must declare the interface of its own context. `populateOnBeforeInsert` takes an `InsertRecord`, `onAfterUpdate` takes an `UpdateRecord`, and so on. Using the wrong one does not compile.

The same object is behind all four interfaces at runtime. The interface is what narrows it: a delete handler cannot ask for the new record because `DeleteRecord` does not declare that method, and no delete or undelete handler can write to the record because neither interface declares `put`.

## Method Availability

| Method                                                                           | `InsertRecord` | `UpdateRecord` | `DeleteRecord` | `UndeleteRecord` |
| -------------------------------------------------------------------------------- | :------------: | :------------: | :------------: | :--------------: |
| `getId`                                                                           |       ✅       |       ✅       |       ✅       |        ✅        |
| `getNewSObject`                                                                   |       ✅       |       ✅       |                |        ✅        |
| `getOldSObject`                                                                   |                |       ✅       |       ✅       |                  |
| `getNewRelated`                                                                   |       ✅       |       ✅       |                |        ✅        |
| `getOldRelated`                                                                   |                |       ✅       |       ✅       |                  |
| `put`                                                                             |       ✅       |       ✅       |                |                  |
| Record type: `isRecordTypeEqual`, `isRecordTypeNotEqual`                          |       ✅       |       ✅       |       ✅       |        ✅        |
| Value predicates: `equals` … `isFalse`                                            |       ✅       |       ✅       |       ✅       |        ✅        |
| Comparison predicates: `greaterThan` … `lessThanOrEqualTo`                        |       ✅       |       ✅       |       ✅       |        ✅        |
| Change predicates: `isChanged`, `isAnyChanged`, `areAllChanged`, `isChangedTo`, `isChangedFrom`, `isChangedFromTo` |                |       ✅       |                |                  |

Change detection exists only on `UpdateRecord`, because update is the only context with both sides of the record.

## Which Side Predicates Read

Every predicate except the change predicates reads the new record. `DeleteRecord` has no new record, so there the same predicates read the old one. The change predicates compare the new value with the old value.

```apex
public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
  return record.equals(Contact.LeadSource, 'Web');
}
```

`Contact.LeadSource` is read from the deleted row.

## Evaluation Order

Parent enrichment runs once, up front, before any handler executes, so `getNewRelated` and `getOldRelated` are populated inside qualification predicates as well as inside actions.

Qualification is not a global pass. Each handler qualifies its records at its own turn, immediately before it runs. A predicate therefore observes field writes made by handlers registered earlier in the orchestrator's list, and the order of that list is part of the behaviour, not a formatting choice.

## Accessors

### getId

```apex
Id getId()
```

Available on all four interfaces. Id of the record. `null` in before insert, where the record has not been assigned one yet.

### getNewSObject

```apex
SObject getNewSObject()
```

Available on `InsertRecord`, `UpdateRecord` and `UndeleteRecord`.

The `Trigger.new` record. Writable in before contexts, read-only in after contexts.

```apex
Contact contact = (Contact) record.getNewSObject();
```

### getOldSObject

```apex
SObject getOldSObject()
```

Available on `UpdateRecord` and `DeleteRecord`.

The `Trigger.old` record, always read-only.

```apex
Contact oldContact = (Contact) record.getOldSObject();
```

### getNewRelated

```apex
SObject getNewRelated(String relationshipName)
```

Available on `InsertRecord`, `UpdateRecord` and `UndeleteRecord`.

The parent record fetched for the new version of the record. Requires the context's `NewRecordEnrichment` interface. `relationshipName` is the relationship name of the lookup, so `Contact.AccountId` is read back as `'Account'` and a custom lookup `My_Lookup__c` as `'My_Lookup__r'`.

```apex
Account account = (Account) record.getNewRelated('Account');
```

Returns `null` when the lookup is empty on that record, and `null` when the handler never declared that lookup. Nothing is queried for an undeclared relationship.

### getOldRelated

```apex
SObject getOldRelated(String relationshipName)
```

Available on `UpdateRecord` and `DeleteRecord`.

The parent record fetched for the old version of the record. Requires the context's `OldRecordEnrichment` interface. A handler that wants both sides of the same lookup has to declare it on both sides.

```apex
Account priorAccount = (Account) record.getOldRelated('Account');
```

### put

```apex
void put(SObjectField field, Object value)
```

Available on `InsertRecord` and `UpdateRecord`.

Sets a field on the new record. It returns nothing, so calls do not chain. Write one statement per field.

```apex
public with sharing class ContactDefaultsPopulator implements BeforeInsert.Populator {
  public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
    return record.isBlank(Contact.Description);
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Contact.Description, 'Populated by trigger');
    record.put(Contact.LeadSource, 'Web');
  }
}
```

The value is visible to every handler that runs after this one, including in their qualification predicates, and it persists with the record without any DML.

::: danger put in an after context
`put` belongs to before insert and before update. `InsertRecord` and `UpdateRecord` serve both phases of their context, so the compiler cannot stop you from calling it in after insert or after update.

Calling it there raises `System.FinalException: Record is read-only`. That exception is uncatchable. The handler's own `try` and `catch` cannot stop it, `ContinueOnError` cannot swallow it, and the whole transaction is lost.

In after contexts, collect the records you want to change and update them from a [finalizer](/guide/finalizers).
:::

## Record Type

### isRecordTypeEqual

```apex
Boolean isRecordTypeEqual(String recordTypeDeveloperName)
```

### isRecordTypeNotEqual

```apex
Boolean isRecordTypeNotEqual(String recordTypeDeveloperName)
```

Available on all four interfaces. Both compare the record's `RecordTypeId` with the id resolved from the object describe for that developer name.

```apex
public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
  return record.isRecordTypeEqual('Business_Contact');
}
```

::: warning Objects without record types
On an SObject that has no record types beyond Master, both methods throw `TriggerHandler.TriggerHandlerException` naming the SObject, rather than letting a raw `SObjectException: Invalid field RecordTypeId` escape.

Like the framework's own exceptions, it is not suppressed by `ContinueOnError`. It is logged and rethrown, and the DML is aborted.
:::

## Value Predicates

Available on all four interfaces.

### equals

```apex
Boolean equals(SObjectField field, Object value)
```

### doesNotEqual

```apex
Boolean doesNotEqual(SObjectField field, Object value)
```

### contains

```apex
Boolean contains(SObjectField field, String value)
```

`false` when the field is `null`.

### doesNotContain

```apex
Boolean doesNotContain(SObjectField field, String value)
```

`true` when the field is `null`.

### startsWith

```apex
Boolean startsWith(SObjectField field, String value)
```

`false` when the field is `null`.

### endsWith

```apex
Boolean endsWith(SObjectField field, String value)
```

`false` when the field is `null`.

### isNull

```apex
Boolean isNull(SObjectField field)
```

### isNotNull

```apex
Boolean isNotNull(SObjectField field)
```

### isEmpty

```apex
Boolean isEmpty(SObjectField field)
```

`true` when the field is `null` or its string value is empty.

### isNotEmpty

```apex
Boolean isNotEmpty(SObjectField field)
```

### isBlank

```apex
Boolean isBlank(SObjectField field)
```

`true` when the field is `null`, empty or whitespace only.

### isNotBlank

```apex
Boolean isNotBlank(SObjectField field)
```

### isTrue

```apex
Boolean isTrue(SObjectField field)
```

### isFalse

```apex
Boolean isFalse(SObjectField field)
```

## Comparison Predicates

Available on all four interfaces, for `Integer`, `Long`, `Double`, `Decimal`, `Date` and `DateTime` values. All of them return `false` when the field is `null`. Numeric values are compared as `Decimal`, so `Long` values keep their precision.

### greaterThan

```apex
Boolean greaterThan(SObjectField field, Integer value)
Boolean greaterThan(SObjectField field, Long value)
Boolean greaterThan(SObjectField field, Double value)
Boolean greaterThan(SObjectField field, Decimal value)
Boolean greaterThan(SObjectField field, Date value)
Boolean greaterThan(SObjectField field, DateTime value)
```

### greaterThanOrEqualTo

```apex
Boolean greaterThanOrEqualTo(SObjectField field, Integer value)
Boolean greaterThanOrEqualTo(SObjectField field, Long value)
Boolean greaterThanOrEqualTo(SObjectField field, Double value)
Boolean greaterThanOrEqualTo(SObjectField field, Decimal value)
Boolean greaterThanOrEqualTo(SObjectField field, Date value)
Boolean greaterThanOrEqualTo(SObjectField field, DateTime value)
```

### lessThan

```apex
Boolean lessThan(SObjectField field, Integer value)
Boolean lessThan(SObjectField field, Long value)
Boolean lessThan(SObjectField field, Double value)
Boolean lessThan(SObjectField field, Decimal value)
Boolean lessThan(SObjectField field, Date value)
Boolean lessThan(SObjectField field, DateTime value)
```

### lessThanOrEqualTo

```apex
Boolean lessThanOrEqualTo(SObjectField field, Integer value)
Boolean lessThanOrEqualTo(SObjectField field, Long value)
Boolean lessThanOrEqualTo(SObjectField field, Double value)
Boolean lessThanOrEqualTo(SObjectField field, Decimal value)
Boolean lessThanOrEqualTo(SObjectField field, Date value)
Boolean lessThanOrEqualTo(SObjectField field, DateTime value)
```

```apex
record.greaterThan(Opportunity.Amount, 10000)
record.lessThan(Opportunity.CloseDate, Date.today())
```

## Change Predicates

Available on `UpdateRecord` only, in before update and after update.

They compare the current new value with the old value, so a `put` performed by an earlier before update handler counts as a change for every handler that runs after it.

### isChanged

```apex
Boolean isChanged(SObjectField field)
```

### isAnyChanged

```apex
Boolean isAnyChanged(SObjectField field1, SObjectField field2)
Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3)
Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
Boolean isAnyChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
Boolean isAnyChanged(Iterable<SObjectField> fields)
```

`true` when at least one of the fields changed.

### areAllChanged

```apex
Boolean areAllChanged(SObjectField field1, SObjectField field2)
Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3)
Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
Boolean areAllChanged(Iterable<SObjectField> fields)
```

`true` only when every one of the fields changed.

### isChangedTo

```apex
Boolean isChangedTo(SObjectField field, Object expectedValue)
```

New value equals `expectedValue` and old value did not.

### isChangedFrom

```apex
Boolean isChangedFrom(SObjectField field, Object priorValue)
```

Old value equals `priorValue` and new value does not.

### isChangedFromTo

```apex
Boolean isChangedFromTo(SObjectField field, Object fromValue, Object toValue)
```

Old value equals `fromValue` and new value equals `toValue`.

```apex
public with sharing class CaseClosureHandler implements AfterUpdate.Handler {
  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isChangedFromTo(Case.Status, 'New', 'Closed');
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    Case closedCase = (Case) record.getNewSObject();
    Case priorCase = (Case) record.getOldSObject();

    System.debug(closedCase.CaseNumber + ' moved from ' + priorCase.Status);
  }
}
```
