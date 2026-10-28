---
description: 'TriggerObject__mdt and TriggerHandler__mdt reference: switch off every handler on an object, or one handler class in one context, org-wide without deploying code, and register the handlers of a runFromMetadata() trigger per context in Order__c order; fields, the ApexClassName__c format, when the records are read, and how to deploy them.'
---

# Custom Metadata

Two custom metadata types switch handlers off for the whole org, without code changes. For a trigger that calls [`runFromMetadata()`](/api/trigger-orchestrator#run-from-metadata), they also register its handlers. Create the records in Setup under **Custom Metadata Types → Manage Records**, or deploy them. In Setup, the Trigger Handler page layout groups the seven context fields in a **Contexts** section.

## TriggerObject__mdt {#trigger-object}

One record per object.

| Field | Holds |
|---|---|
| `ObjectAPIName__c` | the object's API name, such as `Account` or `Invoice__c`; case does not matter |
| `Bypass__c` | checked: every handler on the object is off, in every context |

- **The whole run is skipped.** No handler, parent query or provider runs, and no Logger method is called.
- **Also the parent of handler records.** Their context field names it, so create it even with `Bypass__c` unchecked.
- **Keep one record per object.** With several, only one applies, and the handler records that name the others are ignored.

## TriggerHandler__mdt {#trigger-handler}

One record is one handler class in one context on one object. It names the class and, in exactly one of the seven context fields, the object.

| Field | Holds |
|---|---|
| `ApexClassName__c` | the handler's class name |
| `BeforeInsert__c`, `AfterInsert__c`, `BeforeUpdate__c`, `AfterUpdate__c`, `BeforeDelete__c`, `AfterDelete__c`, `AfterUndelete__c` | exactly one of them: the `TriggerObject__mdt` record of the object, in the record's context; the other six stay blank |
| `Bypass__c` | checked: this class is off on that object, in that context |
| `Order__c` | required; the run order within the context under `runFromMetadata()`, lowest first, ties by class name |
| `Description__c` | free text for admins; the library never reads it |

- **Two roles.** Under `runFromMetadata()`, a record runs its class in its context, unless `Bypass__c` is checked. Under `run(orchestrator)`, it only switches its class off in that context, and `Order__c` is ignored, though it is still required. Deleting a record switches nothing off.
- **Exactly one context.** The validation rule `OneContextRequired` rejects a record with no context field filled, or with more than one, in Setup and in a deployment. A record with `BeforeInsert__c` filled neither runs nor switches off its class in after insert.
- **One record per context.** A class that runs in several contexts has a record for each, with its own `Order__c`. Name them `<ClassName>_<Context>`, such as `AccountRatingPopulator_BeforeInsert` and `AccountRatingPopulator_BeforeUpdate`. To switch the class off everywhere, check `Bypass__c` on each.
- **One object per record.** The context field names one object, so a class used on Account and on Contact needs a record for each.

### ApexClassName__c Format {#class-name-format}

For a bypass, the value is matched against the class name without its outer class. Case does not matter.

| Handler class | Values that match |
|---|---|
| top-level `AccountRatingPopulator` | `AccountRatingPopulator` |
| inner `AccountRules.RatingPopulator` | `RatingPopulator` or `AccountRules.RatingPopulator` |

- **`runFromMetadata()` needs the full name,** such as `AccountRules.RatingPopulator`, or `ns.AccountRatingPopulator` for a class in another namespace. It throws on a name it cannot find.
- **A misspelled name** in a bypass matches nothing, and nothing warns you.
- **Inner classes with the same name can clash.** `SalesRules.RatingPopulator` and `ServiceRules.RatingPopulator` share the bypass key `RatingPopulator`, so one record can switch off both.

## When They Are Read {#reading}

- **Once per transaction.** The first `run`, `runFromMetadata` or `bypass()` call runs two queries: one for the `TriggerObject__mdt` records, then one for the `TriggerHandler__mdt` records, ordered by `Order__c` and then `ApexClassName__c`. Each handler record is attached to the object record its context field names. Changes apply from the next transaction.
- **No SOQL limit cost.** Custom metadata queries do not count toward the limit.
- **Tests see the org's records.** Tests that run the orchestrator can [mock the queries](/guide/testing#mock-metadata).

## Deploy Records {#deploy}

The file name is `<Type>.<DeveloperName>.md-meta.xml`, for example in `force-app/main/default/customMetadata/`. A handler record is named `<ClassName>_<Context>`.

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

```xml [TriggerHandler.AccountRatingPopulator_BeforeInsert.md-meta.xml]
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>AccountRatingPopulator Before Insert</label>
    <protected>false</protected>
    <values>
        <field>ApexClassName__c</field>
        <value xsi:type="xsd:string">AccountRatingPopulator</value>
    </values>
    <values>
        <field>BeforeInsert__c</field>
        <value xsi:type="xsd:string">Account</value>
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

:::

- **Declare `xmlns:xsd`.** Without it, the deployment fails with an `UNKNOWN_EXCEPTION` that names no component.
- **The context field holds the DeveloperName alone,** such as `Account`, not `TriggerObject.Account`. Leave out the `<values>` blocks of the other six context fields. A second context is a second file, such as `TriggerHandler.AccountRatingPopulator_BeforeUpdate.md-meta.xml`.
- **`Order__c` is a required `xsd:double`.** A record without it fails to deploy.
