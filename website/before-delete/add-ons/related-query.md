---
template: add-on
context: BeforeDelete
interface: RelatedQuery
description: "Query children, siblings, records that look up to the rows being deleted, or configuration in a before delete Handler, once per run."
---

# BeforeDelete.RelatedQuery

Load children, siblings, records that look up to the rows being deleted, or configuration in **before delete**, with one query per provider instead of SOQL in your handler, while the rows are still in the database and still linked.

<!--@include: @/_parts/generated/before-delete/related-query/available-in.md-->

## When to Use {#when-to-use}

- Children or records that point at the rows being deleted, such as the open opportunities of an account or the reports of a contact. Here they are still linked; after the delete they are gone or their lookups are cleared.
- Siblings under the same parent, or configuration rows such as custom metadata.
- Use [PriorParentQuery](/before-delete/add-ons/prior-parent-query) instead for fields of the parent itself.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/related-query/signature.md-->

<!--@include: @/_parts/generated/before-delete/related-query/method-table.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/before-delete/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/related-query/skeleton.md-->

```apex [Block the delete]
public with sharing class AccountDeletionGuardHandler implements BeforeDelete.Handler, BeforeDelete.RelatedQuery {
    public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
        return new Map<String, BeforeDelete.RecordsProvider>{ 'openOpportunities' => new OpenOpportunitiesProvider() };
    }

    public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
        return record.getRelated('openOpportunities').getFirstWhereKeyEquals(record.getId()) != null;
    }

    public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
        record.getOldSObject().addError('Close or move the open opportunities before you delete this account.');
    }

    private without sharing class OpenOpportunitiesProvider implements BeforeDelete.RecordsProvider {
        public List<SObject> query(TriggerHandler.DeleteRecords records) {
            return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
        }

        public String keyOf(SObject record) {
            return ((Opportunity) record).AccountId;
        }
    }
}
```

:::

The Skeleton counts the contacts of each account, the deleted one included, and blocks the delete of the last one. The guard keys open opportunities by `AccountId` and reads them in the predicate; its provider is `without sharing`, so it also sees opportunities the running user cannot.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-before-delete-->

### Key Patterns {#key-patterns}

::: details Key patterns: children, siblings, text and composite keys, configuration, dependent queries

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

`query(records)` receives `TriggerHandler.DeleteRecords` with every record in the chunk, qualified or not. The handler reads the result with `record.getRelated('<provider name>')`, then `getFirstWhereKeyEquals`, `getAllWhereKeyEquals`, `getRecords` or `isEmpty`, in the predicate, the action and the Finalizer.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-delete/related-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

- **Counts include the records being deleted.** A query run here still returns them. To count what will remain, exclude them with `Id NOT IN :records.getIds()`, or recompute from what remains in an [AfterDelete.Writer](/after-delete/writer).
- **Last chance for cascade victims.** Children that a cascade delete will remove are still here, and they run no delete triggers of their own. Read them now if you need them.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

The guard example registers its provider as `'openOpportunities'` and keys by `AccountId`, so group each opportunity under its account Id; its [Handler page](/before-delete/handler#test) shows the full test.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-delete/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [RelatedRecords & RecordsProvider](/api/related-records)
- [AfterDelete.RelatedQuery](/after-delete/add-ons/related-query): after the rows are gone.
- [BeforeDelete.PriorParentQuery](/before-delete/add-ons/prior-parent-query): fields of the parent.
