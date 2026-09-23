---
template: role
context: AfterInsert
interface: Dispatcher
description: AfterInsert.Dispatcher - after insert, make one bulk call per chunk with the qualified records - enqueue a Queueable for a callout, publish events, send email or submit approvals.
---

# AfterInsert.Dispatcher

After insert, make one bulk call per chunk with the qualified records: enqueue a Queueable (async work, a callout), publish platform events, send email or submit records for approval. A Dispatcher selects records with a predicate and then acts once, instead of once per record.

<!--@include: @/_parts/generated/after-insert/dispatcher/available-in.md-->

## When to Use {#when-to-use}

- A side effect that is one call for many records: one job, one publish, one email batch.
- A callout: enqueue a Queueable that implements `Database.AllowsCallouts` and pass it the Ids.
- Use a [Writer](/after-insert/writer) instead for record DML that should be merged with the other handlers' writes and commit with the save.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/dispatcher/signature.md-->

<!--@include: @/_parts/generated/after-insert/dispatcher/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/dispatcher/skeleton.md-->

```apex [Publish once per chunk]
public with sharing class AccountSyncDispatcher implements AfterInsert.Dispatcher {
    public Boolean dispatchOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
        return record.startsWith(Account.Type, 'Partner');
    }

    public void dispatchOnAfterInsert(TriggerHandler.InsertRecords records) {
        List<AccountSync__e> events = new List<AccountSync__e>();

        for (Id accountId : records.getIds()) {
            events.add(new AccountSync__e(AccountId__c = accountId));
        }

        new DML().identifier('AccountSyncDispatcher').publishImmediately(events);
    }
}
```

:::

`AccountSync__e` stands for a platform event object in your org, with a Text field `AccountId__c`. `publishImmediately` calls `EventBus.publish` at once; the identifier lets a test mock the publish.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/dispatcher-loop.md-->

<!--@include: @/_parts/roles/dispatcher.md-->

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-insert/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-insert/accessors.md-->

- **The dispatch method gets `InsertRecords`**, the qualified records only. `getIds()` works here, unlike in before insert. The other methods are listed on [Record API in AfterInsert](/after-insert/record-api#collections).
- **`getRecords()` is the library's own list**, not a copy. Removing items from it changes what the Finalizer receives.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/dispatcher/works-with.md-->

## Gotchas {#gotchas}

- **It never receives a unit of work**, and OwnUnitOfWork is ignored. Record DML here is direct DML: it runs at once, is not merged and costs its own statement.
- **Once per chunk.** A 1,000-record insert dispatches up to 5 times: 5 jobs, 5 publishes, 5 email calls.
- **Its side effects happen before the shared commit.** If that commit fails, Publish Immediately events have already gone out. Emails and enqueued jobs are sent or started only when the transaction commits.
- **Partial saves run it again.** When a partial save re-runs the handlers for the records that did not fail, Publish Immediately events published in the first attempt are not rolled back and can go out twice.

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the dispatch method with the records the predicate would qualify, and mock the publish by its identifier:

```apex
@IsTest
static void dispatchOnAfterInsertPublishesOneEventPerAccount() {
    // Setup
    DML.mock('AccountSyncDispatcher').allPublishes();
    Account partner = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Type = 'Partner');

    // Test
    new AccountSyncDispatcher().dispatchOnAfterInsert(new TriggerHandler.InsertTriggerRecords(new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(partner, null) }));

    // Verify
    Assert.areEqual(1, DML.retrieveResultFor('AccountSyncDispatcher').eventsOf(AccountSync__e.SObjectType).records().size(), 'One event should be published.');
}
```

The mocked publish never reaches `EventBus.publish`, so nothing is published and no DML runs. Test the predicate on its own, one case per test, such as `dispatchOnAfterInsertWhenTypeIsCustomer`. More in [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/dispatcher/other-contexts.md-->

## See Also {#see-also}

- [AfterInsert.Writer, Platform Events](/after-insert/writer#platform-events): publish with the save instead
- [Unit of Work](/guide/unit-of-work)
- [AfterInsert](/after-insert/): how the run is ordered
