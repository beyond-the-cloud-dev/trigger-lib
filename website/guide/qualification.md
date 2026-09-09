---
outline: deep
---

# Record Qualification

Every handler declares which records it works on. The framework calls `qualifiesFor...When` for each trigger record and passes only the records that return `true` to the action method. A handler with no qualified records is skipped entirely, including its finalizer.

## Predicate API

`TriggerHandler.Record` exposes a set of null-safe predicates. They read the new version of the record, or the old one in delete contexts where there is no new version.

```apex
public Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record) {
    return record.isRecordTypeEqual('Enterprise')
        && record.isChangedTo(Account.Rating, 'Hot')
        && record.isNotBlank(Account.Industry)
        && record.greaterThan(Account.AnnualRevenue, 1000000);
}
```

### Value Checks

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

### Comparisons

`greaterThan`, `greaterThanOrEqualTo`, `lessThan` and `lessThanOrEqualTo` accept `Integer`, `Long`, `Double`, `Decimal`, `Date` and `DateTime`. They return `false` when the field is `null`.

```apex
record.greaterThan(Opportunity.Amount, 50000)
record.lessThanOrEqualTo(Opportunity.CloseDate, Date.today().addDays(30))
```

### Change Detection

Change predicates compare the new and old versions of a record. Use them in before update and after update contexts.

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

```apex
public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChangedFromTo(Case.Status, 'New', 'Working')
        || record.isAnyChanged(Case.OwnerId, Case.Priority);
}
```

::: warning
Change predicates require an old record. Calling them in insert, delete or undelete contexts throws a `NullPointerException`.
:::

## Qualifying on Parent Data

Parent records are [enriched](/guide/enrichment) before qualification runs, so the predicate can read them:

```apex
public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert() {
    return new Map<SObjectField, TriggerHandler.FieldSelection>{
        Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Type)
    };
}

public Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record) {
    Account account = (Account) record.getNewRelated('Account');

    return account?.Type == 'Customer';
}
```

## Qualifying Everything

Returning `true` qualifies every record. This is a deliberate choice, and the framework still skips the handler when the trigger has no records.

```apex
public Boolean qualifiesForAfterDeleteWhen(TriggerHandler.Record record) {
    return true;
}
```

## Delete Contexts

In before delete and after delete there is no new record. Predicates such as `equals` or `isBlank` read the deleted record, and `getNewSObject()` returns `null`.
