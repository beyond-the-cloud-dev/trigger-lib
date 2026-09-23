---
template: add-on
context: AfterDelete
interface: PriorParentQuery
description: Read fields of the former parent (lookup) of a deleted record in an after delete Writer or Dispatcher, without SOQL in the handler.
---

# AfterDelete.PriorParentQuery

Reads fields of the record a lookup pointed to before the delete, such as a contact's former account, without SOQL in your handler. For the Id alone you do not need it: the old row still holds the lookup.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/prior-parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/prior-parent-query/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Read by relationship name.** Use `getOldParent('Account')` for `AccountId`. The name is case-sensitive.
- **Read as it is now.** The parent is queried when the trigger runs, so its fields show current values. It is null when the lookup was empty or the parent no longer exists.
- **Only declared fields.** The parent holds the declared fields and its `Id`. Reading any other field throws an `SObjectException`.
- **Costs SOQL even when nothing qualifies.** Each declared lookup costs one query per chunk, before any predicate runs.
- **No sharing.** Parents are read in system mode, so a handler can see records the user cannot.
