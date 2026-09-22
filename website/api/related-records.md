---
outline: deep
---

# Related Records

Three pieces. A **provider** declares a query and a key. The framework turns it into **`TriggerHandler.RelatedRecords`**, which is what a handler reads. Both work over a **record collection**, one per context.

See [Related Records](/guide/related-records) for the guide.

## RecordsProvider

Each context class declares its own, so the collection `query` receives matches the context.

```apex
public interface RecordsProvider {
  List<SObject> query(TriggerHandler.UpdateRecords records);
  String keyOf(SObject record);
}
```

| Context        | Interface                       | Collection                       |
| -------------- | ------------------------------- | -------------------------------- |
| Before Insert  | `BeforeInsert.RecordsProvider`  | `TriggerHandler.InsertRecords`   |
| After Insert   | `AfterInsert.RecordsProvider`   | `TriggerHandler.InsertRecords`   |
| Before Update  | `BeforeUpdate.RecordsProvider`  | `TriggerHandler.UpdateRecords`   |
| After Update   | `AfterUpdate.RecordsProvider`   | `TriggerHandler.UpdateRecords`   |
| Before Delete  | `BeforeDelete.RecordsProvider`  | `TriggerHandler.DeleteRecords`   |
| After Delete   | `AfterDelete.RecordsProvider`   | `TriggerHandler.DeleteRecords`   |
| After Undelete | `AfterUndelete.RecordsProvider` | `TriggerHandler.UndeleteRecords` |

### query

Runs at most once per trigger invocation, on the first `getRelated` call for that provider. Providers with the same class and the same field values are pooled, so declaring one in several handlers still costs one query. Any SOQL is allowed: plain, SOQL Lib, a selector, more than one statement. Returning `null` counts as no records.

### keyOf

The value a record is found by. Return the record's Id, a lookup field, a text field, or a concatenation of two values. Returning `null` leaves that record out of the key index, but it still appears in `getRecords`.

A provider may implement several context interfaces and overload `query`.

## RelatedRecords

What `record.getRelated(providerName)` returns.

```apex
public interface RelatedRecords {
  SObject getFirstWhereKeyEquals(Object key);
  List<SObject> getAllWhereKeyEquals(Object key);
  List<SObject> getRecords();
  Boolean isEmpty();
}
```

| Method                   | Returns                                                                   |
| ------------------------ | ------------------------------------------------------------------------- |
| `getFirstWhereKeyEquals` | The first record whose `keyOf` equals the key, in query order, or `null`. |
| `getAllWhereKeyEquals`   | Every record whose `keyOf` equals the key. Never `null`.                  |
| `getRecords`             | Everything the query returned.                                            |
| `isEmpty`                | Whether the query returned nothing.                                       |

Keys are compared as text, so an Id and its 18 character string find the same records. Text keys are case sensitive unless `keyOf` normalises them.

`getRecords` hands back the provider's own list. Read it, do not modify it.

## Record Collections

The collection a provider's `query` receives. Four interfaces, one per record type.

```apex
public interface UpdateRecords {
  Set<Id> getIds();

  Set<Id> getIdsOf(SObjectField field);
  Set<Id> getIdsOf(String relationshipName, SObjectField field);
  Set<Id> getOldIdsOf(SObjectField field);
  Set<Id> getOldIdsOf(String relationshipName, SObjectField field);

  Set<String> getValuesOf(SObjectField field);
  Set<String> getValuesOf(String relationshipName, SObjectField field);
  Set<String> getOldValuesOf(SObjectField field);
  Set<String> getOldValuesOf(String relationshipName, SObjectField field);

  List<TriggerHandler.UpdateRecord> getRecords();

  Integer size();
}
```

`InsertRecords`, `DeleteRecords` and `UndeleteRecords` have the same methods without the four `getOld...` ones, and `getRecords` typed to their own record interface.

| Method                              | Returns                                                                |
| ----------------------------------- | ---------------------------------------------------------------------- |
| `getIds`                            | Ids of the trigger records. Empty in before insert.                    |
| `getIdsOf(field)`                   | Values of the field, as Ids.                                           |
| `getIdsOf(relationshipName, field)` | Values of a field on the enriched parent.                              |
| `getValuesOf(...)`                  | The same, as text.                                                     |
| `getOldIdsOf`, `getOldValuesOf`     | The same from the old version of the record. Update contexts only.     |
| `getRecords`                        | The record wrappers, for a query that needs a loop to build its input. |
| `size`                              | Number of trigger records.                                             |

Every extractor returns a new set, without nulls and without duplicates.

The unprefixed methods read the new version of the record, and in the delete contexts the old one, the same rule the [record predicates](/api/record#which-side-predicates-read) follow.

The relationship name is the one [`getNewParent`](/api/record#getnewparent) takes, so `Account` for `Contact.AccountId`. A nested path such as `Account.Owner` works when the parent declaration selected it. A relationship nobody enriched contributes nothing.

```apex
records.getIdsOf('Account', Account.OwnerId)
```

## getRelated

On every record interface.

```apex
TriggerHandler.RelatedRecords getRelated(String providerName)
```

The argument is the name the handler used in its `RelatedQuery` map, not a relationship name. The first call runs the provider's query; later calls return the loaded records. Asking for a name the handler did not declare throws a `TriggerHandler.TriggerHandlerException`.
