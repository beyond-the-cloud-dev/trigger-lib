---
template: add-on
context: AfterUpdate
interface: ParentQuery
description: Read parent (lookup) fields, such as an opportunity's account, in an after update Writer or Dispatcher without writing SOQL.
---

# AfterUpdate.ParentQuery

Reads fields of the record a lookup points to now, such as an opportunity's account, without SOQL in your handler. The saved row holds only the lookup Id.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/parent-query/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [In the action]

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [In the predicate]

:::

## Good to Know {#good-to-know}

- **Read by relationship name.** Use `getNewParent('Account')` for `AccountId` and `getNewParent('Owner')` for `OwnerId`. The name is case-sensitive.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Declare every field you read.** The parent holds only the fields the active handlers declared. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per chunk.** One query on the trigger records loads every declared parent, even when no record qualifies. A parent it does not return costs one more query for that lookup.
- **No sharing.** Parents are read in system mode, so a handler can see records the user cannot. For the parent before the update, use [PriorParentQuery](/after-update/add-ons/prior-parent-query).
