---
template: add-on
context: BeforeDelete
interface: ContinueOnError
description: "Let a before delete Handler fail without failing the delete; its exception is logged and swallowed."
---

# BeforeDelete.ContinueOnError

Let a **before delete** handler fail without failing the delete: its exception is logged and swallowed (ignored, caught), and the other handlers and the delete go on.

<!--@include: @/_parts/generated/before-delete/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- Work whose failure must not block the delete, such as cleanup, archiving or stamping other records.
- Never on a handler whose job is to block deletes: a swallowed exception means no error is attached, so the record is deleted.
- Make sure the org has a Logger, or the swallowed error leaves no trace.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/continue-on-error/signature.md-->

<!--@include: @/_parts/generated/before-delete/continue-on-error/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/continue-on-error/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

Errors already attached with `addError`, and records written by DML statements that already ran in this handler, stay: the library sets no savepoint.

### What Still Throws {#still-throws}

- `TriggerHandler.TriggerHandlerException`, for example from `getRelated` with an unknown provider name or `isRecordTypeEqual` on an object without record types, and `TriggerOrchestratorException`. Both are always rethrown → [TriggerHandlerException](/api/record#triggerhandlerexception), [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).
- Errors no code can catch, such as `System.LimitException`, and the `FinalException` from writing to `getOldSObject()`.

BeforeDelete has no DML guard and no check that a qualified record got an error, so neither can throw here.

<!--@include: @/_parts/notes/never-logged.md-->

Here that means `beforeDeleteHandlers()`, `bypassOnBeforeDeleteWhen()`, `queryParentsOnBeforeDelete()` and the parent queries it causes. The shared unit of work is always empty in this context.

### Logging {#logging}

The swallowed exception goes to the org's `TriggerOrchestrator.Logger` as a `TriggerOrchestrator.Error`, with the handler's simple class name and every Id in the chunk. Without a Logger it leaves no trace → [Errors & Logging](/guide/error-handling#logger).

## Records Here {#records}

No record parameter: implementing the interface is the whole opt-in.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-delete/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **A failed DML statement is swallowed too.** The delete proceeds without the cleanup, and statements that ran before the failure keep their changes.
- **A provider failure skips the whole handler.** An exception in a RelatedQuery provider happens before the first predicate, so the handler processes no record in that chunk.
- **A guard stops guarding.** On a handler that blocks deletes, any swallowed exception lets the delete through.

## Test It {#test}

There is nothing to stub: the behaviour lives in the orchestrator, not in your class. Running the orchestrator in a test works in the same namespace only; see [Testing](/guide/testing).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-delete/continue-on-error/other-contexts.md-->

The marker exists in all 7 contexts. In the after contexts it also gives a Writer a private unit of work; BeforeDelete has no unit.

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling)
- [TriggerOrchestrator](/api/trigger-orchestrator)
- [BeforeDelete.Handler](/before-delete/handler)
