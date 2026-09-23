---
template: add-on
context: AfterUndelete
interface: ContinueOnError
description: Log and swallow an after undelete Writer's or Dispatcher's exceptions so later handlers run and the restore goes on; what still throws and how it is logged.
---

# AfterUndelete.ContinueOnError

Let an **after undelete** Writer or Dispatcher fail without failing the restore: its exception is logged and swallowed, later handlers still run, and the records still come back from the Recycle Bin.

<!--@include: @/_parts/generated/after-undelete/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- The handler's work is optional, such as a follow-up Task or a notification, and must never block a restore.
- On a Writer, its registrations should be all or nothing for that Writer alone: its private unit is discarded when it fails.
- Leave it off when the restore must fail with the handler, which is the default.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/continue-on-error/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

<!--@include: @/_parts/add-ons/continue-on-error.md#writer-->

On a Dispatcher, side effects that happened before the exception stay: a Queueable already enqueued, or a Publish Immediately event already published.

### What Still Throws {#still-throws}

- `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are logged and always rethrown. In after undelete, the second comes from `getRelated` with an unknown provider name and from `isRecordTypeEqual` on an object without record types. See [`TriggerOrchestratorException`](/api/trigger-orchestrator#triggerorchestratorexception) and [`TriggerHandlerException`](/api/record#triggerhandlerexception).
- Errors no `catch` can stop: the `FinalException` from writing to the read-only restored row, and `System.LimitException`.

<!--@include: @/_parts/notes/never-logged.md-->

In after undelete that means `afterUndeleteHandlers()`, `ownUnitOfWorkOnAfterUndelete()`, `bypassOnAfterUndeleteWhen()`, `queryParentsOnAfterUndelete()` with its parent SOQL, and the shared unit's commit.

### Logging {#logging}

A swallowed exception reaches the org's `TriggerOrchestrator.Logger` implementation, if there is one, as a `TriggerOrchestrator.Error`. Without a Logger it leaves no trace. `getRecordIds()` holds every record Id in the chunk, not only the record that failed, `getHandlerName()` is the handler's simple class name, and `getOperation()` is `AFTER_UNDELETE`. Setting up a Logger: [Errors & Logging](/guide/error-handling#logger).

## Records Here {#records}

The marker takes no records. When it swallows an exception, the rest of the chunk's records are skipped by this handler only; later handlers receive every record.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **A private unit costs its own statements.** A ContinueOnError Writer commits separately from the shared unit: one DML statement per operation and object type.
- **It commits before the shared unit.** A private unit commits at the Writer's turn, so its rows land before what earlier Writers registered in the shared unit.
- **The shared commit is not covered.** A failure in the shared unit's commit is not swallowed and fails the restore, whichever handler registered the failing row.

## Test It {#test}

Test the handler's own methods as on the [Writer](/after-undelete/writer#test) and [Dispatcher](/after-undelete/dispatcher#test) pages. To check that an exception is swallowed and logged, run the orchestrator in a test with a small `TriggerOrchestrator.Logger` class of your own, which works in the same namespace only: [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/continue-on-error/other-contexts.md-->

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling)
- [AfterUndelete.Writer: Which Unit You Get](/after-undelete/writer#which-unit)
- [AfterUndelete.OwnUnitOfWork](/after-undelete/add-ons/own-unit-of-work)
