---
template: role
context: AfterUndelete
interface: Dispatcher
description: After undelete, make one bulk call per chunk with the restored records that qualify - enqueue a Queueable (async, callout), publish events or send email.
---

# AfterUndelete.Dispatcher

Makes one bulk call per chunk with the restored records that qualify: enqueue a Queueable, publish platform events or send email.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/dispatcher/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/dispatcher/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Pass Ids, not rows.** Hand `records.getIds()` to async work and query the records there.
- **Call out from a Queueable.** Give the job `Database.AllowsCallouts` and make the callout in `execute`.
- **No unit of work.** DML here runs at once and is not merged. Change records from a [Writer](/after-undelete/writer).
- **Runs before the commit.** A Publish Immediately event sent here reaches subscribers even if the restore fails later.
- **Writer wins.** A class that also implements `AfterUndelete.Writer` runs only as a Writer.

## Test {#test}

```apex
@IsTest
static void dispatchOnAfterUndeleteEnqueuesOneJob() {
    // Setup
    Contact restoredContact = new Contact(Id = new TriggerHandler.RandomIdGenerator().get(Contact.SObjectType));
    List<TriggerHandler.TriggerRecord> qualified = new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(restoredContact, null) };

    // Test
    new ContactDispatcher().dispatchOnAfterUndelete(new TriggerHandler.UndeleteTriggerRecords(qualified));

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued.');
}
```
