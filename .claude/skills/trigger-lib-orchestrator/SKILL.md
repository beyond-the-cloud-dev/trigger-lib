---
name: trigger-lib-orchestrator
description: Wiring Apex triggers to Trigger Lib, the one-line trigger per object and the <Object>TriggerOrchestrator that lists each context's handlers in run order. Also covers TriggerOrchestrator.runFromMetadata() with TriggerObject__mdt and TriggerHandler__mdt records, bypasses and the TriggerOrchestrator.Logger. Use when creating or changing an Apex trigger, registering, ordering or removing handlers, switching trigger logic off for a data load, a batch, a test or a user, letting admins disable a handler without a deployment, logging handler errors, or moving logic out of an existing trigger or another trigger framework, in a project that uses Trigger Lib (TriggerOrchestrator), from source or as the btcdev package. Not for the logic inside a handler (use trigger-lib-handler) or for test classes (use trigger-lib-testing).
---

# Trigger Lib: Trigger, Orchestrator and Bypasses

Each object has one trigger whose body is one line. The trigger passes an orchestrator to `TriggerOrchestrator.run(...)`, and the orchestrator returns each context's handlers in run order. Alternatively, the trigger calls `TriggerOrchestrator.runFromMetadata()` and takes its handlers from custom metadata records.

## Rules

1. One trigger per object. It lists all seven events (a trigger on a platform event or change event takes only `after insert`), and its body is only the `run(...)` or `runFromMetadata()` call. Salesforce doesn't guarantee the order of several triggers on one object, and code next to `run(...)` ignores bypasses and never reaches the Logger.
2. The orchestrator implements one registration interface per context it uses and returns `new` handler instances in run order. Return an empty list, never `null`, which fails the save.
3. List only classes that implement a role (Populator, Validator, Writer or Dispatcher). List Populators before Validators, so that the Validators check the final values.
4. `TriggerOrchestrator.run(...)` works only inside a trigger and throws anywhere else. Tests run handlers with `TriggerOrchestrator.runTestFor(...)` (see the `trigger-lib-testing` skill).
5. Switch logic off with a bypass, never by commenting out a handler or adding flags to the trigger.
6. If Trigger Lib is installed as the `btcdev` package (existing code calls `btcdev.TriggerOrchestrator`, or `sfdx-project.json` or `sf package installed list` shows the Trigger Lib package), prefix the library types (`btcdev.TriggerOrchestrator`, `btcdev.BeforeInsert.Handler`) and the custom metadata: `btcdev__TriggerObject__mdt`, `btcdev__TriggerHandler__mdt`, and fields such as `btcdev__Bypass__c`.

## Before writing

1. Look for triggers that already exist on the object. If one isn't on Trigger Lib, move its logic into handlers (see [Moving an existing trigger](#moving-an-existing-trigger)) and replace its body. Don't add a second trigger.
2. Follow the project's names and folders for triggers, orchestrators and handlers. The usual names are `<Object>Trigger` and `<Object>TriggerOrchestrator`.

## Trigger

```apex
trigger OpportunityTrigger on Opportunity(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerOrchestrator.run(new OpportunityTriggerOrchestrator());
}
```

List all seven events even when the orchestrator uses fewer; a trigger on a platform event or change event takes only `after insert`. A context the orchestrator doesn't implement does nothing, so handlers can be added later without touching the trigger. Create the `.trigger-meta.xml` next to it with the project's API version and `<status>Active</status>`.

A production deployment fails while a trigger has no test coverage, and the mocked handler tests never fire it. Give every new trigger at least one test that saves a record of its object with DML (see `trigger-lib-testing`).

## Orchestrator

```apex
public with sharing class OpportunityTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{ new OpportunityCloseDatePopulator(), new OpportunityAmountValidator() };
    }

    public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
        return new List<BeforeUpdate.Handler>{ new OpportunityAmountValidator() };
    }

    public List<AfterUpdate.Handler> afterUpdateHandlers() {
        return new List<AfterUpdate.Handler>{ new OpportunityWinTaskWriter() };
    }
}
```

