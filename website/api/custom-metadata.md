---
description: 'TriggerObject__mdt and TriggerHandler__mdt reference: switch off every handler on an object, or one handler class, org-wide without deploying code; fields, the ApexClassName__c format, when the records are read, and how to deploy them.'
---

# Custom Metadata

Two custom metadata types switch Trigger Lib handlers off (bypass, disable) for the whole org without changing code: a `TriggerObject__mdt` record for every handler on one object, and a `TriggerHandler__mdt` record under it for one handler class. Create the records in Setup under **Custom Metadata Types → Manage Records**, or deploy them.

## TriggerObject__mdt {#trigger-object}

One record per object.

| Field | Type | Holds |
|---|---|---|
| `ObjectAPIName__c` | Text(255), required | the object's API name, such as `Account` or `Invoice__c`, with the namespace prefix for an object from a managed package; compared ignoring case and surrounding spaces |
| `Bypass__c` | Checkbox, default unchecked | checked: every handler on the object is switched off, in every context |

- **The whole run is skipped.** With `Bypass__c` checked, `run()` returns before it calls the orchestrator's handler method, so no handler, parent query or provider runs, and no Logger method is called.
- **Also the parent of handler records.** A `TriggerHandler__mdt` record applies only under the `TriggerObject__mdt` record of the object whose trigger is running. That object record may leave `Bypass__c` unchecked.
- **One record per object.** When two records name the same object, only one of them is used.

## TriggerHandler__mdt {#trigger-handler}

One record per handler class you want to switch off on one object.

| Field | Type | Holds |
|---|---|---|
| `TriggerObject__c` | Metadata Relationship to `TriggerObject__mdt`, required | the object record this handler record belongs to |
| `ApexClassName__c` | Text(255), required | the handler's class name; see the format below |
| `Bypass__c` | Checkbox, default unchecked | checked: this handler is switched off on that object |

- **In every context.** The record matches the class wherever it is registered for that object: a class that serves before insert and before update is switched off in both. To switch off one context only, use that context's Bypassable add-on, or leave the class out of that context's handler list.
- **Only on that object.** A class registered for Account and for Contact needs a handler record under each object record.
- **Checked per handler.** After `TriggerOrchestrator.bypass().handler(…)` and before the handler's own Bypassable method, which is not called when the record switches the handler off.

### ApexClassName__c Format {#class-name-format}

The value is compared with the handler's simple class name, the class name without its outer class, ignoring case and surrounding spaces.

| Handler class | Values that match |
|---|---|
| top-level `AccountRatingPopulator` | `AccountRatingPopulator` |
| inner `AccountRules.RatingPopulator` | `RatingPopulator` or `AccountRules.RatingPopulator` |

- **Dotted values match by their last segment.** `AccountRules.RatingPopulator` also registers as `RatingPopulator`, and a namespace prefix in front of the class name is dropped the same way.
- **Same simple name, same switch.** The inner classes `AccountRules.RatingPopulator` and `ContactRules.RatingPopulator` are both switched off by either value, on that object.
- **A class that overrides `toString()`** is named by the text before the first `:` of what it returns.
- **A misspelled name** matches nothing, and nothing warns you.

## When They Are Read {#reading}

- **Once per transaction.** The first call to `TriggerOrchestrator.run` or `TriggerOrchestrator.bypass()` in a transaction reads every record with one query, in system mode. Every later run in the transaction uses what it read.
- **No SOQL against the limit.** Queries on custom metadata do not count toward the SOQL query limit.
- **Changes apply from the next transaction.** A record edited or deployed during a long transaction, such as a batch `execute`, does not change the runs of that transaction.
- **Unit tests see deployed records.** The records in the org also apply when tests run. Tests that run the orchestrator mock the query instead: [Testing](/guide/testing#mock-metadata).

## Deploy Records {#deploy}

Records are metadata, so they can live in source next to your code, for example in `force-app/main/default/customMetadata/`. The file name is `<Type>.<DeveloperName>.md-meta.xml`.

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

```xml [TriggerHandler.AccountRatingPopulator.md-meta.xml]
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
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
```

:::

- **Declare `xmlns:xsd`.** Without it on `<CustomMetadata>`, the deployment fails with an `UNKNOWN_EXCEPTION` that names no component.
- **The relationship value is the DeveloperName alone.** `TriggerObject__c` holds `Account`, the DeveloperName of the object record, not `TriggerObject.Account`.
- **Deploying `Bypass__c = true`** switches the handler off in that org as soon as the deployment finishes. Keep such records out of the packages you deploy to production unless that is the intent.

## See Also {#see-also}

- [Bypassing](/guide/bypasses): every switch in the order the library checks them, and the [data migration recipe](/guide/bypasses#data-migration)
- [`TriggerOrchestrator.bypass()`](/api/trigger-orchestrator#bypass): switches from Apex for one transaction

Bypassable, the switch a handler implements itself, in each context:

<!--@include: @/_parts/generated/chips/bypassable.md-->
