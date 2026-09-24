---
template: add-on
context: AfterDelete
interface: ContinueOnError
description: Keep a delete going when an after delete Writer or Dispatcher fails - log and swallow its exception so later handlers still run.
---

# AfterDelete.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the delete goes on.

**Signature**

<!--@include: @/_parts/generated/after-delete/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-delete/continue-on-error/skeleton.md-->

:::

## Rules {#rules}

- **The handler stops for the chunk.** Its other records and its Finalizer are skipped.
- **Add a [Logger](/guide/error-handling#logger).** Without one, a swallowed exception leaves no trace.
- **A Writer gets the automatic unit of work.** Unless it implements OwnUnitOfWork, its writes commit right after it, so a failure never touches other Writers' writes.

::: warning
Some errors still fail the delete. [Library exceptions](/api/trigger-orchestrator#triggerlibexception), `System.LimitException`, the `FinalException` from writing a trigger row and exceptions outside the handler's own methods, such as `bypassOnAfterDeleteWhen()` or the final commit, are never swallowed.
:::
