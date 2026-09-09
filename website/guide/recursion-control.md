---
outline: deep
---

# Recursion Control

An after update handler that updates its own records fires the trigger again. Workflow rules, flows and other triggers do the same. Trigger Lib limits how many times an update handler runs for a given record within one transaction.

## Default Depth

Before update and after update handlers run at most **3 times per record** by default. The counter is kept per handler class, per context and per record Id, so:

- two different handlers on the same record have independent counters,
- the before update and after update counters of one handler are independent,
- the counter lives for the whole transaction.

A record over the limit is skipped for that handler. Other records in the same trigger batch and other handlers are not affected.

## Overriding the Depth

Implement `RecursionGuard` to set a different limit for a handler.

```apex
public with sharing class OpportunityRollupHandler implements AfterUpdate.Handler, AfterUpdate.RecursionGuard {
  public Integer maxRecursionDepthOnAfterUpdate() {
    return 1;
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChanged(Opportunity.Amount);
  }

  public void onAfterUpdate(TriggerHandler.Record record) {
    // ...
  }
}
```

`maxRecursionDepthOnBeforeUpdate()` is the equivalent for before update.

A depth of `1` means the handler processes each record once per transaction, which is the right choice for handlers that write back to the triggering object.

## Counting Rules

The counter increments when a record **qualifies** for the handler, not when it merely passes through the trigger. Records that fail `qualifiesFor...When` do not consume depth.

## Insert, Delete and Undelete

Recursion control applies only to update contexts. Insert, delete and undelete cannot re-enter the same context for the same record, so no counter is kept.
