---
template: add-on
context: BeforeUpdate
interface: ContinueOnError
description: Let a non-critical before update handler fail without failing the update. The exception is logged and swallowed.
---

# BeforeUpdate.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the update goes on.

**Signature**

<!--@include: @/_parts/generated/before-update/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/continue-on-error/skeleton.md-->

:::

## Rules {#rules}

- **One failure stops the handler for the chunk.** Its remaining records and its Finalizer are skipped. Values it already set stay. To skip only one record, catch the exception in the action.
- **Some exceptions still fail the update.** DML in the handler, a Validator that attaches no error, `TriggerHandler.TriggerHandlerException`, `System.LimitException`, the `FinalException` from touching the old row and exceptions from methods that run before the handler's turn, such as `bypassOnBeforeUpdateWhen()`, are never swallowed.
- **Add a [Logger](/guide/error-handling#logger).** Without one, a swallowed exception leaves no trace.

::: warning
Keep it off Validators that protect data. When such a Validator throws, the records it has not checked yet save unchecked.
:::
