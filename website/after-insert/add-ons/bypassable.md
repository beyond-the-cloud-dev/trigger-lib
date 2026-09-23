---
template: add-on
context: AfterInsert
interface: Bypassable
description: AfterInsert.Bypassable - skip (bypass, disable, turn off) an after insert Writer or Dispatcher for the whole run when a condition holds.
---

# AfterInsert.Bypassable

Skip (bypass, disable, turn off) an **after insert** Writer or Dispatcher for the whole run when a condition holds: a static flag, a custom permission, a feature switch. The handler's other contexts are not affected.

<!--@include: @/_parts/generated/after-insert/bypassable/available-in.md-->

## When to Use {#when-to-use}

- Switch one handler off from code, for example while a service or a data fix inserts records.
- Switch it off for users with a custom permission, such as a migration user.
- Skip only the after insert run of a class that also serves other contexts.
- To skip single records, return false from the predicate instead.

## Interface {#interface}

<!--@include: @/_parts/generated/after-insert/bypassable/signature.md-->

<!--@include: @/_parts/generated/after-insert/bypassable/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-insert/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/contact/after-insert/writer/ContactOwnerAlignmentWriter.cls [Static flag]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

`ContactOwnerAlignmentWriter` is a top-level class, so `TriggerOrchestrator.bypass().handler(ContactOwnerAlignmentWriter.class)` switches it off, in after insert and in any other context it serves.

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

## Records Here {#records}

`bypassOnAfterInsertWhen()` takes no records: it decides for the whole run, before any record is looked at.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-insert/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Outside the error handling.** An exception thrown by `bypassOnAfterInsertWhen()` is not logged, ContinueOnError does not apply, and the insert fails.
- **The unit is chosen first.** A bypassed Writer that implements OwnUnitOfWork still has `ownUnitOfWorkOnAfterInsert()` called.
- **Static flags last for the transaction.** `ContactOwnerAlignmentWriter.isDisabled = true` stays set for every later chunk and every nested save until you reset it.
- **Two Bypassables.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `AfterInsert.Bypassable` is this handler add-on.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

For the example: set `ContactOwnerAlignmentWriter.isDisabled = true`, then assert that `new ContactOwnerAlignmentWriter().bypassOnAfterInsertWhen()` is true.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-insert/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses)
- [Custom Metadata](/api/custom-metadata)
- [TriggerOrchestrator](/api/trigger-orchestrator)
