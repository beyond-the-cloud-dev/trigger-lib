---
description: Switch Trigger Lib handlers off (bypass, skip, disable) from Apex for one transaction with TriggerOrchestrator.bypass(), org-wide with TriggerObject__mdt and TriggerHandler__mdt, or on a condition with a context's Bypassable, plus the fixed order of checks and a data migration recipe.
---

# Bypassing

Switch Trigger Lib handlers off (bypass, skip, disable, turn off triggers) in three ways: from Apex for one transaction, org-wide from custom metadata without a deployment, or on a condition inside the handler. The library checks them in a fixed order, and none of them touches anything that does not run through Trigger Lib.

## Three Layers {#layers}

| Layer | Switches off | Lasts | Set by |
|---|---|---|---|
| [`TriggerOrchestrator.bypass()`](#apex) | every run, an object, an orchestrator or a handler class | until `clear()` or the end of the transaction | Apex that runs before the DML |
| [Custom metadata](#metadata) | an object, or one handler class on that object | while `Bypass__c` is checked, for every user | an admin in Setup, or a deployment |
| [`<Ctx>.Bypassable`](#bypassable) | one handler in one context | one run: the method is asked again on every run | the handler's own code |

To skip only some records, return false from the handler's predicate instead. Each context's overview sums the layers up under Switching Handlers Off, for example [BeforeInsert](/before-insert/#switching-off).

## From Apex: `TriggerOrchestrator.bypass()` {#apex}

`TriggerOrchestrator.bypass()` returns a builder, `TriggerOrchestrator.Bypassable`, that keeps its switches in a static for the rest of the transaction:

| Method | Switches off | Returns |
|---|---|---|
| `sObject(SObjectType)` | every run on that object, in every context | the builder |
| `orchestrator(System.Type)` | every run of that orchestrator class, in every context | the builder |
| `handler(System.Type)` | that handler class, in every context and on every object | the builder |
| `all()` | every Trigger Lib run | nothing |
| `clear()` | removes every switch; there is no way to remove only one | nothing |

```apex
TriggerOrchestrator.bypass().sObject(Contact.SObjectType).handler(AccountOwnerTransferWriter.class);
try {
    update accounts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- **Set it before the DML.** A switch applies to the runs that start after it is set, nested saves included: a Writer's commit that updates Contacts sees the Contact switch above.
- **One transaction only.** A Queueable, a future method or the next batch `execute` runs in a new transaction, where no switch is set.
- **Same for every user.** It is plain Apex, so the code that sets it decides who is affected.

::: warning `handler(X.class)` and `orchestrator(X.class)` match top-level classes only
They store the name that `X.class` reports, which is `Outer.Inner` for an inner class, and compare it with the running class's simple name, `Inner`. An inner class therefore never matches, and the call switches nothing off. For an inner handler class, use its [`TriggerHandler__mdt` record](#metadata) or its [Bypassable](#bypassable); for an inner orchestrator class, use `sObject(…)`. Matching in a namespaced installation has not been verified.
:::

## From Custom Metadata {#metadata}

Two custom metadata types ship with the library. Records of either type only ever switch things off: with no records, every handler runs, and reading them costs nothing.

| Type | Field | Meaning |
|---|---|---|
| `TriggerObject__mdt` (Trigger Object) | `ObjectAPIName__c` | API name of the object, such as `Account` or `Invoice__c`; trimmed and compared ignoring case |
| | `Bypass__c` | checked: no Trigger Lib handler runs on this object, in any context |
| `TriggerHandler__mdt` (Trigger Handler) | `TriggerObject__c` | the Trigger Object record it belongs to (required) |
| | `ApexClassName__c` | the handler's class name: `Inner` or `Outer.Inner` for an inner class; trimmed and compared ignoring case |
| | `Bypass__c` | checked: this handler class is skipped on that object, in every context |

- **Handler records work only under their object's record.** A Trigger Handler record under the Account record does nothing on Contact, even for a class that also runs there.
- **Read once per transaction.** The library reads both types the first time it is used in a transaction and keeps them in a static. A change applies from the next transaction. Custom metadata queries do not count against the SOQL limit.
- **Every user, every context.** There is no per-context or per-user field. For those, see [one context](#one-context) and [per user](#per-user).
- **Same simple name, same switch.** The class name is matched by simple name, so inner classes named alike in different outer classes are switched off together. See [the `ApexClassName__c` format](/api/custom-metadata#class-name-format).
- **They apply in tests too.** Deployed records are visible to test methods. Mock them when you run the orchestrator in a test: [Testing](/guide/testing#mock-metadata).

Create the records in Setup, under **Custom Metadata Types**, **Manage Records**, or deploy them as source. The file names are `<Type>.<DeveloperName>.md-meta.xml` in a `customMetadata` folder:

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

- **`TriggerObject__c` holds the parent's developer name alone**, `Account`, not `TriggerObject.Account`.
- **Declare `xmlns:xsd`** on `<CustomMetadata>`. Without it the deployment fails with an `UNKNOWN_EXCEPTION` that names no component.

To switch off one handler, keep the object record's `Bypass__c` unchecked and check it on the handler record. To switch off the whole object, check it on the object record; handler records under it no longer matter.

## From the Handler: Bypassable {#bypassable}

Every context has a `Bypassable` add-on with one method, `bypassOn<Ctx>When()`. When it returns true, the handler is skipped for that run. This Validator switches itself off through a static flag and in batch Apex:

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactReachabilityValidator.cls

<!--@include: @/_parts/add-ons/bypassable.md-->

Each context's page has the signature, an example and the context's own details:

<!--@include: @/_parts/generated/chips/bypassable.md-->

## Order of Checks {#order}

Every run checks the switches in this order. The first one that applies wins, and the later checks for that run or handler are not made:

| # | Check | When it applies |
|---|---|---|
| 1 | Called outside a trigger | `run()` throws; nothing else happens |
| 2 | `TriggerOrchestrator.bypass()`: `all()`, `sObject(…)` or `orchestrator(…)` | the run ends before any of your code, `<ctx>Handlers()` included |
| 3 | `TriggerObject__mdt.Bypass__c` on the object's record | the run ends the same way |
| 4 | The orchestrator does not implement `TriggerOrchestrator.<Ctx>` | the run ends silently |
| 5 | `<ctx>Handlers()` is called and each handler is adapted | the getters `ownUnitOfWorkOn<Ctx>()` and `maxRecursionDepthOn<Ctx>()` run here, bypassed or not |
| 6 | `TriggerOrchestrator.bypass().handler(…)` | that handler is skipped |
| 7 | `TriggerHandler__mdt.Bypass__c` on the handler's record under this object | that handler is skipped |
| 8 | `bypassOn<Ctx>When()` | that handler is skipped |

Checks 6 to 8 run for every handler in the list before the first handler starts. Only then do parents load and the remaining handlers run, in list order. A skipped handler contributes no parent declarations: another handler that reads a parent only the skipped handler declared now gets `null`. Its instance is still built by `<ctx>Handlers()`, so its constructor runs.

The complete sequence of a run, with parents, providers and commits, is on [Execution Order & Cost](/guide/execution-order).

## Only One Context {#one-context}

No switch works per context. A metadata record and `handler(X.class)` switch a class off in every context it serves, and `sObject(…)` and `orchestrator(…)` switch off every context of the object or the orchestrator. To skip a class in one context:

- implement that context's Bypassable and return true, or
- leave the class out of that context's `<ctx>Handlers()` list.

## Per User or Permission {#per-user}

There is no per-user, per-profile or per-permission switch: metadata applies to the whole org, and `TriggerOrchestrator.bypass()` to one transaction. Check a custom permission yourself.

For one handler, in its Bypassable method:

```apex
public Boolean bypassOnAfterUpdateWhen() {
    return FeatureManagement.checkPermission('Bypass_Account_Automation');
}
```

For every handler of a context, in the orchestrator:

```apex
public List<AfterUpdate.Handler> afterUpdateHandlers() {
    if (FeatureManagement.checkPermission('Bypass_Account_Automation')) {
        return new List<AfterUpdate.Handler>();
    }

    return new List<AfterUpdate.Handler>{ new AccountAddressCascadeWriter(), new AccountOwnerTransferWriter() };
}
```

Both methods run outside every handler's error handling: an exception there is not logged, and it fails the save.

## During a Data Migration {#data-migration}

**Data Loader, Bulk API or an import wizard.** None of your Apex runs before the load, so use metadata:

1. Open the object's Trigger Object record, or create one with `ObjectAPIName__c` set to the object's API name, and check `Bypass__c`. Every Trigger Lib handler on the object is now skipped, in every context, for every user.
2. Run the load.
3. Uncheck `Bypass__c`.
4. Backfill what the handlers would have done, such as derived fields or related records. Nothing re-runs a skipped handler later.

To skip only some handlers, leave the object record unchecked and check `Bypass__c` on their Trigger Handler records instead. While the switch is on, other users' saves skip the handlers too. If the org stays in use during the load, switch the handlers off for the migration user only, with a custom permission [as above](#per-user).

**Apex script, anonymous Apex or a batch.** Switch the object off in the same transaction as the DML:

```apex
TriggerOrchestrator.bypass().sObject(Account.SObjectType);
try {
    update accounts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

In a batch, set the switch inside `execute`. Every `execute` call runs in its own transaction, and a switch set in `start` does not carry over.

## Scope {#scope}

Every switch skips only handlers that run through Trigger Lib. Flows, validation rules, duplicate rules, workflow rules and triggers not built on Trigger Lib still run, so a migration that must skip them switches them off separately.

## Testing Bypasses {#testing}

**A Bypassable method.**

<!--@include: @/_parts/add-ons/test-techniques.md#bypass-->

**Test data without handlers.** In an integration test that inserts real records, switch the object off while you build the data:

```apex
@TestSetup
static void setup() {
    TriggerOrchestrator.bypass().sObject(Account.SObjectType);
    insert new Account(Name = 'Acme');
}
```

Each test method starts with fresh static values, so the switch set in `@TestSetup` does not reach the test methods, and a switch set in one test method does not leak into the next.

**Metadata records.** Deployed Trigger Object and Trigger Handler records apply in tests. When you run the orchestrator in a test, mock them, or return a record to test a metadata bypass: [Testing](/guide/testing#mock-metadata).

## See Also {#see-also}

- [Custom Metadata](/api/custom-metadata): both types field by field
- [TriggerOrchestrator](/api/trigger-orchestrator): `bypass()` and the `Bypassable` builder
- [Execution Order & Cost](/guide/execution-order): the whole run, step by step
- [Errors & Logging](/guide/error-handling#never-logged): what happens when a bypass method throws
