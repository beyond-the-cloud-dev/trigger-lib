---
template: role
context: AfterDelete
interface: Writer
description: Create, update or delete other records after a delete — clean up orphans, note the former parent, recompute a rollup — through the unit of work in an AfterDelete Writer.
---

# AfterDelete.Writer

A Writer runs in **after delete** and registers writes to *other* records on a unit of work, only when the delete really happens: remove orphans, leave a task on the former parent (lookup), recompute a parent from the records that remain, or publish an event. Skip it (bypass) with Bypassable.

<!--@include: @/_parts/generated/after-delete/writer/available-in.md-->

## When to Use {#when-to-use}

- Write other records only if the delete goes through: a record that fails in before delete never reaches this handler.
- Recompute a parent from the records that remain, with a RelatedQuery keyed by the old lookups.
- Use [BeforeDelete.Handler](/before-delete/handler) instead to stop the delete, or when the work needs the records still present and linked.
- Use a [Dispatcher](/after-delete/dispatcher) instead for async work, callouts or email.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/writer/signature.md-->

<!--@include: @/_parts/generated/after-delete/writer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/writer/skeleton.md-->

```apex [Skip merge losers]
public with sharing class ContactRemovalTaskWriter implements AfterDelete.Writer, AfterDelete.PriorParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterDelete() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.OwnerId) };
    }

    public Boolean writeOnAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
        return record.isNull(Contact.MasterRecordId) && record.getOldParent('Account') != null;
    }

    public void writeOnAfterDelete(TriggerHandler.DeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Contact contactRecord = (Contact) record.getOldSObject();
        Account accountRecord = (Account) record.getOldParent('Account');

        unitOfWork.toInsert(new Task(WhatId = contactRecord.AccountId, OwnerId = accountRecord.OwnerId, Subject = 'Contact removed: ' + contactRecord.LastName));
    }
}
```

:::

The second tab skips the records that lose a merge (`MasterRecordId` is set) and contacts without a former account, then leaves a task for the former account's owner.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/writer.md-->

There is no recursion counter in after delete, so every record that qualifies is processed once per run.

### Unit of Work Methods {#unit-of-work-methods}

<!--@include: @/_parts/uow/methods.md-->

Nothing you register can touch the deleted rows: a `toUpdate` of one fails the commit with `ENTITY_IS_DELETED`, a `toDelete` with `SELF_REFERENCE_FROM_TRIGGER`, and the unit has no undelete.

### Which Unit You Get {#which-unit}

<!--@include: @/_parts/uow/which-unit.md-->

### When It Commits {#when-it-commits}

<!--@include: @/_parts/uow/commit-timing.md-->

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-delete/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-delete/accessors.md-->

- `getId()` is the deleted Id. SOQL no longer finds that row, so read what you need from `getOldSObject()`.
- `getOldSObject()` is read-only: writing a field throws a `FinalException` that cannot be caught.
- `getOldParent` returns a parent only for lookups a PriorParentQuery declared, and `getRelated` only for providers of this handler's RelatedQuery.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/writer/works-with.md-->

## Gotchas {#gotchas}

- **Never register the deleted row.** An update of it fails with `ENTITY_IS_DELETED`. On the shared unit that fails the whole delete, and the error is not passed to `TriggerOrchestrator.Logger`.
- **Key by the old lookups, not by the deleted Ids.** A query on the trigger object by `records.getIds()` returns nothing, with no error.
- **Merge losers qualify** unless the predicate checks `record.isNull(Contact.MasterRecordId)`.
- **Records deleted by a cascade never arrive here.** Put that logic on the parent's delete.
- **`getOldSObject().addError(…)` rolls the delete back**, but only after all the work that ran before it. Stop deletes in [BeforeDelete](/before-delete/handler).

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the predicate and the action directly with a `TriggerRecord` built from an in-memory old row (`null` for the new row), and pass the action a small unit of work of your own. This test covers the Skeleton tab:

```apex
@IsTest
static void writeOnAfterDeleteInsertsTaskOnFormerAccount() {
    // Setup
    Id accountId = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType);
    Contact oldContact = new Contact(Id = new TriggerHandler.RandomIdGenerator().get(Contact.SObjectType), AccountId = accountId, LastName = 'Doe');
    RegisteredWrites unitOfWork = new RegisteredWrites();

    // Test
    new ContactWriter().writeOnAfterDelete(new TriggerHandler.TriggerRecord(null, oldContact), unitOfWork);

    // Verify
    Assert.areEqual(accountId, ((Task) unitOfWork.inserted[0]).WhatId, 'The task should be linked to the former account.');
}
```

::: details RegisteredWrites: a unit of work that only records

```apex
private class RegisteredWrites implements TriggerHandler.UnitOfWork {
    public List<SObject> inserted = new List<SObject>();

    public TriggerHandler.UnitOfWork toInsert(SObject record) {
        this.inserted.add(record);
        return this;
    }

    public TriggerHandler.UnitOfWork toInsert(DML.Record record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpdate(SObject record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpdate(DML.Record record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) {
        return this;
    }

    public TriggerHandler.UnitOfWork toDelete(SObject record) {
        return this;
    }

    public TriggerHandler.UnitOfWork toPublish(SObject event) {
        return this;
    }
}
```

:::

A merge loser needs `MasterRecordId`, which cannot be set in the constructor: build the old row with `JSON.deserialize`. More techniques: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/writer/other-contexts.md-->

## See Also {#see-also}

- [AfterDelete](/after-delete/) overview and [AfterDelete.Dispatcher](/after-delete/dispatcher)
- [BeforeDelete.Handler](/before-delete/handler), to stop a delete
- [AfterDelete add-ons](/after-delete/add-ons/): PriorParentQuery, RelatedQuery, OwnUnitOfWork, Finalizer
- [Unit of Work](/guide/unit-of-work) and [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [Record API in AfterDelete](/after-delete/record-api)
