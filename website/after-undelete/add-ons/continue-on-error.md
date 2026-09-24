---
template: add-on
context: AfterUndelete
interface: ContinueOnError
description: Log and swallow an after undelete Writer's or Dispatcher's exceptions so later handlers run and the restore goes on.
---

# AfterUndelete.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the restore goes on.

**Signature**

<!--@include: @/_parts/generated/after-undelete/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/after-undelete/continue-on-error/skeleton.md-->

:::

## Rules {#rules}

- **The handler stops for the chunk.** After an exception, it skips its remaining records and its Finalizer.
- **A Writer gets the automatic unit of work.** Unless it implements OwnUnitOfWork, its writes commit right after it. When it throws, its registrations are discarded.
- **Add a [Logger](/guide/error-handling#logger).** Without one, a swallowed exception leaves no trace.

::: warning
Some errors still fail the restore. [Library exceptions](/api/trigger-orchestrator#triggerlibexception), `System.LimitException`, the `FinalException` from writing a trigger row and exceptions outside the handler's own methods, such as `bypassOnAfterUndeleteWhen()` or the final commit, are never swallowed.
:::
