---
description: RelatedQuery recipes for Trigger Lib - RecordsProvider classes that query children, siblings, records under the previous parent, text and composite keys, configuration, a declared parent's field, dependent queries and the trigger records' own formula fields, once per handler per run.
---

# RelatedQuery Recipes

Recipes for RelatedQuery providers: load children, siblings, duplicates, configuration or any other records a handler needs (related records beyond its parents) with one query per handler per run, then read them from memory in every predicate, action and Finalizer.

Parents are simpler: declare them with ParentQuery or PriorParentQuery ([Field Selection](/api/field-selection)). Use a provider for everything else.

## A Complete Example {#example}

A provider is a class with two methods: `query(records)` receives the chunk's records and returns rows, and `keyOf(row)` says under which key each row is found again. The handler implements its context's RelatedQuery add-on, returns its providers by name, and reads them with `record.getRelated('<name>')`:

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

One query serves the whole chunk, whether one Account is saved or two hundred. The read methods:

| Method | Returns |
|---|---|
| `getAllWhereKeyEquals(key)` | every row stored under the key, in query order; an empty list when there is none |
| `getFirstWhereKeyEquals(key)` | the first of them, or null |
| `getRecords()` | every row the query returned, including rows whose key was null |
| `isEmpty()` | true when the query returned no rows |

The RelatedQuery page of each context has its signature and the context's own details:

<!--@include: @/_parts/generated/chips/related-query.md-->

## How Providers Run {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

## Recipes {#recipes}

Each recipe names the context it is written for. In another context, implement that context's `RecordsProvider` and take its collection type: `InsertRecords`, `UpdateRecords`, `DeleteRecords` or `UndeleteRecords`.

### Children of Each Record {#children}

The records whose lookup points at a trigger record. They need Ids, so not in before insert.

```apex
public with sharing class AccountContactsProvider implements AfterUpdate.RecordsProvider {
    public List<SObject> query(TriggerHandler.UpdateRecords records) {
        return [SELECT Id, AccountId, Email FROM Contact WHERE AccountId IN :records.getIds()];
    }

    public String keyOf(SObject row) {
        return ((Contact) row).AccountId;
    }
}
```

```apex
List<SObject> contacts = record.getRelated('contacts').getAllWhereKeyEquals(record.getId());
```

### Siblings, Without the Records Being Saved {#siblings}

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

```apex
Opportunity opportunityRecord = (Opportunity) record.getNewSObject();
Opportunity nextOpportunity = (Opportunity) record.getRelated('openSiblings').getFirstWhereKeyEquals(opportunityRecord.AccountId);
```

`getFirstWhereKeyEquals` returns the first row in query order, so the `ORDER BY` decides which one. In after delete, the deleted rows are already invisible to SOQL, so `Id NOT IN` is not needed there.

### Records Under the Previous Parent {#previous-parent}

In before update and after update, `getOldIdsOf` reads the lookup values from before the save. This provider finds the contacts that stay on the account a contact moved away from:

```apex
public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return [SELECT Id, AccountId FROM Contact WHERE AccountId IN :records.getOldIdsOf(Contact.AccountId) AND Id NOT IN :records.getIds()];
}

public String keyOf(SObject row) {
    return ((Contact) row).AccountId;
}
```

```apex
Id previousAccountId = ((Contact) record.getOldSObject()).AccountId;
Boolean wasLastContact = record.getRelated('remainingContacts').getAllWhereKeyEquals(previousAccountId).isEmpty();
```

### Matching on a Text Value {#text-key}

Records that share a value, such as an email address. SOQL compares text ignoring case, but keys are compared exactly, so normalize both sides the same way:

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

In before insert the new records are not in the database yet, so two new contacts with the same email in one chunk do not find each other. Compare those in memory, for example in the Finalizer. In the update contexts, add `Id NOT IN :records.getIds()` to the query.

### A Key Built From Two Fields {#composite-key}

Put the key format in one static method, so the provider and the handler build it the same way:

```apex
public with sharing class OpportunityLineItemsProvider implements BeforeInsert.RecordsProvider {
    public static String key(Id opportunityId, Id productId) {
        return opportunityId + '|' + productId;
    }

    public List<SObject> query(TriggerHandler.InsertRecords records) {
        return [SELECT Id, OpportunityId, Product2Id FROM OpportunityLineItem WHERE OpportunityId IN :records.getIdsOf(OpportunityLineItem.OpportunityId)];
    }

    public String keyOf(SObject row) {
        OpportunityLineItem lineItem = (OpportunityLineItem) row;

        return OpportunityLineItemsProvider.key(lineItem.OpportunityId, lineItem.Product2Id);
    }
}
```

```apex
OpportunityLineItem lineItem = (OpportunityLineItem) record.getNewSObject();
Boolean isDuplicate = record.getRelated('existingLineItems').getFirstWhereKeyEquals(OpportunityLineItemsProvider.key(lineItem.OpportunityId, lineItem.Product2Id)) != null;
```

### Configuration {#configuration}

Rows that do not depend on the trigger records, such as custom metadata. Key them by what the handler looks up, or read them all with `getRecords()`:

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [SELECT Country__c, Region__c FROM RegionMapping__mdt];
}

