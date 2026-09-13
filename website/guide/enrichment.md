---
outline: deep
---

# Parent Enrichment

Handlers often need data from a parent record: the account of a contact, the owner of an opportunity. Instead of querying inside the handler, declare the lookup field and the parent fields you need. The framework queries them once and attaches the parent record to every trigger record.

## Freshness

Parents are resolved before the first handler runs. In **before insert** and **before update** they are also re-checked at every handler boundary, because those are the only contexts in which a handler can change a record.

If a handler there changes a declared lookup field, the next handler sees the parent the record now points at. A lookup moved from one parent to another resolves to the new one; a lookup filled in from empty resolves instead of staying null.

The re-check costs nothing when nothing changed. When a lookup has changed, the framework issues **one** additional query for that lookup field, covering every record whose value changed, and only for parents it has not already loaded. Re-pointing two hundred records to two hundred different parents is one query, not two hundred. Pointing a record at a parent already loaded for another record is free.

Every other context resolves parents exactly once. After insert, after update, the delete contexts and after undelete cannot change a record, so there is nothing to re-check and no work is done between handlers.

The old side is never refreshed in any context. `Trigger.old` is immutable, so `getOldRelated` is resolved on the first pass and never looked at again.


## Declaring Fields

Implement `NewRecordEnrichment` and return a map from the lookup field on the triggering object to a [`TriggerHandler.FieldSelection`](/api/field-selection) listing the parent fields.

```apex
public with sharing class ContactAccountHandler implements AfterInsert.Handler, AfterInsert.NewRecordEnrichment {
  public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert() {
    return new Map<SObjectField, TriggerHandler.FieldSelection>{
      Contact.AccountId => TriggerHandler.FieldSelection.with(
        Account.Name,
        Account.Industry,
        Account.BillingCountry
      ),
      Contact.CreatedById => TriggerHandler.FieldSelection.with(
        User.Name,
        User.Email
      )
    };
  }

  public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
    return record.isNotNull(Contact.AccountId);
  }

  public void onAfterInsert(TriggerHandler.InsertRecord record) {
    Account account = (Account) record.getNewRelated('Account');
    User creator = (User) record.getNewRelated('CreatedBy');

    // ...
  }
}
```

The map key is the lookup field. The parent object is taken from the field describe, so `Contact.AccountId` resolves to `Account` and `Contact.CreatedById` to `User`.

::: warning Polymorphic lookups
A polymorphic lookup resolves to the **first** type in its describe. `OwnerId` on objects with queues enabled, such as `Case` or `Lead`, lists `Group` before `User`, so the query runs against `Group` and user owners come back as `null`. On objects without queues, such as `Contact`, `OwnerId` resolves to `User` and works as expected.
:::

## Reading Parents

`getNewRelated(relationshipName)` returns the parent record attached to the new version of the trigger record. The relationship name is the one from the field describe: `Account` for `AccountId`, `CreatedBy` for `CreatedById`, `Custom_Object__r` for `Custom_Object__c`.

Only the declared fields are populated on the returned SObject. Reading any other field raises the platform's usual `SObjectException` for an unqueried field.

`getNewRelated` returns `null` in every case where no parent was attached:

- The relationship was never declared. **No query is issued for an undeclared relationship**, so this is a silent `null`, not an error. A typo in the relationship name string behaves the same way.
- The lookup is empty on that record. An unset lookup fetches nothing: the record contributes no Id to the query, no parent is attached to it, and no error is raised.
- The lookup points at a record that the query did not return.

Always null-check, or use safe navigation:

```apex
Account account = (Account) record.getNewRelated('Account');
String industry = account?.Industry;
```

## Nested Relationships

`FieldSelection.with(relationshipName, fields...)` adds fields through a further relationship on the parent.

```apex
Contact.AccountId => TriggerHandler.FieldSelection
    .with(Account.Name, Account.Industry)
    .with('Owner', User.Name, User.Email)
    .with('Parent', Account.Name)
```

```apex
Account account = (Account) record.getNewRelated('Account');
String ownerEmail = account.Owner.Email;
String parentName = account.Parent?.Name;
```

