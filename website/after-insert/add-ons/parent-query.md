---
template: add-on
context: AfterInsert
interface: ParentQuery
description: Read parent (lookup) fields in an after insert Writer or Dispatcher without writing SOQL.
---

# AfterInsert.ParentQuery

Reads fields of the record a lookup points to, such as a new contact's account, without SOQL in your handler. The saved row holds only the lookup Id.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [In the action]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Grandparent in the predicate]

:::

## Good to Know {#good-to-know}

- **Read by relationship name.** Use `getNewParent('Account')` for `AccountId` and `getNewParent('Owner')` for `OwnerId`. The name is case-sensitive.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per chunk.** One SOQL query on the saved records loads every declared parent, even when no record qualifies.
- **No sharing.** Parents are read in system mode, so a handler can see records the user cannot.
