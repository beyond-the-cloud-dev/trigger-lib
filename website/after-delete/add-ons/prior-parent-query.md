---
template: add-on
context: AfterDelete
interface: PriorParentQuery
description: Read fields of the former parent (lookup) of a deleted record in an after delete Writer or Dispatcher, without SOQL in the handler.
---

# AfterDelete.PriorParentQuery

Read fields of the parent the old row pointed to, such as a contact's former account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/after-delete/prior-parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-delete/prior-parent-query/skeleton.md-->

:::

## Rules {#rules}

- **Read by relationship name.** Use `getOldParent('Account')` for `AccountId`. The name is case-sensitive. For the Id alone, read the lookup from `getOldSObject()`.
- **Read as it is now.** The parent is queried when the trigger runs, so its fields show current values. It is null when the lookup was empty or the parent no longer exists.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`.
- **One query per lookup.** Each declared lookup costs at most one SOQL query per chunk, even when no record qualifies.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
