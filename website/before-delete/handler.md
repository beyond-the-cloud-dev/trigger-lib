---
template: role
context: BeforeDelete
interface: Handler
description: "The single before delete role. Block (veto, prevent) a delete with addError, or clean up related records with direct DML."
---

# BeforeDelete.Handler

`BeforeDelete.Handler` is the one role in **before delete**: it checks each record about to be deleted and acts on it, to block (veto, prevent) the delete with `addError` or to clean up related records with direct DML while the rows and their links still exist.

<!--@include: @/_parts/generated/before-delete/handler/available-in.md-->

## When to Use {#when-to-use}

- Block the delete of records that must stay, with `record.getOldSObject().addError(…)`.
- Clean up, archive or reassign records that point at the rows being deleted, with one DML statement in a [Finalizer](/before-delete/add-ons/finalizer).
- Read the parent's fields or the children of the rows being deleted before they are gone, through [PriorParentQuery](/before-delete/add-ons/prior-parent-query) or [RelatedQuery](/before-delete/add-ons/related-query).
- Use [AfterDelete.Writer](/after-delete/writer) instead when the write must happen only if the delete succeeds, and [AfterDelete.Dispatcher](/after-delete/dispatcher) for jobs, callouts and email.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/handler/signature.md-->

<!--@include: @/_parts/generated/before-delete/handler/method-table.md-->

## Example {#example}

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

The guard's provider is `without sharing`, so it also finds open opportunities the running user cannot see. The cleanup handler moves the direct reports of a deleted contact up to that contact's own manager, with one query and one `update` per chunk, before the platform clears their `ReportsToId`.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

- **No DML guard here.** Unlike before insert and before update, DML in the action runs at once, one statement per call. Collect in `onBeforeDelete` and write once in the Finalizer.
- **Nothing checks the error.** A qualified record that gets no `addError` is simply deleted, and an error does not remove the record from the later handlers' loops.
- **No recursion guard.** Nothing is counted per record in this context.

## Register {#register}

<!--@include: @/_parts/generated/before-delete/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/before-delete/accessors.md-->

- `getOldSObject()` is the `Trigger.old` row: writing to it throws, and passing it to DML throws `System.SObjectException`. To write to another record, build a fresh instance, for example `new Contact(Id = contactId, ReportsToId = managerId)`.
- `getOldSObject().addError(…)` is how you block the delete of that record.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-delete/handler/works-with.md-->

## Gotchas {#gotchas}

- **The rows being deleted are off-limits for DML.** Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`. Updating one succeeds and fires the update triggers, and then the record is deleted anyway.
- **Merge losers qualify like any delete.** `MasterRecordId` is not set yet here, so the handler cannot tell a merge from a plain delete, and a guard's error fails the merge too.
- **A guard needs every row.** A `with sharing` provider misses the rows the running user cannot see, and a missed row lets a delete through. Declare the provider class `without sharing` when the check must see every row; parents are always read without sharing.
- **ContinueOnError on a guard lets deletes through.** A swallowed exception in the provider or the predicate means no error is attached, so the record is deleted.
- **Partial deletes run twice.** With `Database.delete(records, false)`, every handler runs again for the surviving records after a failure; direct DML from the first attempt is rolled back.

## Test It {#test}

Call the action with a record built from an in-memory row. `addError` on an in-memory row works outside a trigger, and `hasErrors()` reports it:

```apex
@IsTest
private class AccountDeletionGuardHandlerTest {
    @IsTest
    static void onBeforeDeleteAttachesError() {
        // Setup
        Account accountRecord = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');

        // Test
        new AccountDeletionGuardHandler().onBeforeDelete(new TriggerHandler.TriggerRecord(null, accountRecord));

        // Verify
        Assert.isTrue(accountRecord.hasErrors(), 'The delete should be blocked.');
    }
}
```

For the predicate, hand the record its provider rows yourself, grouped under the key `keyOf` would return:

```apex
@IsTest
static void qualifiesForBeforeDeleteWhenOpenOpportunity() {
    // Setup
    Id accountId = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType);
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(null, new Account(Id = accountId, Name = 'Acme'));
    TriggerHandler.ProvidedRecords provided = new TriggerHandler.ProvidedRecords(new List<SObject>{ new Opportunity(AccountId = accountId) });
    provided.groupUnderKey(accountId, provided.getRecords()[0]);
    record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ 'openOpportunities' => provided });

    // Test
    Boolean qualifies = new AccountDeletionGuardHandler().qualifiesForBeforeDeleteWhen(record);

    // Verify
    Assert.isTrue(qualifies, 'An account with an open opportunity should qualify.');
}
```

`setProvidedRecords` is public, but `TriggerHandler` lists it under an internal-use comment, so it may change in a later version. A Finalizer that queries and updates, like the cleanup example, needs real records: test it in a separate integration test class. More in [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-delete/handler/other-contexts.md-->

The after contexts split the work into a [Writer](/after-delete/writer), which registers writes on a unit of work, and a [Dispatcher](/after-delete/dispatcher), which runs once with the qualified records.

## See Also {#see-also}

- [BeforeDelete](/before-delete/): how the context runs, and its gotchas.
- [Add-ons in BeforeDelete](/before-delete/add-ons/)
- [Record API in BeforeDelete](/before-delete/record-api)
- [AfterDelete.Writer](/after-delete/writer)
- [Testing](/guide/testing)
