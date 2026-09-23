---
template: add-on
context: BeforeUpdate
interface: ContinueOnError
description: Let a non-critical before update handler fail without failing the update. The exception is logged and swallowed.
---

# BeforeUpdate.ContinueOnError

Lets a handler fail without failing the update. The library logs and swallows the exception, and the save goes on.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/continue-on-error/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **One failure stops the handler for the chunk.** Its remaining records and its Finalizer are skipped. Values it already set stay, and later handlers still run. To skip only one record, catch the exception in the action.
- **Keep it off Validators that protect data.** When such a Validator throws, the records it has not checked yet save unchecked.
- **Some exceptions still fail the update.** These are the library's `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException`, `LimitException`, and the `FinalException` from touching the old row. The DML guard and a Validator that attaches no error throw a `TriggerOrchestratorException`.
- **Setup code is not covered.** Exceptions in `beforeUpdateHandlers()`, `bypassOnBeforeUpdateWhen()`, `maxRecursionDepthOnBeforeUpdate()` and the parent queries are never logged and fail the update.
- **Logging needs a Logger.** The swallowed exception goes to your `TriggerOrchestrator.Logger` implementation, if the org has one. See [Errors & Logging](/guide/error-handling).