## Old Record Enrichment

Update and delete contexts also have an old version of the record. Implement `OldRecordEnrichment` when the handler needs the parent the record pointed to before the change, and read it with `getOldRelated`.

```apex
public with sharing class ContactAccountMoveHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.OldRecordEnrichment {
  public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
    return new Map<SObjectField, TriggerHandler.FieldSelection>{
      Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name)
    };
  }

  public Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnAfterUpdate() {
    return new Map<SObjectField, TriggerHandler.FieldSelection>{
      Contact.AccountId => TriggerHandler.FieldSelection.with(Account.Name)
    };
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isChanged(Contact.AccountId);
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    Account previousAccount = (Account) record.getOldRelated('Account');
    Account currentAccount = (Account) record.getNewRelated('Account');

    // ...
  }
}
```

The two sides are declared independently. Declaring `Contact.AccountId` on the new side only attaches a parent to the new record; `getOldRelated('Account')` still returns `null` until the old side declares it too.

Which side is available depends on the context, and so does the record interface the handler methods receive:

| Context        | Record interface                 | `NewRecordEnrichment` | `OldRecordEnrichment` |
| -------------- | -------------------------------- | :-------------------: | :-------------------: |
| Before Insert  | `TriggerHandler.InsertRecord`    |          ✅           |                       |
| After Insert   | `TriggerHandler.InsertRecord`    |          ✅           |                       |
| Before Update  | `TriggerHandler.UpdateRecord`    |          ✅           |          ✅           |
| After Update   | `TriggerHandler.UpdateRecord`    |          ✅           |          ✅           |
| Before Delete  | `TriggerHandler.DeleteRecord`    |                       |          ✅           |
| After Delete   | `TriggerHandler.DeleteRecord`    |                       |          ✅           |
| After Undelete | `TriggerHandler.UndeleteRecord`  |          ✅           |                       |

The record interfaces only expose the side that exists in their context. `InsertRecord` and `UndeleteRecord` have `getNewRelated` and no `getOldRelated`; `DeleteRecord` has `getOldRelated` and no `getNewRelated`; `UpdateRecord` has both. Calling the missing one is a compile error, not a `null`.

## One Query Per Lookup

Enrichment runs once, before any handler in the context executes.

1. The field selections of every **active** handler in the context are merged per lookup field. Handlers filtered out by a [bypass](/guide/bypasses) are already gone at this point and contribute nothing.
2. One query is executed per lookup field, with the parent Ids gathered from the new and old records of the whole invocation.
3. A lookup with no populated value on any record in the invocation is not queried at all.
4. Queries run in system mode without sharing, so enrichment does not depend on the running user's access to the parent.

The cost is **one query per declared lookup field per trigger invocation**, whatever the number of handlers or records. Five handlers declaring `Contact.AccountId` over 200 contacts still produce a single `Account` query, carrying the union of the fields they asked for.

## Declarations Are Pooled

The merged declarations are applied to the shared trigger records, so any active handler can read any relationship that any other active handler declared, even one it never declared itself.

```apex
// AccountNameHandler declares Contact.AccountId => Account.Name
// ContactOwnerHandler declares nothing, but still gets the parent:
public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    Account account = (Account) record.getNewRelated('Account');
}
```

This is convenient, and it is fragile. The parent is only there while the handler that declared it is active. Bypass that handler, remove it from the orchestrator list, or move it to another context, and `getNewRelated` starts returning `null` in a handler that was never touched. Declare what you read.

## Enrichment and Qualification

Enrichment happens once up front, for every trigger record in the invocation, not only the ones a handler ends up qualifying. Qualification is evaluated later, at each handler's own turn. That ordering is what lets a `...When` predicate read parent data:

```apex
public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    Account account = (Account) record.getNewRelated('Account');

    return account?.Industry == 'Technology';
}
```

::: tip
Enrichment uses the bundled [SOQL Lib](https://soql.beyondthecloud.dev) `SOQL` class to build and execute the queries.
:::
