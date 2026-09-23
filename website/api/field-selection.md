---
description: 'TriggerHandler.ParentFields reference: choose the parent (lookup) and grandparent fields that ParentQuery and PriorParentQuery load, the lookup map key, how declarations merge, the SOQL each context spends on parents, and polymorphic lookups.'
---

# TriggerHandler.ParentFields

`TriggerHandler.ParentFields` lists the parent (lookup) fields and grandparent fields that a ParentQuery or PriorParentQuery add-on loads. The library queries them once for all handlers, and a handler reads them with `record.getNewParent(…)` or `record.getOldParent(…)`.

## Example {#example}

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls

The Writer loads the contact's Account with its `OwnerId`, and the Account owner's `IsActive` through `with('Owner', …)`, then reads them as `accountRecord.OwnerId` and `accountRecord.Owner.IsActive`.

## The Map Key {#map-key}

The ParentQuery and PriorParentQuery methods return a `Map<SObjectField, TriggerHandler.ParentFields>`. The key is a lookup or master-detail field of the trigger object; the fields in the value belong to the object that lookup points to.

| Key | Parent object queried | Read back with |
|---|---|---|
| `Contact.AccountId` | `Account` | `getNewParent('Account')` |
| `Contact.OwnerId` | `User` | `getNewParent('Owner')` |
| `Contact.ReportsToId` | `Contact` | `getNewParent('ReportsTo')` |
| `Invoice__c.Region__c` | `Region__c` | `getNewParent('Region__r')` |

- **Read back by relationship name**, the lookup's `getRelationshipName()`, case-sensitive.
- **Both sides use the same keys.** PriorParentQuery returns the same map shape, read back with `getOldParent`. Declaring a lookup on one side does not declare it on the other.

## Methods {#methods}

A selection starts from the static `TriggerHandler.ParentFields` property, which returns a new, empty selection on every read. Every `with` returns the same selection, so calls chain.

### with {#with}

Adds fields of the parent object.

```apex
ParentFields with(SObjectField field)
ParentFields with(SObjectField field1, SObjectField field2)
ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3)
ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
ParentFields with(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
ParentFields with(Iterable<SObjectField> fields)
```

```apex
TriggerHandler.ParentFields.with(Account.Name, Account.Industry, Account.BillingCountry)
```

### with Relationship {#with-relationship}

Adds fields of the record the parent points to, the grandparent. `relationshipName` is a relationship name on the parent object, such as `Owner`, `Parent` or `Region__r`, and the fields belong to the grandparent object.

```apex
ParentFields with(String relationshipName, SObjectField field)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)
ParentFields with(String relationshipName, SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)
ParentFields with(String relationshipName, Iterable<SObjectField> fields)
```

```apex
Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name).with('Owner', User.Email).with('Parent', Account.Name)
```

Each field is queried as `<relationshipName>.<field>`, so read it through the parent: `parentAccount.Owner.Email`, `parentAccount.Parent?.Name`.

`ParentFields` also declares `getFields()`, which the library uses to build the query. It is internal: [Internal Members](/api/record#internals).

## What Is Loaded {#what-is-loaded}

- **The declared fields and the parent's `Id`.** The `Id` is always selected. Reading a field that no handler declared throws an `SObjectException`.
- **Merged across handlers.** Before the first handler runs, the library merges the declarations of every handler that is not switched off, per lookup, so one query serves them all. Declaring a field twice is harmless.
- **One entry per lookup.** Two lookups to the same object, such as `OwnerId` and `CreatedById`, are loaded separately, each under its own relationship name.
- **For every record, qualified or not.** Parents are attached to every record of the chunk before any predicate runs.

## Query Cost {#query-cost}

The parent queries run once per run: per context and per 200-record chunk. None runs when no handler that is still active declares a lookup.

| Context | Queries for declared parents |
|---|---|
| before insert | one per declared lookup that has a value on at least one record; after each Populator, one more per lookup when a lookup it changed points to a parent not loaded yet |
| before update | the same, with the previous Ids of PriorParentQuery lookups in the same query per lookup |
| after insert, after undelete | one query on the trigger object that reads every declared parent through its relationship path, plus one per lookup for a parent it did not return |
| after update | as after insert, plus one per lookup for previous parents (PriorParentQuery) that are not loaded yet |
| before delete, after delete | one per declared lookup that has a value on at least one old row |

The whole run, with providers and Logger discovery: [Execution Order & Cost](/guide/execution-order#query-cost).

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

## See Also {#see-also}

- [Record API](/api/record#getnewparent): `getNewParent` and `getOldParent`
- [Record Collections](/api/record-collections): `getIdsOf('Account', …)` and `getValuesOf('Account', …)` read loaded parents in bulk

ParentQuery in each context:

<!--@include: @/_parts/generated/chips/parent-query.md-->

PriorParentQuery in each context:

<!--@include: @/_parts/generated/chips/prior-parent-query.md-->
