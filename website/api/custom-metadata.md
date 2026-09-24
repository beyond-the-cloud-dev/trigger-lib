---
description: 'TriggerObject__mdt and TriggerHandler__mdt reference: switch off every handler on an object, or one handler class, org-wide without deploying code; fields, the ApexClassName__c format, when the records are read, and how to deploy them.'
---

# Custom Metadata

Two custom metadata types switch handlers off for the whole org, without code changes. Create the records in Setup under **Custom Metadata Types → Manage Records**, or deploy them.

## TriggerObject__mdt {#trigger-object}

One record per object.

| Field | Holds |
|---|---|
| `ObjectAPIName__c` | the object's API name, such as `Account` or `Invoice__c`; case does not matter |
| `Bypass__c` | checked: every handler on the object is off, in every context |

- **The whole run is skipped.** No handler, parent query or provider runs, and no Logger method is called.
- **Also the parent of handler records.** `TriggerHandler__mdt` records need it, even with `Bypass__c` unchecked.

## TriggerHandler__mdt {#trigger-handler}

One record per handler class to switch off on one object.

| Field | Holds |
|---|---|
| `TriggerObject__c` | the `TriggerObject__mdt` record of the object |
| `ApexClassName__c` | the handler's class name |
| `Bypass__c` | checked: this handler is off on that object |

- **In every context.** A class registered in before insert and before update is off in both. To switch off one context only, use that context's Bypassable add-on.
- **Only on that object.** A class used on Account and on Contact needs a record under each object.

### ApexClassName__c Format {#class-name-format}

The value is matched against the class name without its outer class. Case does not matter.

| Handler class | Values that match |
|---|---|
| top-level `AccountRatingPopulator` | `AccountRatingPopulator` |
| inner `AccountRules.RatingPopulator` | `RatingPopulator` or `AccountRules.RatingPopulator` |

- **A misspelled name** matches nothing, and nothing warns you.

## When They Are Read {#reading}

- **Once per transaction.** The first `run` or `bypass()` call reads all records with one query. Changes apply from the next transaction.
- **No SOQL limit cost.** Custom metadata queries do not count toward the limit.
- **Tests see the org's records.** Tests that run the orchestrator can [mock the query](/guide/testing#mock-metadata).

## Deploy Records {#deploy}

The file name is `<Type>.<DeveloperName>.md-meta.xml`, for example in `force-app/main/default/customMetadata/`.

**Example**

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

- **Declare `xmlns:xsd`.** Without it, the deployment fails with an `UNKNOWN_EXCEPTION` that names no component.
- **`TriggerObject__c` holds the DeveloperName alone,** such as `Account`, not `TriggerObject.Account`.
