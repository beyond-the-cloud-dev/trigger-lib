---
description: Switch Trigger Lib handlers off from Apex for one transaction with TriggerOrchestrator.bypass(), org-wide with TriggerObject__mdt and TriggerHandler__mdt, or on a condition with a context's Bypassable, plus a data migration recipe.
---

# Bypassing

Switch handlers off from Apex for one transaction, org-wide with custom metadata, or from the handler with Bypassable. Only Trigger Lib handlers are skipped: flows, validation rules and other triggers still run.

## From Apex {#apex}

[`TriggerOrchestrator.bypass()`](/api/trigger-orchestrator#bypass) switches off an object, an orchestrator, a handler class in every context, or every run:

```apex
TriggerOrchestrator.bypass().sObject(Contact.SObjectType).handler(AccountOwnerTransferWriter.class);
try {
    update accounts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- **Set it before the DML.** It lasts until `clear()` or the end of the transaction, nested saves included.
- **One transaction only.** A Queueable, a future method or the next batch `execute` starts without bypasses.

## From Custom Metadata {#metadata}

Check `Bypass__c` on a `TriggerObject__mdt` record to switch off every handler on an object for every user, or on a `TriggerHandler__mdt` record under it to switch off one class. Changes apply from the next transaction. Fields, deployment and test mocks: [Custom Metadata](/api/custom-metadata).

## From the Handler {#bypassable}

Implement the context's Bypassable. `bypassOn<Ctx>When()` runs once per handler per run and takes no records. When it returns true, the handler is skipped for that run.

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactReachabilityValidator.cls

- **Checked last.** The Apex and metadata bypasses win.
- **Checked before the first handler runs.** A flag set by an earlier handler in the same run applies from the next run.
- **One context only.** The other bypasses cover every context. To skip a class in one context, use Bypassable or leave it out of that context's list.
- **To skip only some records,** return false from the predicate instead.

## Per User {#per-user}

There is no per-user bypass. Check a custom permission yourself:

```apex
public Boolean bypassOnAfterUpdateWhen() {
    return FeatureManagement.checkPermission('Bypass_Account_Automation');
}
```

To skip a whole context, return an empty list from `<ctx>Handlers()` under the same check.

## Data Migration {#data-migration}

For Data Loader, the Bulk API or an import wizard:

1. Check `Bypass__c` on the object's `TriggerObject__mdt` record. Create the record if it is missing.
2. Run the load.
3. Uncheck `Bypass__c`.
4. Backfill what the handlers would have done. Nothing re-runs them later.

The bypass affects every user while it is on.
