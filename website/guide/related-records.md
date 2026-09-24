---
description: RelatedQuery recipes for Trigger Lib - RecordsProvider classes that load children, siblings, records under the previous parent, text and composite keys, configuration, a declared parent's field and the trigger records' own formula fields, once per handler per run.
---

# RelatedQuery Recipes

A RelatedQuery provider loads children, siblings or any other records with one query per handler per run, and every predicate, action and Finalizer reads them from memory. For parents, use a ParentQuery instead.

## A Complete Example {#example}

A provider has two methods. `query(records)` returns rows, and `keyOf(row)` returns the key each row is stored under. The handler returns its providers by name and reads them with `record.getRelated('<name>')`:

::: code-group

```apex [Validator]
public with sharing class AccountColdRatingValidator implements BeforeUpdate.Validator, BeforeUpdate.RelatedQuery {
    public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
        return new Map<String, BeforeUpdate.RecordsProvider>{ 'openOpportunities' => new OpenOpportunities() };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Account.Rating, 'Cold') && !record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId()).isEmpty();
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        record.addError(Account.Rating, 'This account has open opportunities and cannot be rated Cold.');
    }

    private without sharing class OpenOpportunities implements BeforeUpdate.RecordsProvider {
        public List<SObject> query(TriggerHandler.UpdateRecords records) {
            return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
        }

        public String keyOf(SObject row) {
            return ((Opportunity) row).AccountId;
        }
    }
}
```

<<< @/../examples/main/default/classes/account/after-update/writer/AccountAddressCascadeWriter.cls [Writer]

:::

## Recipes {#recipes}

### Siblings {#siblings}

Other records under the same parent. Exclude the trigger records, so a record never finds itself:

```apex
public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return [
        SELECT Id, AccountId, CloseDate
        FROM Opportunity
        WHERE AccountId IN :records.getIdsOf(Opportunity.AccountId) AND Id NOT IN :records.getIds() AND IsClosed = FALSE
        ORDER BY CloseDate
    ];
}

public String keyOf(SObject row) {
    return ((Opportunity) row).AccountId;
}
```

The `ORDER BY` decides which row `getFirstWhereKeyEquals` returns.

### Records Under the Previous Parent {#previous-parent}

In the update contexts, `getOldIdsOf` reads the lookup values from before the save:

```apex
public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return [SELECT Id, AccountId FROM Contact WHERE AccountId IN :records.getOldIdsOf(Contact.AccountId) AND Id NOT IN :records.getIds()];
}
```

### Matching on a Text Value {#text-key}

Keys match exactly, case included. Normalize both sides the same way:

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [SELECT Id, Email FROM Contact WHERE Email IN :records.getValuesOf(Contact.Email)];
}

public String keyOf(SObject row) {
    return ((Contact) row).Email?.toLowerCase();
}
```

```apex
String email = ((Contact) record.getNewSObject()).Email;
Boolean isDuplicate = email != null && record.getRelated('sameEmail').getFirstWhereKeyEquals(email.toLowerCase()) != null;
```

### A Key Built From Two Fields {#composite-key}

Build the key in one static method, so the provider and the handler agree:

```apex
public static String key(Id opportunityId, Id productId) {
    return opportunityId + '|' + productId;
}

public String keyOf(SObject row) {
    OpportunityLineItem lineItem = (OpportunityLineItem) row;

    return OpportunityLineItemsProvider.key(lineItem.OpportunityId, lineItem.Product2Id);
}
```

### Configuration {#configuration}

Rows that do not depend on the trigger records, such as custom metadata:

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [SELECT Country__c, Region__c FROM RegionMapping__mdt];
}

public String keyOf(SObject row) {
    return ((RegionMapping__mdt) row).Country__c;
}
```

### A Declared Parent's Field {#parent-field}

Parents load before providers run. Declare `Account.OwnerId` with a ParentQuery, then collect it by the relationship name:

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [SELECT Id, OwnerId FROM Account WHERE OwnerId IN :records.getIdsOf('Account', Account.OwnerId)];
}
```

### The Trigger Records Themselves {#self}

Formula, roll-up and system fields that the trigger rows do not carry:

```apex
public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return [SELECT Id, ExpectedRevenue FROM Opportunity WHERE Id IN :records.getIds()];
}

public String keyOf(SObject row) {
    return row.Id;
}
```

In after insert, update and undelete the query returns the new values. In before update and before delete it returns the values from before the save.

### One Provider, Several Contexts {#several-contexts}

Implement each context's `RecordsProvider` and add one `query` overload per collection type:

```apex
public without sharing class AccountOpenOpportunitiesProvider implements BeforeUpdate.RecordsProvider, BeforeDelete.RecordsProvider {
    public List<SObject> query(TriggerHandler.UpdateRecords records) {
        return this.openOpportunitiesOf(records.getIds());
    }

    public List<SObject> query(TriggerHandler.DeleteRecords records) {
        return this.openOpportunitiesOf(records.getIds());
    }

    public String keyOf(SObject row) {
        return ((Opportunity) row).AccountId;
    }

    private List<SObject> openOpportunitiesOf(Set<Id> accountIds) {
        return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :accountIds AND IsClosed = FALSE];
    }
}
```

## Rules {#rules}

- **Only the qualified records need it?** Query once in the Finalizer instead.
