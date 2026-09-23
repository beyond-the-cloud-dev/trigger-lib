---
template: add-on
context: AfterUpdate
interface: ContinueOnError
description: Log and swallow the exceptions of an after update Writer or Dispatcher, so later handlers still run and the update is saved.
---

# AfterUpdate.ContinueOnError

Logs and swallows the exceptions of an after update Writer or Dispatcher, so later handlers still run and the update is saved. A Writer also gets a private unit of work, so a failure discards only its own writes.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/continue-on-error/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [Writer]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [With RelatedQuery]

:::

## Good to Know {#good-to-know}

- **The handler stops.** After an exception, its remaining records and its Finalizer are skipped. Later handlers still run.
- **The private unit commits early.** It commits right after the Writer, before the unit of work the other Writers share. A Writer that also implements [OwnUnitOfWork](/after-update/add-ons/own-unit-of-work) gets its own unit instead.
- **A Dispatcher keeps what it did.** A job already enqueued or an event already published stays.
- **Some errors still fail the update.** `TriggerHandler.TriggerHandlerException`, `System.LimitException` and the `FinalException` from writing to a trigger row are never swallowed. Neither are errors in `bypassOnAfterUpdateWhen()`, in the parent queries or in the commit after the last handler.
- **Add a Logger.** Without a `TriggerOrchestrator.Logger` implementation, a swallowed exception leaves no trace. See [Errors & Logging](/guide/error-handling).
