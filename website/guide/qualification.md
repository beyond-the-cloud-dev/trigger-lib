---
outline: deep
---

# Record Qualification

Every handler declares which records it works on. The framework calls the handler's predicate once per trigger record and passes only the records that returned `true` to the handler's second method. A handler with no qualified records is skipped entirely, including its finalizer.

Each context names its predicate after what the handler does with the record:

| Context        | Interface                | Predicate                                 | Record                          |
| -------------- | ------------------------ | ----------------------------------------- | ------------------------------- |
| Before Insert  | `BeforeInsert.Populator` | `populateOnBeforeInsertWhen`              | `TriggerHandler.InsertRecord`   |
| Before Insert  | `BeforeInsert.Validator` | `errorShouldBeAttachedOnBeforeInsertWhen` | `TriggerHandler.InsertRecord`   |
| Before Update  | `BeforeUpdate.Populator` | `populateOnBeforeUpdateWhen`              | `TriggerHandler.UpdateRecord`   |
| Before Update  | `BeforeUpdate.Validator` | `errorShouldBeAttachedOnBeforeUpdateWhen` | `TriggerHandler.UpdateRecord`   |
| After Insert   | `AfterInsert.Handler`    | `qualifiesForAfterInsertWhen`             | `TriggerHandler.InsertRecord`   |
| After Update   | `AfterUpdate.Handler`    | `qualifiesForAfterUpdateWhen`             | `TriggerHandler.UpdateRecord`   |
| Before Delete  | `BeforeDelete.Handler`   | `qualifiesForBeforeDeleteWhen`            | `TriggerHandler.DeleteRecord`   |
| After Delete   | `AfterDelete.Handler`    | `qualifiesForAfterDeleteWhen`             | `TriggerHandler.DeleteRecord`   |
| After Undelete | `AfterUndelete.Handler`  | `qualifiesForAfterUndeleteWhen`           | `TriggerHandler.UndeleteRecord` |

They are all the same thing: a per-record predicate. A validator's predicate is worded the other way round, it returns `true` for the records that are **wrong** and must carry the error.

## Evaluation Order

Qualification is not a single pass over all handlers at the start of the invocation. Each handler's predicate is evaluated at that handler's own turn, immediately before that handler runs, and after every handler above it in the list has already finished.

For one handler, the framework walks the records, evaluates the predicate on each, and then runs the action for the records that qualified followed by the finalizer. Only then does it move to the next handler and start evaluating its predicate.

The consequence is that a predicate reads the record as it is right now, including fields written by earlier handlers in the same invocation.

```apex
public List<BeforeInsert.Handler> beforeInsertHandlers() {
  return new List<BeforeInsert.Handler>{
    new AccountRatingPopulator(),
    new AccountPriorityPopulator()
  };
}
```

```apex
public with sharing class AccountRatingPopulator implements BeforeInsert.Populator {
  public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
    return record.greaterThan(Account.AnnualRevenue, 1000000);
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Account.Rating, 'Hot');
  }
}
```

```apex
public with sharing class AccountPriorityPopulator implements BeforeInsert.Populator {
  public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
    return record.equals(Account.Rating, 'Hot');
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Account.Description, 'Priority account');
  }
}
```

`AccountPriorityPopulator` qualifies the records that `AccountRatingPopulator` just rated, because the rating was already written when its predicate ran. Swap the two entries in the orchestrator list and it qualifies only the records that arrived with `Rating = 'Hot'` from the caller.

::: warning
Registration order in the orchestrator's list is part of the behaviour, not presentation. Reordering handlers can change which records later handlers qualify. Treat the list as an ordered pipeline.
:::

The same applies to change detection in before update. `isChanged` compares the new record against the old one, and `put` mutates the new record. When a populator writes a value into `Account.Rating` that differs from the stored one, `isChanged(Account.Rating)` returns `true` for every handler after it, even for records where the user changed nothing.

## What Happens Before the Predicate

Two things are settled for the whole invocation before any predicate runs, and one is checked per record at the handler's own turn.

- **Bypasses**, up front. A [bypassed handler](/guide/bypasses) is dropped from the invocation. Its predicate is never called at all.
- **Parent enrichment**, up front. Parents are [queried once](/guide/enrichment) for every handler that survived the bypass step. This is the one part of the pipeline that is not per handler, and it is why predicates can read `getNewRelated` and `getOldRelated` freely.
- **Recursion depth**, at the handler's turn. In update contexts, a record that has already been through this handler the allowed number of times is skipped before the predicate is evaluated. The skip is silent: no exception, nothing reaches the logger, and the DML succeeds. See [Recursion Control](/guide/recursion-control).

## Predicate API

The record interfaces expose a set of null-safe predicates. They read the new version of the record, or the old one in delete contexts where there is no new version.

```apex
public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isRecordTypeEqual('Enterprise')
        && record.isChangedTo(Account.Rating, 'Hot')
        && record.isNotBlank(Account.Industry)
        && record.greaterThan(Account.AnnualRevenue, 1000000);
}
```

### Value Checks

