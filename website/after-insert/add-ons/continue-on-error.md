---
template: add-on
context: AfterInsert
interface: ContinueOnError
description: Log and swallow an after insert handler's exception so later handlers run and the insert goes on.
---

# AfterInsert.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the insert goes on.

**Signature**

<!--@include: @/_parts/generated/after-insert/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-insert/continue-on-error/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-insert/writer/AccountWelcomeTaskWriter.cls [With ParentQuery]

:::

## Rules {#rules}

- **The rest of the handler is skipped.** After an exception, its remaining records and its Finalizer do not run.
- **A Writer gets the automatic unit of work.** It commits right after the Writer, so a failure never touches other Writers' writes.
- **Add a [Logger](/guide/error-handling#logger).** Without one, a swallowed exception leaves no trace.

::: warning
Some errors still fail the insert. [Library exceptions](/api/trigger-orchestrator#triggerlibexception), `System.LimitException`, `EventBus.RetryableException` (a platform event subscriber asking for redelivery), the `FinalException` from writing a trigger row and exceptions outside the handler's own methods, such as `bypassOnAfterInsertWhen()` or the final commit, are never swallowed.
:::
