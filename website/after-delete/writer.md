---
template: role
context: AfterDelete
interface: Writer
description: Create, update or delete other records after a delete - remove orphans, note the former parent, recompute a rollup - through a unit of work.
---

# AfterDelete.Writer

Change other records or publish platform events after the delete, through a unit of work.

**Signature**

<!--@include: @/_parts/generated/after-delete/writer/signature.md-->

**Example**

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

## Rules {#rules}

- **Read the old row, not SOQL.** SOQL no longer finds the deleted row. Read its values from `getOldSObject()`, which is read-only.
- **Merge losers qualify.** Skip them as `[Skip merge losers]` does.
- **Register with `toInsert`, `toUpdate`, `toUpsert`, `toDelete` or `toPublish` (platform events).** They commit after the last handler, or right after this Writer with [OwnUnitOfWork](/after-delete/add-ons/own-unit-of-work) or [ContinueOnError](/after-delete/add-ons/continue-on-error).
- **Writer wins.** A class that also implements `AfterDelete.Dispatcher` runs only as a Writer.

::: warning
Never register the deleted row. An update of it fails the commit with `ENTITY_IS_DELETED`, and a delete with `SELF_REFERENCE_FROM_TRIGGER`.
:::

## Test {#test}

```apex
@IsTest
static void writeOnAfterDeleteWhenQualifiesContactWithAccount() {
    // Setup
    Contact oldContact = new Contact(AccountId = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType));

    // Test
    Boolean qualifies = new ContactWriter().writeOnAfterDeleteWhen(new TriggerHandler.TriggerRecord(null, oldContact));

    // Verify
    Assert.isTrue(qualifies, 'A contact with a former account should qualify.');
}
```
