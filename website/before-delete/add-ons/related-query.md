---
template: add-on
context: BeforeDelete
interface: RelatedQuery
description: Query children, siblings or other records in a before delete Handler with one query per provider, while the rows are still linked.
---

# BeforeDelete.RelatedQuery

Loads children, siblings or other records with one query per provider, instead of SOQL in your handler. The rows being deleted are still linked, so their children can be found.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/related-query/signature.md-->

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

## Good to Know {#good-to-know}

- **Read by provider name.** Call `record.getRelated('<name>')`. An unknown name throws `TriggerHandler.TriggerHandlerException`.
- **Counts include the records being deleted.** A query here still returns them. To count what will remain, add `Id NOT IN :records.getIds()`.
- **Last chance for cascade children.** Children removed by a cascade delete run no delete triggers of their own. Read them here.
- **Sharing can hide rows.** A provider uses its own class's sharing keyword. A `with sharing` guard misses rows the user cannot see, so those deletes go through. Use `without sharing` when it must see every row.
- **Runs even when nothing qualifies.** Providers run before the first predicate, so they cost their SOQL on every chunk. Return an empty list from `query` when no record can qualify.
