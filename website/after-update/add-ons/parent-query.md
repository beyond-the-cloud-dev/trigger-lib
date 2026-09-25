---
template: add-on
context: AfterUpdate
interface: ParentQuery
description: Read parent (lookup) fields, such as an opportunity's account, in an after update Writer or Dispatcher without writing SOQL.
---

# AfterUpdate.ParentQuery

Read fields of the record a lookup points to, such as an opportunity's account, without SOQL in your handler.

**Signature**

<!--@include: @/_parts/generated/after-update/parent-query/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [In the action]

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [In the predicate]

:::

## Rules {#rules}

- **Read by lookup field.** Pass the lookup field you declared, such as `getNewParent(Opportunity.AccountId)` or `getNewParent(Opportunity.OwnerId)`.
- **Check for null.** The parent is null when the lookup is empty or no record has that Id.
- **Declare every field you read.** The parent holds only the fields the active handlers declared. Reading any other field throws an `SObjectException`. Add grandparent fields with `.with('Owner', User.IsActive)`.
- **One query per chunk.** One query on the trigger records loads every declared parent, even when no record qualifies.

::: warning
Parents are read in system mode without sharing, so a handler can see records the user cannot.
:::
