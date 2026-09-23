---
template: add-on
context: BeforeInsert
interface: ContinueOnError
description: Let a before insert handler fail without failing the insert - its exceptions are logged and swallowed, and the save goes on.
---

# BeforeInsert.ContinueOnError

Let a **before insert** handler fail without failing the insert: an exception it throws is logged and swallowed (continue on error, fail silently, best effort), later handlers still run, and the insert goes on.

<!--@include: @/_parts/generated/before-insert/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- Best-effort Populators, where a missing default is better than a failed insert.
- Handlers whose failure you want to see in the Logger rather than as a save error.

Do not use it to reject one record: call `addError` on that record instead. And think twice on a Validator: records after the failing one are never checked.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/continue-on-error/signature.md-->

<!--@include: @/_parts/generated/before-insert/continue-on-error/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/continue-on-error/skeleton.md-->

:::

The compiled examples that use ContinueOnError are Writers: see [AfterInsert.ContinueOnError](/after-insert/add-ons/continue-on-error#example) and [AfterUpdate.ContinueOnError](/after-update/add-ons/continue-on-error#example).

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

In before insert, values already put on earlier records, and errors a Validator already attached, stay on those records.

### What Still Throws {#still-throws}

- **The DML guard.** DML or an immediately published event in the handler throws `TriggerOrchestratorException`, even though the handler's own exception was swallowed.
- **A qualified record without an error.** A Validator whose `addErrorOnBeforeInsert` attaches no error to a record its predicate qualified throws `TriggerOrchestratorException`.
- **Library exceptions.** `TriggerOrchestratorException` and `TriggerHandler.TriggerHandlerException` are always rethrown. The second one comes from `getRelated` with a provider name the handler did not return, and from `isRecordTypeEqual` on an object without record types. See [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception) and [TriggerHandlerException](/api/record#triggerhandlerexception).
- **Errors no code can catch**, such as `System.LimitException`.

<!--@include: @/_parts/notes/never-logged.md-->

In before insert that means `beforeInsertHandlers()`, `bypassOnBeforeInsertWhen()`, `queryParentsOnBeforeInsert()` with the parent queries it causes, and the parent query after a Populator.

### Logging {#logging}

The swallowed exception reaches the org's `TriggerOrchestrator.Logger` implementation, if there is one, as a `TriggerOrchestrator.Error`: `getHandlerName()` is the handler's simple class name, `getOperation()` is `BEFORE_INSERT`, and `getRecordIds()` returns an empty set, because nothing has an Id yet. Without a Logger, a swallowed error leaves no trace. See [the Logger](/guide/error-handling#logger).

## Records Here {#records}

ContinueOnError has no methods and receives no records. When it swallows an exception, the records the handler had already processed keep what it did to them, and the rest of the chunk is left as it was.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **On a Validator, the rest of the chunk goes unchecked.** When the predicate or the error method throws on one record, the Validator stops for that chunk: this Validator never checks the records after it, and they are saved unless another handler rejects them.
- **No Finalizer after a failure.** The swallowed exception also skips the handler's Finalizer for that chunk, so checks across records that live there do not run either.

## Test It {#test}

Swallowing happens in the orchestrator, so a unit test of the handler alone sees the exception. To test it through the orchestrator, which works in the same namespace only, see [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/continue-on-error/other-contexts.md-->

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling): the Logger and the `Error` payload.
- [TriggerOrchestrator](/api/trigger-orchestrator#triggerorchestratorexception): why you cannot catch the library's exception by type.
- [BeforeInsert](/before-insert/) overview.
