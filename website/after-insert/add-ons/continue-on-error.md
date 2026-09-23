---
template: add-on
context: AfterInsert
interface: ContinueOnError
description: Log and swallow an after insert handler's exception so later handlers run and the insert goes on.
---

# AfterInsert.ContinueOnError

Logs and swallows a Writer's or Dispatcher's exception, so later handlers run and the insert goes on. A Writer also gets a private unit of work, so a failure discards only its own writes.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/continue-on-error/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [With ParentQuery]

:::

## Good to Know {#good-to-know}

- **The rest of the handler is skipped.** After an exception, its remaining records and its Finalizer do not run.
- **Add a Logger.** Without a `TriggerOrchestrator.Logger`, a swallowed error leaves no trace. See [Errors & Logging](/guide/error-handling).
- **Some errors still fail the insert.** `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are logged and rethrown. `System.LimitException` and the `FinalException` from writing to the row cannot be caught.
- **Only the handler's own work.** A failure in `bypassOnAfterInsertWhen()`, `queryParentsOnAfterInsert()` or the shared commit still fails the insert.
- **The private unit costs its own statements.** It commits right after the Writer, before the shared unit, and is never merged with it.
