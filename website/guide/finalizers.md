---
outline: deep
---

# Finalizers

Handlers process one record at a time, so anything that must be bulk, DML, callouts, platform events, is collected per record and executed once in a finalizer.

## Finalizer Interface

Implement the `Finalizer` interface of the context. `finalize...` runs once, after the action method was called for every qualified record.

```apex
public with sharing class OpportunityWonHandler implements AfterUpdate.Handler, AfterUpdate.Finalizer {
  private List<Task> followUps = new List<Task>();

  public Boolean qualifiesForAfterUpdateWhen(
    TriggerHandler.UpdateRecord record
  ) {
    return record.isChangedTo(Opportunity.StageName, 'Closed Won');
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    followUps.add(
      new Task(
        WhatId = record.getId(),
        OwnerId = (Id) record.getNewSObject().get(Opportunity.OwnerId),
        Subject = 'Schedule kick-off'
      )
    );
  }

  public void finalizeAfterUpdate() {
    insert followUps;
  }
}
```

## When It Runs

- It fires **exactly once** per handler, after the last qualified record of that handler and before the next handler in the orchestrator list starts. Not once per record, and not once per transaction.
- It **does not fire at all** when the handler qualifies no records. A handler whose predicate returned `false` for every record is skipped entirely, finalizer included. Do not use a finalizer for work that has to happen whether or not anything qualified.
- Records that a [recursion guard](/guide/recursion-control) skips never reach qualification. If the guard skips every record, nothing qualifies, and the finalizer does not fire.
- A DML of more than 200 records reaches the trigger in chunks of 200. Each chunk is a separate invocation with its own handler instances, so the finalizer fires once per chunk: 201 records means two runs, one over 200 records and one over 1.

## No DML in Before Contexts

In `before insert` and `before update` the DML guard covers the finalizer exactly like the action method. There is no opt-out.

```apex
public with sharing class AccountDefaultsHandler implements BeforeInsert.Populator, BeforeInsert.Finalizer {
  private List<Task> tasks = new List<Task>();

  public Boolean populateOnBeforeInsertWhen(
    TriggerHandler.InsertRecord record
  ) {
    return record.isBlank(Account.Rating);
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Account.Rating, 'Warm');
    tasks.add(new Task(Subject = 'Review rating'));
  }

  public void finalizeBeforeInsert() {
    insert tasks; // rejected, the whole DML is rolled back
  }
}
```

The framework raises a `TriggerOrchestratorException` naming the handler:

```
AccountDefaultsHandler performed DML in a before context.
Populate the trigger record instead, or move the DML to an after context.
```

Details worth knowing:

- Publishing a platform event with the **Publish Immediately** behaviour counts as DML here and is rejected the same way.
- `ContinueOnError` does not suppress it. That interface covers a handler's own exceptions, never a framework contract violation, so the exception still propagates and nothing is committed.
- Throwing after the DML does not get past the guard either. The check runs on the way out regardless of how the handler exited.

Move the DML to the matching after context. The before context is for populating the trigger record.

## Method Names

| Context        | Interface                 | Finalizer method        |
| -------------- | ------------------------- | ----------------------- |
| Before Insert  | `BeforeInsert.Finalizer`  | `finalizeBeforeInsert`  |
| After Insert   | `AfterInsert.Finalizer`   | `finalizeAfterInsert`   |
| Before Update  | `BeforeUpdate.Finalizer`  | `finalizeBeforeUpdate`  |
| After Update   | `AfterUpdate.Finalizer`   | `finalizeAfterUpdate`   |
| Before Delete  | `BeforeDelete.Finalizer`  | `finalizeBeforeDelete`  |
| After Delete   | `AfterDelete.Finalizer`   | `finalizeAfterDelete`   |
| After Undelete | `AfterUndelete.Finalizer` | `finalizeAfterUndelete` |

In `before insert` and `before update` the handler implements `Populator` or `Validator` rather than a plain `Handler`, but the `Finalizer` interface is the same and fires after the last qualified record either way.

## Collecting Work

Instance fields are the natural place to gather records. The orchestrator's handler list method is called once per invocation, so a list returning fresh instances starts every invocation with empty fields.

```apex
private Map<Id, Account> accountsById = new Map<Id, Account>();

public void onAfterInsert(TriggerHandler.InsertRecord record) {
    Contact contact = (Contact) record.getNewSObject();

    accountsById.put(contact.AccountId, new Account(Id = contact.AccountId, Has_Contacts__c = true));
}

public void finalizeAfterInsert() {
    update accountsById.values();
}
```

Using a map keyed by Id de-duplicates parents when several contacts share the same account.

## Errors in a Finalizer

An exception thrown by the finalizer is the handler's own exception and follows the usual rules: it aborts the DML and propagates, unless the handler implements the context's `ContinueOnError`, in which case the remaining handlers still run. Either way a `TriggerOrchestrator.Logger`, if one is implemented, receives it. See [Error Handling](/guide/error-handling).
