---
template: role
context: AfterUndelete
interface: Dispatcher
description: After undelete, make one bulk call per chunk with the restored records that qualify - enqueue a Queueable (async, callout), publish events or send email.
---

# AfterUndelete.Dispatcher

After records are restored from the Recycle Bin (**after undelete**), make one bulk call per chunk with the qualified records: enqueue a Queueable for async work or a callout, publish platform events, or send email.

<!--@include: @/_parts/generated/after-undelete/dispatcher/available-in.md-->

## When to Use {#when-to-use}

- Tell an external system that records are back: enqueue one Queueable with `records.getIds()` and call out from it.
- Publish events or send email once for the chunk, not once per record.
- Use a [Writer](/after-undelete/writer) instead for record DML that should be merged and committed with the other handlers' writes.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/dispatcher/signature.md-->

<!--@include: @/_parts/generated/after-undelete/dispatcher/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/dispatcher/skeleton.md-->

```apex [With a callout]
public with sharing class AccountRestoreDispatcher implements AfterUndelete.Dispatcher {
    public Boolean dispatchOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record) {
        return record.isNotBlank(Account.AccountNumber);
    }

    public void dispatchOnAfterUndelete(TriggerHandler.UndeleteRecords records) {
        System.enqueueJob(new RestoreSyncJob(records.getIds()));
    }

    public class RestoreSyncJob implements Queueable, Database.AllowsCallouts {
        private Set<Id> accountIds;

        public RestoreSyncJob(Set<Id> accountIds) {
            this.accountIds = accountIds;
        }

        public void execute(QueueableContext context) {
        }
    }
}
```

:::

The second tab enqueues one job per chunk for the restored Accounts that have an account number. The job implements `Database.AllowsCallouts`: query the Accounts by Id and make the callout in its `execute` method.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/dispatcher-loop.md-->

<!--@include: @/_parts/roles/dispatcher.md-->

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-undelete/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-undelete/accessors.md-->

- `dispatchOnAfterUndelete` receives `TriggerHandler.UndeleteRecords` with the qualified records only: `getIds()`, `getIdsOf(…)`, `getValuesOf(…)`, `size()` and `getRecords()`.
- The restored rows can be queried by Id, so pass `records.getIds()` to async work, not the rows.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/dispatcher/works-with.md-->

## Gotchas {#gotchas}

- **No unit of work.** Record DML here is direct DML: it runs at once, is not merged and costs its own statements.
- **Once per chunk.** Restoring 1,000 records means 5 dispatches: 5 jobs, 5 publishes or 5 emails.
- **Before the shared commit.** A Publish Immediately event published here reaches subscribers even if the shared commit later fails the restore.
- **Partial restores run it again.** With `Database.undelete(records, false)` and a failing record, Salesforce rolls back the first attempt and runs the handlers again for the remaining records, so Publish Immediately events may go out twice. Whether a job enqueued in the rolled-back attempt is discarded has not been verified, so make the job safe to run twice.
- **A self-delete fails.** Deleting a record that is being restored throws a `DmlException` with `SELF_REFERENCE_FROM_TRIGGER`.

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the dispatch method directly with the records your predicate would qualify, and count what it enqueued. `System.enqueueJob` is not DML, so the test stays DML-free:

```apex
@IsTest
static void dispatchOnAfterUndeleteWithTwoRecords() {
    // Setup
    List<TriggerHandler.TriggerRecord> qualified = new List<TriggerHandler.TriggerRecord>{
        new TriggerHandler.TriggerRecord(new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType)), null),
        new TriggerHandler.TriggerRecord(new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType)), null)
    };

    // Test
    new AccountRestoreDispatcher().dispatchOnAfterUndelete(new TriggerHandler.UndeleteTriggerRecords(qualified));

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued.');
}
```

Test the predicate the same way, with one `TriggerRecord` and `Assert.isTrue` or `Assert.isFalse`. More in [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/dispatcher/other-contexts.md-->

## See Also {#see-also}

- [AfterUndelete.Writer](/after-undelete/writer#platform-events)
- [AfterUndelete.Finalizer](/after-undelete/add-ons/finalizer)
- [Unit of Work](/guide/unit-of-work)
- [Testing](/guide/testing)
