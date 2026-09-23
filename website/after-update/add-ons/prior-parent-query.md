---
template: add-on
context: AfterUpdate
interface: PriorParentQuery
description: 'Read fields of the parent a lookup pointed to before the update, such as the previous owner or account, in an after update Writer or Dispatcher.'
---

# AfterUpdate.PriorParentQuery

Read fields of the parent a lookup pointed to **before** this update (the previous owner, the account a contact or an opportunity moved away from) in an **after update** Writer or Dispatcher, without SOQL in your handler.

<!--@include: @/_parts/generated/after-update/prior-parent-query/available-in.md-->

## When to Use {#when-to-use}

- A lookup changed and the handler must notify or update the previous parent, such as a task for the old account's owner.
- The handler compares the previous parent with the current one: implement PriorParentQuery and [ParentQuery](/after-update/add-ons/parent-query) together.
- Use ParentQuery alone when only the current parent matters.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/prior-parent-query/signature.md-->

<!--@include: @/_parts/generated/after-update/prior-parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/prior-parent-query/skeleton.md-->

```apex [Old vs new account]
public with sharing class OpportunityAccountMoveTaskWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.PriorParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.OwnerId) };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Opportunity.AccountId) && record.getOldParent('Account') != null;
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Account previousAccount = (Account) record.getOldParent('Account');
        Account newAccount = (Account) record.getNewParent('Account');

        unitOfWork.toInsert(new Task(WhatId = previousAccount.Id, OwnerId = previousAccount.OwnerId, Subject = 'Opportunity moved to ' + newAccount?.Name));
    }
}
```

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Everything together]

:::

Both declarations name `Opportunity.AccountId`, so their fields are merged: the previous and the current account each carry `Name` and `OwnerId`.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/prior-parent-query.md-->

In after update, current parents are loaded first, through one query on the trigger records, when an active handler declares a ParentQuery. A previous parent that this query already returned, such as the parent of an unchanged lookup, is reused. The rest cost one query per lookup, against the first object the lookup can reference.

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

## Records Here {#records}

- `queryPriorParentsOnAfterUpdate()` takes no records. It returns the declaration once per run.
- Read the previous parent per record with `record.getOldParent('Account')`. It is null when the old lookup was empty or the previous parent no longer exists.
- In a provider, a dispatch or a Finalizer, `records.getOldIdsOf('Account', Account.OwnerId)` and `records.getOldValuesOf('Account', Account.Name)` collect values of the loaded previous parents; `records.getOldIdsOf(Opportunity.AccountId)` needs no add-on, because it reads the old rows.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/prior-parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **Each side needs its own declaration.** `getOldParent` returns null for a lookup that no active handler declares with PriorParentQuery, even when the lookup did not change. In the same way, `getNewParent` needs a ParentQuery.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

For `AccountOwnerTransferWriter`, attach both owners with `enrichOld('Owner', …)` and `enrichNew('Owner', …)`, and its open opportunities with `setProvidedRecords` under `'openOpportunities'`. `User.Name` cannot be written, so build each owner with `JSON.deserialize`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/prior-parent-query/other-contexts.md-->

## See Also {#see-also}

- [AfterUpdate.ParentQuery](/after-update/add-ons/parent-query)
- [Field Selection](/api/field-selection)
- [Parents and Related in AfterUpdate](/after-update/record-api#parents)
- [Testing](/guide/testing)
