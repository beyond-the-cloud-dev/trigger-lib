# RelatedQuery recipes

A RelatedQuery provider loads rows once per handler per chunk, and every predicate, action and Finalizer of that handler reads them from memory. For parents, use a ParentQuery instead.

The recipes show inline SOQL to keep the filters easy to read. With SOQL Lib, put the same filters in `whereAre(...)`, add `.systemMode()` so the provider class's sharing keyword applies (SOQL Lib runs in user mode otherwise), and give the query a `mockId('<Handler>.<provider name>')`, so a unit test can mock it.

## Contents

- [Children](#children)
- [Siblings](#siblings)
- [Records under the previous parent](#records-under-the-previous-parent)
- [Matching on a text value](#matching-on-a-text-value)
- [A key built from two fields](#a-key-built-from-two-fields)
- [Configuration that depends on the records](#configuration-that-depends-on-the-records)
- [A declared parent's field](#a-declared-parents-field)
- [The trigger records themselves](#the-trigger-records-themselves)
- [One provider in several contexts](#one-provider-in-several-contexts)

## Children

```apex
private without sharing class OpenOpportunitiesProvider implements BeforeUpdate.RecordsProvider {
    public List<SObject> query(TriggerTypes.UpdateRecords records) {
        return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
    }

    public String keyOf(SObject row) {
        return ((Opportunity) row).AccountId;
    }
}
```

Read: `record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId())`.

## Siblings

Other records under the same parent. Exclude the trigger records, so a record never finds itself. That also hides the chunk's other records and their new values, so compare those in memory when they matter:

```apex
public List<SObject> query(TriggerTypes.UpdateRecords records) {
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

Read by the parent: `getAllWhereKeyEquals(((Opportunity) record.getNewSObject()).AccountId)`. The `ORDER BY` decides which row `getFirstWhereKeyEquals` returns.

## Records under the previous parent

In the update contexts, `getOldIdsOf` reads the lookup values from before the save:

```apex
public List<SObject> query(TriggerTypes.UpdateRecords records) {
    return [SELECT Id, AccountId FROM Contact WHERE AccountId IN :records.getOldIdsOf(Contact.AccountId) AND Id NOT IN :records.getIds()];
}
```

## Matching on a text value

Keys match exactly, case included. Normalize both sides the same way:

```apex
public List<SObject> query(TriggerTypes.InsertRecords records) {
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

The query finds only saved records, so two new records with the same value in one save both pass. To compare the chunk's records with each other, add a Finalizer to a Populator: it gets every qualified record at once, and can reject one with `((Contact) record.getNewSObject()).Email.addError(...)`. Records in different chunks are never compared.

## A key built from two fields

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

## Configuration that depends on the records

Configuration rows that depend on the trigger records, such as the region of each billing country. Configuration that doesn't depend on them belongs in a static variable.

```apex
public List<SObject> query(TriggerTypes.InsertRecords records) {
    return [SELECT Country__c, Region__c FROM RegionMapping__mdt WHERE Country__c IN :records.getValuesOf(Account.BillingCountry)];
}

public String keyOf(SObject row) {
    return ((RegionMapping__mdt) row).Country__c;
}
```

## A declared parent's field

Parents load on the first read, also inside `query`. Declare `Account.OwnerId` in the handler's ParentQuery for the `Contact.AccountId` lookup, then collect it by the relationship name:

```apex
public List<SObject> query(TriggerTypes.InsertRecords records) {
    return [SELECT Id, OwnerId FROM Account WHERE OwnerId IN :records.getIdsOf('Account', Account.OwnerId)];
}
```

## The trigger records themselves

Formula, roll-up and system fields that the trigger rows don't carry:

```apex
public List<SObject> query(TriggerTypes.UpdateRecords records) {
    return [SELECT Id, ExpectedRevenue FROM Opportunity WHERE Id IN :records.getIds()];
}

public String keyOf(SObject row) {
    return row.Id;
}
```

In after insert, after update and after undelete the query returns the new values. In before update and before delete it returns the values from before the save.

## One provider in several contexts

Implement each context's `RecordsProvider` and add one `query` overload per collection type:

```apex
public without sharing class AccountOpenOpportunitiesProvider implements BeforeUpdate.RecordsProvider, BeforeDelete.RecordsProvider {
    public List<SObject> query(TriggerTypes.UpdateRecords records) {
        return this.openOpportunitiesOf(records.getIds());
    }

    public List<SObject> query(TriggerTypes.DeleteRecords records) {
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
