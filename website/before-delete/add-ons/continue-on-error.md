---
template: add-on
context: BeforeDelete
interface: ContinueOnError
description: Let a before delete Handler fail without failing the delete - its exception is logged and swallowed.
---

# BeforeDelete.ContinueOnError

Logs and swallows the handler's exceptions, so the other handlers and the delete go on. Use it for cleanup that must not block a delete.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/continue-on-error/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **Never on a guard.** A swallowed exception means no error is attached, so the record is deleted.
- **The rest of the handler is skipped.** After an exception, this handler's remaining records and its Finalizer are skipped. An exception in a provider skips every record. Later handlers still run.
- **No rollback.** Errors already attached and DML statements that already ran stay. The library sets no savepoint.
- **Some exceptions always throw.** `TriggerHandler.TriggerHandlerException` and `TriggerOrchestratorException` are rethrown. `System.LimitException` cannot be caught. Exceptions in `bypassOnBeforeDeleteWhen()` and `queryParentsOnBeforeDelete()` fail the delete.
- **Add a Logger.** The exception goes to the org's `TriggerOrchestrator.Logger`. Without one it leaves no trace. See [Errors & Logging](/guide/error-handling).
