---
outline: deep
---

# TriggerHandler.Record

The record passed to every handler method. It wraps the new and old versions of one trigger record together with the enriched parent records.

Predicates read the new record. In delete contexts, where there is no new record, they read the old one.

## Accessors

### getId

```apex
Id getId()
```

Id of the record. `null` in before insert.

### getNewSObject

```apex
SObject getNewSObject()
```

The `Trigger.new` record. `null` in delete contexts. Writable in before contexts.

```apex
Contact contact = (Contact) record.getNewSObject();
```

### getOldSObject

```apex
SObject getOldSObject()
```

The `Trigger.old` record. `null` in insert and undelete contexts.

### getNewRelated

```apex
SObject getNewRelated(String relationshipName)
```

Parent record enriched for the new version of the record. Requires `NewRecordEnrichment`. Returns `null` when the lookup is empty or the parent was not declared.

```apex
Account account = (Account) record.getNewRelated('Account');
```

### getOldRelated

```apex
SObject getOldRelated(String relationshipName)
```

Parent record enriched for the old version of the record. Requires `OldRecordEnrichment`.

### put

```apex
Record put(SObjectField field, Object value)
```

Sets a field on the new record. Use it in before contexts. Returns the record for chaining.

```apex
record.put(Contact.Description, 'Populated by trigger').put(Contact.LeadSource, 'Web');
```

## Record Type

### isRecordTypeEqual

```apex
Boolean isRecordTypeEqual(String recordTypeDeveloperName)
```

### isRecordTypeNotEqual

```apex
Boolean isRecordTypeNotEqual(String recordTypeDeveloperName)
```

Compare `RecordTypeId` with the record type resolved by developer name from the object describe.

```apex
record.isRecordTypeEqual('Business_Contact')
```

## Value Predicates

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

### endsWith

```apex
Boolean endsWith(SObjectField field, String value)
```

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

Available for `Integer`, `Long`, `Double`, `Decimal`, `Date` and `DateTime` values. All return `false` when the field is `null`.

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
Boolean lessThan(SObjectField field, Double value)
Boolean lessThan(SObjectField field, Decimal value)
Boolean lessThan(SObjectField field, Date value)
Boolean lessThan(SObjectField field, DateTime value)
```

### lessThanOrEqualTo

```apex
Boolean lessThanOrEqualTo(SObjectField field, Integer value)
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

Compare the new and old record. Use them in before update and after update only.

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

### areAllChanged

```apex
Boolean areAllChanged(SObjectField field1, SObjectField field2)
Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3)
Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
Boolean areAllChanged(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
Boolean areAllChanged(Iterable<SObjectField> fields)
```

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
record.isChangedFromTo(Case.Status, 'New', 'Closed')
```
