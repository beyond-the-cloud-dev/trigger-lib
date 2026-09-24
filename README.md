<div align="center">
  <a href="https://trigger.beyondthecloud.dev">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://trigger.beyondthecloud.dev/logo.png">
      <img alt="Trigger Lib logo" src="https://trigger.beyondthecloud.dev/logo.png" height="98">
    </picture>
  </a>
  <h1><a href="https://trigger.beyondthecloud.dev">Trigger Lib</a></h1>

<a href="https://beyondthecloud.dev"><img alt="Beyond The Cloud logo" src="https://img.shields.io/badge/MADE_BY_BEYOND_THE_CLOUD-555?style=for-the-badge"></a>

<img alt="API version" src="https://img.shields.io/badge/api-v67.0-blue?style=for-the-badge">
<a href="https://github.com/beyond-the-cloud-dev/trigger-lib/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-mit-green?style=for-the-badge"></a>
<img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/beyond-the-cloud-dev/trigger-lib?style=for-the-badge&logo=github&color=blue">
<img alt="GitHub Release" src="https://img.shields.io/github/v/release/beyond-the-cloud-dev/trigger-lib?display_name=tag&style=for-the-badge&color=blue">
<img alt="Codecov" src="https://img.shields.io/codecov/c/github/beyond-the-cloud-dev/trigger-lib?style=for-the-badge">
</div>

# Getting Started

The Trigger Lib provides an orchestrator and small role-based handlers for Apex triggers, with record qualification, declared parent queries, a unit of work, bypasses and recursion control.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of production-ready Salesforce libraries by [Beyond the Cloud](https://blog.beyondthecloud.dev/blog).

**Trigger**

```apex
trigger AccountTrigger on Account(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerOrchestrator.run(new AccountTriggerOrchestrator());
}
```

**Orchestrator**

```apex
public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{ new AccountRatingPopulator(), new AccountCustomerDataValidator() };
    }

    public List<AfterInsert.Handler> afterInsertHandlers() {
        return new List<AfterInsert.Handler>{ new AccountWelcomeTaskWriter() };
    }
}
```

## Populator

```apex
public with sharing class AccountRatingPopulator implements BeforeInsert.Populator {
    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isBlank(Account.Rating) && record.isNotNull(Account.AnnualRevenue);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        record.put(Account.Rating, record.greaterThanOrEqualTo(Account.AnnualRevenue, 5000000) ? 'Hot' : 'Warm');
    }
}
```

## Validator

```apex
public with sharing class AccountCustomerDataValidator implements BeforeInsert.Validator {
    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer') && record.isBlank(Account.Industry);
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        record.addError(Account.Industry, 'A customer account requires Industry.');
    }
}
```

## Writer

```apex
public with sharing class AccountWelcomeTaskWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.ContinueOnError {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.OwnerId => TriggerTypes.ParentFields.with(User.Name) };
    }

    public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer');
    }

    public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Account newAccount = (Account) record.getNewSObject();
        User owner = (User) record.getNewParent('Owner');

        unitOfWork.toInsert(new Task(WhatId = record.getId(), OwnerId = newAccount.OwnerId, Subject = 'Onboarding call - ' + newAccount.Name, Description = 'Assigned to ' + owner?.Name));
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
