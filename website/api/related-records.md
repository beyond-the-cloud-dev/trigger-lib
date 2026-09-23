---
description: 'RelatedRecords and RecordsProvider reference: the provider a RelatedQuery add-on returns to query children, siblings or unrelated records once per chunk, its query and keyOf methods in every context, and the RelatedRecords index a handler reads with getRelated.'
---

# RelatedRecords & RecordsProvider

A RecordsProvider queries related records (children, siblings, configuration, unrelated records) once for the whole chunk, and says which key each row is found by. The library indexes the rows as `TriggerHandler.RelatedRecords`, which a handler reads per record with `record.getRelated('<provider name>')`.

## How They Fit {#overview}

1. The handler implements its context's RelatedQuery add-on, whose method returns a `Map<String, <Ctx>.RecordsProvider>`: provider names to providers.
2. At the handler's turn, the library calls each provider's `query` once with every record of the chunk, then `keyOf` once per returned row.
3. The handler's predicates, actions, dispatch method and Finalizer read the rows with `record.getRelated('<provider name>')`.

RelatedQuery in each context:

<!--@include: @/_parts/generated/chips/related-query.md-->

## RecordsProvider {#records-provider}

Each context class declares its own `RecordsProvider`, so `query` receives the context's collection type. In after update:

<!--@include: @/_parts/generated/after-update/related-query/records-provider.md-->

| Context | Interface | `query` receives |
|---|---|---|
| BeforeInsert | `BeforeInsert.RecordsProvider` | `TriggerHandler.InsertRecords` |
| AfterInsert | `AfterInsert.RecordsProvider` | `TriggerHandler.InsertRecords` |
| BeforeUpdate | `BeforeUpdate.RecordsProvider` | `TriggerHandler.UpdateRecords` |
| AfterUpdate | `AfterUpdate.RecordsProvider` | `TriggerHandler.UpdateRecords` |
| BeforeDelete | `BeforeDelete.RecordsProvider` | `TriggerHandler.DeleteRecords` |
| AfterDelete | `AfterDelete.RecordsProvider` | `TriggerHandler.DeleteRecords` |
| AfterUndelete | `AfterUndelete.RecordsProvider` | `TriggerHandler.UndeleteRecords` |

### query {#query}

- **Once per handler per run**, at the handler's turn and before its first predicate, with every record of the chunk, qualified or not. Two handlers that use the same provider class query twice.
- **Any query you like.** Inline SOQL, SOQL Lib, a selector, or several statements. Returning `null` counts as no rows.
- **Your sharing.** The query runs under the provider class's own sharing keyword. Declare one on every provider class, inner classes included.
- **Parents are already loaded**, so `query` can collect parent values in bulk, such as `records.getIdsOf('Account', Account.OwnerId)`.
- **Inside the handler's error handling.** An exception is logged, and with ContinueOnError it is swallowed; the handler then processes no record in that chunk.

The collection's methods: [Record Collections](/api/record-collections).

### keyOf {#keyof}

- **Called once per returned row.** Return the value the handler will look the row up by: the row's Id, a lookup such as `AccountId`, a text field, or a combination.
- **`null` leaves the row out of the index.** It is still in `getRecords()`.
- **Normalize text keys.** Keys are compared exactly, case included. Lowercase or trim in `keyOf`, and in the same way when you read.

A class can serve several contexts by implementing each context's `RecordsProvider`: the `query` methods then differ by parameter type. `BeforeInsert` and `AfterInsert` share the parameter type, so one `query(TriggerHandler.InsertRecords)` serves both.

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
| `getFirstWhereKeyEquals(key)` | the first row whose key equals `key`, in query order, or `null` |
| `getAllWhereKeyEquals(key)` | every row whose key equals `key`, in query order; an empty list when there is none |
| `getRecords()` | every row `query` returned, including rows with a null key; it is the list `query` returned, not a copy |
| `isEmpty()` | true when `query` returned no rows |

- **Keys compare as text.** The `key` you pass is converted with `String.valueOf` and compared exactly with what `keyOf` returned. An Id and the same Id returned as a `String` from `keyOf` match, because both become the 18-character form.
- **One index per provider name**, shared by every record of the chunk. Look up by the current record, for example `getAllWhereKeyEquals(record.getId())`.

## Example {#example}

Before delete, block the delete of accounts that still have open opportunities:

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

More provider shapes, such as siblings, text keys, composite keys and configuration: [RelatedQuery Recipes](/guide/related-records).

## getRelated {#getrelated}

```apex
TriggerHandler.RelatedRecords getRelated(String providerName)
```

On every record type. `providerName` is a key of the map the handler's RelatedQuery method returned.

- **Private to the handler.** A handler reads only the providers it returned itself, never another handler's.
- **Unknown names throw** `TriggerHandler.TriggerHandlerException`, even with ContinueOnError. See [TriggerHandlerException](/api/record#triggerhandlerexception).

## Record Collections {#record-collections}

The collection a provider's `query` receives, with `getIds()`, `getIdsOf(…)` and `getValuesOf(…)`, has its own page: [Record Collections](/api/record-collections).

## In Unit Tests {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [Record API](/api/record#getrelated) and [Test API](/api/record#test-api)
