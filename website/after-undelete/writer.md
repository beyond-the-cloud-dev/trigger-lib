---
template: role
context: AfterUndelete
interface: Writer
description: After undelete, create, update or delete other records, or publish platform events, through a unit of work that commits with the restore.
---

# AfterUndelete.Writer

After records are restored from the Recycle Bin (**after undelete**), create, update or delete other records, or publish platform events, through a unit of work that commits with the restore: no DML statements in your handler.

<!--@include: @/_parts/generated/after-undelete/writer/available-in.md-->

## When to Use {#when-to-use}

- Create records for a restored record, such as a follow-up Task for its owner.
- Update parents or other records, such as a summary field on the parent.
- Publish a platform event that should roll back with the restore.
- Use a [Dispatcher](/after-undelete/dispatcher) instead for async work, callouts through a Queueable, email or one publish per chunk.
- Use `record.getNewSObject().addError(…)` from here to block a restore: [There Is No BeforeUndelete](/after-undelete/#no-before-undelete).

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/writer/signature.md-->

<!--@include: @/_parts/generated/after-undelete/writer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/writer/skeleton.md-->

```apex [With ParentQuery]
public with sharing class AccountRestoreTaskWriter implements AfterUndelete.Writer, AfterUndelete.ParentQuery {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUndelete() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.IsActive) };
    }

    public Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
        User owner = (User) record.getNewParent('Owner');

        return owner?.IsActive == true;
    }

    public void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Account accountRecord = (Account) record.getNewSObject();

        unitOfWork.toInsert(
            new Task(WhatId = record.getId(), OwnerId = accountRecord.OwnerId, Subject = 'Restored - ' + accountRecord.Name, ActivityDate = Date.today().addDays(1))
        );
    }
}
```

:::

The second tab creates a Task for the owner of every restored Account whose owner is still active. The owner's `IsActive` comes from [ParentQuery](/after-undelete/add-ons/parent-query), loaded once for the chunk.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/writer.md-->

### Unit of Work Methods {#unit-of-work-methods}

<!--@include: @/_parts/uow/methods.md-->

### Which Unit You Get {#which-unit}

<!--@include: @/_parts/uow/which-unit.md-->

### When It Commits {#when-it-commits}

<!--@include: @/_parts/uow/commit-timing.md-->

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-undelete/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-undelete/accessors.md-->

- To change the restored record, register `toUpdate(new Account(Id = record.getId(), …))` on the unit; it fires the update triggers ([Gotchas](#gotchas)).
- Relationship fields on the row, such as `getNewSObject().Owner`, are empty. Read parents with `getNewParent` after declaring a [ParentQuery](/after-undelete/add-ons/parent-query).

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/writer/works-with.md-->

## Gotchas {#gotchas}

- **A self-update fires the update triggers.** A `toUpdate` of a restored record runs BeforeUpdate and AfterUpdate for it during the shared commit: a second save.
- **A self-delete fails.** A `toDelete` of a record that is being restored throws a `DmlException` with `SELF_REFERENCE_FROM_TRIGGER` at commit.
- **Cascades, lookups and partial restores.** Children that Salesforce restores with their parent do not fire their own after undelete trigger, inbound lookups may not be back yet, and a partial restore runs the Writer again for the remaining records ([overview Gotchas](/after-undelete/#gotchas)).

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the predicate and the action directly with a `TriggerHandler.TriggerRecord` built in memory. Pass `null` as the old row, because a restore has none, and attach the parent with `enrichNew` instead of letting the library query it:

```apex
@IsTest
static void writeOnAfterUndeleteWhenOwnerIsActive() {
    // Setup
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Account(Name = 'Acme'), null);
    record.enrichNew('Owner', new User(IsActive = true));

    // Test
    Boolean qualifies = new AccountRestoreTaskWriter().writeOnAfterUndeleteWhen(record);

    // Verify
    Assert.isTrue(qualifies, 'The record should qualify.');
}
```

For the action, pass a small class of your own that implements `TriggerHandler.UnitOfWork` and keeps what it receives:

::: code-group

```apex [Test]
@IsTest
static void writeOnAfterUndeleteTaskSubject() {
    // Setup
    Account accountRecord = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
    RegisteredWork unitOfWork = new RegisteredWork();

    // Test
    new AccountRestoreTaskWriter().writeOnAfterUndelete(new TriggerHandler.TriggerRecord(accountRecord, null), unitOfWork);

    // Verify
    Assert.areEqual('Restored - Acme', ((Task) unitOfWork.inserted[0]).Subject, 'Wrong subject.');
}
```

```apex [RegisteredWork]
private class RegisteredWork implements TriggerHandler.UnitOfWork {
    public List<SObject> inserted = new List<SObject>();

    public TriggerHandler.UnitOfWork toInsert(SObject record) {
        this.inserted.add(record);
        return this;
    }

    public TriggerHandler.UnitOfWork toInsert(DML.Record record) { return this; }
    public TriggerHandler.UnitOfWork toUpdate(SObject record) { return this; }
    public TriggerHandler.UnitOfWork toUpdate(DML.Record record) { return this; }
    public TriggerHandler.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) { return this; }
    public TriggerHandler.UnitOfWork toDelete(SObject record) { return this; }
    public TriggerHandler.UnitOfWork toPublish(SObject event) { return this; }
}
```

:::

Neither test runs DML or SOQL. `enrichNew` is public, but `TriggerHandler` lists it under an internal-use comment, so it may change in a later version. Running the Writer through the orchestrator, with the shared unit mocked by `DML.mock('triggerUow')`, is covered in [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/writer/other-contexts.md-->

In the before contexts, change the trigger record with a Populator instead. There is no before undelete: [No BeforeUndelete](/after-undelete/#no-before-undelete).

## See Also {#see-also}

- [AfterUndelete.Dispatcher](/after-undelete/dispatcher)
- [AfterUndelete.OwnUnitOfWork](/after-undelete/add-ons/own-unit-of-work)
- [Unit of Work](/guide/unit-of-work)
- [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [Testing](/guide/testing)
