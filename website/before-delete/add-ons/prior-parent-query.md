---
template: add-on
context: BeforeDelete
interface: PriorParentQuery
description: Read parent (lookup) fields of the records being deleted in a before delete Handler, without SOQL in the handler.
---

# BeforeDelete.PriorParentQuery

Reads fields of the record a lookup points to, such as a deleted contact's account, without SOQL in your handler. The row being deleted holds only the lookup Id.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/prior-parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/prior-parent-query/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Read by relationship name.** Use `getOldParent('Account')` for `AccountId` and `getOldParent('Parent')` for `ParentId`. The name is case-sensitive.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per lookup.** Each declared lookup costs at most one SOQL query per chunk, even when no record qualifies.
- **No sharing.** Parents are read in system mode, so a handler can see records the user cannot.
