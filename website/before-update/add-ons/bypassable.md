---
template: add-on
context: BeforeUpdate
interface: Bypassable
description: BeforeUpdate.Bypassable skips (bypasses, disables) a before update Populator or Validator for the whole run when a condition holds, such as a static flag or a custom permission.
---

# BeforeUpdate.Bypassable

Skip (bypass, disable, turn off) a **before update** Populator or Validator for the whole run when a condition holds: a static flag, a batch, a data fix or a custom permission.

<!--@include: @/_parts/generated/before-update/bypassable/available-in.md-->

## When to Use {#when-to-use}

- A job or a data fix must save records without this handler: it sets a static flag before its DML.
- Only some users should run the handler: check a custom permission.
- Only the before update half of a class should stop, while it keeps running in other contexts.

To skip only some records, return false from the predicate instead. To switch handlers off without deploying code, use custom metadata ([Other Ways to Switch Off](#other-ways)).

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/bypassable/signature.md-->

<!--@include: @/_parts/generated/before-update/bypassable/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityReopenValidator.cls [Static flag]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

In before update, the getter that still runs for a bypassed handler is a Populator's `maxRecursionDepthOnBeforeUpdate()`.

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

For the example, `TriggerOrchestrator.bypass().handler(OpportunityReopenValidator.class)` works, because it is a top-level class. `TriggerOrchestrator.bypass().orchestrator(OpportunityTriggerOrchestrator.class)` switches off every Opportunity handler that orchestrator registers.

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

## Records Here {#records}

No record parameter. The method runs once per handler per run, before any record is looked at, so it cannot decide per record.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Exceptions here are not logged.** `bypassOnBeforeUpdateWhen()` runs outside the handler's try block: an exception there never reaches the Logger, ContinueOnError does not apply, and the update fails.
- **A static flag lasts for the transaction.** It stays set for every chunk and every nested update until you reset it, so reset it in a `finally` block.
- **Metadata cannot switch off only this context.** A `TriggerHandler__mdt` row switches the class off in AfterUpdate and every other context it serves. This add-on is the per-context switch.
- **Two `Bypassable` types.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `BeforeUpdate.Bypassable` is this add-on.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

The example's flag is `OpportunityReopenValidator.isBypassed`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses)
- [Custom Metadata](/api/custom-metadata)
- [TriggerOrchestrator](/api/trigger-orchestrator)
