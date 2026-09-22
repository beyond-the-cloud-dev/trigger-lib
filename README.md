<div align="center">
  <a href="https://trigger.beyondthecloud.dev">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://trigger.beyondthecloud.dev/logo.png">
      <img alt="Trigger Lib logo" src="https://trigger.beyondthecloud.dev/logo.png" height="98">
    </picture>
  </a>
  <h1>Trigger Lib</h1>

<a href="https://beyondthecloud.dev"><img alt="Beyond The Cloud logo" src="https://img.shields.io/badge/MADE_BY_BEYOND_THE_CLOUD-555?style=for-the-badge"></a>

<img alt="API version" src="https://img.shields.io/badge/api-v67.0-blue?style=for-the-badge">
<a href="https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-mit-green?style=for-the-badge"></a>
<img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/beyond-the-cloud-dev/trigger-lib?style=for-the-badge&logo=github&color=blue">
<img alt="GitHub Release" src="https://img.shields.io/github/v/release/beyond-the-cloud-dev/trigger-lib?display_name=tag&style=for-the-badge&color=blue">
<img alt="Codecov" src="https://img.shields.io/codecov/c/github/beyond-the-cloud-dev/trigger-lib?style=for-the-badge">
</div>

# Getting Started

The Trigger Lib provides an orchestrator and per-record handlers for Apex triggers, with record qualification, parent enrichment, bypasses and recursion control.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of production-ready Salesforce libraries by [Beyond the Cloud](https://blog.beyondthecloud.dev/blog).

**Trigger**

```apex
trigger ContactTrigger on Contact(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerOrchestrator.run(new ContactTriggerOrchestrator());
}
```

**Orchestrator**

```apex
public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{ new ContactMailingCountryPopulator() };
    }

    public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
        return new List<BeforeUpdate.Handler>{ new ContactEmailValidator() };
    }

    public List<AfterUpdate.Handler> afterUpdateHandlers() {
        return new List<AfterUpdate.Handler>{ new ContactAccountSyncHandler() };
    }
}
```

## Populator

```apex
public with sharing class ContactMailingCountryPopulator implements BeforeInsert.Populator {
    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isBlank(Contact.MailingCountry);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        record.put(Contact.MailingCountry, 'Poland');
    }
}
```

## Validator

```apex
public with sharing class ContactEmailValidator implements BeforeUpdate.Validator {
    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Contact.Email, null);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        return 'Email cannot be removed.';
    }
}
```

## Handler

```apex
public with sharing class ContactAccountSyncHandler implements AfterUpdate.Handler, AfterUpdate.ParentQuery, AfterUpdate.Finalizer {
    private List<Account> accountsToUpdate = new List<Account>();

    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Contact.Email) && record.isNotNull(Contact.AccountId);
    }

    public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
        Account account = (Account) record.getNewRelated('Account');

        this.accountsToUpdate.add(new Account(Id = account.Id, Description = account.Name + ': contact email changed'));
    }

    public void finalizeAfterUpdate() {
        update this.accountsToUpdate;
    }
}
```

## Deploy to Salesforce

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Documentation

Visit the [documentation](https://trigger.beyondthecloud.dev) to view the full documentation.

## Features

Read about the features in the [introduction](https://trigger.beyondthecloud.dev/introduction).

## Contributors

<a href="https://github.com/beyond-the-cloud-dev/trigger-lib/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=beyond-the-cloud-dev/trigger-lib" />
</a>

## License notes

- For proper license management each repository should contain LICENSE file similar to this one.
- Each original class should contain copyright mark: Copyright (c) 2026 Beyond The Cloud Sp. z o.o. (BeyondTheCloud.Dev)
