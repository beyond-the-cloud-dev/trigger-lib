---
template: add-on
context: AfterDelete
interface: ContinueOnError
description: Keep a delete going when an after delete Writer or Dispatcher fails - log and swallow its exception and discard a Writer's writes together.
---

# AfterDelete.ContinueOnError

Logs and swallows a Writer's or Dispatcher's exception, so the delete goes on. The rest of that handler's records and its Finalizer are skipped.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/continue-on-error/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Add a Logger.** The exception goes to the org's `TriggerOrchestrator.Logger` implementation. Without one it leaves no trace. See [Errors & Logging](/guide/error-handling).
- **A Writer gets a private unit.** Unless it implements OwnUnitOfWork, its writes go to a unit that commits right after it. A failed Writer loses only its own writes.
- **Some errors still throw.** `TriggerHandler.TriggerHandlerException` and `TriggerOrchestratorException` are logged, then rethrown. A `System.LimitException` cannot be caught at all.
- **The old row stays read-only.** Writing a field on `getOldSObject()` throws a `FinalException` that nothing can catch.
- **Code outside the handler is not covered.** An exception in `afterDeleteHandlers()`, `bypassOnAfterDeleteWhen()`, `ownUnitOfWorkOnAfterDelete()`, `queryParentsOnAfterDelete()` or the shared commit fails the delete.
