---
template: add-on
context: BeforeUpdate
interface: RecursionGuard
description: BeforeUpdate.RecursionGuard caps how many times a before update Populator acts on the same record in one transaction when the update re-enters.
---

# BeforeUpdate.RecursionGuard

Stop a **before update** Populator from acting on the same record again when the update re-enters (recursion, re-fire, loop, run once per transaction).

<!--@include: @/_parts/generated/before-update/recursion-guard/available-in.md-->

## When to Use {#when-to-use}

- The Populator is not idempotent, for example it appends an audit line, and something updates the same records again later in the transaction: an AfterUpdate Writer's `toUpdate`, a Flow, another trigger.
- You want a limit other than the default of 3.

A Populator gated on a change often needs no guard: on a nested update, `isChanged` compares with the values the previous update saved, so it is false unless the field changed again. A Validator ignores this add-on and runs on every pass.

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/recursion-guard/signature.md-->

<!--@include: @/_parts/generated/before-update/recursion-guard/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/recursion-guard/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/populator/OpportunityClosingPopulator.cls [One pass]

<<< @/../examples/main/default/classes/account/before-update/populator/AccountTypeAuditPopulator.cls [Audit line]

<<< @/../examples/main/default/classes/contact/before-update/populator/ContactAccountTransferPopulator.cls [With parent queries]

:::

All three examples return 1. Read [Edge Values](#edge-values) before you copy that.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/recursion-guard.md-->

In before update, the count is separate from AfterUpdate's: a class that runs in both contexts has one budget for each.

### Edge Values {#edge-values}

<!--@include: @/_parts/add-ons/recursion-edge-values.md-->

## Records Here {#records}

No record parameter. The limit applies to each record Id separately, so every record in the chunk has its own count.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/recursion-guard/works-with.md-->

There is no orchestrator-wide setting: each Populator declares its own limit, and one without this add-on gets 3.

## Gotchas {#gotchas}

- **"Depth" means qualifying passes, not nesting level.** The limit counts how many times the record qualified in the transaction, whether those passes came from one nested update or from several separate updates in the same transaction.
- **The platform has its own limit.** Whatever the guard allows, the platform stops at 16 nested trigger levels.
- **A limit of 1 blocks a second, legitimate edit.** Two separate updates of the same record in one transaction, such as two steps of one service method, both qualify, and the second one is skipped.

## Test It {#test}

Test the limit you return and the predicate directly. Counting passes needs the orchestrator run twice in a test, which works in the same namespace only: [Testing](/guide/testing#orchestrator).

```apex
@IsTest
static void maxRecursionDepthOnBeforeUpdate() {
    // Test
    Integer depth = new OpportunityClosingPopulator().maxRecursionDepthOnBeforeUpdate();

    // Verify
    Assert.areEqual(1, depth, 'One pass per record should be allowed.');
}
```

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/recursion-guard/other-contexts.md-->

## See Also {#see-also}

- [AfterUpdate.RecursionGuard](/after-update/add-ons/recursion-guard)
- [Change Detection](/before-update/record-api#change-detection)
- [Execution Order & Cost](/guide/execution-order)
