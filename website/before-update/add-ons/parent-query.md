---
template: add-on
context: BeforeUpdate
interface: ParentQuery
description: BeforeUpdate.ParentQuery loads parent (lookup) fields for a before update Populator or Validator without SOQL in the handler, including a lookup the user just changed.
---

# BeforeUpdate.ParentQuery

Read fields of the record a lookup points to now (parent, lookup, `Account.Name`, owner fields) in a **before update** Populator or Validator, without writing SOQL, including a lookup the user just changed.

<!--@include: @/_parts/generated/before-update/parent-query/available-in.md-->

## When to Use {#when-to-use}

- A predicate or an error message needs a field of the current parent: the account's name, the parent account's billing country.
- A Populator copies a parent value onto the record when the lookup changes.
- Together with [PriorParentQuery](/before-update/add-ons/prior-parent-query), to compare the old and the new parent.

Use a [RelatedQuery](/before-update/add-ons/related-query) for children, siblings or any other records.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/parent-query/signature.md-->

<!--@include: @/_parts/generated/before-update/parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityAccountMoveValidator.cls [In the error method]

<<< @/../examples/main/default/classes/account/before-update/validator/AccountParentMoveValidator.cls [Self-lookup in the predicate]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [In a Populator]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/parent-query.md#before-->

In before update:

- **Both sides in one query.** A lookup declared by a ParentQuery and a PriorParentQuery is loaded with one query that carries the current and the previous parent Ids, and both sides get every field either side declared.
- **Which parent later handlers see.** When a Populator sets `Contact.AccountId` to another account, `getNewParent('Account')` returns that account in every handler listed after it. Handlers listed before it saw the account the lookup held when the run started.

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

## Records Here {#records}

The method takes no records. Read the parent with `record.getNewParent('Account')` in the predicate, the action or error method, and the Finalizer. For the self-lookup `Account.ParentId` the relationship name is `Parent`, as in `AccountParentMoveValidator`.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **Parents in the same update show saved values.** A parent that is itself part of this update, such as another account in the same save for `Account.ParentId`, is read from the database, so it shows its values from before the update.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

`OpportunityAccountMoveValidator` names both accounts in its message, so set both sides before you call `addErrorOnBeforeUpdate`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/parent-query/other-contexts.md-->

## See Also {#see-also}

- [Field Selection](/api/field-selection)
- [Parents and Related in BeforeUpdate](/before-update/record-api#parents)
- [Query cost](/guide/execution-order#query-cost)
