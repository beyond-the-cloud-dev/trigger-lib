---
template: add-on
context: AfterInsert
interface: ParentQuery
description: AfterInsert.ParentQuery - read parent (lookup) fields, and grandparent fields, in an after insert Writer or Dispatcher without SOQL in your handler.
---

# AfterInsert.ParentQuery

Read fields of the record a lookup points to, such as the account of a new contact or the owner of a new account, in **after insert**, without SOQL in your handler. Declare the lookup and the parent fields once; the library loads them before the first handler runs, and you read them with `record.getNewParent('Account')`.

<!--@include: @/_parts/generated/after-insert/parent-query/available-in.md-->

## When to Use {#when-to-use}

- A Writer or Dispatcher needs a field of the parent, or of the parent's parent, in its predicate or action: the account's owner, the owner's email, a flag on the account.
- Use a [RelatedQuery](/after-insert/add-ons/related-query) instead for children, siblings or records that no lookup on the trigger object points to.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/parent-query/signature.md-->

<!--@include: @/_parts/generated/after-insert/parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [In the action]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Grandparent, in the predicate]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactFollowUpTaskWriter.cls [Null-safe read]

:::

`ContactFollowUpTaskWriter` checks the parent for null, because a Contact can be inserted without an account.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/parent-query.md#after-->

For `ContactOwnerAlignmentWriter`, the query on the trigger records selects `Account.Id, Account.OwnerId, Account.Owner.IsActive`. `ContactFollowUpTaskWriter`, listed after it, declares `Account.Name` for the same lookup, so the one query also selects `Account.Name`, and both Writers read the same parent.

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

There is no PriorParentQuery in after insert: an insert has no previous parent. It exists in [AfterUpdate](/after-update/add-ons/prior-parent-query).

## Records Here {#records}

The method takes no records: it only declares lookups and fields. Read the result in any method that receives a record:

- `record.getNewParent('Account')` returns the parent, or null when the lookup is empty, no active handler declared it, or the parent does not exist.
- A grandparent is read through the parent: `((Account) record.getNewParent('Account')).Owner.IsActive`.
- On a collection, `records.getIdsOf('Account', Account.OwnerId)` collects a field of the loaded parents, in providers too, because parents load before providers run.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **The row itself stays empty.** `((Contact) record.getNewSObject()).Account` is null in after insert; only `getNewParent('Account')` holds the loaded parent.
- **Nested saves load again.** An update of the inserted records runs the update triggers during the shared commit, and those runs load their own parents.
- **Not for event objects.** Platform-event and change-event objects have no lookup fields to declare.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

For `ContactOwnerAlignmentWriter`, attach the account with its owner: `record.enrichNew('Account', new Account(OwnerId = ownerId, Owner = new User(Id = ownerId, IsActive = true)))`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/parent-query/other-contexts.md-->

## See Also {#see-also}

- [Field Selection](/api/field-selection): `TriggerHandler.ParentFields`
- [AfterInsert.RelatedQuery](/after-insert/add-ons/related-query): children, siblings and other records
- [Record API in AfterInsert](/after-insert/record-api#parents)
