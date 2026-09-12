---
outline: deep
---

# Bypasses

A bypass switches a handler off for the current trigger invocation. There are two ways to express one:

- **In code**, with the `Bypassable` interface of the context, so the condition lives next to the logic it disables.
- **In custom metadata**, with `TriggerObject__mdt` and `TriggerHandler__mdt`, so an admin can switch a handler or a whole object off without a deployment.

**Zero metadata records are required.** With no `TriggerObject__mdt` records in the org, every handler runs, nothing about the behaviour changes, and no SOQL is consumed. Metadata records only ever turn things off.

## Bypassable Handler

Implement the `Bypassable` interface of the context and return `true` from `bypassOn...When()` to skip the handler.

```apex
public with sharing class AccountScoringHandler implements AfterUpdate.Handler, AfterUpdate.Bypassable {
  public static Boolean isDisabled = false;

  public Boolean bypassOnAfterUpdateWhen() {
    return isDisabled || System.isBatch();
  }

  public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
    return record.isChanged(Account.AnnualRevenue);
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    // ...
  }
}
```

`bypassOn...When()` takes no record. It is asked once per invocation, for the handler as a whole, not per record. Per-record decisions belong in [qualification](/guide/qualification).

| Context        | Interface                   | Method                     |
| -------------- | --------------------------- | -------------------------- |
| Before Insert  | `BeforeInsert.Bypassable`   | `bypassOnBeforeInsertWhen` |
| After Insert   | `AfterInsert.Bypassable`    | `bypassOnAfterInsertWhen`  |
| Before Update  | `BeforeUpdate.Bypassable`   | `bypassOnBeforeUpdateWhen` |
| After Update   | `AfterUpdate.Bypassable`    | `bypassOnAfterUpdateWhen`  |
| Before Delete  | `BeforeDelete.Bypassable`   | `bypassOnBeforeDeleteWhen` |
| After Delete   | `AfterDelete.Bypassable`    | `bypassOnAfterDeleteWhen`  |
| After Undelete | `AfterUndelete.Bypassable`  | `bypassOnAfterUndeleteWhen`|

A class that runs in several contexts implements one `Bypassable` per context, and each is answered separately.

## Bypass Sources

The bypass method is plain Apex, so any condition works:

- A static flag set by a data migration or a test.
- A custom permission checked with `FeatureManagement.checkPermission`.
- A custom setting, when you want per-user or per-profile control.
- Execution context, such as `System.isBatch()` or `System.isFuture()`.

```apex
public Boolean bypassOnBeforeInsertWhen() {
    return FeatureManagement.checkPermission('Bypass_Account_Defaults');
}
```

## Metadata Bypass

`TriggerObject__mdt` names an object. `TriggerHandler__mdt` names an Apex class and points at its `TriggerObject__mdt` parent.

**TriggerObject\_\_mdt**

| Field              | Type     | Meaning                                                   |
| ------------------ | -------- | --------------------------------------------------------- |
| `ObjectAPIName__c` | Text     | API name of the object, for example `Account`              |
| `Bypass__c`        | Checkbox | When checked, no handler runs for this object             |

**TriggerHandler\_\_mdt**

| Field              | Type                 | Meaning                                        |
| ------------------ | -------------------- | ---------------------------------------------- |
| `ApexClassName__c` | Text                 | Name of the handler class                      |
| `TriggerObject__c` | Metadata Relationship| The `TriggerObject__mdt` record this belongs to |
| `Bypass__c`        | Checkbox             | When checked, this handler is skipped          |

### Bypassing One Handler

Create a `TriggerObject__mdt` record for the object with `Bypass__c` unchecked, then a `TriggerHandler__mdt` child for the class with `Bypass__c` checked. Handler records are only read through their parent, so the object record has to exist even when you are only switching off one class.

```xml
<!-- force-app/main/default/customMetadata/TriggerObject.Account.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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

```xml
<!-- force-app/main/default/customMetadata/TriggerHandler.AccountScoringHandler.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>Account Scoring Handler</label>
    <protected>false</protected>
    <values>
        <field>ApexClassName__c</field>
        <value xsi:type="xsd:string">AccountScoringHandler</value>
    </values>
    <values>
        <field>TriggerObject__c</field>
        <value xsi:type="xsd:string">TriggerObject.Account</value>
    </values>
    <values>
        <field>Bypass__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
```

The `TriggerObject__c` value is the parent record's full name, `TriggerObject.` followed by its developer name.

The other handlers of the object keep running, and the DML succeeds as usual.

### Bypassing a Whole Object

Check `Bypass__c` on the `TriggerObject__mdt` record. No handler of that object runs, in any context, and the DML succeeds. The check happens before the orchestrator is asked for its handler list, so nothing else is evaluated at all.

### Inner Class Names

Handlers are often inner classes of a larger class. Both spellings work in `ApexClassName__c`:

```
Outer.Inner
Inner
```

Matching is case-insensitive and surrounding whitespace is ignored, so `outer.inner` and ` Inner ` match too.

::: warning Simple names collide
The name the framework compares against at runtime is the handler's simple class name, which is why the bare `Inner` spelling works at all. The consequence is that **two inner classes sharing a simple name are bypassed together**, even when they live in different outer classes. `AccountRules.Scoring` and `ContactRules.Scoring` cannot be bypassed independently through metadata. Give them distinct names, or bypass one of them in code with `Bypassable`.
:::

### Query Cost

The metadata is read once per transaction, through a query on `TriggerObject__mdt` with its `TriggerHandler__mdt` children. Custom metadata queries do not count against the SOQL governor limit, so reading it costs **zero SOQL** no matter how many objects and handlers are configured. With no records at all, the read still costs nothing and changes nothing.

## Order of Checks

For each invocation:

1. The object bypass is checked. If `TriggerObject__mdt.Bypass__c` is true for the object, the invocation ends here.
2. The orchestrator returns its handler list for the context, and the handlers are validated. A before insert or before update class that implements neither or both of `Populator` and `Validator` is rejected with a `TriggerOrchestratorException` at this point, whether or not it is about to be bypassed.
3. Each handler is checked for a bypass. Metadata first: a handler bypassed in metadata never has its `bypassOn...When()` called. Otherwise, `Bypassable` decides.
4. [Parent enrichment](/guide/enrichment) runs for the surviving handlers only.
5. The surviving handlers run in list order.

A bypassed handler is out before enrichment, so it contributes no parent fields to the queries and never sees a record. If another handler was relying on a relationship that only the bypassed handler declared, `getNewRelated` starts returning `null` for it.

## Bypassing a Whole Context

An orchestrator can return an empty list for a context. Nothing runs and the DML succeeds.

```apex
public List<AfterInsert.Handler> afterInsertHandlers() {
    return new List<AfterInsert.Handler>();
}
```

Leaving the `TriggerOrchestrator.AfterInsert` interface off the orchestrator entirely has the same effect: the event is a silent no-op.

## Bypasses in Tests

Static flags make it easy to isolate a handler under test:

```apex
@IsTest
static void createsTaskWhenPriorityChanges() {
    AccountScoringHandler.isDisabled = true;

    // insert and update records, assert on the handler under test
}
```

Custom metadata records deployed to the org apply in tests as well, since they are visible without `@IsTest(SeeAllData=true)`. A handler switched off in metadata stays off in every test that exercises it.
