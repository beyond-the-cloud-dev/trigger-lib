---
description: 'TriggerHandler.ParentFields reference: choose the parent (lookup) and grandparent fields that ParentQuery and PriorParentQuery load, the lookup map key, how declarations merge, and what the parent queries cost.'
---

# TriggerHandler.ParentFields

Lists the parent (lookup) fields that a ParentQuery or PriorParentQuery add-on loads. Read the parents with `record.getNewParent(…)` or `record.getOldParent(…)`.

## Example {#example}

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls

The Writer loads the contact's account with `OwnerId`, and the account owner's `IsActive` through `with('Owner', …)`.

## The Map Key {#map-key}

The add-on method returns a `Map<SObjectField, TriggerHandler.ParentFields>`. The key is a lookup field on the trigger object. The fields belong to the object the lookup points to.

| Key | Read back with |
|---|---|
| `Contact.AccountId` | `getNewParent('Account')` |
| `Contact.OwnerId` | `getNewParent('Owner')` |
| `Invoice__c.Region__c` | `getNewParent('Region__r')` |

Read back by the lookup's relationship name. It is case-sensitive.

## Methods {#methods}

```apex
ParentFields with(SObjectField field)
ParentFields with(String relationshipName, SObjectField field)
```

Both take up to five fields, or an `Iterable<SObjectField>`.

```apex
Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name).with('Owner', User.Email)
```

- **Start from `TriggerHandler.ParentFields`.** Each read returns a new, empty selection. Every `with` returns the selection, so calls chain.
- **Grandparents.** `with('Owner', User.Email)` loads the parent's owner. Read it as `parentAccount.Owner.Email`.

## What Is Loaded {#what-is-loaded}

- **The declared fields and the `Id`.** Reading any other field throws an `SObjectException`.
- **Declare what you read.** Declarations of all handlers are merged, so a handler may see another handler's fields. If that handler is switched off, the field is gone. Declare every field in the handler that reads it.
- **Every record, qualified or not.** Parents load before any predicate runs, so the query costs SOQL even when nothing qualifies.
- **Once per chunk.** The parent queries run per chunk, never per record. When a Populator points a lookup to a parent not loaded yet, one more query loads it.
- **No sharing.** Parents are read in system mode, so a handler can see records and fields the user cannot.
- **Polymorphic lookups are limited.** For `WhatId`, `WhoId` or an `OwnerId` that can hold a queue, some parents come back null. In after insert, after update and after undelete, a field outside the `Name` object makes the query fail.
