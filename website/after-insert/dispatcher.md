---
template: role
context: AfterInsert
interface: Dispatcher
description: Make one bulk call per chunk after insert - enqueue a Queueable, publish events or send email for the records that qualified.
---

# AfterInsert.Dispatcher

Make one bulk call per chunk with the records that qualify, such as enqueueing a Queueable or publishing events.

**Signature**

<!--@include: @/_parts/generated/after-insert/dispatcher/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/dispatcher/skeleton.md-->

:::

## Rules {#rules}

- **Pass Ids to async work.** Let the job query what it needs.
- **No unit of work.** A Dispatcher never gets one, and OwnUnitOfWork is ignored. DML here runs at once and is not merged. Use a [Writer](/after-insert/writer) for record writes.
- **Publish with `EventBus.publish(events)`.** It runs at once, before the shared unit of work commits.
- **Writer wins.** A class that also implements `AfterInsert.Writer` runs only as a Writer.

::: warning
No synchronous callouts. A callout from a trigger throws, so enqueue a Queueable that implements `Database.AllowsCallouts`.
:::

## Test {#test}

```apex
@IsTest
static void dispatchOnAfterInsertWithEmail() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@example.com');

    TriggerOrchestrator.mock().afterInsertFor(ContactDispatcher.class).with(doe);

    // Test
    TriggerOrchestrator.runTestFor(new ContactDispatcher());

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued for the chunk.');
}
```
