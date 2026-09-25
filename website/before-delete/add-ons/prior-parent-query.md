---
template: add-on
context: BeforeDelete
interface: PriorParentQuery
description: Read parent (lookup) fields of the records being deleted in a before delete Validator or Writer, without SOQL in the handler.
---

# BeforeDelete.PriorParentQuery

Read fields of the parent the old row pointed to, such as a deleted contact's account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/before-delete/prior-parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/prior-parent-query/skeleton.md-->

:::

## Rules {#rules}

- **Read by lookup field.** Pass the lookup field you declared, such as `getOldParent(Contact.AccountId)` or `getOldParent(Account.ParentId)`.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per lookup.** Each declared lookup costs at most one SOQL query per chunk, even when no record qualifies.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
