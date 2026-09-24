---
template: role
context: AfterUpdate
interface: Dispatcher
description: After update, collect the qualifying records and make one bulk call per chunk, such as enqueueing a Queueable for a callout.
---

# AfterUpdate.Dispatcher

Make one bulk call per chunk with the records that qualify, such as enqueueing a Queueable or publishing events.

**Signature**

<!--@include: @/_parts/generated/after-update/dispatcher/signature.md-->

**Example**

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

## Rules {#rules}

- **One dispatch per chunk.** An update of 1,000 records dispatches 5 times, so the example enqueues 5 jobs. A synchronous transaction can enqueue at most 50 Queueable jobs.
- **No unit of work.** DML here runs at once and is not merged with the Writers' changes. Use a [Writer](/after-update/writer) for record changes that commit with the save.
- **Writers' changes may not be saved yet.** By default, their registrations commit after the last handler, so a query here does not see them.
- **Writer wins.** A class that also implements `AfterUpdate.Writer` runs only as a Writer.

::: warning
A callout here throws `System.CalloutException`. Call out from a Queueable that implements `Database.AllowsCallouts`, and pass it `records.getIds()`.
:::

## Test {#test}

```apex
@IsTest
static void dispatchOnAfterUpdateWhenStageChangedToClosedWon() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(new Opportunity(StageName = 'Closed Won'), new Opportunity(StageName = 'Negotiation/Review'));

    // Test
    Boolean result = new OpportunityWonSyncDispatcher().dispatchOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```
