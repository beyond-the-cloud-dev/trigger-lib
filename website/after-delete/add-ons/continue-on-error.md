---
template: add-on
context: AfterDelete
interface: ContinueOnError
description: Keep a delete going when an after delete Writer or Dispatcher fails — log and swallow its exception, skip the rest of its records, and discard a Writer's writes together.
---

# AfterDelete.ContinueOnError

Keep an **after delete** going when one Writer or Dispatcher fails: its exception is logged and swallowed (skip instead of fail), and a Writer gets a private unit of work, so its writes are discarded together.

<!--@include: @/_parts/generated/after-delete/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- Side work that must never block a delete: a courtesy task, a sync job, a note on the former parent.
- Pair it with a `TriggerOrchestrator.Logger` implementation; without one, a swallowed error leaves no trace.
- Leave it off for writes that must succeed together with the delete.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/continue-on-error/signature.md-->

<!--@include: @/_parts/generated/after-delete/continue-on-error/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/continue-on-error/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

<!--@include: @/_parts/add-ons/continue-on-error.md#writer-->

### What Still Throws {#still-throws}

- `TriggerHandler.TriggerHandlerException`, for example from `getRelated` with a provider name the handler did not return, or from `isRecordTypeEqual` on an object without record types, and the library's own `TriggerOrchestratorException`, are logged and then rethrown. See [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).
- `System.LimitException` and the `FinalException` from writing a field on `getOldSObject()` cannot be caught at all.
- After delete has no DML guard, so direct DML in the handler does not throw on its own.

<!--@include: @/_parts/notes/never-logged.md-->

Here that means `afterDeleteHandlers()`, `ownUnitOfWorkOnAfterDelete()` on a Writer, `bypassOnAfterDeleteWhen()`, `queryParentsOnAfterDelete()` with its parent queries, and the shared unit's commit.

### Logging {#logging}

The swallowed exception goes to the org's `TriggerOrchestrator.Logger` implementation, as a `TriggerOrchestrator.Error` with the handler's simple class name, the exception, the operation `AFTER_DELETE` and every Id in the chunk. Without a Logger it leaves no trace. See [Errors & Logging](/guide/error-handling#logger).

## Records Here {#records}

The marker has no methods and receives no records. It changes how the handler's own methods are run.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **A self-update is swallowed too.** A Writer that registers an update of a deleted row fails its private commit with `ENTITY_IS_DELETED`; the failure is logged and swallowed, the Writer's writes are lost, and the delete goes on.
- **A Dispatcher's job is already enqueued** when its Finalizer throws and the exception is swallowed.
- **Each ContinueOnError Writer commits its own private unit**, which costs at least one more DML statement per operation and object type, per chunk.

## Test It {#test}

The behaviour lives in the orchestrator, not in your class: test the handler's methods directly, and test the swallowing by running the orchestrator in a test, which works in the same namespace only. See [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/continue-on-error/other-contexts.md-->

The marker exists in all seven contexts. In the four after contexts it also gives a Writer a private unit.

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling)
- [AfterDelete.Writer](/after-delete/writer#which-unit), for which unit a Writer gets
- [AfterDelete.OwnUnitOfWork](/after-delete/add-ons/own-unit-of-work), which takes precedence over the private unit
