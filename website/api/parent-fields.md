---
description: 'TriggerTypes.ParentFields reference: choose the parent (lookup) and grandparent fields that ParentQuery and PriorParentQuery load, the lookup map key, how declarations merge, and what the parent queries cost.'
---

# TriggerTypes.ParentFields

Lists the parent (lookup) fields a ParentQuery or PriorParentQuery add-on loads. Read the parents with `record.getNewParent(…)` or `record.getOldParent(…)`.

**Example**

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls

## The Map Key {#map-key}

The add-on method returns a `Map<SObjectField, TriggerTypes.ParentFields>`. The key is a lookup field on the trigger object, and the fields belong to the object it points to.

Read the parent back with the same key, such as `record.getNewParent(Contact.AccountId)`.

## Methods {#methods}

**Signature**

```apex
ParentFields with(SObjectField field)
ParentFields with(String relationshipName, SObjectField field)
```

Both take up to five fields, or an `Iterable<SObjectField>`.

**Example**

```apex
Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name).with('Owner', User.Email)
```

- **Start from `TriggerTypes.ParentFields`.** Every `with` returns the selection, so calls chain.
- **Grandparents.** `with('Owner', User.Email)` loads the parent's owner. Read it as `parentAccount.Owner.Email`.

## What Is Loaded {#what-is-loaded}

- **The declared fields and the `Id`.** Reading any other field throws an `SObjectException`.
- **Declare what you read.** Declarations of all handlers are merged, so a handler may see another handler's fields. If that handler is switched off, the field is gone. Declare every field in the handler that reads it.
- **Every record, qualified or not.** The first read of a lookup's parent loads the parents of every record in the chunk. A lookup whose parent no handler reads costs no SOQL.
- **Once per chunk.** The parent queries run per chunk, never per record.
- **No sharing.** Parents are read in system mode, so a handler can see records and fields the user cannot.
- **Polymorphic lookups are limited.** For `WhatId`, `WhoId` or an `OwnerId` that can hold a queue, some parents come back null. In after insert, after update and after undelete, a field outside the `Name` object makes the query fail.
