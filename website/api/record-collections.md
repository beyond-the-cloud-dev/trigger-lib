---
description: 'Record Collections reference: InsertRecords, UpdateRecords, DeleteRecords and UndeleteRecords, the bulk view that a RecordsProvider query, a Dispatcher and a Finalizer receive, with getIds, getIdsOf, getValuesOf, getOldIdsOf, getRecords and size.'
---

# Record Collections

The bulk view of the chunk's records, to collect Ids and values for one bulk query.

## Where You Get One {#where}

- **`query(records)`** of a RecordsProvider gets every record in the chunk.
- **`dispatchOn<Ctx>(records)`** of a Dispatcher gets the records its predicate qualified.
- **`finalize<Ctx>(records)`** of a Finalizer gets the records its predicate qualified.

The type follows the context: `InsertRecords` in the insert contexts, `UpdateRecords` in the update contexts, `DeleteRecords` in the delete contexts and `UndeleteRecords` in after undelete.

## Interfaces {#interfaces}

**Signature**

```apex
public interface InsertRecords {
    Set<Id> getIds();

    Set<Id> getIdsOf(SObjectField field);
    Set<Id> getIdsOf(String relationshipName, SObjectField field);

    Set<String> getValuesOf(SObjectField field);
    Set<String> getValuesOf(String relationshipName, SObjectField field);

    List<TriggerHandler.InsertRecord> getRecords();

    Integer size();
}

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

`DeleteRecords` and `UndeleteRecords` have the methods of `InsertRecords`, with their own record type in `getRecords()`.

## Methods {#methods}

| Method | Returns |
|---|---|
| `getIds()` | the record Ids; empty in before insert |
| `getIdsOf(field)` | the values of an Id or lookup field |
| `getValuesOf(field)` | the values of any field, as text |
| `getIdsOf(relationshipName, field)`, `getValuesOf(relationshipName, field)` | the same, read from each record's loaded parent |
| `getOldIdsOf(…)`, `getOldValuesOf(…)` | the same, read from the old row or from the parent PriorParentQuery loaded |
| `getRecords()` | the records |
| `size()` | the number of records |

- **They read the new row.** In the delete contexts they read the old row.
- **No nulls, no duplicates.** Each call returns a new set.
- **Parents by relationship name.** Pass the name `getNewParent` takes, such as `'Account'`. A record without a loaded parent adds nothing.
- **Ids only from Id fields.** `getIdsOf` throws on a field that does not hold Ids, such as `Contact.Email`. Use `getValuesOf` there.
- **Do not change `getRecords()`.** It is the library's own list, not a copy. Call `.clone()` before you add or remove elements.

**Example**

```apex
private without sharing class ExistingEmailsProvider implements BeforeInsert.RecordsProvider {
    public List<SObject> query(TriggerHandler.InsertRecords records) {
        return [SELECT Id, Email FROM Contact WHERE Email IN :records.getValuesOf(Contact.Email)];
    }

    public String keyOf(SObject record) {
        return ((Contact) record).Email?.toLowerCase();
    }
}
```
