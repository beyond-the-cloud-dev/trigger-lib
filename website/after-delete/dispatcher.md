---
template: role
context: AfterDelete
interface: Dispatcher
description: Hand work to a Queueable, callout, platform event or email once per chunk after records are deleted, with an AfterDelete Dispatcher.
---

# AfterDelete.Dispatcher

A Dispatcher runs in **after delete**, collects the deleted records its predicate accepts, and hands them over once per chunk: enqueue a job that makes a callout to an external system, send one email, or publish an event. Skip it (bypass) with Bypassable.

<!--@include: @/_parts/generated/after-delete/dispatcher/available-in.md-->

## When to Use {#when-to-use}

- Tell an external system that records were removed, from a Queueable that implements `Database.AllowsCallouts`.
- Send one email or publish one set of events per chunk, not per record.
- Use a [Writer](/after-delete/writer) instead for record writes that must commit with the delete.
- Use [BeforeDelete.Handler](/before-delete/handler) instead to stop the delete.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/dispatcher/signature.md-->

<!--@include: @/_parts/generated/after-delete/dispatcher/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/dispatcher/skeleton.md-->

```apex [Pass the values]
public with sharing class ContactRemovalSyncDispatcher implements AfterDelete.Dispatcher {
    public Boolean dispatchOnAfterDeleteWhen(TriggerHandler.DeleteRecord record) {
        return record.isNotBlank(Contact.Email) && record.isNull(Contact.MasterRecordId);
    }

    public void dispatchOnAfterDelete(TriggerHandler.DeleteRecords records) {
        System.enqueueJob(new RemovalSyncJob(records.getValuesOf(Contact.Email)));
    }

    public class RemovalSyncJob implements Queueable, Database.AllowsCallouts {
        private Set<String> emails;

        public RemovalSyncJob(Set<String> emails) {
            this.emails = emails;
        }

        public void execute(QueueableContext context) {
        }
    }
}
```

:::

The second tab passes the email addresses themselves, because the job runs after the transaction commits and can no longer query the deleted contacts. It also skips merge losers.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/dispatcher-loop.md-->

<!--@include: @/_parts/roles/dispatcher.md-->

Nothing is counted in after delete: there is no recursion guard, so every record is offered to the predicate once per run.

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-delete/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-delete/accessors.md-->

`dispatchOnAfterDelete` receives `DeleteRecords` with the qualified records only:

- `getIds()` returns the deleted Ids, which SOQL no longer finds.
- `getIdsOf(Contact.AccountId)` and `getValuesOf(Contact.Email)` read the old rows. `getIdsOf('Account', Account.OwnerId)` walks the former parents that a PriorParentQuery loaded.
- There is no `getOldIdsOf`: `getIdsOf` already reads the old row.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/dispatcher/works-with.md-->

## Gotchas {#gotchas}

- **Pass values, not only Ids.** A job enqueued here runs after the commit, when the deleted rows are gone from ordinary SOQL. Pass the values it needs, or the Ids of records that still exist, such as the former parents.
- **Merge losers arrive here too.** Filter them with `record.isNull(Contact.MasterRecordId)` when a merge should not count as a removal.
- **Partial deletes run twice.** With `Database.delete(records, false)` and one failing record, the platform re-runs the handlers for the survivors. Publish Immediately events from the first attempt are not rolled back, so they can go out twice; whether emails repeat is not verified.

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the dispatch method directly with a `DeleteTriggerRecords` built from an in-memory old row, and assert on `Limits.getQueueableJobs()` right after the call, so the test does not depend on the job running. Test the job's `execute` in its own test, with a callout mock. This test covers the Skeleton tab:

```apex
@IsTest
static void dispatchOnAfterDeleteEnqueuesOneJob() {
    // Setup
    Contact oldContact = new Contact(Id = new TriggerHandler.RandomIdGenerator().get(Contact.SObjectType), LastName = 'Doe', Email = 'jane@acme.com');
    TriggerHandler.DeleteRecords records = new TriggerHandler.DeleteTriggerRecords(new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(null, oldContact) });

    // Test
    new ContactDispatcher().dispatchOnAfterDelete(records);

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued for the chunk.');
}
```

Test the predicate the same way, with `new TriggerHandler.TriggerRecord(null, oldContact)`. More techniques: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/dispatcher/other-contexts.md-->

## See Also {#see-also}

- [AfterDelete](/after-delete/) overview and [AfterDelete.Writer](/after-delete/writer)
- [AfterDelete add-ons](/after-delete/add-ons/): PriorParentQuery, RelatedQuery, Finalizer
- [Execution Order & Cost](/guide/execution-order)
- [Record API in AfterDelete](/after-delete/record-api)
