---
template: add-on
context: BeforeInsert
interface: ContinueOnError
description: Let a before insert handler fail without failing the insert - its exceptions are logged and swallowed, and the save goes on.
---

# BeforeInsert.ContinueOnError

Lets a handler fail without failing the insert. Its exception is logged and swallowed, later handlers still run, and the save goes on.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/continue-on-error/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/continue-on-error/skeleton.md-->

:::

## Good to Know {#good-to-know}

- **The handler stops for the chunk.** Its remaining records and its Finalizer are skipped. Values it already set and errors it already attached stay.
- **On a Validator, the rest goes unchecked.** Records after the failing one are saved unless another handler rejects them.
- **Some exceptions still fail the insert.** DML in the handler, a Validator that attaches no error, `TriggerHandler.TriggerHandlerException` and `System.LimitException` are never swallowed.
- **Only the handler's own code is covered.** An exception in `bypassOnBeforeInsertWhen()`, `queryParentsOnBeforeInsert()` or the parent query fails the insert and is not logged.
- **Implement a Logger to see failures.** The library finds your `TriggerOrchestrator.Logger` class and passes it each swallowed error. Without one, nothing records it. See [Errors & Logging](/guide/error-handling).
