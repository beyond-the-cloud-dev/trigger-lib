---
template: role
context: AfterUpdate
interface: Dispatcher
description: 'After update, collect the qualifying records and make one bulk call per chunk, such as enqueueing a Queueable for a callout, publishing events or sending email.'
---

# AfterUpdate.Dispatcher

After update, collect the records that qualify and make one bulk call per chunk with them: enqueue a Queueable (async work, a callout), publish platform events, send email or submit approvals.

<!--@include: @/_parts/generated/after-update/dispatcher/available-in.md-->

## When to Use {#when-to-use}

- One call for many records, such as syncing won opportunities to an external system through a Queueable that calls out.
- Work that should not slow down or fail the save, handed to async Apex.
- Use a [Writer](/after-update/writer) instead for record DML that should be merged and committed with the other handlers, or for an event that must roll back with the save (`toPublish`).

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/dispatcher/signature.md-->

<!--@include: @/_parts/generated/after-update/dispatcher/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/dispatcher/skeleton.md-->

```apex [Enqueue a callout]
public with sharing class OpportunityWonSyncDispatcher implements AfterUpdate.Dispatcher {
    public Boolean dispatchOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Won');
    }

    public void dispatchOnAfterUpdate(TriggerHandler.UpdateRecords records) {
        System.enqueueJob(new SyncJob(records.getIds()));
    }

    public class SyncJob implements Queueable, Database.AllowsCallouts {
        private Set<Id> opportunityIds;

        public SyncJob(Set<Id> opportunityIds) {
            this.opportunityIds = opportunityIds;
        }

        public void execute(QueueableContext context) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Erp/opportunities');
            request.setMethod('POST');
            request.setBody(JSON.serialize([SELECT Id, Name, Amount FROM Opportunity WHERE Id IN :this.opportunityIds]));
            new Http().send(request);
        }
    }
}
```

:::

The callout runs in the Queueable, after the transaction commits: a trigger cannot call out, and `Database.AllowsCallouts` is what lets the job do it. `callout:Erp` stands for a Named Credential of your own.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/dispatcher-loop.md-->

<!--@include: @/_parts/roles/dispatcher.md-->

In after update, a record that has used up this Dispatcher's recursion budget is skipped before its predicate, and every record that qualifies spends one pass, although nothing is written per record. See [RecursionGuard](/after-update/add-ons/recursion-guard).

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-update/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-update/accessors.md-->

- `dispatchOnAfterUpdate` receives `TriggerHandler.UpdateRecords` with the qualified records only: `getIds()`, `getIdsOf(…)`, `getOldIdsOf(…)`, `getValuesOf(…)`, `getOldValuesOf(…)`, `size()` and `getRecords()`. Every method: [Record API in AfterUpdate](/after-update/record-api#collections).
- `getRecords()` returns the library's own list, not a copy, and the Finalizer receives the same list.
- Pass Ids to async work, `records.getIds()`, and let the job query what it needs.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/dispatcher/works-with.md-->

## Gotchas {#gotchas}

- **One job per chunk.** A statement of 1,000 records makes the example enqueue 5 jobs. A synchronous transaction can enqueue at most 50 Queueable jobs, and every chunk of the statement counts toward that limit.
- **Partial saves dispatch again.** When a partial save (`Database.update(records, false)`, Data Loader, Bulk API) retries the surviving records, the Dispatcher runs again for them. Whether a job enqueued in the rolled-back attempt is discarded is not verified, so make the job safe to run twice.
- **Recursion budget.** A self-update that re-runs AfterUpdate can dispatch the same record again, up to 3 times per transaction by default. Qualify on a change (`isChangedTo`), as the example does.

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the predicate and the dispatch method directly. This test runs the Skeleton's dispatch, whose job does nothing, so it needs no callout mock. Enqueueing a job is not DML:

```apex
@IsTest
static void dispatchOnAfterUpdateEnqueuesOneJob() {
    // Setup
    Id contactId = new TriggerHandler.RandomIdGenerator().get(Contact.SObjectType);
    List<TriggerHandler.TriggerRecord> qualified = new List<TriggerHandler.TriggerRecord>{
        new TriggerHandler.TriggerRecord(new Contact(Id = contactId, Email = 'new@example.com'), new Contact(Id = contactId, Email = 'old@example.com'))
    };

    // Test
    new ContactDispatcher().dispatchOnAfterUpdate(new TriggerHandler.UpdateTriggerRecords(qualified));

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued.');
}
```

```apex
@IsTest
static void dispatchOnAfterUpdateWhenStageChangedToClosedWon() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
        new Opportunity(StageName = 'Closed Won'),
        new Opportunity(StageName = 'Negotiation/Review')
    );

    // Test
    Boolean result = new OpportunityWonSyncDispatcher().dispatchOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```

More techniques, including running the whole orchestrator (same namespace only): [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/dispatcher/other-contexts.md-->

## See Also {#see-also}

- [Before → after handoff](/guide/orchestrator#before-after-handoff): act on a value a BeforeUpdate Populator stamped.
- [AfterUpdate.Writer](/after-update/writer#platform-events): publish events that commit with the save.
- [Unit of Work](/guide/unit-of-work)
