---
template: add-on
context: AfterUpdate
interface: RecursionGuard
description: 'Cap how many times an after update Writer or Dispatcher acts on the same record in one transaction, to stop recursion from self-updates (default 3).'
---

# AfterUpdate.RecursionGuard

Cap how many times an **after update** Writer or Dispatcher acts on the same record in one transaction, to stop recursion (re-entry, infinite loops) when updates fire the update triggers again. Without it, the limit is 3.

<!--@include: @/_parts/generated/after-update/recursion-guard/available-in.md-->

## When to Use {#when-to-use}

- The handler updates records of its own object, directly or through another object's trigger, and must not act on the same record again in the nested runs.
- The handler must act at most once per record per transaction (return 1), whatever else updates the record.
- Prefer a change gate in the predicate (`isChanged`, `isChangedTo`) where it is enough: it stops re-entry without counting, and it survives partial-save retries.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/recursion-guard/signature.md-->

<!--@include: @/_parts/generated/after-update/recursion-guard/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/recursion-guard/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [One pass per transaction]

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [With ContinueOnError]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/recursion-guard.md-->

In after update, the count is kept per record Id, simple handler class name and `AFTER_UPDATE`. It is separate from the BeforeUpdate count, so a class that serves both contexts has two budgets. A Dispatcher's records spend it when they qualify, although it acts only once per chunk.

### Edge Values {#edge-values}

<!--@include: @/_parts/add-ons/recursion-edge-values.md-->

## Records Here {#records}

`maxRecursionDepthOnAfterUpdate()` takes no records and returns one limit for every record the handler sees. The count behind it is kept per record.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/recursion-guard/works-with.md-->

There is no orchestrator-wide setting: each Writer or Dispatcher declares its own limit, and one without this add-on gets 3.

## Gotchas {#gotchas}

- **It counts qualifying passes, not nesting depth.** Separate updates of the same record in one transaction count too, so with 1, `AccountAddressCascadeWriter` cascades only the first address change of an account in a transaction; a second change later in the same transaction reaches no contact.
- **Partial saves.** A retry after a partial save counts as a pass, so with a limit of 1 the survivors are skipped and their registrations are lost ([Edge Values](#edge-values)).
- **Shared by simple class name.** Two instances of one class in the list share a budget, and so do inner classes with the same name in different outer classes.
- **The limit is per record of this object.** `OpportunityAccountTypeWriter` counts opportunities; the Accounts it updates are counted, if at all, by the Account handlers.

## Test It {#test}

The limit is applied by the orchestrator, not by the handler, so a unit test of the handler calls its predicate and action directly, one pass at a time. To check that a second pass skips the record, run the orchestrator in a test, which works in the same namespace only: [Testing](/guide/testing#orchestrator).

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/recursion-guard/other-contexts.md-->

## See Also {#see-also}

- [BeforeUpdate.RecursionGuard](/before-update/add-ons/recursion-guard): the separate count for before update.
- [Updating the same object](/after-update/#gotchas): how self-updates re-enter this context.
- [Execution Order & Cost](/guide/execution-order)
