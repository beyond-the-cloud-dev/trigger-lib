---
template: role
context: BeforeDelete
interface: Handler
description: The single before delete role - block a delete with addError, or clean up related records with direct DML.
---

# BeforeDelete.Handler

Check each record before it is deleted, then block the delete or clean up the records that point at it.

**Signature**

<!--@include: @/_parts/generated/before-delete/handler/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/handler/skeleton.md-->

```apex [Block the delete]
public with sharing class AccountDeletionGuardHandler implements BeforeDelete.Handler, BeforeDelete.RelatedQuery {
    public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
        return new Map<String, BeforeDelete.RecordsProvider>{ 'openOpportunities' => new OpenOpportunitiesProvider() };
    }

    public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
        return record.getRelated('openOpportunities').getFirstWhereKeyEquals(record.getId()) != null;
    }

    public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
        record.getOldSObject().addError('Close or move the open opportunities before you delete this account.');
    }

    private without sharing class OpenOpportunitiesProvider implements BeforeDelete.RecordsProvider {
        public List<SObject> query(TriggerHandler.DeleteRecords records) {
            return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
        }

        public String keyOf(SObject record) {
            return ((Opportunity) record).AccountId;
        }
    }
}
```

```apex [Clean up in the Finalizer]
public with sharing class ContactReportsReassignHandler implements BeforeDelete.Handler, BeforeDelete.Finalizer {
    private Map<Id, Id> managerIdByContactId = new Map<Id, Id>();

    public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
        return record.isNotNull(Contact.ReportsToId);
    }

    public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
        this.managerIdByContactId.put(record.getId(), ((Contact) record.getOldSObject()).ReportsToId);
    }

    public void finalizeBeforeDelete(TriggerHandler.DeleteRecords records) {
        List<Contact> reports = [SELECT Id, ReportsToId FROM Contact WHERE ReportsToId IN :records.getIds()];

        for (Contact report : reports) {
            report.ReportsToId = this.managerIdByContactId.get(report.ReportsToId);
        }

        update reports;
    }
}
```

:::

## Rules {#rules}

- **Block with `addError`.** Call `record.getOldSObject().addError('…')`. Writing a field on the old row throws. Nothing checks that a qualified record got an error.
- **DML is allowed.** It runs at once, one statement per call. Collect in `onBeforeDelete` and write once in a [Finalizer](/before-delete/add-ons/finalizer). To write another record, build a fresh instance, such as `new Contact(Id = contactId)`.
- **Leave the records being deleted alone.** DML on a `Trigger.old` row throws. Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`.
- **An error does not stop later handlers.** A record with an error still reaches every later handler in the list.

::: warning
A guard must see every row. A `with sharing` provider misses rows the user cannot see, and a missed row lets the delete through. Never add [ContinueOnError](/before-delete/add-ons/continue-on-error) to a guard: a swallowed exception lets the delete through too.
:::

## Test {#test}

```apex
@IsTest
static void onBeforeDeleteAttachesError() {
    // Setup
    Account accountRecord = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

    // Test
    new AccountDeletionGuardHandler().onBeforeDelete(new TriggerHandler.TriggerRecord(null, accountRecord));

    // Verify
    Assert.isTrue(accountRecord.hasErrors(), 'The delete should be blocked.');
}
```
