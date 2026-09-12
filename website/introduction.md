---
outline: deep
---

# Introduction

Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of production-ready Salesforce libraries by [Beyond the Cloud](https://beyondthecloud.dev).

A trigger calls the orchestrator. The orchestrator lists its handlers per context. The framework pulls parent data, guards recursion, qualifies records and runs each handler record by record.

## Features

- **Orchestrator & Handlers** - One orchestrator per SObject, one handler per concern, wired in Apex
- **Record Filtering** - Handlers run only against records that qualify, so logic never guards itself
- **Parent Enrichment** - Related data is pulled up front, so handlers make no SOQL queries of their own
- **Bypasses** - Skip a single handler from code, or a handler or a whole object from metadata
- **Recursion Control** - Depth limiting built in, defaulting to three passes per record
- **No Required Metadata** - Works with zero custom metadata records; metadata only overrides defaults

## Why Trigger Lib?

### Handlers work on a single record

The framework iterates over `Trigger.new` and `Trigger.old` for you. A handler receives one record at a time and has no bulk loop of its own. Bulkification happens in the orchestrator, not in every handler.

The record is not an `SObject`. It is one of four context-specific interfaces, and each handler method takes the one that matches its context:

| Context | Record interface | Sides available |
| --- | --- | --- |
| Before insert, after insert | `TriggerHandler.InsertRecord` | new only |
| Before update, after update | `TriggerHandler.UpdateRecord` | new and old |
| Before delete, after delete | `TriggerHandler.DeleteRecord` | old only |
| After undelete | `TriggerHandler.UndeleteRecord` | new only |

The interface carries only what its context can answer. `DeleteRecord` has no `getNewSObject`, `InsertRecord` has no `isChanged`, and neither `DeleteRecord` nor `UndeleteRecord` has `put`.

### Before contexts have roles

`BeforeInsert` and `BeforeUpdate` do not have a plain handler interface. A class picks a role:

- `Populator` - sets values on the triggering record.
- `Validator` - decides that a record is invalid and supplies the message the framework attaches with `addError`.

Exactly one role per context, per class. A class that implements both, or neither, is rejected with a `TriggerOrchestratorException` that names the class and both interfaces. `BeforeInsert.Handler` and `BeforeUpdate.Handler` are empty markers that `Populator` and `Validator` extend so the orchestrator can hold them in one list; you never implement them directly.

The other five contexts - after insert, after update, before delete, after delete, after undelete - use a plain `Handler` interface with a `qualifiesFor...When` predicate and an `on...` action.

### Records are qualified before handlers run

Every handler declares a predicate: `qualifiesFor...When` for a plain handler, `populateOn...When` for a populator, `errorShouldBeAttachedOn...When` for a validator. Only records that pass it reach the action method. The predicate API is fluent and null-safe: `isChangedTo`, `isRecordTypeEqual`, `isBlank`, `greaterThan` and more.

The predicate is evaluated at the handler's own turn, immediately before that handler runs, not in one pass up front. A handler therefore sees the field values that handlers earlier in the list already wrote. Registration order in the orchestrator is part of the behaviour, not a cosmetic choice.

### Parents are enriched, not queried

A handler declares the parent lookups and fields it needs. The framework runs one query per lookup field, merges the field lists of all active handlers and attaches the parent record to each trigger record. Handlers never write SOQL.

Enrichment happens once, up front, for every handler in the context, before the first predicate is evaluated. `getNewRelated` and `getOldRelated` are therefore safe to call from a qualification predicate.

### Guard rails are built in

- DML inside a before insert or before update handler throws and rolls the DML back.
- Update handlers run at most three times per record.
- Errors are reported to a pluggable logger before they propagate.

## Quick Example

### Trigger

```apex
trigger ContactTrigger on Contact(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete,
  after undelete
) {
  TriggerOrchestrator.run(new ContactTriggerOrchestrator());
}
```

A context the orchestrator does not implement is a silent no-op, so listing all seven events costs nothing.

### Orchestrator

```apex
public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterUpdate {
  public List<BeforeInsert.Handler> beforeInsertHandlers() {
    return new List<BeforeInsert.Handler>{
      new ContactDescriptionPopulator(),
      new ContactEmailValidator()
    };
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new ContactAccountSyncHandler() };
  }
}
```

### Before Insert Populator

```apex
public with sharing class ContactDescriptionPopulator implements BeforeInsert.Populator {
  public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
    return record.isBlank(Contact.Description);
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Contact.Description, 'Created by ContactDescriptionPopulator');
  }
}
```

`put` returns nothing, so there is no chaining. One call per field.

### Before Insert Validator

```apex
public with sharing class ContactEmailValidator implements BeforeInsert.Validator {
  public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
    return record.isBlank(Contact.Email);
  }

  public String beforeInsertValidationMessage(TriggerHandler.InsertRecord record) {
    return 'Email is required on a new contact.';
  }
}
```

The validator never calls `addError` itself. It returns the message and the framework attaches it, so the record is blocked and carries exactly that string as its DML error.

### After Update Handler With Parent Enrichment

```apex
public with sharing class ContactAccountSyncHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.Finalizer {
  private List<Account> accountsToUpdate = new List<Account>();

  public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
    return new Map<SObjectField, TriggerHandler.FieldSelection>{
      Contact.AccountId => TriggerHandler.FieldSelection.with(
        Account.Name,
        Account.Industry
      )
    };
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isChanged(Contact.Email) &&
      record.isNotNull(Contact.AccountId);
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    Account account = (Account) record.getNewRelated('Account');

    this.accountsToUpdate.add(
      new Account(
        Id = account.Id,
        Description = 'Contact email changed: ' + account.Name
      )
    );
  }

  public void finalizeAfterUpdate() {
    update this.accountsToUpdate;
  }
}
```

The handler collects work per record and performs a single DML in the finalizer, which runs once after all qualified records were processed. A handler that qualifies no records does not run its finalizer at all.

## Execution Flow

`TriggerOrchestrator.run` does the following for the current `Trigger.operationType`:

1. Throws a `TriggerOrchestratorException` if it was not called from a trigger.
2. Reads the bypass metadata and returns immediately if the object is bypassed.
3. Picks the handlers returned by the matching orchestrator method, for example `afterUpdateHandlers()`. A context the orchestrator does not implement does nothing.
4. Checks the before insert and before update roles, and throws if a class implements both or neither.
5. Drops handlers bypassed in metadata or by their own `bypassOn...When()`.
6. Collects parent fields declared by the remaining handlers and queries them, one query per lookup field.
7. Runs the handlers in list order. For each handler: records past its recursion budget are skipped, the qualification predicate is evaluated, the action runs for each qualified record, then the handler's finalizer runs once.
8. Calls `finalize()` on the logger when the outermost invocation finishes.

## Sharp Edges

These are the places where the framework will bite. They are documented rather than hidden.

- **DML in a before context aborts the DML.** A populator, validator or before-context finalizer that performs DML, or publishes an immediate platform event, causes a `TriggerOrchestratorException` naming the handler. Nothing is committed. Throwing after the DML does not get past the check.
- **`ContinueOnError` never suppresses a framework error.** It covers a handler's own exceptions. Any `TriggerOrchestratorException` is logged and rethrown, and the DML is aborted.
- **`put` in an after context loses the transaction.** After insert and after update records are read-only in Apex, and `put` raises `System.FinalException: Record is read-only`, which cannot be caught. The type system does not stop you, because `InsertRecord` and `UpdateRecord` serve both the before and after phases.
- **Recursion limits are silent.** A record that reaches a handler more times than its guard allows is skipped for that handler. No exception is thrown, nothing reaches the logger, and the DML succeeds.
- **Record type helpers throw on objects without record types.** `isRecordTypeEqual` and `isRecordTypeNotEqual` raise a `TriggerHandler.TriggerHandlerException` naming the SObject when it has no record types beyond Master.
- **Only one logger.** Two classes implementing `TriggerOrchestrator.Logger` cause a `TriggerOrchestratorException`.

## Next Steps

- [Installation](/installation)
- [Design Principles](/introduction/design-principles)
- [Orchestrator](/guide/orchestrator)
- [Handlers](/guide/handlers)
- [Record Qualification](/guide/qualification)
- [Parent Enrichment](/guide/enrichment)
