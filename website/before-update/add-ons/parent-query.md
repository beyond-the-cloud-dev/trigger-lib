---
template: add-on
context: BeforeUpdate
interface: ParentQuery
description: Read parent (lookup) fields in a before update Populator or Validator without writing SOQL, including a lookup the user just changed.
---

# BeforeUpdate.ParentQuery

Reads fields of the record a lookup points to now, such as a contact's account, without SOQL in your handler. It follows a lookup the user just changed.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityAccountMoveValidator.cls [In a Validator]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [In a Populator]

:::

## Good to Know {#good-to-know}

- **Read by relationship name.** Use `getNewParent('Account')` for `AccountId` and `getNewParent('Parent')` for `ParentId`. The name is case-sensitive. The parent is null when the lookup is empty or no record has that Id.
- **Later handlers see the new parent.** When a Populator changes the lookup, every handler listed after it gets the new parent.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per lookup.** Each declared lookup costs one SOQL query per chunk, even when no record qualifies. A [PriorParentQuery](/before-update/add-ons/prior-parent-query) on the same lookup shares that query.
- **No sharing.** Parents are read in system mode, so a handler can see records the user cannot.