public String keyOf(SObject row) {
    return ((RegionMapping__mdt) row).Country__c;
}
```

```apex
String country = ((Account) record.getNewSObject()).BillingCountry;
RegionMapping__mdt mapping = (RegionMapping__mdt) record.getRelated('regions').getFirstWhereKeyEquals(country);
```

`RegionMapping__mdt` stands for a custom metadata type of your own. Custom metadata queries do not count against the SOQL limit, but the provider still runs once per handler per run.

### A Declared Parent's Field {#parent-field}

Parents are loaded before providers run, so a provider can collect a field of a declared parent in bulk. This Writer declares the Account's owner with ParentQuery, and its provider loads the other accounts of that owner:

```apex
public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
    return new Map<SObjectField, TriggerHandler.ParentFields>{ Contact.AccountId => TriggerHandler.ParentFields.with(Account.OwnerId) };
}
```

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
    return [SELECT Id, OwnerId FROM Account WHERE OwnerId IN :records.getIdsOf('Account', Account.OwnerId)];
}

public String keyOf(SObject row) {
    return ((Account) row).OwnerId;
}
```

```apex
Account parentAccount = (Account) record.getNewParent('Account');
List<SObject> ownerAccounts = record.getRelated('ownerAccounts').getAllWhereKeyEquals(parentAccount?.OwnerId);
```

The first argument of `getIdsOf` and `getValuesOf` is the relationship name, the same name `getNewParent` takes. Before delete and after delete read the previous parents this way too.

### A Second Query That Depends on the First {#dependent-query}

Both queries go in the same `query`. A provider is never built from another provider's result:

```apex
public List<SObject> query(TriggerHandler.InsertRecords records) {
    Set<Id> pricebookIds = new Set<Id>();

    for (Opportunity opportunityRecord : [SELECT Pricebook2Id FROM Opportunity WHERE Id IN :records.getIdsOf(OpportunityLineItem.OpportunityId)]) {
        pricebookIds.add(opportunityRecord.Pricebook2Id);
    }

    return [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id IN :pricebookIds];
}
```

When the first hop is a lookup of the trigger record, declare it with ParentQuery instead, as in [the recipe above](#parent-field). That saves the first query.

### The Trigger Records Themselves {#self}

Formula, roll-up summary and system fields that the trigger rows do not carry. Query the trigger object by the records' own Ids:

```apex
public List<SObject> query(TriggerHandler.UpdateRecords records) {
    return [SELECT Id, ExpectedRevenue FROM Opportunity WHERE Id IN :records.getIds()];
}

public String keyOf(SObject row) {
    return row.Id;
}
```

```apex
Opportunity saved = (Opportunity) record.getRelated('self').getFirstWhereKeyEquals(record.getId());
```

It returns the new values in after insert, after update and after undelete, where formulas are recalculated when queried. In before update and before delete it returns the values from before this save, and in after delete it returns nothing. Before insert has no Ids.

### One Provider, Several Contexts {#several-contexts}

Implement each context's `RecordsProvider` and add one `query` overload per collection type. Both overloads call one private method, and `keyOf` is shared:

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

## What `records` Holds per Context {#per-context}

### Before Insert {#before-insert}

<!--@include: @/_parts/add-ons/related-query.md#ids-before-insert-->

### Before Update {#before-update}

<!--@include: @/_parts/add-ons/related-query.md#ids-before-update-->

### After Insert, After Update and After Undelete {#after-saved}

<!--@include: @/_parts/add-ons/related-query.md#ids-after-->

### Before Delete {#before-delete}

<!--@include: @/_parts/add-ons/related-query.md#ids-before-delete-->

### After Delete {#after-delete}

<!--@include: @/_parts/add-ons/related-query.md#ids-after-delete-->

## Sharing {#sharing}

A provider's query runs under its own class's sharing keyword, so the provider decides what it can see.

- **`without sharing`** when the result must not depend on who saves, such as a duplicate check or a rule that blocks a save. Otherwise the check passes whenever the conflicting record is invisible to the running user.
- **`with sharing`** when the result is meant to depend on the running user.
- **Declare it on every provider class.** An inner class does not take its outer class's keyword, as the Validator above shows: the Validator is `with sharing`, its provider `without sharing`.

Parents declared with ParentQuery and PriorParentQuery are always loaded in system mode, without sharing.

## Providers or the Finalizer {#provider-or-finalizer}

- **Use a provider** when a predicate or an action needs the data. Providers run before the first predicate, over every record in the chunk.
- **Query in a Finalizer** when only the qualified records need it, for a bulk step after the per-record work. The Finalizer runs only when at least one record qualified, and receives only those records, so its query is often smaller, or skipped.

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

## Testing Providers {#testing}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

## See Also {#see-also}

- [RelatedRecords & RecordsProvider](/api/related-records): the interfaces
- [Record Collections](/api/record-collections): `getIds`, `getIdsOf`, `getValuesOf` and the old-value variants
- [Field Selection](/api/field-selection): declaring parents instead
- [Execution Order & Cost](/guide/execution-order#query-cost): what providers cost per run
