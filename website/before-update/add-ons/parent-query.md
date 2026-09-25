---
template: add-on
context: BeforeUpdate
interface: ParentQuery
description: Read parent (lookup) fields in a before update Populator or Validator without writing SOQL, including a lookup the user just changed.
---

# BeforeUpdate.ParentQuery

Read fields of the record a lookup points to, such as a contact's current account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/before-update/parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityAccountMoveValidator.cls [In a Validator]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [In a Populator]

:::

## Rules {#rules}

- **Read by lookup field.** Pass the lookup field you declared, such as `getNewParent(Contact.AccountId)` or `getNewParent(Account.ParentId)`. The parent is null when the lookup is empty or no record has that Id.
- **Later handlers see the new parent.** When a Populator changes the lookup, handlers after it get the new parent. A parent not loaded yet costs one more query.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per lookup.** Each declared lookup costs at most one SOQL query before the first handler, even when no record qualifies. A [PriorParentQuery](/before-update/add-ons/prior-parent-query) on the same lookup shares that query.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
