---
description: Switch Trigger Lib handlers off from Apex for one transaction with TriggerOrchestrator.bypass(), org-wide with TriggerObject__mdt and TriggerHandler__mdt, or on a condition with a context's Bypassable, plus a data migration recipe.
---

# Bypassing

Switch handlers off in three ways: from Apex for one transaction, org-wide with custom metadata, or from the handler itself with Bypassable. To skip only some records, return false from the predicate instead.

Every switch skips only Trigger Lib handlers. Flows, validation rules and other triggers still run.

## From Apex {#apex}

`TriggerOrchestrator.bypass()` returns a builder:

| Method | Switches off |
|---|---|
| `sObject(SObjectType)` | every run on that object |
| `orchestrator(System.Type)` | every run of that orchestrator |
| `handler(System.Type)` | that handler class, in every context |
| `all()` | every Trigger Lib run |
| `clear()` | removes every switch |

```apex
TriggerOrchestrator.bypass().sObject(Contact.SObjectType).handler(AccountOwnerTransferWriter.class);
try {
    update accounts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- **Set it before the DML.** It lasts until `clear()` or the end of the transaction, nested saves included.
- **One transaction only.** A Queueable, a future method or the next batch `execute` starts without switches.

::: warning Inner classes never match
`handler(X.class)` and `orchestrator(X.class)` do not match an inner class. For an inner handler, use a `TriggerHandler__mdt` record or Bypassable. For an inner orchestrator, use `sObject(…)`.
:::

## From Custom Metadata {#metadata}

Two custom metadata types switch handlers off for every user, without a deployment:

| Type | Fields |
|---|---|
| `TriggerObject__mdt` | `ObjectAPIName__c` (such as `Account`) and `Bypass__c`: when checked, no handler runs on the object |
| `TriggerHandler__mdt` | `TriggerObject__c` (the object record), `ApexClassName__c` and `Bypass__c`: when checked, that class is skipped on that object |

::: code-group

```xml [TriggerObject.Account.md-meta.xml]
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Account</label>
    <protected>false</protected>
    <values>
        <field>ObjectAPIName__c</field>
        <value xsi:type="xsd:string">Account</value>
    </values>
    <values>
        <field>Bypass__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
</CustomMetadata>
```

```xml [TriggerHandler.AccountOwnerTransferWriter.md-meta.xml]
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Account Owner Transfer Writer</label>
    <protected>false</protected>
    <values>
        <field>TriggerObject__c</field>
        <value xsi:type="xsd:string">Account</value>
    </values>
    <values>
        <field>ApexClassName__c</field>
        <value xsi:type="xsd:string">AccountOwnerTransferWriter</value>
    </values>
    <values>
        <field>Bypass__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
```

:::

- **No records, no switches.** Records only ever switch things off.
- **Read once per transaction.** A change applies from the next transaction. The read does not count against the SOQL limit.
- **A handler record works only under its object's record.**
- **Declare `xmlns:xsd`.** Without it the deployment fails with an `UNKNOWN_EXCEPTION`.
- **Deployed records apply in tests.** Mock them when you run the orchestrator: [Testing](/guide/testing#mock-metadata).

## From the Handler {#bypassable}

Implement the context's Bypassable. `bypassOn<Ctx>When()` runs once per handler per run and takes no records. When it returns true, the handler is skipped for that run.

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactReachabilityValidator.cls

- **Checked last.** The Apex and metadata switches win.
- **Checked before the first handler runs.** A flag set by an earlier handler in the same run applies from the next run.
- **One context only.** The other switches cover every context. To skip a class in one context, use Bypassable or leave it out of that context's list.

## Per User {#per-user}

There is no per-user switch. Check a custom permission yourself:

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

The switch affects every user while it is on. For an Apex script or a batch, call `TriggerOrchestrator.bypass().sObject(…)` in the same transaction as the DML. In a batch, set it inside `execute`.

## In Tests {#testing}

- **Test data without handlers.** Call `TriggerOrchestrator.bypass().sObject(…)` in `@TestSetup` before the insert.
- **No leaks.** Every test method starts with fresh static values, so a switch never reaches the next test.
