---
outline: deep
---

# Related Records

Parents come from [enrichment](/guide/enrichment). Everything else a handler needs from the database comes from a **provider**: a small class with one query and one key.

The handler names the providers it wants. The framework runs each one once, before the first record is processed, and every predicate and action reads the result from memory.

## A Provider

Two methods. `query` receives the trigger records of the context and returns what it found. `keyOf` says how each returned record is looked up again.

```apex
public without sharing class AccountOpenOpportunitiesProvider implements BeforeUpdate.RecordsProvider {
  public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return [
      SELECT Id, Name, AccountId
      FROM Opportunity
      WHERE AccountId IN :records.getIds() AND IsClosed = FALSE
    ];
  }

  public String keyOf(SObject record) {
    return ((Opportunity) record).AccountId;
  }
}
```

No constructor and no fields. The collection it receives carries the Ids and values of the trigger records; see [Record Collections](/api/related-records#record-collections).

## A Handler Using It

Implement the context's `RelatedQuery`, name the provider, read it with `getRelated`.

```apex
public with sharing class AccountColdRatingValidator implements BeforeUpdate.Validator, BeforeUpdate.RelatedQuery {
  public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
    return new Map<String, BeforeUpdate.RecordsProvider>{
      'openOpportunities' => new AccountOpenOpportunitiesProvider()
    };
  }

  public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(
    TriggerHandler.UpdateRecord record
  ) {
    return record.isChangedTo(Account.Rating, 'Cold') &&
      !record.getRelated('openOpportunities')
        .getAllWhereKeyEquals(record.getId())
        .isEmpty();
  }

  public String beforeUpdateValidationMessage(
    TriggerHandler.UpdateRecord record
  ) {
    return 'This Account has open Opportunities and cannot be rated Cold.';
  }
}
```

One query for the whole invocation, whether one Account is updated or two hundred.

## Showcases

### Children Of The Record

Key by the child's lookup, read with the record's own Id.

```apex
public String keyOf(SObject record) {
  return ((Opportunity) record).AccountId;
}
```

```apex
List<SObject> children = record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId());
```

### Siblings, Excluding The Records Being Saved

Bind the lookup values, then exclude the trigger records so a record never finds itself.

```apex
public List<SObject> query(TriggerHandler.UpdateRecords records) {
  return [
    SELECT Id, Name, AccountId
    FROM Opportunity
    WHERE AccountId IN :records.getIdsOf(Opportunity.AccountId)
      AND Type = 'Renewal'
      AND IsClosed = FALSE
      AND Id NOT IN :records.getIds()
    ORDER BY CloseDate
  ];
}

public String keyOf(SObject record) {
  return ((Opportunity) record).AccountId;
}
```

```apex
Opportunity opportunity = (Opportunity) record.getNewSObject();
Opportunity existing = (Opportunity) record.getRelated('openRenewals').getFirstWhereKeyEquals(opportunity.AccountId);
```

`getFirstWhereKeyEquals` returns the first record in query order, so the `ORDER BY` decides which one.

### Matching On A Text Value

Key by the field, normalised the same way on both sides.

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
  return [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :records.getValuesOf(Contact.Email)];
}

public String keyOf(SObject record) {
  return ((Contact) record).Email?.toLowerCase();
}
```

```apex
Contact contact = (Contact) record.getNewSObject();
SObject duplicate = record.getRelated('contactsByEmail').getFirstWhereKeyEquals(contact.Email.toLowerCase());
```

### A Key Built From Two Fields

Put the key format in one static method so the provider and the handler build it the same way.

```apex
public with sharing class OpportunityProductLineItemsProvider implements BeforeInsert.RecordsProvider {
  public static String key(Id opportunityId, Id productId) {
    return opportunityId + '-' + productId;
  }

  public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [
      SELECT Id, OpportunityId, Product2Id
      FROM OpportunityLineItem
      WHERE
        OpportunityId IN :records.getIdsOf(OpportunityLineItem.OpportunityId)
    ];
  }

  public String keyOf(SObject record) {
    OpportunityLineItem lineItem = (OpportunityLineItem) record;

    return OpportunityProductLineItemsProvider.key(
      lineItem.OpportunityId,
      lineItem.Product2Id
    );
  }
}
```

```apex
OpportunityLineItem lineItem = (OpportunityLineItem) record.getNewSObject();
String key = OpportunityProductLineItemsProvider.key(lineItem.OpportunityId, lineItem.Product2Id);

