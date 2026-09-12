---
outline: deep
---

# Installation

## Deploy via Button

Deploy Trigger Lib to your Salesforce org using the deploy button:

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Copy and Deploy

Clone the repository and deploy the `force-app` directory:

```bash
git clone https://github.com/beyond-the-cloud-dev/trigger-lib.git
cd trigger-lib
sf project deploy start -d force-app -o your-org-alias
```

The `examples` directory holds a reference orchestrator, handlers and a Contact trigger. It is a separate package directory and is not deployed with the library. Deploy it on its own when you want to try the framework:

```bash
sf project deploy start -d examples -o your-org-alias
```

## What Gets Deployed

**Framework**

- `TriggerOrchestrator` - entry point and execution engine
- `TriggerHandler` - the `InsertRecord`, `UpdateRecord`, `DeleteRecord` and `UndeleteRecord` APIs, the `FieldSelection` API, and `TriggerHandlerException`
- `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete`, `AfterUndelete` - per-context handler interfaces

**Custom metadata types**

- `TriggerObject__mdt` - one row per object, with `ObjectAPIName__c` and `Bypass__c`
- `TriggerHandler__mdt` - one row per handler class, with `ApexClassName__c`, `TriggerObject__c` and `Bypass__c`

No records of either type are required. With none present, every handler runs and no SOQL is consumed.

**Bundled dependency**

- `SOQL` from [SOQL Lib](https://soql.beyondthecloud.dev), used for parent record enrichment. It lives in `force-app/main/default/dependencies/soql-lib`.

::: warning SOQL Lib already in your org?
If your org already contains the `SOQL` class from SOQL Lib, skip the `dependencies/soql-lib` folder during deployment to avoid overwriting it. Trigger Lib only needs the `SOQL.of`, `with`, `byIds`, `systemMode`, `withoutSharing` and `toMap` methods.
:::

## Unlocked Package

An unlocked package with the `btcdev` namespace is not published yet. Use one of the deployment options above.
