---
template: add-on
context: AfterInsert
interface: ParentQuery
description: Read parent (lookup) fields in an after insert Writer or Dispatcher without writing SOQL.
---

# AfterInsert.ParentQuery

Read fields of the record a lookup points to, such as a new contact's account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/after-insert/parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [In the action]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Grandparent in the predicate]

:::

## Rules {#rules}

- **Read by lookup field.** Pass the lookup field you declared, such as `getNewParent(Contact.AccountId)` or `getNewParent(Account.OwnerId)`.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per chunk.** The first parent a handler reads runs one SOQL query on the saved records, which loads every declared parent. A chunk that reads no parent costs nothing.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
