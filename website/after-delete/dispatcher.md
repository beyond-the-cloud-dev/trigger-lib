---
template: role
context: AfterDelete
interface: Dispatcher
description: Hand deleted records to a Queueable, callout, platform event or email once per chunk with an AfterDelete Dispatcher.
---

# AfterDelete.Dispatcher

Make one bulk call per chunk with the records that qualify, such as enqueueing a Queueable or publishing events.

**Signature**

<!--@include: @/_parts/generated/after-delete/dispatcher/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-delete/dispatcher/skeleton.md-->

```apex [Pass the values]
public with sharing class ContactRemovalSyncDispatcher implements AfterDelete.Dispatcher {
    public Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record) {
        return record.isNotBlank(Contact.Email) && record.isNull(Contact.MasterRecordId);
    }

    public void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records) {
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

## Rules {#rules}

- **No synchronous callouts.** A callout from a trigger throws a `System.CalloutException`. Call out from a Queueable that implements `Database.AllowsCallouts`.
- **No unit of work.** DML here runs at once and is not merged with the Writers' unit. Use a [Writer](/after-delete/writer) for record writes.
- **Merge losers arrive here too.** Skip them with `record.isNull(Contact.MasterRecordId)` when a merge should not count as a removal.
- **Writer wins.** A class that also implements `AfterDelete.Writer` runs only as a Writer.

::: warning
Pass values, not the deleted Ids. The job runs after the commit, when the deleted rows can no longer be queried. Pass the values it needs, or the Ids of records that still exist.
:::

## Test {#test}

```apex
@IsTest
static void dispatchOnAfterDeleteWithEmail() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@example.com');

    TriggerOrchestrator.mock().afterDeleteFor(ContactDispatcher.class).with(doe);

    // Test
    TriggerOrchestrator.runTestFor(new ContactDispatcher());

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued for the chunk.');
}
```