| Context | Registration interface | Method |
|---|---|---|
| before insert | `TriggerOrchestrator.BeforeInsert` | `List<BeforeInsert.Handler> beforeInsertHandlers()` |
| after insert | `TriggerOrchestrator.AfterInsert` | `List<AfterInsert.Handler> afterInsertHandlers()` |
| before update | `TriggerOrchestrator.BeforeUpdate` | `List<BeforeUpdate.Handler> beforeUpdateHandlers()` |
| after update | `TriggerOrchestrator.AfterUpdate` | `List<AfterUpdate.Handler> afterUpdateHandlers()` |
| before delete | `TriggerOrchestrator.BeforeDelete` | `List<BeforeDelete.Handler> beforeDeleteHandlers()` |
| after delete | `TriggerOrchestrator.AfterDelete` | `List<AfterDelete.Handler> afterDeleteHandlers()` |
| after undelete | `TriggerOrchestrator.AfterUndelete` | `List<AfterUndelete.Handler> afterUndeleteHandlers()` |

- `TriggerOrchestrator.BeforeInsert` is the registration interface. `BeforeInsert` on its own holds the handler interfaces.
- A class that implements several contexts, such as `BeforeInsert.Validator` and `BeforeUpdate.Validator`, goes into each context's list.
- A class that implements two roles of one context runs only as the first: Populator over Validator, Validator over Writer, Writer over Dispatcher. A class that implements only `<Ctx>.Handler` never runs.
- The handler methods run on every run: per context, per chunk and per nested save. Inserts and updates arrive in chunks of up to 200 records, while an Apex `delete` or `undelete` can deliver all its rows in one run. Handlers created there start with empty instance fields each time. Constructor arguments are allowed, but keep SOQL out of constructors.

## Handler order

- List order is run order, whatever the role. Each handler finishes all records of the chunk before the next one starts, and its predicate sees what earlier handlers set with `put`.
- The Writers' DML on the shared unit of work commits once, after the last handler, so later handlers never see it. A Writer with OwnUnitOfWork or ContinueOnError commits right after itself.
- In the update contexts, a Populator, Writer or Dispatcher acts on the same record at most 3 times per transaction by default, and later passes skip the record without an error. A handler's RecursionGuard add-on changes its limit.

## Handlers in custom metadata

Use `runFromMetadata()` when the trigger's package can't compile against every handler, for example when handlers live in packages that depend on a core package. There is no orchestrator class:

```apex
trigger AccountTrigger on Account(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerOrchestrator.runFromMetadata();
}
```

Deploy one `TriggerObject__mdt` record for the object and one `TriggerHandler__mdt` record per handler class, in `customMetadata/<Type>.<DeveloperName>.md-meta.xml`:

```xml
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

That is `TriggerObject.Account.md-meta.xml`. Next to it, `TriggerHandler.AccountRatingPopulator.md-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>AccountRatingPopulator</label>
    <protected>false</protected>
    <values>
        <field>TriggerObject__c</field>
        <value xsi:type="xsd:string">Account</value>
    </values>
    <values>
        <field>ApexClassName__c</field>
        <value xsi:type="xsd:string">AccountRatingPopulator</value>
    </values>
    <values>
        <field>Bypass__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Order__c</field>
        <value xsi:type="xsd:double">10</value>
    </values>