Available on all four record interfaces.

| Method                        | True when                                     |
| ----------------------------- | --------------------------------------------- |
| `equals(field, value)`        | field value equals `value`                    |
| `doesNotEqual(field, value)`  | field value differs from `value`              |
| `isNull(field)`               | field is `null`                               |
| `isNotNull(field)`            | field is not `null`                           |
| `isEmpty(field)`              | field is `null` or an empty string            |
| `isNotEmpty(field)`           | field has a value with at least one character |
| `isBlank(field)`              | field is `null`, empty or whitespace only     |
| `isNotBlank(field)`           | field has a non-whitespace value              |
| `isTrue(field)`               | checkbox is checked                           |
| `isFalse(field)`              | checkbox is unchecked                         |
| `contains(field, text)`       | string field contains `text`                  |
| `doesNotContain(field, text)` | field is `null` or does not contain `text`    |
| `startsWith(field, text)`     | string field starts with `text`               |
| `endsWith(field, text)`       | string field ends with `text`                 |

### Record Type

| Method                                | True when                                             |
| ------------------------------------- | ----------------------------------------------------- |
| `isRecordTypeEqual(developerName)`    | `RecordTypeId` matches the record type developer name |
| `isRecordTypeNotEqual(developerName)` | `RecordTypeId` does not match                         |

Record type Ids are resolved from the object describe and cached per transaction. No query is made.

::: warning
Both methods throw `TriggerHandler.TriggerHandlerException` when the object has no record types beyond Master:

```
Account has no record types, so isRecordTypeEqual cannot be used on it.
```

The framework raises this instead of letting the platform report `SObjectException: Invalid field RecordTypeId`, so the message names the object you got wrong. Like every framework exception it is never suppressed: `ContinueOnError` does not swallow it, and the DML is aborted.
:::

### Comparisons

`greaterThan`, `greaterThanOrEqualTo`, `lessThan` and `lessThanOrEqualTo` accept `Integer`, `Long`, `Double`, `Decimal`, `Date` and `DateTime`. They return `false` when the field is `null`. The `Long` overloads compare without precision loss.

```apex
record.greaterThan(Opportunity.Amount, 50000)
record.lessThanOrEqualTo(Opportunity.CloseDate, Date.today().addDays(30))
```

### Change Detection

Change predicates compare the new and old versions of a record.

| Method                                  | True when                                    |
| --------------------------------------- | -------------------------------------------- |
| `isChanged(field)`                      | new value differs from old value             |
| `isAnyChanged(field1, field2, ...)`     | at least one of up to five fields changed    |
| `isAnyChanged(Iterable<SObjectField>)`  | at least one field in the collection changed |
| `areAllChanged(field1, field2, ...)`    | all of up to five fields changed             |
| `areAllChanged(Iterable<SObjectField>)` | all fields in the collection changed         |
| `isChangedTo(field, value)`             | new value is `value` and old value was not   |
| `isChangedFrom(field, value)`           | old value was `value` and new value is not   |
| `isChangedFromTo(field, from, to)`      | old value was `from` and new value is `to`   |

They exist only on `TriggerHandler.UpdateRecord`, the interface used by before update and after update. Insert, delete and undelete handlers receive an interface without them, so calling one there does not compile.

```apex
public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isChangedFromTo(Case.Status, 'New', 'Working')
        || record.isAnyChanged(Case.OwnerId, Case.Priority);
}
```

## Qualifying on Parent Data

Parent records are [enriched](/guide/enrichment) once, before any handler runs, so a predicate can read them:

```apex
public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnAfterInsert() {
    return new Map<SObjectField, TriggerHandler.ParentFields>{
        Contact.AccountId => TriggerHandler.ParentFields.with(Account.Type)
    };
}

public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
    Account account = (Account) record.getNewRelated('Account');

    return account?.Type == 'Customer';
}
```

`getNewRelated` returns `null` for a relationship the handler never declared, and for records whose lookup is empty. No query is issued in either case, so the null check belongs in the predicate.

## Qualifying Everything

Returning `true` qualifies every record. This is a deliberate choice, and the framework still skips the handler when the trigger has no records.

```apex
public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
    return true;
}
```

## Delete Contexts

In before delete and after delete there is no new record. `TriggerHandler.DeleteRecord` exposes `getOldSObject` and `getOldRelated` only, and predicates such as `equals` or `isBlank` read the deleted row.

```apex
public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
    return record.equals(Opportunity.StageName, 'Closed Won');
}
```

After undelete is the mirror image. `TriggerHandler.UndeleteRecord` exposes the new side only, and the old side is empty.

## Merge

A merge deletes the losing records, so before delete and after delete fire for them like any other delete. The deleted row carries `MasterRecordId`, the Id of the record that won the merge, which is how a delete handler detects a merge and reaches the winner.

```apex
public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
    return record.isNotNull(Contact.MasterRecordId);
}

public void onAfterDelete(TriggerHandler.DeleteRecord record) {
    Id winnerId = (Id) record.getOldSObject().get(Contact.MasterRecordId);

    // ...
}
```
