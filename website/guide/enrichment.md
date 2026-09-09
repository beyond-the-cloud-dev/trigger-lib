---
outline: deep
---

# Parent Enrichment

Handlers often need data from a parent record: the account of a contact, the owner of an opportunity. Instead of querying inside the handler, declare the lookup field and the parent fields you need. The framework queries them once and attaches the parent record to every trigger record.

## Declaring Fields

Implement `NewRecordEnrichment` and return a map from the lookup field on the triggering object to a `TriggerHandler.FieldSelection` listing the parent fields.

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

  public Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record) {
    return record.isNotNull(Contact.AccountId);
  }

  public void onAfterInsert(TriggerHandler.Record record) {
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

The result is `null` when the lookup is empty or the parent was not found. Only the declared fields are populated on the returned SObject.

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

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChanged(Contact.AccountId);
  }

  public void onAfterUpdate(TriggerHandler.Record record) {
    Account previousAccount = (Account) record.getOldRelated('Account');
    Account currentAccount = (Account) record.getNewRelated('Account');

    // ...
  }
}
```

Which side is available depends on the context:

| Context        | `NewRecordEnrichment` | `OldRecordEnrichment` |
| -------------- | :-------------------: | :-------------------: |
| Before Insert  |          ✅           |                       |
| After Insert   |          ✅           |                       |
| Before Update  |          ✅           |          ✅           |
| After Update   |          ✅           |          ✅           |
| Before Delete  |                       |          ✅           |
| After Delete   |                       |          ✅           |
| After Undelete |          ✅           |                       |

## How Queries Are Built

1. Field selections from all non-bypassed handlers of the current context are merged per lookup field.
2. One query per lookup field is executed with the parent Ids gathered from the new and old records.
3. The query runs in system mode without sharing, so enrichment does not depend on the running user's access to the parent.
4. Lookups without any parent Id in the batch are not queried.

Two handlers declaring `Contact.AccountId` produce one query on `Account` with the union of their fields. Enrichment runs before qualification, so predicates can use parent data, and it runs for all trigger records, not only the qualified ones.

::: tip
Enrichment uses the bundled [SOQL Lib](https://soql.beyondthecloud.dev) `SOQL` class to build and execute the queries.
:::
