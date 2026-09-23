---
template: add-on
context: BeforeDelete
interface: Bypassable
description: "Skip (bypass, disable) a before delete Handler for the whole run when a condition holds, such as a batch purge or a data migration."
---

# BeforeDelete.Bypassable

Skip (bypass, disable, turn off) a **before delete** handler for the whole run when a condition holds, for example during a batch purge, a data migration or for users with a custom permission.

<!--@include: @/_parts/generated/before-delete/bypassable/available-in.md-->

## When to Use {#when-to-use}

- A condition decides once per run whether the handler works at all: a static flag, `System.isBatch()`, or `FeatureManagement.checkPermission(…)`.
- Return false from `qualifiesForBeforeDeleteWhen` instead to skip only some records.
- Use a `TriggerHandler__mdt` record instead to switch the handler off in production without deploying code.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/bypassable/signature.md-->

<!--@include: @/_parts/generated/before-delete/bypassable/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/bypassable/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

For the top-level Skeleton class, the Apex switch is `TriggerOrchestrator.bypass().handler(ContactHandler.class)`.

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

A switch on the whole object also turns off the handlers that block deletes, so a purge run with it on can delete records they normally protect.

## Records Here {#records}

No record parameter: `bypassOnBeforeDeleteWhen()` runs once per run, before any record is looked at.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-delete/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Outside the error handling.** `bypassOnBeforeDeleteWhen()` runs before the handler's `try` block. An exception there is not passed to the Logger, ContinueOnError does not apply, and the delete fails.
- **Static flags last for the whole transaction**, nested saves included. Reset a flag in a `finally` block after the DML it was meant for.
- **A bypassed guard blocks nothing.** Switching off a handler that vetoes deletes lets those deletes through for as long as the switch is on.
- **Two `Bypassable` types.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `BeforeDelete.Bypassable` is this add-on.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

For the Skeleton, set `ContactHandler.isDisabled = true` and assert that `bypassOnBeforeDeleteWhen()` returns true.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-delete/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses): every switch and the order of checks.
- [Custom Metadata](/api/custom-metadata): `TriggerObject__mdt` and `TriggerHandler__mdt`.
- [Switching Handlers Off in BeforeDelete](/before-delete/#switching-off)
