---
description: What Trigger Lib is, how the trigger, orchestrator and handlers fit together, and which roles each Salesforce trigger context has.
---

# Introduction

Trigger Lib is an Apex trigger framework for Salesforce. You write one small class per concern and give it a role in a trigger context. The library runs it only for the records that qualify.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of Salesforce libraries by [Beyond the Cloud](https://beyondthecloud.dev).

## How It Fits Together {#how-it-fits}

<<< @/../examples/main/default/triggers/AccountTrigger.trigger

1. **The trigger** passes an orchestrator to `TriggerOrchestrator.run(…)`. Nothing else goes in it.
2. **The orchestrator** returns each context's handlers in run order.
3. **Each handler** implements one role, such as `BeforeInsert.Populator`, plus any add-ons, such as `BeforeInsert.ParentQuery`.
4. **The library** loads the declared parents and runs the handlers in list order. Each handler acts only on the records its predicate accepts.

## Roles per Context {#roles}

| Context | Roles |
|---|---|
| [BeforeInsert](/before-insert/) | [Populator](/before-insert/populator), [Validator](/before-insert/validator) |
| [AfterInsert](/after-insert/) | [Writer](/after-insert/writer), [Dispatcher](/after-insert/dispatcher) |
| [BeforeUpdate](/before-update/) | [Populator](/before-update/populator), [Validator](/before-update/validator) |
| [AfterUpdate](/after-update/) | [Writer](/after-update/writer), [Dispatcher](/after-update/dispatcher) |
| [BeforeDelete](/before-delete/) | [Handler](/before-delete/handler) |
| [AfterDelete](/after-delete/) | [Writer](/after-delete/writer), [Dispatcher](/after-delete/dispatcher) |
| [AfterUndelete](/after-undelete/) | [Writer](/after-undelete/writer), [Dispatcher](/after-undelete/dispatcher) |

- **Populator** sets fields on the record being saved. **Validator** attaches an error to it. Neither may run DML.
- **Writer** registers DML on a unit of work. By default it commits once, after the last handler.
- **Dispatcher** gets all qualified records at once, to start async work, publish an event or send an email.
- **Handler** runs per record before delete, and can block the delete with `addError`.

## Next Steps {#next-steps}

- [Installation](/installation)
- [Your First Handler](/guide/first-handler)
- [Trigger & Orchestrator](/guide/orchestrator)
