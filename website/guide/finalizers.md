---
outline: deep
---

# Finalizers

Handlers process one record at a time, so anything that must be bulk, DML, callouts, platform events, is collected per record and executed once in a finalizer.

## Finalizer Interface

Implement the `Finalizer` interface of the context. `finalize...` runs once per trigger invocation, after `on...` was called for every qualified record.

```apex
public with sharing class OpportunityWonHandler implements AfterUpdate.Handler, AfterUpdate.Finalizer {
  private List<Task> followUps = new List<Task>();

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChangedTo(Opportunity.StageName, 'Closed Won');
  }

  public void onAfterUpdate(TriggerHandler.Record record) {
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

- The finalizer runs only when at least one record qualified. A handler with no qualified records is skipped together with its finalizer.
- It runs after the last qualified record of the handler and before the next handler in the orchestrator list starts.
- In before insert and before update the DML guard covers the finalizer as well. A finalizer that performs DML in a before context throws unless the handler implements `AllowDmls`.

## Method Names

| Context        | Finalizer method        |
| -------------- | ----------------------- |
| Before Insert  | `finalizeBeforeInsert`  |
| After Insert   | `finalizeAfterInsert`   |
| Before Update  | `finalizeBeforeUpdate`  |
| After Update   | `finalizeAfterUpdate`   |
| Before Delete  | `finalizeBeforeDelete`  |
| After Delete   | `finalizeAfterDelete`   |
| After Undelete | `finalizeAfterUndelete` |

## Collecting Work

Instance fields are the natural place to gather records. The orchestrator creates a new handler instance on every invocation, so the lists start empty each time.

```apex
private Map<Id, Account> accountsById = new Map<Id, Account>();

public void onAfterInsert(TriggerHandler.Record record) {
    Contact contact = (Contact) record.getNewSObject();

    accountsById.put(contact.AccountId, new Account(Id = contact.AccountId, Has_Contacts__c = true));
}

public void finalizeAfterInsert() {
    update accountsById.values();
}
```

Using a map keyed by Id de-duplicates parents when several contacts share the same account.
