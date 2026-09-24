---
template: role
context: BeforeDelete
interface: Writer
description: Create, update or delete other records before a delete, while the rows and the records that point at them still exist - through a unit of work.
---

# BeforeDelete.Writer

Change other records or publish platform events before the delete, through a unit of work.

**Signature**

<!--@include: @/_parts/generated/before-delete/writer/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/writer/skeleton.md-->

```apex [Reassign direct reports]
public with sharing class ContactReportsReassignWriter implements BeforeDelete.Writer, BeforeDelete.RelatedQuery {
    public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
        return new Map<String, BeforeDelete.RecordsProvider>{ 'directReports' => new DirectReportsProvider() };
    }

    public Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
        return !record.getRelated('directReports').getAllWhereKeyEquals(record.getId()).isEmpty();
    }

    public void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Id managerId = ((Contact) record.getOldSObject()).ReportsToId;

        for (SObject report : record.getRelated('directReports').getAllWhereKeyEquals(record.getId())) {
            unitOfWork.toUpdate(new Contact(Id = report.Id, ReportsToId = managerId));
        }
    }

    private without sharing class DirectReportsProvider implements BeforeDelete.RecordsProvider {
        public List<SObject> query(TriggerTypes.DeleteRecords records) {
            return [SELECT Id, ReportsToId FROM Contact WHERE ReportsToId IN :records.getIds() AND Id NOT IN :records.getIds()];
        }

        public String keyOf(SObject row) {
            return ((Contact) row).ReportsToId;
        }
    }
}
```

:::

## Rules {#rules}

- **Register, do not run DML.** `toInsert`, `toUpdate`, `toUpsert`, `toDelete` and `toPublish` (platform events) take one record each.
- **Commits before the delete.** The shared unit of work commits once, after the last handler of the run, while the records still exist. A Writer with [ContinueOnError](/before-delete/add-ons/continue-on-error) gets an automatic unit, committed right after it. [OwnUnitOfWork](/before-delete/add-ons/own-unit-of-work) supplies your own.
- **Links still point at the rows.** Records that look up to the deleted rows still hold the Ids here, so a query by `records.getIds()` finds them.
- **Validator wins.** A class that also implements `BeforeDelete.Validator` runs only as a Validator.

::: warning
Leave the records being deleted alone. A `toDelete` of one fails the commit with `SELF_REFERENCE_FROM_TRIGGER`, and an update of one is lost when the delete goes through.
:::

## Test {#test}

```apex
@IsTest
static void writeOnBeforeDeleteWhenQualifiesContactWithAccount() {
    // Setup
    Contact oldContact = new Contact(AccountId = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType));

    // Test
    Boolean qualifies = new ContactWriter().writeOnBeforeDeleteWhen(new TriggerTypes.TriggerRecord(null, oldContact));

    // Verify
    Assert.isTrue(qualifies, 'A contact with an account should qualify.');
}
```
