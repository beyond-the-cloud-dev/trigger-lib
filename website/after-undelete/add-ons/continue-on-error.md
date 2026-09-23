---
template: add-on
context: AfterUndelete
interface: ContinueOnError
description: Log and swallow an after undelete Writer's or Dispatcher's exceptions so later handlers run and the restore goes on.
---

# AfterUndelete.ContinueOnError

Logs and swallows a Writer's or Dispatcher's exceptions. Later handlers still run, and the records are still restored.

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/continue-on-error/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **The handler stops for the chunk.** After an exception, it skips its remaining records and its Finalizer.
- **A Writer gets a private unit.** Unless it implements OwnUnitOfWork, its writes commit right after it. When it throws, its registrations are discarded.
- **Some errors still fail the restore.** `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are logged and rethrown. A `FinalException` or `LimitException` cannot be caught.
- **Not everything is covered.** Exceptions in `afterUndeleteHandlers()`, `bypassOnAfterUndeleteWhen()`, `ownUnitOfWorkOnAfterUndelete()`, `queryParentsOnAfterUndelete()` and the shared commit fail the restore.
- **Logged only with a Logger.** A swallowed exception goes to the org's `TriggerOrchestrator.Logger` implementation. Without one it leaves no trace. See [Errors & Logging](/guide/error-handling).
