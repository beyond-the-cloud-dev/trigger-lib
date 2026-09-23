---
template: add-on
context: AfterUndelete
interface: Bypassable
description: Skip (bypass, disable, turn off) an after undelete Writer or Dispatcher for the whole run when a condition holds, and the other ways to switch handlers off.
---

# AfterUndelete.Bypassable

Skip (bypass, disable, turn off) an **after undelete** Writer or Dispatcher for the whole run when a condition holds, such as a static flag, a custom permission or a batch context.

<!--@include: @/_parts/generated/after-undelete/bypassable/available-in.md-->

## When to Use {#when-to-use}

- A handler must not run in some situations: during a restore script, for an integration user, or when a feature flag is off.
- Only the restore run of a class that also serves other contexts should be skipped.
- Use the predicate instead to skip single records, and metadata to switch a handler off without deploying code ([Other Ways to Switch Off](#other-ways)).

## Interface {#interface}

<!--@include: @/_parts/generated/after-undelete/bypassable/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-undelete/bypassable/skeleton.md-->

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

With the Skeleton above, the Apex switch is `TriggerOrchestrator.bypass().handler(ContactWriter.class)`, which works because `ContactWriter` is a top-level class.

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

## Records Here {#records}

`bypassOnAfterUndeleteWhen()` takes no records. It answers for the whole run, once per handler.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-undelete/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Outside the error handling.** An exception in `bypassOnAfterUndeleteWhen()` is not logged, ContinueOnError does not apply, and the restore fails.
- **Static flags last for the transaction.** A flag set before an `undelete` statement stays set for nested saves and later chunks until you reset it, so reset it in a `finally` block.
- **Name collision.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `AfterUndelete.Bypassable` is this add-on.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

With the Skeleton above, the flag is `ContactWriter.isDisabled`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-undelete/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses)
- [Custom Metadata](/api/custom-metadata)
- [TriggerOrchestrator](/api/trigger-orchestrator)
