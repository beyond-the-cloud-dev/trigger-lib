---
template: add-on
context: AfterUpdate
interface: Bypassable
description: 'Skip (bypass, disable, turn off) an after update Writer or Dispatcher for a whole run when a condition holds, such as a static flag, a batch job or a custom permission.'
---

# AfterUpdate.Bypassable

Skip (bypass, disable, turn off) an **after update** Writer or Dispatcher for the whole run when a condition holds: a static flag, a batch context, a custom permission.

<!--@include: @/_parts/generated/after-update/bypassable/available-in.md-->

## When to Use {#when-to-use}

- Code that knows better switches the handler off for a while, through a static flag.
- The handler must not run in some execution contexts, such as batch jobs or a data migration user.
- Use `TriggerOrchestrator.bypass()` or custom metadata instead to switch off a handler in every context, and return false from the predicate to skip single records.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/bypassable/signature.md-->

<!--@include: @/_parts/generated/after-update/bypassable/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/account/after-update/writer/AccountOwnerTransferWriter.cls [Static flag or batch]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

In after update, the getters are `maxRecursionDepthOnAfterUpdate()` on a Writer or Dispatcher and `ownUnitOfWorkOnAfterUpdate()` on a Writer.

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

For the example, that is `TriggerOrchestrator.bypass().handler(AccountOwnerTransferWriter.class)`: it is a top-level class, so the name matches.

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

## Records Here {#records}

`bypassOnAfterUpdateWhen()` takes no records: the decision covers the whole run, that is, every record of the chunk. To skip single records, return false from the predicate.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Outside the error handling.** An exception thrown by `bypassOnAfterUpdateWhen()` is not logged, ContinueOnError does not apply, and the update fails.
- **Static flags last for the transaction.** Set a flag in a `try` and reset it in `finally`, or it also skips the handler in every later update of the same transaction, nested saves included.
- **`System.isBatch()` covers every batch.** `AccountOwnerTransferWriter` returns true in any batch `execute`, so owner changes made by any batch job leave the open opportunities with the old owner, not only those of a data migration.
- **Two types named Bypassable.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `AfterUpdate.Bypassable` is this add-on.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

For the example, set `AccountOwnerTransferWriter.isDisabled = true` and assert that `bypassOnAfterUpdateWhen()` returns true.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses): every switch and the full order of checks.
- [Custom Metadata](/api/custom-metadata): `TriggerObject__mdt` and `TriggerHandler__mdt`.
- [Switching handlers off in AfterUpdate](/after-update/#switching-off)
