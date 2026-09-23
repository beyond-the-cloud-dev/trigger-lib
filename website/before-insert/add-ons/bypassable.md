---
template: add-on
context: BeforeInsert
interface: Bypassable
description: Skip (bypass, disable) a before insert handler for the whole run when a condition holds, such as a static flag or a batch.
---

# BeforeInsert.Bypassable

Skip (bypass, disable, turn off) a **before insert** handler for the whole run when a condition holds, such as a static flag, a batch job or a custom permission, without touching the orchestrator.

<!--@include: @/_parts/generated/before-insert/bypassable/available-in.md-->

## When to Use {#when-to-use}

- Let code that inserts records switch a handler off for its own save, through a static flag.
- Skip a handler in batch or other async contexts, such as a validation that bulk loads must not hit.
- Skip a handler for users with a custom permission, such as a migration user.

To skip only some records, return false from the predicate instead. To switch a handler off without deploying code, use custom metadata (below).

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/bypassable/signature.md-->

<!--@include: @/_parts/generated/before-insert/bypassable/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/bypassable/skeleton.md-->

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactReachabilityValidator.cls [Static flag or batch]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/bypassable.md-->

### Other Ways to Switch Off {#other-ways}

<!--@include: @/_parts/add-ons/switch-off.md-->

### During a Data Migration {#data-migration}

<!--@include: @/_parts/add-ons/data-migration.md-->

## Records Here {#records}

`bypassOnBeforeInsertWhen()` receives no records: it decides for the whole run, before any predicate. To skip only some records, return false from `populateOnBeforeInsertWhen` or `errorShouldBeAttachedOnBeforeInsertWhen`.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/bypassable/works-with.md-->

## Gotchas {#gotchas}

- **Outside the error handling.** `bypassOnBeforeInsertWhen()` runs before the handler's try block. An exception thrown there is not logged, ContinueOnError does not apply, and the insert fails.
- **Static flags last for the transaction.** A flag set to true stays true for every later save in the same transaction, nested saves included. Set it back to false in a `finally` block after your own DML.
- **A bypassed Validator lets records through.** Nothing checks what that Validator would have rejected, so records it would block are saved.
- **Two interfaces named Bypassable.** `TriggerOrchestrator.Bypassable` is the builder that `TriggerOrchestrator.bypass()` returns; `BeforeInsert.Bypassable` is this add-on, which a handler implements to switch itself off.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

For the `[Static flag or batch]` example, set `ContactReachabilityValidator.isDisabled = true` and assert that `bypassOnBeforeInsertWhen()` returns true; a plain test method is not a batch, so `System.isBatch()` is false.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/bypassable/other-contexts.md-->

## See Also {#see-also}

- [Bypassing](/guide/bypasses): every switch and the order of checks.
- [Custom Metadata](/api/custom-metadata): `TriggerObject__mdt` and `TriggerHandler__mdt`.
- [BeforeInsert](/before-insert/#switching-off) overview.
