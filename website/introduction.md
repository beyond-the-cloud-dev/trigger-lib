---
description: What Trigger Lib is, why to use it, a quick example, how a trigger run works, and the roles and add-ons of each Salesforce trigger context.
---

# Introduction

Trigger Lib is an Apex trigger framework for Salesforce. You write one small class per concern and give it a role in a trigger context. The library loops over the records, loads the data your handlers declare and commits their DML, all in bulk.

## Why Trigger Lib? {#why}

- **One-Line Triggers** - The trigger passes an orchestrator that lists each context's handlers in run order
- **Record Filtering** - Each handler acts only on the records its predicate picks
- **Declared Queries** - Declare parent fields and related records, with no SOQL in your handler
- **Unit of Work** - Writers register DML, committed once after the last handler by default
- **Guard Rails** - SOQL or DML in a per-record method fails the save, whether a developer or an AI agent wrote it
- **Bypasses and Recursion Control** - Switch handlers off in Apex or custom metadata, and log or cap recursion in the update contexts
- **Testability** - Test handlers with in-memory records, no trigger and no DML

## Quick Example {#quick-example}

::: code-group

<<< @/../examples/main/default/triggers/ContactTrigger.trigger [ContactTrigger.trigger]

```apex [ContactTriggerOrchestrator.cls]
public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{ new ContactEmailNormalizationPopulator() };
    }
}
```

<<< @/../examples/main/default/classes/contact/before-insert/populator/ContactEmailNormalizationPopulator.cls [ContactEmailNormalizationPopulator.cls]

:::

## How It Works {#how-it-works}

Trigger Lib has three levels:

1. **Trigger** - one per object, with a one-line body: `TriggerOrchestrator.run(new ContactTriggerOrchestrator())`, or `TriggerOrchestrator.runFromMetadata()` for handlers registered in [custom metadata](/guide/orchestrator#from-metadata).
2. **Orchestrator** - lists the handlers of each context in run order. Under `runFromMetadata()`, `TriggerHandler__mdt` records do it instead.
3. **Handler** - a small class with one role in a context, plus the add-ons it needs.

Every role has a predicate and an action, such as `populateOnBeforeInsertWhen(record)` and `populateOnBeforeInsert(record)`. The library loops over the records of the chunk, calls the predicate for each one and runs the action only when the predicate returns true: the `if` inside the `for` loop you would otherwise write yourself. A Dispatcher is the exception: its dispatch method runs once, with all the qualified records.

Around that loop, the library:

- **Loads data in bulk.** Handlers declare parents and related records, and the library queries them per chunk, never per record. Your own SOQL in a predicate or an action throws. See [Queries](/guide/queries).
- **Commits DML in bulk.** Writers register DML on a unit of work, which commits after the last handler by default. DML in a predicate or an action throws. See [Unit of Work](/guide/unit-of-work).
- **Handles errors.** A handler's exception goes to your Logger and fails the save, unless the handler implements ContinueOnError. See [Errors & Logging](/guide/error-handling).
- **Skips what you switch off** from Apex, custom metadata or the handler itself. See [Bypassing](/guide/bypasses).
- **Reports recursion.** In the update contexts, a record that comes back to a Populator, Writer or Dispatcher after 3 runs in the transaction logs an error. A RecursionGuard sets its own depth and also skips the record.

Every step of a run, in order: [Execution Order & Cost](/guide/execution-order).

## Roles {#roles}

| Role | What it does | Contexts |
|---|---|---|
| Populator | Sets fields on the record being saved. No DML. | [BeforeInsert](/before-insert/populator), [BeforeUpdate](/before-update/populator) |
| Validator | Attaches an error to the record being saved or deleted, which rejects it. | [BeforeInsert](/before-insert/validator), [BeforeUpdate](/before-update/validator), [BeforeDelete](/before-delete/validator) |
| Writer | Registers DML on a unit of work. | [AfterInsert](/after-insert/writer), [AfterUpdate](/after-update/writer), [BeforeDelete](/before-delete/writer), [AfterDelete](/after-delete/writer), [AfterUndelete](/after-undelete/writer) |
| Dispatcher | Gets all qualified records at once, for async work, events or emails. | [AfterInsert](/after-insert/dispatcher), [AfterUpdate](/after-update/dispatcher), [AfterDelete](/after-delete/dispatcher), [AfterUndelete](/after-undelete/dispatcher) |

## Add-ons {#add-ons}

Pick one role per context and as many add-ons as you need. Each add-on exists only in the contexts where it fits:

| Add-on | What it does | Contexts |
|---|---|---|
| ParentQuery | Loads fields of the records the lookups point to. | [BeforeInsert](/before-insert/add-ons/parent-query), [AfterInsert](/after-insert/add-ons/parent-query), [BeforeUpdate](/before-update/add-ons/parent-query), [AfterUpdate](/after-update/add-ons/parent-query), [AfterUndelete](/after-undelete/add-ons/parent-query) |
| PriorParentQuery | Loads the records the lookups pointed to before the save. | [BeforeUpdate](/before-update/add-ons/prior-parent-query), [AfterUpdate](/after-update/add-ons/prior-parent-query), [BeforeDelete](/before-delete/add-ons/prior-parent-query), [AfterDelete](/after-delete/add-ons/prior-parent-query) |
| RelatedQuery | Loads children, siblings or any other records with your own query. | [Every context](/contexts) |
| OwnUnitOfWork | Gives a Writer its own unit of work and settings, committed right after it. | [AfterInsert](/after-insert/add-ons/own-unit-of-work), [AfterUpdate](/after-update/add-ons/own-unit-of-work), [BeforeDelete](/before-delete/add-ons/own-unit-of-work), [AfterDelete](/after-delete/add-ons/own-unit-of-work), [AfterUndelete](/after-undelete/add-ons/own-unit-of-work) |
| Bypassable | Skips the handler for a run on a condition, such as a feature flag. | [Every context](/contexts) |
| RecursionGuard | Skips a record after the handler acted on it a set number of times. | [BeforeUpdate](/before-update/add-ons/recursion-guard), [AfterUpdate](/after-update/add-ons/recursion-guard) |
| Finalizer | Runs once after the loop when records qualified, with those records. | [Every context](/contexts) |
| ContinueOnError | Logs the handler's exception and lets the save go on. | [Every context](/contexts) |
