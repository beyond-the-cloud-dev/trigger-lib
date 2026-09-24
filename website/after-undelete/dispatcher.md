---
template: role
context: AfterUndelete
interface: Dispatcher
description: After undelete, make one bulk call per chunk with the restored records that qualify - enqueue a Queueable (async, callout), publish events or send email.
---

# AfterUndelete.Dispatcher

Make one bulk call per chunk with the records that qualify, such as enqueueing a Queueable or publishing events.

**Signature**

<!--@include: @/_parts/generated/after-undelete/dispatcher/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/dispatcher/skeleton.md-->

:::

## Rules {#rules}

- **Pass Ids, not rows.** Hand `records.getIds()` to async work and query the records there.
- **Call out from a Queueable.** Give the job `Database.AllowsCallouts` and make the callout in `execute`.
- **No unit of work.** DML here runs at once and is not merged. Change records from a [Writer](/after-undelete/writer).
- **Writer wins.** A class that also implements `AfterUndelete.Writer` runs only as a Writer.

::: warning
The Dispatcher runs before the commit. A Publish Immediately event sent here reaches subscribers even if the restore fails later.
:::

## Test {#test}

```apex
@IsTest
static void dispatchOnAfterUndeleteEnqueuesOneJob() {
    // Setup
    Contact restoredContact = new Contact(Id = new TriggerTypes.RandomIdGenerator().get(Contact.SObjectType));
    List<TriggerTypes.TriggerRecord> qualified = new List<TriggerTypes.TriggerRecord>{ new TriggerTypes.TriggerRecord(restoredContact, null) };

    // Test
    new ContactDispatcher().dispatchOnAfterUndelete(new TriggerTypes.UndeleteTriggerRecords(qualified));

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued.');
}
```
