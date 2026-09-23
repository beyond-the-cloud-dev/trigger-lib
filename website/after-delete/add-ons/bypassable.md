---
template: add-on
context: AfterDelete
interface: Bypassable
description: Skip, bypass or disable an after delete Writer or Dispatcher for the whole run when a condition holds, for example during a batch purge or a data migration.
---

# AfterDelete.Bypassable

Skip (bypass, disable, turn off) an **after delete** Writer or Dispatcher for the whole run when a condition holds, for example during a batch purge or a data migration.

<!--@include: @/_parts/generated/after-delete/bypassable/available-in.md-->

## When to Use {#when-to-use}

- Switch one handler off, in after delete only, from a static flag, a custom permission or `System.isBatch()`.
- To skip only some records, return false from the predicate instead.
- To switch a handler off in every context, or without deploying code, use metadata or `TriggerOrchestrator.bypass()`, described below.

## Interface {#interface}

<!--@include: @/_parts/generated/after-delete/bypassable/signature.md-->

<!--@include: @/_parts/generated/after-delete/bypassable/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-delete/bypassable/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

In after delete the only getter is a Writer's `ownUnitOfWorkOnAfterDelete()`; there is no recursion getter.

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

For the Skeleton that is `TriggerOrchestrator.bypass().handler(ContactWriter.class)`, which matches because `ContactWriter` is a top-level class.

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

An object-wide switch also skips the object's BeforeDelete handlers, so a purge that runs with the object switched off also skips the checks that would have blocked a delete.

## Records Here {#records}

The method takes no records: it decides for the whole run. To skip single records, return false from `writeOnAfterDeleteWhen` or `dispatchOnAfterDeleteWhen`.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-delete/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Outside the error handling.** The method runs before any handler, outside the handler's try block. An exception thrown here is not logged, ContinueOnError does not apply, and the delete fails.
- **Static flags last for the whole transaction**, later chunks and nested saves included. Reset a flag in a `finally` block after the work that set it.
- **Two types named Bypassable.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `AfterDelete.Bypassable` is this add-on.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

For the Skeleton, set `ContactWriter.isDisabled = true` and assert that `bypassOnAfterDeleteWhen()` returns true.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-delete/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses) and [Bypassing during a data migration](/guide/bypasses#data-migration)
- [Custom Metadata](/api/custom-metadata)
- [TriggerOrchestrator](/api/trigger-orchestrator), for the `bypass()` builder
- [AfterDelete](/after-delete/#switching-off) overview
