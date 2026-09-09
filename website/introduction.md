---
outline: deep
---

# Introduction

Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of production-ready Salesforce libraries by [Beyond the Cloud](https://beyondthecloud.dev).

A trigger calls the orchestrator. The orchestrator lists its handlers per context. The framework qualifies records, pulls parent data, guards recursion and runs each handler record by record.

## Features

- **Orchestrator & Handlers** - One orchestrator per SObject, one handler per concern, wired in Apex
- **Record Filtering** - Handlers run only against records that qualify, so logic never guards itself
- **Parent Enrichment** - Related data is pulled up front, so handlers make no SOQL queries of their own
- **Bypasses** - Disable an individual handler or a whole orchestrator when you need to
- **Recursion Control** - Depth limiting built in, defaulting to 3
- **No Required Metadata** - Works with zero custom metadata records; metadata only overrides defaults

## Why Trigger Lib?

### Handlers work on a single record

The framework iterates over `Trigger.new` and `Trigger.old` for you. A handler receives one `TriggerHandler.Record` at a time and has no bulk loop of its own. Bulkification happens in the orchestrator, not in every handler.

### Records are qualified before handlers run

Every handler declares a `qualifiesFor...When` predicate. Only records that pass it reach the `on...` method. The predicate API is fluent and null-safe: `isChangedTo`, `isRecordTypeEqual`, `isBlank`, `greaterThan` and more.

### Parents are enriched, not queried

A handler declares the parent lookups and fields it needs. The framework runs one query per lookup field, merges the field lists of all active handlers and attaches the parent record to each trigger record. Handlers never write SOQL.

### Guard rails are built in

- DML inside a before insert or before update handler throws.
- Update handlers run at most three times per record.
- Exceptions are reported to a pluggable logger.

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

### Orchestrator

```apex
public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterUpdate {
  public List<BeforeInsert.Handler> beforeInsertHandlers() {
    return new List<BeforeInsert.Handler>{ new ContactDescriptionHandler() };
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new ContactAccountSyncHandler() };
  }
}
```

### Before Insert Handler

```apex
public with sharing class ContactDescriptionHandler implements BeforeInsert.Handler {
  public Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record) {
    return record.isRecordTypeEqual('Business_Contact') &&
      record.isBlank(Contact.Description);
  }

  public void onBeforeInsert(TriggerHandler.Record record) {
    record.put(Contact.Description, 'Created by ContactDescriptionHandler');
  }
}
```

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

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChanged(Contact.Email) &&
      record.isNotNull(Contact.AccountId);
  }

  public void onAfterUpdate(TriggerHandler.Record record) {
    Account account = (Account) record.getNewRelated('Account');

    accountsToUpdate.add(
      new Account(
        Id = account.Id,
        Description = 'Contact email changed: ' + account.Name
      )
    );
  }

  public void finalizeAfterUpdate() {
    update accountsToUpdate;
  }
}
```

The handler collects work per record and performs a single DML in the finalizer, which runs once after all qualified records were processed.

## Execution Flow

`TriggerOrchestrator.run` does the following for the current `Trigger.operationType`:

1. Picks the handlers returned by the matching orchestrator method, for example `afterUpdateHandlers()`.
2. Drops handlers whose `bypassOn...When()` returns `true`.
3. Collects parent fields declared by the remaining handlers and queries them, one query per lookup field.
4. Skips records that exceeded the recursion depth of a handler.
5. Asks each handler which records qualify.
6. Runs `on...` for each qualified record, then the handler finalizer, one handler at a time.

## Next Steps

- [Installation](/installation)
- [Orchestrator](/guide/orchestrator)
- [Handlers](/guide/handlers)
- [Record Qualification](/guide/qualification)
- [Parent Enrichment](/guide/enrichment)
