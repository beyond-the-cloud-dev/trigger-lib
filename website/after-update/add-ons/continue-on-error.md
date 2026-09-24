---
template: add-on
context: AfterUpdate
interface: ContinueOnError
description: Log and swallow the exceptions of an after update Writer or Dispatcher, so later handlers still run and the update is saved.
---

# AfterUpdate.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the update goes on.

**Signature**

<!--@include: @/_parts/generated/after-update/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-update/continue-on-error/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [Writer]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [With RelatedQuery]

:::

## Rules {#rules}

- **The handler stops.** After an exception, its remaining records and its Finalizer are skipped.
- **A Writer gets the automatic unit of work.** Its failure never touches the other Writers' writes. The unit commits right after the Writer, before the shared unit of work. A Writer that also implements [OwnUnitOfWork](/after-update/add-ons/own-unit-of-work) uses that unit instead.
- **A Dispatcher keeps what it did.** A job already enqueued or an event already published stays.
- **Some errors still fail the update.** [Library exceptions](/api/trigger-orchestrator#triggerlibexception), `System.LimitException`, the `FinalException` from writing a trigger row and exceptions outside the handler's own methods, such as `bypassOnAfterUpdateWhen()` or the final commit, are never swallowed.

::: tip
Add a [Logger](/guide/error-handling#logger). Without one, a swallowed exception leaves no trace.
:::
