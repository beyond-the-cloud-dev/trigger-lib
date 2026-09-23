---
template: role
context: AfterUpdate
interface: Writer
description: 'After update, create, update or delete other records (children, parents, tasks) or publish platform events through a unit of work that commits with the save.'
---

# AfterUpdate.Writer

After update, change other records (update children or the parent, create a follow-up task, delete records) or publish platform events, per record, through a unit of work that commits with the save.

<!--@include: @/_parts/generated/after-update/writer/available-in.md-->

## When to Use {#when-to-use}

- Cascade a change to children or to the parent, such as a new billing address to the account's contacts.
- Create a record when a field changes to a value, such as a task when an opportunity is won.
- Publish a platform event that must roll back with the save (`toPublish`).
- Use a [Dispatcher](/after-update/dispatcher) instead for a Queueable, a callout or email, and [BeforeUpdate.Populator](/before-update/populator) for fields on the record being updated.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/writer/signature.md-->

<!--@include: @/_parts/generated/after-update/writer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/writer/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [Update the parent]

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [Insert a record]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [Update children]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/roles/per-record-loop.md-->

<!--@include: @/_parts/roles/writer.md-->

In after update, a record that has used up this Writer's recursion budget is skipped before its predicate, and every record that qualifies spends one pass. See [RecursionGuard](/after-update/add-ons/recursion-guard).

### Unit of Work Methods {#unit-of-work-methods}

<!--@include: @/_parts/uow/methods.md-->

### Which Unit You Get {#which-unit}

<!--@include: @/_parts/uow/which-unit.md-->

### When It Commits {#when-it-commits}

<!--@include: @/_parts/uow/commit-timing.md-->

In after update, a `toUpdate` of records of the object being updated runs BeforeUpdate and AfterUpdate again during the commit, as nested runs.

### Platform Events {#platform-events}

<!--@include: @/_parts/uow/platform-events.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-update/register.md-->

## Records Here {#records}

<!--@include: @/_parts/generated/after-update/accessors.md-->

- `put` throws `System.FinalException` here, and so does any field assignment on `getNewSObject()` or `getOldSObject()`.
- To change the record being updated, set the value in a [BeforeUpdate.Populator](/before-update/populator), or register a new instance with its Id, `toUpdate(new Opportunity(Id = record.getId(), …))`, which runs the update triggers again.
- `getNewParent` and `getOldParent` return null unless the Writer, or another active handler, declares that lookup in a [ParentQuery](/after-update/add-ons/parent-query) or a [PriorParentQuery](/after-update/add-ons/prior-parent-query).

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/writer/works-with.md-->

## Gotchas {#gotchas}

- **A self-update runs the update triggers again.** Updating records of the object being updated re-runs BeforeUpdate and AfterUpdate for them during the commit. Gate the predicate on a change, `isChanged` or `isChangedTo`, and see the [overview gotchas](/after-update/#gotchas).
- **Registrations on the shared unit are merged.** When two opportunities of one account are won in the same chunk, `OpportunityAccountTypeWriter` registers the same Account twice; the shared unit merges them into one update, and fields set by the later registration win.
- **Private units commit first.** `OpportunityWinTaskWriter` implements ContinueOnError, so its Tasks are inserted by its private unit right after it runs, while the Account updates that `OpportunityAccountTypeWriter` registered earlier on the shared unit are saved only after the last handler.
- **Parents are loaded before the first handler.** A parent that an earlier Writer registered for update on the shared unit still shows its old values in `getNewParent`, because the unit has not committed yet.

<!--@include: @/_parts/roles/one-role.md#after-->

## Test It {#test}

Call the predicate and the action directly with a record built in memory. For the action, pass a small class of your own that keeps what it receives:

```apex
private class RecordingUnitOfWork implements TriggerHandler.UnitOfWork {
    public List<SObject> inserted = new List<SObject>();

    public TriggerHandler.UnitOfWork toInsert(SObject record) { this.inserted.add(record); return this; }
    public TriggerHandler.UnitOfWork toInsert(DML.Record record) { return this; }
    public TriggerHandler.UnitOfWork toUpdate(SObject record) { return this; }
    public TriggerHandler.UnitOfWork toUpdate(DML.Record record) { return this; }
    public TriggerHandler.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) { return this; }
    public TriggerHandler.UnitOfWork toDelete(SObject record) { return this; }
    public TriggerHandler.UnitOfWork toPublish(SObject event) { return this; }
}
```

```apex
@IsTest
static void writeOnAfterUpdateWhenStageChangedToClosedWon() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
        new Opportunity(StageName = 'Closed Won'),
        new Opportunity(StageName = 'Negotiation/Review')
    );

    // Test
    Boolean result = new OpportunityWinTaskWriter().writeOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```

```apex
@IsTest
static void writeOnAfterUpdateTaskSubject() {
    // Setup
    Opportunity won = new Opportunity(Id = new TriggerHandler.RandomIdGenerator().get(Opportunity.SObjectType), Name = 'Renewal', StageName = 'Closed Won');
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(won, new Opportunity(StageName = 'Negotiation/Review'));
    record.enrichNew('Account', new Account(Name = 'Acme'));
    RecordingUnitOfWork unitOfWork = new RecordingUnitOfWork();

    // Test
    new OpportunityWinTaskWriter().writeOnAfterUpdate(record, unitOfWork);

    // Verify
    Assert.areEqual('Onboarding kick-off: Acme', ((Task) unitOfWork.inserted[0]).Subject, 'Wrong task subject.');
}
```

`enrichNew` attaches the parent that ParentQuery would load. It is public, but `TriggerHandler` lists it under an internal-use comment, so it may change in a later version. Running the whole orchestrator with the shared unit mocked through `DML.mock('triggerUow')` works in the same namespace only: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/writer/other-contexts.md-->

## See Also {#see-also}

- [Before → after handoff](/guide/orchestrator#before-after-handoff): act on a value a BeforeUpdate Populator stamped.
- [Unit of Work](/guide/unit-of-work) and [TriggerHandler.UnitOfWork](/api/unit-of-work)
- [AfterUpdate.OwnUnitOfWork](/after-update/add-ons/own-unit-of-work): user mode, sharing, partial success or your own statement order.
- [AfterUpdate.Dispatcher](/after-update/dispatcher)
