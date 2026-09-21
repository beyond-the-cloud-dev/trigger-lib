---
outline: deep
---

# TriggerHandler.ParentFields

Describes which fields to query on a parent record during [enrichment](/guide/enrichment). A new selection starts from the `TriggerHandler.ParentFields` static property and every `with` call returns the same selection, so calls chain.

```apex
public with sharing class ContactAccountHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment {
  public Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnAfterUpdate() {
    return new Map<SObjectField, TriggerHandler.ParentFields>{
      Contact.AccountId => TriggerHandler.ParentFields
        .with(Account.Name, Account.Industry)
        .with('Owner', User.Name, User.Email)
    };
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.getNewRelated('Account') != null;
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    Account account = (Account) record.getNewRelated('Account');

    System.debug(account.Name + ' owned by ' + account.Owner.Email);
  }
}
```

Reading the `TriggerHandler.ParentFields` property hands back a new, empty selection every time, so each map entry starts from scratch.

## The Map Key

The map key is the lookup field on the triggering object. The fields in the selection belong to the parent object that lookup points to.

The key also decides the name the parent is read back under. The framework uses the relationship name of the lookup, so `Contact.AccountId` is read with `getNewRelated('Account')` and a custom lookup `My_Lookup__c` with `getNewRelated('My_Lookup__r')`.

| Declared key         | Parent object queried | Read back with              |
| -------------------- | --------------------- | --------------------------- |
| `Contact.AccountId`  | `Account`             | `getNewRelated('Account')`  |
| `Contact.OwnerId`    | `User`                | `getNewRelated('Owner')`    |
| `Contact.CreatedById`| `User`                | `getNewRelated('CreatedBy')`|

`OldRecordEnrichment` uses the same keys and the same names, read with `getOldRelated`. Declaring a lookup on one side does not declare it on the other.

## Methods

### with

Adds fields of the parent object.

**Signatures**

```apex
ParentFields with(SObjectField field)
ParentFields with(SObjectField field1, SObjectField field2)
ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3)
ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
ParentFields with(Iterable<SObjectField> fields)
```

**Example**

```apex
TriggerHandler.ParentFields.with(Account.Name, Account.Industry, Account.BillingCountry)
```

```apex
TriggerHandler.ParentFields.with(new List<SObjectField>{ Account.Name, Account.Industry })
```

### with relationship

Adds fields reached through a relationship on the parent object. `relationshipName` is the relationship name on the parent, for example `Owner`, `Parent` or `Custom_Lookup__r`.

**Signatures**

```apex
ParentFields with(String relationshipName, SObjectField field)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
ParentFields with(String relationshipName, Iterable<SObjectField> fields)
```

Each field is added to the query as `relationshipName.Field`, so it is read by traversing the parent record that comes back. The relationship name does not change how the parent itself is read back, only what it carries.

**Example**

```apex
Contact.AccountId => TriggerHandler.ParentFields
  .with(Account.Name)
  .with('Owner', User.Name, User.Email)
  .with('Parent', Account.Name)
```

```apex
Account account = (Account) record.getNewRelated('Account');
String ownerEmail = account.Owner.Email;
String parentName = account.Parent?.Name;
```

### getFields

```apex
List<String> getFields()
```

Used by the framework to build the query. Handlers have no reason to call it.

## Merging

Selections from all handlers that run in the same context are merged per lookup field, so one query on the parent object serves every handler. Declaring the same field twice is harmless. A handler that is [bypassed](/guide/bypasses) contributes nothing, because bypassed handlers are removed before enrichment runs.

Parents are fetched for every record in the invocation, before any qualification predicate is evaluated. That is what makes the parents readable inside the predicates, and it means the query cost does not depend on how many records qualify.

## Id

The parent `Id` is always populated on the returned record. There is no need to add it to the selection.
