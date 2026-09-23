---
description: 'RelatedRecords and RecordsProvider reference: the provider a RelatedQuery add-on returns to query children, siblings or unrelated records once per chunk, its query and keyOf methods, and the RelatedRecords index a handler reads with getRelated.'
---

# RelatedRecords & RecordsProvider

A RecordsProvider queries related records once per chunk: children, siblings, configuration or unrelated records. A handler reads them per record with `record.getRelated('<provider name>')`.

## How They Fit {#overview}

1. The handler implements its context's RelatedQuery add-on. Its method returns a map of provider names to providers.
2. At the handler's turn, the library calls each provider's `query`, then `keyOf` for every returned row.
3. The handler reads the rows with `record.getRelated('<provider name>')`.

## RecordsProvider {#records-provider}

Each context declares its own `RecordsProvider`, so `query` gets that context's [collection](/api/record-collections). In after update:

<!--@include: @/_parts/generated/after-update/related-query/records-provider.md-->

- **Runs before the first predicate.** Two handlers that use the same provider class query twice.
- **Any query you like.** Use inline SOQL, SOQL Lib or a selector.
- **Your sharing.** The query runs under the provider class's own sharing keyword. Declare one on every provider class.
- **Parents are loaded already.** In `query`, `records.getIdsOf('Account', Account.OwnerId)` works.
- **Normalize text keys.** Keys are compared exactly, case included. Lowercase them in `keyOf` and when you read.

## RelatedRecords {#relatedrecords}

What `record.getRelated('<provider name>')` returns.

```apex
public interface RelatedRecords {
    SObject getFirstWhereKeyEquals(Object key);

    List<SObject> getAllWhereKeyEquals(Object key);
    List<SObject> getRecords();

    Boolean isEmpty();
}
```

| Method | Returns |
|---|---|
| `getFirstWhereKeyEquals(key)` | the first row with that key, or `null` |
| `getAllWhereKeyEquals(key)` | every row with that key; an empty list when there is none |
| `getRecords()` | every row `query` returned, rows with a null key included |
| `isEmpty()` | true when `query` returned no rows |

- **Keys compare as text.** An Id matches the same Id returned as a `String` from `keyOf`.
- **One index per provider, shared by the chunk.** Look up by the current record, for example `getAllWhereKeyEquals(record.getId())`.
- **Only your own providers.** `getRelated` with a name the handler did not return throws a [`TriggerHandlerException`](/api/record#triggerhandlerexception).

## Example {#example}

Block the delete of accounts that still have open opportunities:

```apex
public with sharing class AccountOpenDealsGuard implements BeforeDelete.Handler, BeforeDelete.RelatedQuery {
    public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
        return new Map<String, BeforeDelete.RecordsProvider>{ 'openOpportunities' => new OpenOpportunitiesProvider() };
    }

    public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
        return !record.getRelated('openOpportunities').getAllWhereKeyEquals(record.getId()).isEmpty();
    }

    public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
        record.getOldSObject().addError('Close or move the open opportunities before deleting this account.');
    }

    private with sharing class OpenOpportunitiesProvider implements BeforeDelete.RecordsProvider {
        public List<SObject> query(TriggerHandler.DeleteRecords records) {
            return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
        }

        public String keyOf(SObject record) {
            return ((Opportunity) record).AccountId;
        }
    }
}
```

## In Unit Tests {#test}

Give the record its provider results yourself, so no query runs. Group each row under the key your `keyOf` returns for it.

```apex
Account existing = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
TriggerHandler.ProvidedRecords provided = new TriggerHandler.ProvidedRecords(new List<SObject>{ existing });
provided.groupUnderKey('acme', existing);

record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ '<provider name>' => provided });
```

`record` is a `TriggerHandler.TriggerRecord`. More in [Testing](/guide/testing).
