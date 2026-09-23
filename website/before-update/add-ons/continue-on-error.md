---
template: add-on
context: BeforeUpdate
interface: ContinueOnError
description: BeforeUpdate.ContinueOnError lets a non-critical before update handler fail without failing the update. The exception is logged and swallowed, and the save goes on.
---

# BeforeUpdate.ContinueOnError

Let a non-critical **before update** handler fail without failing the update: its exception is logged and swallowed (ignore the error, keep going), and the save continues.

<!--@include: @/_parts/generated/before-update/continue-on-error/available-in.md-->

## When to Use {#when-to-use}

- Best-effort enrichment, such as a default value or a derived description, that must never block the user's save.
- A handler that depends on data that may be missing, where saving without its values is acceptable.

Leave it off Validators that protect your data: when such a Validator throws, the records it has not checked yet are saved unchecked.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/continue-on-error/signature.md-->

<!--@include: @/_parts/generated/before-update/continue-on-error/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/continue-on-error/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/continue-on-error.md#common-->

In before update:

- **Work done before the failure stays.** Records the handler processed before the exception keep their `put` values and their recursion count, and errors a Validator already attached stay, so those records are still rejected.
- **The parent query still runs.** After a Populator, the current parents are loaded for the records it qualified before the failure, because that step sits outside the try block.

### What Still Throws {#still-throws}

These fail the update even with ContinueOnError:

- **The DML guard.** DML or an immediately published event in this handler throws a `TriggerOrchestratorException`, checked after the swallow.
- **A Validator that qualifies a record but attaches no error** in `addErrorOnBeforeUpdate`.
- **Library exceptions.** Every [`TriggerOrchestratorException`](/api/trigger-orchestrator#triggerorchestratorexception), and every [`TriggerHandler.TriggerHandlerException`](/api/record#triggerhandlerexception), for example from `getRelated` with an unknown provider name or from `isRecordTypeEqual` on an object without record types.
- **Exceptions nothing can catch.** The `FinalException` from writing to `getOldSObject()` or calling `addError` on it, and `System.LimitException`.

<!--@include: @/_parts/notes/never-logged.md-->

Here that means `beforeUpdateHandlers()`, a Populator's `maxRecursionDepthOnBeforeUpdate()`, `bypassOnBeforeUpdateWhen()`, `queryParentsOnBeforeUpdate()` and `queryPriorParentsOnBeforeUpdate()` with their SOQL, and the parent query after a Populator.

### Logging {#logging}

The swallowed exception goes to the org's `TriggerOrchestrator.Logger` implementation, if there is one, as a `TriggerOrchestrator.Error`: the exception, the handler's simple class name, `BEFORE_UPDATE`, the object and the Ids of every record in the chunk. The Logger's `finalize()` is called when the outermost Trigger Lib run ends, not after nested runs. Setting up a Logger: [Errors & Logging](/guide/error-handling#logger).

## Records Here {#records}

No record parameter: this add-on is a marker with no methods.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/continue-on-error/works-with.md-->

## Gotchas {#gotchas}

- **Half-populated saves.** After a swallowed failure, values put before the throw stay, the rest of this handler's records get nothing, and the update saves anyway.
- **One failure skips the rest of the chunk for this handler.** Its remaining records and its Finalizer are skipped, not just the record that failed. To skip one record only, catch the exception inside the action yourself.

## Test It {#test}

The marker has no method to call. Check that the class carries it, here the Skeleton's `ContactPopulator`, and test the swallow with the orchestrator and a small purpose-built Logger, which works in the same namespace only: [Testing](/guide/testing).

```apex
@IsTest
static void continueOnErrorIsImplemented() {
    // Test
    Object handler = new ContactPopulator();

    // Verify
    Assert.isInstanceOfType(handler, BeforeUpdate.ContinueOnError.class, 'The handler should continue on error.');
}
```

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/continue-on-error/other-contexts.md-->

On an after-context Writer the marker also gives the Writer a private unit of work → [AfterUpdate.ContinueOnError](/after-update/add-ons/continue-on-error).

## See Also {#see-also}

- [Errors & Logging](/guide/error-handling)
- [Fail one record, not the whole save](/guide/error-handling#one-record)
- [TriggerOrchestrator](/api/trigger-orchestrator)