</CustomMetadata>
```

- Declare `xmlns:xsd`. Without it, the deployment fails with an `UNKNOWN_EXCEPTION` that names no component.
- `TriggerObject__c` holds the `TriggerObject__mdt` record's DeveloperName alone, such as `Account`, not `TriggerObject.Account`.
- `ObjectAPIName__c` is the object's API name, such as `Account` or `Invoice__c`. Keep one `TriggerObject__mdt` record per object: with several, only one is read.
- `Order__c` is an `xsd:double`. The lowest runs first, a blank order runs last (leave its `<values>` block out), and ties run in class name order.
- `ApexClassName__c` holds the full class name: `AccountRules.RatingPopulator` for an inner class, or `ns.AccountRatingPopulator` for a class in another namespace.
- A record's DeveloperName, the part of the file name after the type, holds at most 40 characters: letters, digits and single underscores, starting with a letter. Shorten it when the class name is longer, and keep the full name in `ApexClassName__c`.
- The class needs a public no-argument constructor. The library creates every registered class in every context of the object and runs it in each context whose role it implements, so keep the constructor cheap.
- A record whose class can't be found or created, or that implements no handler interface, fails every save on the object with a `TriggerTypes.TriggerLibException`. Add a registration test with the `trigger-lib-testing` skill.
- With the `btcdev` package, the type and field names carry the prefix and the values don't: the files are `btcdev__TriggerObject.Account.md-meta.xml` and `btcdev__TriggerHandler.AccountRatingPopulator.md-meta.xml`, each field is written like `<field>btcdev__Bypass__c</field>`, and `btcdev__TriggerObject__c` and `btcdev__ApexClassName__c` hold `Account` and `AccountRatingPopulator` as above.

## Bypasses

| You need to | Use |
|---|---|
| Skip handlers in one transaction from Apex, such as a data fix, a batch or test setup | `TriggerOrchestrator.bypass()` with `sObject(...)`, `handler(...)`, `orchestrator(...)` or `all()`, and `clear()` in `finally` |
| Let admins switch an object or one handler off for the whole org without a deployment | `Bypass__c` on the object's `TriggerObject__mdt` record, which switches off every handler on the object, or on a `TriggerHandler__mdt` record under it, which switches off one class |
| Skip one handler in one context on a condition that doesn't depend on the records, such as a feature flag, `System.isBatch()` or a custom permission | The context's Bypassable add-on, `bypassOn<Ctx>When()` (see `trigger-lib-handler`) |
| Skip some records | Return false from the handler's predicate |
| Skip handlers for some users | There is no built-in per-user bypass. Check a custom permission in `bypassOn<Ctx>When()`, or return an empty list from `<ctx>Handlers()` under the same check |

```apex
TriggerOrchestrator.bypass().sObject(Contact.SObjectType).handler(AccountOwnerTransferWriter.class);
try {
    update accounts;
} finally {
    TriggerOrchestrator.bypass().clear();
}
```

- An Apex bypass lasts until `clear()` or the end of the transaction, nested saves included. `clear()` removes every bypass, also those a caller set, so call it only in the code that set the bypass. A Queueable, a future method or the next batch `execute` starts without it.
- `handler(X.class)` and `orchestrator(X.class)` never match an inner class. For an inner handler, use a `TriggerHandler__mdt` record or the Bypassable add-on. `orchestrator(...)` has no effect under `runFromMetadata()`.
- To give admins a switch for one handler, deploy its `TriggerHandler__mdt` record with `Bypass__c` unchecked, together with the object's `TriggerObject__mdt` record. The object's record alone switches off every handler on the object, which suits a data load.
- An admin flips the switch in Setup: Custom Metadata Types, then Manage Records next to Trigger Handler (or Trigger Object), then Edit on the record, then the Bypass checkbox. Metadata is read once per transaction, so the change applies from the next transaction.
- A `TriggerHandler__mdt` record needs its object's `TriggerObject__mdt` record, even with `Bypass__c` unchecked. A record covers every context of its object; to skip one context only, use that context's Bypassable. A class used on two objects needs a record under each.
- Under `run(orchestrator)`, a `TriggerHandler__mdt` record only switches its class off, and `Order__c` is ignored. Deleting the record doesn't switch the class off.
- A deployment that includes the records sets `Bypass__c` back to the deployed value. Once admins flip switches in production, leave the records out of later deployments or keep the files in step with production. To ship a handler switched off, deploy its record checked and uncheck it when it should go live.
- A bypass skips only Trigger Lib handlers. Flows, validation rules and other triggers still run.

For a data load through Data Loader, the Bulk API or an import wizard:

1. Check `Bypass__c` on the object's `TriggerObject__mdt` record, and create the record if it's missing.
2. Run the load.
3. Uncheck `Bypass__c`.
4. Backfill what the handlers would have done. Nothing runs them later.

The bypass affects every user while it's on.

## Logger

Implement `TriggerOrchestrator.Logger` in exactly one class. The library finds it, so nothing is registered. This one publishes a Publish Immediately platform event of your own, so the log survives a failed save:

```apex
public with sharing class TriggerErrorLogger implements TriggerOrchestrator.Logger {
    private List<TriggerError__e> events = new List<TriggerError__e>();

    public void log(TriggerOrchestrator.Error error) {
        this.events.add(
            new TriggerError__e(
                Handler__c = error.getHandlerName(),
                Operation__c = String.valueOf(error.getOperation()),
                Object__c = String.valueOf(error.getSObjectType()),
                RecordIds__c = String.join(new List<Id>(error.getRecordIds()), ','),
                Message__c = error.getException().getMessage(),
                StackTrace__c = error.getException().getStackTraceString()
            )
        );
    }

    public void flush() {
        if (this.events.isEmpty()) {
            return;
        }

        EventBus.publish(this.events);
        this.events.clear();
    }
}
```

- `log(error)` runs for every exception in a handler's turn, before the library rethrows it or ContinueOnError swallows it. `flush()` runs at the end of each outermost run, also when the run failed, so clear your buffer there.
- With two Logger classes in the org, every Trigger Lib trigger throws. Never throw from a Logger: its exception replaces the handler's and fails the save.
- ContinueOnError never swallows a `TriggerTypes.TriggerLibException` or an `EventBus.RetryableException`, which asks for redelivery of a platform event.
- Not logged, and never swallowed by ContinueOnError: exceptions in `<ctx>Handlers()`, in creating `runFromMetadata()` classes, in `bypassOn<Ctx>When()`, `ownUnitOfWorkOn<Ctx>()` and `maxRunsPerRecordOn<Ctx>()`, in the ParentQuery and PriorParentQuery methods, and in the shared unit of work's commit.
- `System.LimitException` can't be caught, so neither `log()` nor `flush()` runs for it.

## Moving an existing trigger

Move one concern at a time into its own handler and keep the old execution order.

| Old code | Trigger Lib |
|---|---|
| `if (Trigger.isBefore && Trigger.isInsert)` with a loop that sets fields on `Trigger.new` | BeforeInsert.Populator: the `if` inside the loop goes into the predicate, the assignment becomes `record.put(...)` |
| `record.addError(...)` in a before trigger loop | Validator in the same context |
| `insert`, `update` or `delete` of other records in an after trigger | Writer that registers on the unit of work |
| `@future`, `System.enqueueJob`, callouts or email | Dispatcher, enqueueing a Queueable for callouts |
| A `Map<Id, Account>` queried before the loop to read parent fields | ParentQuery, or PriorParentQuery in the delete contexts |
| Children or siblings queried before the loop | RelatedQuery |
| `Trigger.oldMap.get(r.Id).Status__c != r.Status__c` | `record.isChanged(Case.Status__c)` |
| `static Boolean firstRun` or another recursion flag | A change gate in the predicate, or RecursionGuard in the update contexts |
| A handler class from another framework (`TriggerHandler`, `fflib_SObjectDomain`, Trigger Actions) | One handler per concern, registered in the orchestrator |
| A framework's bypass call or a "disable triggers" custom setting | `TriggerOrchestrator.bypass()`, `Bypass__c`, or a Bypassable that reads the setting |

Then replace the trigger's body with the `run(...)` line, remove or deactivate the object's other triggers in the same deployment, and test each handler with the `trigger-lib-testing` skill. Keep one test that saves records with DML, to compare the behaviour with the old trigger's.

## Common mistakes

| Mistake | Fix |
|---|---|
| The trigger lists only the events in use | List all seven, or only `after insert` on a platform event or change event |
| Logic, `if` or `Trigger.isInsert` next to `run(...)` | Move it into handlers |
| A second trigger on the object | Merge it into the Trigger Lib trigger |
| `<ctx>Handlers()` returns `null` | `return new List<BeforeInsert.Handler>();` |
| A Validator listed before the Populator whose value it checks | Populators first |
| `bypass()` without `clear()` in a `finally` block | Wrap the DML in `try` / `finally` |
| `bypass().handler(...)` with an inner class | A top-level class, or a `TriggerHandler__mdt` record |
| Custom metadata XML without `xmlns:xsd` | Copy the header above |
| `TriggerObject__c` set to `TriggerObject.Account` | The DeveloperName alone: `Account` |
| A second class implementing `TriggerOrchestrator.Logger` | Keep exactly one |
| A metadata handler with constructor arguments | A public no-argument constructor |
