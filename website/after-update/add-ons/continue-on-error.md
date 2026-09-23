---
template: add-on
context: AfterUpdate
interface: ContinueOnError
description: 'Log and swallow the exceptions of an after update Writer or Dispatcher, so later handlers still run and the update is saved; a Writer also gets a private unit of work.'
---

# AfterUpdate.ContinueOnError

Let an **after update** Writer or Dispatcher fail without failing the update: its exception is logged and swallowed (ignored, not rethrown), later handlers still run, and the records are saved. A Writer also gets a private unit of work, so a failure discards only its own writes.

<!--@include: @/_parts/generated/after-update/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- The handler's work is optional for the save, such as a follow-up task or a notification job.
- A failure should be logged, not shown to the user who saved the record.
- Leave it out when the handler's writes must succeed together with the update.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/continue-on-error/signature.md-->

<!--@include: @/_parts/generated/after-update/continue-on-error/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/continue-on-error/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [Writer with a private unit]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [With RelatedQuery]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

<!--@include: @/_parts/add-ons/continue-on-error.md#writer-->

A Dispatcher has no unit, so what it did before the exception stays: a job already enqueued, an event already published.

### What Still Throws {#still-throws}

- `TriggerHandler.TriggerHandlerException`, for example from `getRelated` with a provider name the handler did not return, or from `isRecordTypeEqual` on an object without record types. The library always rethrows it, as it does a `TriggerOrchestratorException`. See [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).
- Errors no `catch` can stop: the `System.FinalException` from `put` or any other write to the trigger rows, and `System.LimitException` from a governor limit.

<!--@include: @/_parts/notes/never-logged.md-->

In after update, that means `afterUpdateHandlers()`, `maxRecursionDepthOnAfterUpdate()`, `ownUnitOfWorkOnAfterUpdate()` (Writers only), `bypassOnAfterUpdateWhen()`, the ParentQuery and PriorParentQuery declarations with their queries, and the shared unit's commit.

### Logging {#logging}

- Without a `TriggerOrchestrator.Logger` implementation in the org, a swallowed exception leaves no trace. See [Logger](/guide/error-handling#logger).
- The Logger receives a `TriggerOrchestrator.Error`: `getHandlerName()` is the simple class name, `getOperation()` is `AFTER_UPDATE`, and `getRecordIds()` holds the Id of every record in the chunk, not only the record that failed.
- The Logger's `finalize()` runs when the outermost Trigger Lib run ends, so once per chunk.

## Records Here {#records}

The marker has no methods and receives no records. It changes how the exceptions of the handler's own methods are handled, for every record of the run.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **The private unit commits early.** It commits right after the Writer, before the shared unit, so `OpportunityWinTaskWriter`'s Tasks are saved before the Account updates that `OpportunityAccountTypeWriter` registered earlier on the shared unit.
- **Extra statements.** The private unit commits its own statements: at least one per operation and object type the Writer registered, in every chunk, on top of the shared unit's.
- **The shared commit is not covered.** A failure there fails the update and never reaches `TriggerOrchestrator.Logger`; only a DML Lib `DML.Logger` implementation, if the org has one, sees the failed statement.
- **Recursion budget is spent anyway.** Records that qualified before the exception keep their count, although the handler's writes for them were discarded.

## Test It {#test}

Swallowing and logging happen in the orchestrator, so a unit test of the handler calls its methods directly and expects the exception. To assert that the error reaches the Logger and the save goes on, run the orchestrator in a test with a small class of your own that implements `TriggerOrchestrator.Logger`, which works in the same namespace only: [Testing](/guide/testing#mock-metadata).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/continue-on-error/other-contexts.md-->

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling)
- [Which unit a Writer gets](/after-update/writer#which-unit)
- [AfterUpdate.OwnUnitOfWork](/after-update/add-ons/own-unit-of-work): takes precedence over the private unit.
