---
template: add-on
context: BeforeInsert
interface: ParentQuery
description: Read parent (lookup) fields in a before insert Populator or Validator without writing SOQL.
---

# BeforeInsert.ParentQuery

Read fields of the record a lookup points to, such as a contact's account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/before-insert/parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-insert/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/before-insert/populator/AccountParentDefaultsPopulator.cls [In a Populator]

<<< @/../examples/main/default/classes/account/before-insert/validator/AccountParentTypeValidator.cls [In a Validator]

:::

## Rules {#rules}

- **Read by lookup field.** Pass the lookup field you declared, such as `getNewParent(Contact.AccountId)` or `getNewParent(Account.ParentId)`. The parent is null when the lookup is empty or no record has that Id.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per lookup.** Each declared lookup costs at most one SOQL query per chunk, even when no record qualifies. A Populator that changes it can add one.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
