Each pattern shows the body of the provider's `query(records)`, the body of its `keyOf(row)`, and the call that reads the result in the handler. The name in quotes is the key the handler gives the provider in its RelatedQuery map.

**Children of each record.** The records whose lookup points at a trigger record. Needs Ids, so not in before insert.

- `query`: `return [SELECT Id, AccountId, Email FROM Contact WHERE AccountId IN :records.getIds()];`
- `keyOf`: `return ((Contact) row).AccountId;`
- Read: `record.getRelated('contacts').getAllWhereKeyEquals(record.getId())`

**Siblings.** Other records under the same parent, without the trigger records themselves.

- `query`: `return [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId IN :records.getIdsOf(Opportunity.AccountId) AND Id NOT IN :records.getIds()];`
- `keyOf`: `return ((Opportunity) row).AccountId;`
- Read: `record.getRelated('siblings').getAllWhereKeyEquals(accountId)`, where `accountId` is the record's own `AccountId`.

`getFirstWhereKeyEquals` returns the first row in query order, so add an `ORDER BY` when you read only one.

**Text key.** Records that share a value, such as a duplicate email.

- `query`: `return [SELECT Id, Email FROM Contact WHERE Email IN :records.getValuesOf(Contact.Email)];`
- `keyOf`: `return ((Contact) row).Email?.toLowerCase();`
- Read: `record.getRelated('sameEmail').getFirstWhereKeyEquals(email.toLowerCase())`

SOQL compares text without case, but keys are compared exactly, so lowercase on both sides. Where the trigger records are already saved, add `Id NOT IN :records.getIds()` so a record does not find itself.

**Composite key.** A match on two fields, such as one product per opportunity.

- `query`: `return [SELECT Id, OpportunityId, Product2Id FROM OpportunityLineItem WHERE OpportunityId IN :records.getIdsOf(OpportunityLineItem.OpportunityId)];`
- `keyOf`: `return ((OpportunityLineItem) row).OpportunityId + '|' + ((OpportunityLineItem) row).Product2Id;`
- Read: `getFirstWhereKeyEquals(opportunityId + '|' + productId)`, built from the record's own fields.

Put the key format in one static method that both `keyOf` and the handler call, so the two sides never drift apart.

**Configuration.** Rows that do not depend on the trigger records, such as custom metadata.

- `query`: `return [SELECT Country_Code__c, Region__c FROM Region_Mapping__mdt];`
- `keyOf`: `return ((Region_Mapping__mdt) row).Country_Code__c;`
- Read: `record.getRelated('regions').getFirstWhereKeyEquals(countryCode)`, or every row with `getRecords()`.

**Dependent query.** A second query that needs the result of a first one. Both run inside the same `query`:

```apex
Set<Id> pricebookIds = new Set<Id>();
for (Opportunity opportunityRecord : [SELECT Pricebook2Id FROM Opportunity WHERE Id IN :records.getIdsOf(OpportunityLineItem.OpportunityId)]) {
    pricebookIds.add(opportunityRecord.Pricebook2Id);
}
return [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id IN :pricebookIds];
```

When the first hop is a parent field, declare it with ParentQuery or PriorParentQuery instead, and read it in the provider with `records.getIdsOf('<relationship>', <field>)`. That saves the first query.

**One provider in several contexts.** A provider class can implement the `RecordsProvider` interface of several contexts. Add one `query` overload per collection type it receives (`InsertRecords`, `UpdateRecords`, `DeleteRecords` or `UndeleteRecords`), let each overload call one private method that takes the Ids or values, and keep a single `keyOf`.

**The trigger records themselves.** Formula, roll-up and system fields that the trigger rows do not carry. Not in before insert, which has no Ids.

- `query`: `return [SELECT Id, ExpectedRevenue FROM Opportunity WHERE Id IN :records.getIds()];`
- `keyOf`: `return row.Id;`
- Read: `record.getRelated('self').getFirstWhereKeyEquals(record.getId())`

It returns the new values in after insert, after update and after undelete. In before update and before delete it returns the saved values from before this save, and in after delete it returns nothing.

More recipes: [RelatedQuery Recipes](/guide/related-records).
