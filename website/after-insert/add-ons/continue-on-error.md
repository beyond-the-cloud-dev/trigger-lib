---
template: add-on
context: AfterInsert
interface: ContinueOnError
description: AfterInsert.ContinueOnError - log and swallow an after insert handler's exception so later handlers run and the insert goes on; a Writer also gets a private unit.
---

# AfterInsert.ContinueOnError

Let an **after insert** Writer or Dispatcher fail without failing the insert: its exception is logged and swallowed, later handlers still run and the records are saved. On a Writer it also gives the handler a private unit of work, so a failure discards only its own writes.

<!--@include: @/_parts/generated/after-insert/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- The handler's work is optional, such as a follow-up Task or a notification, and must never block the save.
- Keep the default instead for work the insert depends on: without ContinueOnError the exception fails the whole DML statement.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/continue-on-error/signature.md-->

<!--@include: @/_parts/generated/after-insert/continue-on-error/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/continue-on-error/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [Writer with a private unit]

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactFollowUpTaskWriter.cls [With ParentQuery]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

<!--@include: @/_parts/add-ons/continue-on-error.md#writer-->

A Dispatcher has no unit, so what it did before the exception is not undone: an event already published immediately stays published, and an email or a job it already queued is still sent or started when the transaction commits.

### What Still Throws {#still-throws}

- `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException`, for example from `getRelated` with an unknown provider name, are logged and always rethrown. See [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).
- Exceptions no `catch` can stop: the `System.FinalException` from `put` or any write to the read-only row, and `System.LimitException`.

<!--@include: @/_parts/notes/never-logged.md-->

In after insert that means `afterInsertHandlers()`, `ownUnitOfWorkOnAfterInsert()`, `bypassOnAfterInsertWhen()`, `queryParentsOnAfterInsert()` with its parent queries, and the shared commit. After insert has no DML guard, so direct DML is never stopped by the library.

### Logging {#logging}

- **Without a Logger, a swallowed error leaves no trace.** Implement `TriggerOrchestrator.Logger` to record it: [Errors & Logging](/guide/error-handling#logger).
- **`Error.getRecordIds()` holds every Id in the chunk**, not only the record being processed when the handler failed.
- **`Error.getHandlerName()` is the simple class name**, and `getOperation()` is `AFTER_INSERT`.

## Records Here {#records}

The marker has no methods and receives no records. It changes how the library treats the handler's own methods.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **A private unit costs its own statements.** It is never merged with the shared unit: each commit costs at least one DML statement per operation and object type it registers, once per chunk in which a record qualified.
- **It commits before the shared unit.** In the Contact example, `ContactFollowUpTaskWriter`'s Task is saved before the owner change that the shared unit holds: see [AfterInsert Gotchas](/after-insert/#gotchas) 4.
- **A failed shared commit is not swallowed.** It fails the insert, whatever the handlers implement, and never reaches `TriggerOrchestrator.Logger`; only a DML Lib `DML.Logger` implementation, if the org has one, sees the failed statement.
- **Not on event-object triggers.** It would also swallow `EventBus.RetryableException`, which a platform-event subscriber throws to ask for a retry.

## Test It {#test}

Swallowing happens inside the orchestrator, so test it by running the orchestrator with a small `TriggerOrchestrator.Logger` of your own. That works in the same namespace only: see [Testing](/guide/testing). The handler's own methods are tested as on the [Writer](/after-insert/writer#test) page.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/continue-on-error/other-contexts.md-->

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling)
- [Which Unit You Get](/after-insert/writer#which-unit)
- [TriggerOrchestrator](/api/trigger-orchestrator)
