---
template: role
context: AfterUndelete
interface: Writer
description: After undelete, create, update or delete other records, or publish platform events, through a unit of work that commits with the restore.
---

# AfterUndelete.Writer

Creates, updates or deletes other records, or publishes platform events, when records are restored. Register the changes on the unit of work; they commit with the restore.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/writer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/writer/skeleton.md-->

```apex [Block a restore]
public with sharing class AccountRestoreGuardWriter implements AfterUndelete.Writer {
    public Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
        return !FeatureManagement.checkPermission('Restore_Accounts');
    }

    public void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        record.getNewSObject().addError('You are not allowed to restore accounts.');
    }
}
```

:::

## Good to Know {#good-to-know}

- **Register, don't run DML.** The library commits what you register on `unitOfWork` after the last handler. Direct DML is not blocked here, but it runs at once, outside the unit of work.
- **A self-update is a second save.** `unitOfWork.toUpdate(new Account(Id = record.getId(), …))` fires BeforeUpdate and AfterUpdate for the restored record.
- **A self-delete fails.** A `toDelete` of a record being restored throws a `DmlException` with `SELF_REFERENCE_FROM_TRIGGER`. Block the restore with `addError` instead.
- **Block a restore with `addError`.** There is no Validator here. Call `record.getNewSObject().addError(…)`, as in the second tab, and list this Writer first. The record stays in the Recycle Bin.
- **Writer wins.** A class that also implements `AfterUndelete.Dispatcher` runs only as a Writer.

## Test {#test}

```apex
@IsTest
static void writeOnAfterUndeleteRejectsRestore() {
    // Setup
    Account restoredAccount = new Account(Name = 'Acme');

    // Test
    new AccountRestoreGuardWriter().writeOnAfterUndelete(new TriggerHandler.TriggerRecord(restoredAccount, null), null);

    // Verify
    Assert.areEqual('You are not allowed to restore accounts.', restoredAccount.getErrors()[0].getMessage(), 'The restore should be rejected.');
}
```
