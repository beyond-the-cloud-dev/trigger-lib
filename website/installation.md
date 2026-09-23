---
description: Deploy Trigger Lib and its bundled SOQL Lib and DML Lib dependencies to a Salesforce org, and optionally the example triggers and handlers.
---

# Installation

Trigger Lib is Apex source that you deploy into your org: the library classes, two custom metadata types, and the two libraries it depends on, SOQL Lib and DML Lib, which ship in the same folder. The project's source API version is 67.0; the bundled DML Lib classes (`DML`, `DML_Test`) are saved at API 66.0.

## Deploy via Button {#deploy-button}

Deploy Trigger Lib to your Salesforce org using the deploy button:

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Deploy with the Salesforce CLI {#deploy-cli}

Clone the repository and deploy the `force-app` directory:

```bash
git clone https://github.com/beyond-the-cloud-dev/trigger-lib.git
cd trigger-lib
sf project deploy start -d force-app -o your-org-alias
```

## What Gets Deployed {#what-gets-deployed}

**Library classes**, in `force-app/main/default/classes`:

- `TriggerOrchestrator`: `run(…)` for the trigger body, `bypass()`, the seven registration interfaces, and the `Logger` and `Error` interfaces.
- `TriggerHandler`: the record types your handlers receive (`InsertRecord`, `UpdateRecord`, `DeleteRecord`, `UndeleteRecord`, `RejectableInsertRecord`, `RejectableUpdateRecord`), the record collections, `ParentFields`, `RelatedRecords`, `UnitOfWork`, `RandomIdGenerator` and `TriggerHandlerException`.
- `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete`, `AfterUndelete`: the role and add-on interfaces of each context.
- `TriggerOrchestratorTest` and `TriggerHandlerTest`.

**Custom metadata types**, to switch objects or handlers off without a deploy:

- `TriggerObject__mdt`: one record per object, with `ObjectAPIName__c` and `Bypass__c`.
- `TriggerHandler__mdt`: one record per handler class, with `ApexClassName__c`, `TriggerObject__c` (the object's `TriggerObject__mdt` record) and `Bypass__c`.

No records of either type are required: with none, every handler runs. The records are read once per transaction and cost no SOQL against the limit. See [Custom Metadata](/api/custom-metadata).

**Bundled dependencies**, in `force-app/main/default/dependencies`. Both are required, and each comes with its test class:

| Folder | Class | Version | Trigger Lib uses it for |
|---|---|---|---|
| `soql-lib` | `SOQL` ([SOQL Lib](https://soql.beyondthecloud.dev)) | 6.11.0 | the parent queries, the custom metadata read, and finding the org's `TriggerOrchestrator.Logger` |
| `dml-lib` | `DML` ([DML Lib](https://github.com/beyond-the-cloud-dev/dml-lib)) | 3.2.0 | the unit of work behind every Writer; `DML.Committable`, which OwnUnitOfWork returns; `DML.Record` for linking a new child to a new parent |

::: warning SOQL Lib or DML Lib already in your org?
Deploying `force-app` replaces the org's `SOQL` and `DML` classes with the bundled versions. If your org already has the same or a newer version, leave the matching `dependencies` folder out of the deployment. An older version may lack methods Trigger Lib calls:

- **SOQL Lib:** `SOQL.of`, `with` (fields and `SOQL.SubQuery`), `whereAre` with `SOQL.Filter`, `byIds`, `setLimit`, `systemMode`, `withoutSharing`, `mockId`, `toList` and `toMap`.
- **DML Lib:** `DML.Committable`, `DML.Record`, `combineOnDuplicate`, `systemMode`, `withoutSharing`, `identifier`, `toInsert`, `toUpdate`, `toUpsert`, `toDelete`, `toPublish` and `commitWork`.
:::

## Visibility and Namespace {#visibility}

- **Every Trigger Lib class is `public`.** None is `global`, and none is `@NamespaceAccessible`. The bundled `SOQL` and `DML` classes are `public` too, with `@NamespaceAccessible` members, and nothing in them is `global`.
- **Namespace `btcdev`.** The repository's `sfdx-project.json` declares the namespace `btcdev`, so scratch orgs created from the repository use it.
- **Supported distribution: source deployment.** Deploy the source into your own org, where your triggers and handlers call the classes directly, without a namespace prefix. No package is published. Because nothing is `global`, a namespaced package built from this source would not expose the classes to code outside the `btcdev` namespace.

## Examples {#examples}

The `examples` directory is a second package directory. It is not deployed with `force-app`:

```text
examples/main/default/
  triggers/          AccountTrigger, ContactTrigger, OpportunityTrigger
  classes/
    account/         AccountTriggerOrchestrator
      before-insert/   populator/  validator/
      before-update/   populator/  validator/
      after-insert/    writer/
      after-update/    writer/
    contact/         ContactTriggerOrchestrator
      before-insert/  before-update/  after-insert/
    opportunity/     OpportunityTriggerOrchestrator
      before-insert/  before-update/  after-update/
```

Handlers sit under `<object>/<context>/<role>/`, for example `contact/before-insert/populator/ContactEmailNormalizationPopulator.cls`. There are 3 orchestrators and 38 handlers: Populators and Validators for before insert and before update, and Writers for after insert and after update.

Deploy them after the library, to a scratch org or sandbox, because they add triggers to Account, Contact and Opportunity that run on every save of those objects:

```bash
sf project deploy start -d examples -o your-org-alias
```

## Next Steps {#next-steps}

- [Your First Handler](/guide/first-handler): a trigger, an orchestrator, a Populator, a Validator and their tests.
- [Trigger & Orchestrator](/guide/orchestrator): how the trigger and the orchestrator are wired.
