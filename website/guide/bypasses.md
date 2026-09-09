---
outline: deep
---

# Bypasses

A bypass switches a handler off for the current trigger invocation. It is expressed in code, on the handler, so the condition is visible next to the logic it disables. No custom metadata records are required.

## Bypassable Handler

Implement the `Bypassable` interface of the context and return `true` from `bypassOn...When()` to skip the handler.

```apex
public with sharing class AccountScoringHandler implements AfterUpdate.Handler, AfterUpdate.Bypassable {
  public static Boolean isDisabled = false;

  public Boolean bypassOnAfterUpdateWhen() {
    return isDisabled || System.isBatch();
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
    return record.isChanged(Account.AnnualRevenue);
  }

  public void onAfterUpdate(TriggerHandler.Record record) {
    // ...
  }
}
```

The bypass check runs first, before enrichment and qualification. A bypassed handler contributes no parent fields to the enrichment query and never sees a record.

## Bypass Sources

The bypass method is plain Apex, so any condition works:

- A static flag set by a data migration or a test.
- A custom permission checked with `FeatureManagement.checkPermission`.
- A custom setting or custom metadata record, when you want admins to control it.
- Execution context, such as `System.isBatch()` or `System.isFuture()`.

```apex
public Boolean bypassOnBeforeInsertWhen() {
    return FeatureManagement.checkPermission('Bypass_Account_Defaults');
}
```

## Bypassing a Whole Orchestrator

Return an empty handler list to skip a context, or guard the trigger itself:

```apex
trigger AccountTrigger on Account(before insert, before update, after update) {
  if (TriggerSettings.isBypassed(Account.SObjectType)) {
    return;
  }

  TriggerOrchestrator.run(new AccountTriggerOrchestrator());
}
```

`TriggerSettings` is your own class. The framework does not prescribe how orchestrator-level bypasses are stored.

## Bypasses in Tests

Static flags make it easy to isolate a handler under test:

```apex
@IsTest
static void createsTaskWhenPriorityChanges() {
    AccountScoringHandler.isDisabled = true;

    // insert and update records, assert on the handler under test
}
```
