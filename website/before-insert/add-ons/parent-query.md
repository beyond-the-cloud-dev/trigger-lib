---
template: add-on
context: BeforeInsert
interface: ParentQuery
description: Read parent (lookup) fields in a before insert Populator or Validator without writing SOQL.
---

# BeforeInsert.ParentQuery

Reads fields of the record a lookup points to, such as a contact's account, without SOQL in your handler. The row being inserted holds only the lookup Id.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/before-insert/populator/AccountParentDefaultsPopulator.cls [In a Populator]

<<< @/../examples/main/default/classes/account/before-insert/validator/AccountParentTypeValidator.cls [In a Validator]

:::

## Good to Know {#good-to-know}

- **Read by relationship name.** Use `getNewParent('Account')` for `AccountId` and `getNewParent('Parent')` for `ParentId`. The name is case-sensitive.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per lookup.** Each declared lookup costs one SOQL query per chunk, even when no record qualifies. When a Populator re-points a lookup to a parent not loaded yet, one more query loads it.
- **No sharing.** Parents are read in system mode, so a handler can see records the user cannot.
