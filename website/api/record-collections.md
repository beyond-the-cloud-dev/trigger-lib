---
description: 'Record Collections reference: InsertRecords, UpdateRecords, DeleteRecords and UndeleteRecords, the bulk view that a RecordsProvider query, a Dispatcher and a Finalizer receive, with getIds, getIdsOf, getValuesOf, getOldIdsOf, getRecords and size.'
---

# Record Collections

A record collection is the bulk view of the trigger records (`Trigger.new`, `Trigger.old` as a list). It collects Ids and field values across the records for one bulk query, and it is what a RecordsProvider's `query`, a Dispatcher's dispatch method and a Finalizer receive.

## Where You Get One {#where}

| Method | Receives |
|---|---|
| `query(records)` of a RecordsProvider | every record in the chunk, before any predicate runs |
| `dispatchOn<Ctx>(records)` of a Dispatcher | the records its predicate qualified |
| `finalize<Ctx>(records)` of a Finalizer | the records the handler's predicate qualified |

The type follows the context: `InsertRecords` in before insert and after insert, `UpdateRecords` in the update contexts, `DeleteRecords` in the delete contexts and `UndeleteRecords` in after undelete. Each context's collection, method by method:

<!--@include: @/_parts/generated/chips/record-api/collections.md-->

## Interfaces {#interfaces}

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

`DeleteRecords` and `UndeleteRecords` have the methods of `InsertRecords`, with `getRecords()` typed `List<TriggerHandler.DeleteRecord>` and `List<TriggerHandler.UndeleteRecord>`. All four are nested in `TriggerHandler`.

## Methods {#methods}

| Method | Returns |
|---|---|
| `getIds()` | the Ids of the records; empty in before insert, where nothing has an Id yet |
| `getIdsOf(field)` | the values of an Id or lookup field on each record's row |
| `getIdsOf(relationshipName, field)` | the values of an Id or lookup field on each record's loaded parent |
| `getValuesOf(field)` | the values of any field on each record's row, as text |
| `getValuesOf(relationshipName, field)` | the values of any field on each record's loaded parent, as text |
| `getOldIdsOf(…)`, `getOldValuesOf(…)` | the same, read from the old row or from the parent loaded by PriorParentQuery; update contexts only |
| `getRecords()` | the records, typed for the context |
| `size()` | the number of records |

- **Which row.** Methods without `Old` read the new row. Before delete and after delete have no new row, so there they read the old row.
- **Which parent.** `relationshipName` is the relationship name that `getNewParent` takes, such as `'Account'`, and it is case-sensitive. Methods without `Old` read the parent loaded by ParentQuery; in the delete contexts they read the one loaded by PriorParentQuery. A record whose parent was not loaded contributes nothing.
- **Grandparents.** A dotted path such as `'Account.Owner'` walks from the parent to the record it points to. Declare that path's fields on the parent, for example `TriggerHandler.ParentFields.with('Owner', User.IsActive)`.
- **New sets, no nulls, no duplicates.** Every Ids and values method builds a new set and leaves out null values.
- **Text values.** The values methods convert each value with `String.valueOf`, so a number, date or checkbox arrives as its text form, and an Id as its 18-character form.
- **Ids only from Id fields.** `getIdsOf` casts each value to `Id`. On a field whose values are not Ids, such as `Contact.Email`, it throws; use `getValuesOf` there.

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

The records being inserted have no Ids yet, so this provider collects their emails for one query.

## getRecords Returns the Library's List {#get-records}

`getRecords()` returns the list the library works with, cast to the context's record type, not a copy.

- **In a provider's `query`**, it is the list of trigger records that this handler, and every handler after it, goes through in this run.
- **In a dispatch method or a Finalizer**, it is this handler's list of qualified records.

Read it and loop over it, but never add or remove elements: the change would reach the library's own processing. To work on a changed list, copy it first, for example with `records.getRecords().clone()`.

## See Also {#see-also}

- [Record API](/api/record): the record types in the list
- [RelatedRecords & RecordsProvider](/api/related-records): where `query` fits
- [Test API](/api/record#test-api): build a collection in a unit test with `new TriggerHandler.InsertTriggerRecords(…)` and its siblings
