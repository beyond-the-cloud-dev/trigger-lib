---
template: add-on
context: AfterUndelete
interface: ParentQuery
description: Read parent (lookup) fields of restored records in an after undelete Writer or Dispatcher without SOQL in the handler.
---

# AfterUndelete.ParentQuery

Read fields of the record a lookup points to, such as a restored contact's account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/after-undelete/parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/parent-query/skeleton.md-->

:::

## Rules {#rules}

- **Read by lookup field.** Pass the lookup field you declared, such as `getNewParent(Contact.AccountId)` or `getNewParent(Contact.OwnerId)`.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Declare every field you read.** Reading a field that no handler declared throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per chunk.** One SOQL query on the restored records reads every declared parent, even when no record qualifies.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
