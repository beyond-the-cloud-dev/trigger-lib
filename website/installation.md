---
description: Deploy Trigger Lib and its bundled SOQL Lib and DML Lib dependencies to a Salesforce org, and optionally the example triggers and handlers.
---

# Installation

Trigger Lib is Apex source that you deploy to your org. It ships with its two dependencies, SOQL Lib and DML Lib.

## Deploy via Button {#deploy-button}

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Deploy with the Salesforce CLI {#deploy-cli}

```bash
git clone https://github.com/beyond-the-cloud-dev/trigger-lib.git
cd trigger-lib
sf project deploy start -d force-app -o your-org-alias
```

## What Gets Deployed {#what-gets-deployed}

- **Library classes:** `TriggerOrchestrator`, `TriggerHandler`, one class per context (`BeforeInsert`, `AfterUpdate` and the others) and their tests.
- **Custom metadata types:** `TriggerObject__mdt` and `TriggerHandler__mdt`. They switch an object or a handler off without a deploy. No records are required. See [Custom Metadata](/api/custom-metadata).
- **Dependencies** in `force-app/main/default/dependencies`: [SOQL Lib](https://soql.beyondthecloud.dev) 6.11.0 and [DML Lib](https://github.com/beyond-the-cloud-dev/dml-lib) 3.2.0. Both are required.

::: warning SOQL Lib or DML Lib already in your org?
Deploying `force-app` replaces the org's `SOQL` and `DML` classes. If your org already has the same or a newer version, leave that `dependencies` folder out.
:::

## Visibility {#visibility}

Every Trigger Lib class is `public`, and none is `global`. Deploy the source into your own org. No package is published.

## Examples {#examples}

The `examples` folder holds 3 orchestrators and 38 handlers for Account, Contact and Opportunity. It is not part of `force-app`. Deploy it only to a scratch org or sandbox, because its triggers run on every save of those objects:

```bash
sf project deploy start -d examples -o your-org-alias
```
