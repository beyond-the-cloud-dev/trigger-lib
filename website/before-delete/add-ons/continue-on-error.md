---
template: add-on
context: BeforeDelete
interface: ContinueOnError
description: Let a before delete Handler fail without failing the delete - its exception is logged and swallowed.
---

# BeforeDelete.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the delete goes on.

**Signature**

<!--@include: @/_parts/generated/before-delete/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/continue-on-error/skeleton.md-->

:::

## Rules {#rules}

- **The rest of the handler is skipped.** After an exception, this handler's remaining records and its Finalizer are skipped. An exception in a provider skips every record.
- **No rollback.** Errors already attached and DML statements that already ran stay. The library sets no savepoint.
- **Some errors still fail the delete.** [Library exceptions](/api/record#triggerhandlerexception), `System.LimitException` and exceptions outside the handler's own methods, such as `bypassOnBeforeDeleteWhen()` or `queryParentsOnBeforeDelete()`, are never swallowed.
- **Add a [Logger](/guide/error-handling#logger).** Without one, a swallowed exception leaves no trace.

::: warning
Never add it to a guard. A swallowed exception means no error is attached, so the record is deleted.
:::
