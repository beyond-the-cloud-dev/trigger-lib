---
template: add-on
context: BeforeInsert
interface: ContinueOnError
description: Let a before insert handler fail without failing the insert - its exceptions are logged and swallowed, and the save goes on.
---

# BeforeInsert.ContinueOnError

Log and swallow the handler's exceptions, so later handlers still run and the insert goes on.

**Signature**

<!--@include: @/_parts/generated/before-insert/continue-on-error/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-insert/continue-on-error/skeleton.md-->

:::

## Rules {#rules}

- **The handler stops for the chunk.** Its remaining records and its Finalizer are skipped. Values it already set and errors it already attached stay.
- **On a Validator, the rest goes unchecked.** Records after the failing one are saved unless another handler rejects them.
- **Add a [Logger](/guide/error-handling#logger).** Without one, a swallowed exception leaves no trace.

::: warning
Some exceptions still fail the insert: DML in the handler, a Validator that attaches no error, `TriggerHandler.TriggerHandlerException`, `System.LimitException`, and exceptions in `bypassOnBeforeInsertWhen()` or while parents load.
:::