Boolean isDuplicate = record.getRelated('existingLineItems').getFirstWhereKeyEquals(key) != null;
```

### Configuration With No Key To Look Up

Read the whole result with `getRecords`.

```apex
public with sharing class ActiveRegionMappingsProvider implements BeforeInsert.RecordsProvider {
  public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [
      SELECT Country_Code__c, Region__c
      FROM Region_Mapping__mdt
      WHERE Active__c = TRUE
    ];
  }

  public String keyOf(SObject record) {
    return ((Region_Mapping__mdt) record).Country_Code__c;
  }
}
```

```apex
SObject mapping = record.getRelated('regions').getFirstWhereKeyEquals(account.BillingCountry);
```

### A Second Query That Depends On The First

Both hops live in one `query`. Providers are never built from other providers.

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
  Set<Id> pricebookIds = new Set<Id>();

  for (Opportunity opportunity : [SELECT Pricebook2Id FROM Opportunity WHERE Id IN :records.getIdsOf(OpportunityLineItem.OpportunityId)]) {
    pricebookIds.add(opportunity.Pricebook2Id);
  }

  return [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id IN :pricebookIds];
}
```

### One Provider, Several Contexts

Implement each context's interface and overload `query`.

```apex
public without sharing class AccountOpenOpportunitiesProvider implements BeforeUpdate.RecordsProvider, BeforeDelete.RecordsProvider {
  public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return this.openOpportunitiesOf(records.getIds());
  }

  public List<SObject> query(TriggerHandler.DeleteRecords records) {
    return this.openOpportunitiesOf(records.getIds());
  }

  public String keyOf(SObject record) {
    return ((Opportunity) record).AccountId;
  }

  private List<SObject> openOpportunitiesOf(Set<Id> accountIds) {
    return [
      SELECT Id, Name, AccountId
      FROM Opportunity
      WHERE AccountId IN :accountIds AND IsClosed = FALSE
    ];
  }
}
```

## Sharing

Sharing is enforced by the class the query sits in, so the provider decides.

A provider that feeds a validator or a populator must see every record, exactly as enrichment does. Declare it `without sharing`. Otherwise a duplicate check passes whenever the conflicting record happens to be invisible to the running user.

Use `with sharing` only when the result is meant to depend on who is saving.

## When It Runs

For each handler, in order:

1. Bypassed handlers are skipped entirely, and never asked for providers.
2. Parents are enriched for the whole context.
3. `queryRelatedOn<Context>` is called once and returns the provider names.
4. Each provider's `query` runs, with a collection over **every** trigger record, including records a recursion guard will skip.
5. Predicates and actions run, reading providers from memory.
6. The finalizer runs, with the providers still readable.

Providers belong to the handler that declared them. The next handler starts with none, and asking for a name it did not declare throws a `TriggerHandlerException`.

The hook and the queries run inside the handler's own error handling, so a failed query is logged with the handler's name and follows its [`ContinueOnError`](/guide/error-handling) choice. In before insert and before update they also sit inside the [DML guard](/guide/handlers#no-dml-in-before-contexts).

A DML of more than 200 records reaches the trigger in chunks of 200, and each chunk queries once.

## Providers Or The Finalizer

Query in a provider when a predicate or an action needs the data.

Query in a [finalizer](/guide/finalizers) when the data only serves a bulk action on the records that qualified. The qualified set is known there and is usually smaller.

::: tip
Providers can use plain SOQL, as above, or the bundled [SOQL Lib](https://soql.beyondthecloud.dev). A provider written with SOQL Lib and a `mockId` can be mocked in tests, so a handler test needs no related data in the database.
:::
