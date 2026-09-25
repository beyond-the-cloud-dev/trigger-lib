---
template: role
context: AfterUndelete
interface: Writer
description: After undelete, create, update or delete other records, or publish platform events, through a unit of work that commits with the restore.
---

# AfterUndelete.Writer

Change other records or publish platform events after the restore, through a unit of work.

**Signature**

<!--@include: @/_parts/generated/after-undelete/writer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/writer/skeleton.md-->

```apex [Block a restore]
public with sharing class AccountRestoreGuardWriter implements AfterUndelete.Writer {
    public Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record) {
        return !FeatureManagement.checkPermission('Restore_Accounts');
    }

    public void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        record.getNewSObject().addError('You are not allowed to restore accounts.');
    }
}
```

:::

## Rules {#rules}

- **Register, don't run DML.** Call `toInsert`, `toUpdate`, `toUpsert`, `toDelete` or `toPublish` (platform events) on `unitOfWork`. Direct DML runs at once, outside the unit.
- **A self-update is a second save.** `unitOfWork.toUpdate(new Account(Id = record.getId(), …))` fires BeforeUpdate and AfterUpdate for the restored record.
- **Block a restore with `addError`.** There is no Validator here. List the blocking Writer first. The record stays in the Recycle Bin.
- **Writer wins.** A class that also implements `AfterUndelete.Dispatcher` runs only as a Writer.

::: warning
A self-delete fails. A `toDelete` of a record being restored throws a `DmlException` with `SELF_REFERENCE_FROM_TRIGGER`.
:::

## Test {#test}

```apex
@IsTest
static void writeOnAfterUndeleteWithoutPermission() {
    // Setup
    Account acme = new Account(Name = 'Acme');

    TriggerOrchestrator.mock().afterUndeleteFor(AccountRestoreGuardWriter.class).with(acme);

    // Test
    TriggerOrchestrator.runTestFor(new AccountRestoreGuardWriter());

    // Verify
    Assert.areEqual('You are not allowed to restore accounts.', acme.getErrors()[0].getMessage(), 'The restore should be rejected.');
}
```
