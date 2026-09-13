---
outline: deep
---

# Recursion Control

An after update handler that updates its own records fires the trigger again. Workflow rules, flows and other triggers do the same. Trigger Lib limits how many times an update handler runs for a given record within one transaction.

Recursion control applies to **before update populators** and **after update handlers**. A before update populator cannot perform DML at all, so its re-entry always comes from somewhere else in the transaction, but it is counted and capped the same way.

Before update **validators** are not counted and cannot be capped. A validator that qualifies attaches an error, which takes that record out of the save, so it cannot run a second time for that record no matter what else happens in the transaction. Declaring `BeforeUpdate.RecursionGuard` on a validator has no effect.

## Default Depth

Before update populators and after update handlers run at most **3 times per record** by default. The counter is keyed by **handler class, trigger operation and record Id**, so:

- two different handlers on the same record have independent counters. One handler exhausting its passes does not consume another handler's,
- the before update and after update counters of one handler are independent,
- every record carries its own budget. A handler limited to two passes and given two records in one DML runs twice for each record, four times in total, and one record exhausting its budget never affects the other,
- the counter lives for the whole transaction.

A record over the limit is skipped for that handler. Other records in the same trigger batch and other handlers are not affected.

## Overriding the Depth

The limit is resolved in three steps, each overriding the one before it:

1. the framework default of **3**,
2. `TriggerOrchestrator.RecursionGuard` on the orchestrator, which sets the default for every handler it returns,
3. the context `RecursionGuard` on an individual handler, which always wins.

### On the Orchestrator

Implement `TriggerOrchestrator.RecursionGuard` to change the default for every handler in that orchestrator, in both update contexts.

```apex
public with sharing class OpportunityTriggerOrchestrator implements TriggerOrchestrator.AfterUpdate, TriggerOrchestrator.RecursionGuard {
  public Integer maxRecursionDepth() {
    return 5;
  }

  public List<AfterUpdate.Handler> afterUpdateHandlers() {
    return new List<AfterUpdate.Handler>{ new OpportunityRollupHandler(), new OpportunityStampHandler() };
  }
}
```

Every handler this orchestrator returns for before update and after update now runs at most 5 times per record, unless it sets its own limit. One value covers both contexts.

### On a Handler

Implement the context `RecursionGuard` to set a limit for one handler. A handler-level limit takes precedence over the orchestrator's.

```apex
public with sharing class OpportunityRollupHandler implements AfterUpdate.Handler, AfterUpdate.RecursionGuard {
  public Integer maxRecursionDepthOnAfterUpdate() {
    return 1;
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isChanged(Opportunity.Amount);
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    // ...
  }
}
```

`maxRecursionDepthOnBeforeUpdate()` is the equivalent for before update.

A depth of `1` means the handler processes each record once per transaction, which is the right choice for handlers that write back to the triggering object.

The minimum is `1`. Returning `0`, a negative number or `null` from either `maxRecursionDepth()` or a context `maxRecursionDepthOn...()` raises a `TriggerOrchestratorException` naming the class and the method, rather than silently disabling the handler or removing its limit.

Unlike the orchestrator setting, the handler setting is per context: a class implementing both `BeforeUpdate.RecursionGuard` and `AfterUpdate.RecursionGuard` can give each context a different limit.

## Counting Rules

The counter increments when a record **qualifies** for the handler, not when it merely passes through the trigger. Records that fail the handler's `...When` predicate do not consume depth.

A record that reaches its limit is **skipped silently** for that handler, before the predicate is evaluated. No exception is thrown, nothing reaches the `Logger`, and the DML succeeds. A handler that stops running is therefore invisible unless you look for it.

Chunking is not recursion. A single DML of 201 records reaches the trigger in two chunks, but each record has its own counter, so no record loses a pass and all 201 are processed.

## Insert, Delete and Undelete

Recursion control applies only to update contexts. Insert, delete and undelete cannot re-enter the same context for the same record, so no counter is kept.
