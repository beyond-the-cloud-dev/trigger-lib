---
outline: deep
---

# Handlers

A handler is a class that implements the `Handler` interface of one or more trigger contexts. Each context lives in its own top-level class: `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete` and `AfterUndelete`.

## Handler Interface

Every `Handler` interface has two methods: a qualification predicate and an action. Both receive a single `TriggerHandler.Record`.

```apex
public with sharing class OpportunityCloseDateHandler implements BeforeUpdate.Handler {
  public Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record) {
    return record.isChangedTo(Opportunity.StageName, 'Closed Won') &&
      record.isNull(Opportunity.CloseDate);
  }

  public void onBeforeUpdate(TriggerHandler.Record record) {
    record.put(Opportunity.CloseDate, Date.today());
  }
}
```

The method names follow the context:

| Context        | Qualification                   | Action            |
| -------------- | ------------------------------- | ----------------- |
| Before Insert  | `qualifiesForBeforeInsertWhen`  | `onBeforeInsert`  |
| After Insert   | `qualifiesForAfterInsertWhen`   | `onAfterInsert`   |
| Before Update  | `qualifiesForBeforeUpdateWhen`  | `onBeforeUpdate`  |
| After Update   | `qualifiesForAfterUpdateWhen`   | `onAfterUpdate`   |
| Before Delete  | `qualifiesForBeforeDeleteWhen`  | `onBeforeDelete`  |
| After Delete   | `qualifiesForAfterDeleteWhen`   | `onAfterDelete`   |
| After Undelete | `qualifiesForAfterUndeleteWhen` | `onAfterUndelete` |

## Optional Capabilities

Capabilities are opt-in interfaces from the same context class. Implement the ones a handler needs. See [Context Interfaces](/api/context-interfaces) for the full matrix.

| Capability            | Purpose                                                        | Guide                                         |
| --------------------- | -------------------------------------------------------------- | --------------------------------------------- |
| `NewRecordEnrichment` | Declare parent fields to query for the new record              | [Parent Enrichment](/guide/enrichment)        |
| `OldRecordEnrichment` | Declare parent fields to query for the old record              | [Parent Enrichment](/guide/enrichment)        |
| `Bypassable`          | Skip the handler for the whole invocation                      | [Bypasses](/guide/bypasses)                   |
| `RecursionGuard`      | Override the per-record execution limit (update contexts only) | [Recursion Control](/guide/recursion-control) |
| `Finalizer`           | Run once after all qualified records were processed            | [Finalizers](/guide/finalizers)               |
| `AllowDmls`           | Permit DML in a before insert or before update handler         | [Before Context DML](#before-context-dml)     |
| `ContinueOnError`     | Log the exception and continue with the next handler           | [Error Handling](/guide/error-handling)       |

## One Record at a Time

`on...` is called once per qualified record. The handler never sees `Trigger.new` and has no loop of its own. This keeps handlers short, but it means any DML or callout must be collected and executed once, in a [finalizer](/guide/finalizers).

```apex
public with sharing class CaseEscalationHandler implements AfterUpdate.Handler, AfterUpdate.Finalizer {
  private List<Task> tasksToInsert = new List<Task>();

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChangedTo(Case.Priority, 'High');
  }

  public void onAfterUpdate(TriggerHandler.Record record) {
    tasksToInsert.add(
      new Task(WhatId = record.getId(), Subject = 'Escalated case')
    );
  }

  public void finalizeAfterUpdate() {
    insert tasksToInsert;
  }
}
```

## Handler Instances

The orchestrator creates a new handler instance on every trigger invocation, so instance fields are a safe place to accumulate work for the finalizer. Use static fields only for state that must survive across invocations in one transaction.

## Before Context DML

A before insert or before update handler exists to populate the triggering records. The framework compares `Limits.getDmlStatements()` and `Limits.getPublishImmediateDML()` before and after the handler runs and throws when either increased:

```
AccountDefaultsHandler performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.
```

Implement `BeforeInsert.AllowDmls` or `BeforeUpdate.AllowDmls` to switch the guard off for a specific handler.

```apex
public with sharing class LegacyAccountHandler implements BeforeUpdate.Handler, BeforeUpdate.AllowDmls {
  // ...
}
```

Before delete has no such guard. Cascading cleanup of other objects is a valid use of a before delete handler.

## Reading and Writing the Record

`TriggerHandler.Record` wraps the new and old versions of a record. Use `put` to populate a field in a before context and `getNewSObject` or `getOldSObject` when you need the raw SObject.

```apex
public void onBeforeInsert(TriggerHandler.Record record) {
    Contact contact = (Contact) record.getNewSObject();

    record.put(Contact.Description, 'Created from ' + contact.LeadSource);
}
```

The full predicate and accessor API is documented under [TriggerHandler.Record](/api/record).
