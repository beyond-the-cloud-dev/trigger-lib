---
outline: deep
---

# TriggerHandler.FieldSelection

Describes which fields to query on a parent record during [enrichment](/guide/enrichment). A new selection starts from the `TriggerHandler.FieldSelection` static property and every `with` call returns the same selection, so calls chain.

```apex
public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
    return new Map<SObjectField, TriggerHandler.FieldSelection>{
        Contact.AccountId => TriggerHandler.FieldSelection
            .with(Account.Name, Account.Industry)
            .with('Owner', User.Name, User.Email)
    };
}
```

The map key is the lookup field on the triggering object. The fields in the selection belong to the parent object that lookup points to.

## Methods

### with

Adds fields of the parent object.

**Signatures**

```apex
FieldSelection with(SObjectField field)
FieldSelection with(SObjectField field1, SObjectField field2)
FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3)
FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
FieldSelection with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
FieldSelection with(Iterable<SObjectField> fields)
```

**Example**

```apex
TriggerHandler.FieldSelection.with(Account.Name, Account.Industry, Account.BillingCountry)
```

```apex
TriggerHandler.FieldSelection.with(new List<SObjectField>{ Account.Name, Account.Industry })
```

### with relationship

Adds fields reached through a relationship on the parent object. `relationshipName` is the relationship name on the parent, for example `Owner`, `Parent` or `Custom_Lookup__r`.

**Signatures**

```apex
FieldSelection with(String relationshipName, SObjectField field)
FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2)
FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3)
FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
FieldSelection with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
FieldSelection with(String relationshipName, Iterable<SObjectField> fields)
```

**Example**

```apex
Contact.AccountId => TriggerHandler.FieldSelection
    .with(Account.Name)
    .with('Owner', User.Name, User.Email)
    .with('Parent', Account.Name)
```

```apex
Account account = (Account) record.getNewRelated('Account');
String ownerEmail = account.Owner.Email;
String parentName = account.Parent?.Name;
```

## Merging

Selections from all active handlers of the same context are merged per lookup field, so one query on the parent object serves every handler. Declaring the same field twice is harmless.

## Id

The parent `Id` is always populated on the returned record. There is no need to add it to the selection.
