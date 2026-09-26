---
description: Install Trigger Lib in a Salesforce org - deploy via button, or copy the Apex classes and custom metadata types together with the SOQL Lib and DML Lib dependencies.
---

# Installation

<!--
 sf package version create --package "Trigger Lib" --target-dev-hub beyondthecloud-prod --installation-key-bypass --wait 30 --code-coverage

 sf package version promote --package "Trigger Lib@0.2.0-1"  --target-dev-hub beyondthecloud-prod
-->

## Install via Unlocked Package {#install-via-unlocked-package}

Install the Trigger Lib unlocked package with `btcdev` namespace to your Salesforce environment:

`/packaging/installPackage.apexp?p0=04tP6000003jhdNIAQ`

[Install on Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tP6000003jhdNIAQ)

[Install on Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tP6000003jhdNIAQ)

## Deploy via Button {#deploy-via-button}

Click the button below to deploy Trigger Lib to your environment.

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

::: warning
The button also deploys [SOQL Lib](https://soql.beyondthecloud.dev) 6.12.0 and [DML Lib](https://dml.beyondthecloud.dev) 4.0.0, replacing the org's `SOQL` and `DML` classes. If the org has the same or a newer version, use [Copy and Deploy](#copy-and-deploy) and skip them.
:::

## Copy and Deploy {#copy-and-deploy}

### Trigger Lib {#trigger-lib}

**Apex**

- [`TriggerOrchestrator.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/TriggerOrchestrator.cls)
- [`TriggerOrchestratorTest.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/TriggerOrchestratorTest.cls)
- [`TriggerTypes.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/TriggerTypes.cls)
- [`TriggerTypesTest.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/TriggerTypesTest.cls)
- [`BeforeInsert.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/BeforeInsert.cls)
- [`AfterInsert.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/AfterInsert.cls)
- [`BeforeUpdate.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/BeforeUpdate.cls)
- [`AfterUpdate.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/AfterUpdate.cls)
- [`BeforeDelete.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/BeforeDelete.cls)
- [`AfterDelete.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/AfterDelete.cls)
- [`AfterUndelete.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/classes/AfterUndelete.cls)

**Custom Metadata Types**

- [`TriggerObject__mdt`](https://github.com/beyond-the-cloud-dev/trigger-lib/tree/main/force-app/main/default/objects/TriggerObject__mdt)
- [`TriggerHandler__mdt`](https://github.com/beyond-the-cloud-dev/trigger-lib/tree/main/force-app/main/default/objects/TriggerHandler__mdt)

### SOQL Lib _(required)_ {#soql-lib}

**Apex**

- [`SOQL.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/dependencies/soql-lib/SOQL.cls)
- [`SOQL_Test.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/dependencies/soql-lib/SOQL_Test.cls)

### DML Lib _(required)_ {#dml-lib}

**Apex**

- [`DML.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/dependencies/dml-lib/DML.cls)
- [`DML_Test.cls`](https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/force-app/main/default/dependencies/dml-lib/DML_Test.cls)

::: tip
The button skips the examples. To add them to a scratch org or sandbox, run `sf project deploy start -d examples -o your-org-alias` in a clone of the repo.
:::
