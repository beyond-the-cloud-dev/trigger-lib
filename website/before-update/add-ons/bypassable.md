---
template: add-on
context: BeforeUpdate
interface: Bypassable
description: Skip a before update Populator or Validator when a condition holds, such as a static flag or a custom permission.
---

# BeforeUpdate.Bypassable

Skips a Populator or Validator for the whole chunk when a condition holds, such as a static flag or a custom permission.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityReopenValidator.cls [Static flag]

:::

## Good to Know {#good-to-know}

- **Not per record.** To skip only some records, return false from the predicate.
- **Reset a static flag in `finally`.** The flag stays set for every chunk and every nested update in the transaction.
- **Exceptions here are not logged.** `bypassOnBeforeUpdateWhen()` runs outside the handler's error handling. ContinueOnError does not apply, and the update fails.
- **Only this context.** A `TriggerHandler__mdt` row or `TriggerOrchestrator.bypass().handler(X.class)` switches the class off in every context. This add-on skips only before update.
- **Inner classes need this add-on.** `TriggerOrchestrator.bypass().handler(X.class)` and `.orchestrator(X.class)` never match an inner class. Use a `TriggerHandler__mdt` row or this add-on.
