---
description: What Trigger Lib is, why to use it, a quick example, and the roles of each Salesforce trigger context.
---

# Introduction

Trigger Lib is an Apex trigger framework for Salesforce. You write one small class per concern and give it a role in a trigger context.

## Why Trigger Lib? {#why}

- **One-Line Triggers** - The trigger passes an orchestrator that lists each context's handlers in run order
- **Record Filtering** - Each handler acts only on the records its predicate picks
- **Declared Queries** - Declare parent fields and related records, with no SOQL in your handler
- **Unit of Work** - Writers register DML, committed once after the last handler by default
- **Bypasses and Recursion Control** - Switch handlers off in Apex or custom metadata, and cap recursion in the update contexts
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

## Roles {#roles}

| Role | What it does | Contexts |
|---|---|---|
| Populator | Sets fields on the record being saved. No DML. | [BeforeInsert](/before-insert/populator), [BeforeUpdate](/before-update/populator) |
| Validator | Attaches an error to the record being saved or deleted, which rejects it. | [BeforeInsert](/before-insert/validator), [BeforeUpdate](/before-update/validator), [BeforeDelete](/before-delete/validator) |
| Writer | Registers DML on a unit of work. | [AfterInsert](/after-insert/writer), [AfterUpdate](/after-update/writer), [BeforeDelete](/before-delete/writer), [AfterDelete](/after-delete/writer), [AfterUndelete](/after-undelete/writer) |
| Dispatcher | Gets all qualified records at once, for async work, events or emails. | [AfterInsert](/after-insert/dispatcher), [AfterUpdate](/after-update/dispatcher), [AfterDelete](/after-delete/dispatcher), [AfterUndelete](/after-undelete/dispatcher) |
