---
template: role
context: AfterInsert
interface: Dispatcher
description: Make one bulk call per chunk after insert - enqueue a Queueable, publish events or send email for the records that qualified.
---

# AfterInsert.Dispatcher

Selects new records with a predicate, then acts once per chunk with the ones that qualified. Use it to enqueue a Queueable, publish events or send email.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/dispatcher/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/dispatcher/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Pass Ids to async work.** Enqueue one job with `records.getIds()` and let the job query what it needs.
- **No unit of work.** A Dispatcher never gets one, and OwnUnitOfWork is ignored. DML here runs at once and is not merged. Use a [Writer](/after-insert/writer) for record writes.
- **Runs before the shared commit.** The Writers' registrations are not saved yet, even from Writers listed earlier. A Publish Immediately event goes out even if that commit fails.
- **No synchronous callouts.** A callout from a trigger throws. Enqueue a Queueable that implements `Database.AllowsCallouts`.
- **Writer wins.** A class that also implements `AfterInsert.Writer` runs only as a Writer.

## Test {#test}

```apex
@IsTest
static void dispatchOnAfterInsertWhenEmailIsSet() {
    // Setup
    Contact newContact = new Contact(Email = 'jane.doe@example.com');

    // Test
    Boolean isQualified = new ContactDispatcher().dispatchOnAfterInsertWhen(new TriggerHandler.TriggerRecord(newContact, null));

    // Verify
    Assert.isTrue(isQualified, 'A contact with an email should be dispatched.');
}
```
