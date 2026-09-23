---
template: add-on
context: BeforeDelete
interface: Finalizer
description: Run once per chunk after a before delete Handler, with the qualified records - the place for one bulk DML statement.
---

# BeforeDelete.Finalizer

Runs once per chunk after the handler's records, with the records that qualified. Use it for one bulk DML statement or one query over all of them.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/finalizer/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-delete/finalizer/skeleton.md-->

```apex [Clean up in the Finalizer]
public with sharing class ContactReportsReassignHandler implements BeforeDelete.Handler, BeforeDelete.Finalizer {
    private Map<Id, Id> managerIdByContactId = new Map<Id, Id>();

    public Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record) {
        return record.isNotNull(Contact.ReportsToId);
    }

    public void onBeforeDelete(TriggerHandler.DeleteRecord record) {
        this.managerIdByContactId.put(record.getId(), ((Contact) record.getOldSObject()).ReportsToId);
    }

    public void finalizeBeforeDelete(TriggerHandler.DeleteRecords records) {
        List<Contact> reports = [SELECT Id, ReportsToId FROM Contact WHERE ReportsToId IN :records.getIds()];

        for (Contact report : reports) {
            report.ReportsToId = this.managerIdByContactId.get(report.ReportsToId);
        }

        update reports;
    }
}
```

:::

## Good to Know {#good-to-know}

- **DML is allowed here.** Before delete has no DML guard and no unit of work, so a statement runs at once. Collect Ids in `onBeforeDelete` and write once here.
- **The DML fires triggers.** Records written here run their own triggers at once, nested in this run. Every statement counts against the transaction's limits.
- **Leave the records being deleted alone.** Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`. An update of one is lost when the delete goes through.
- **An exception skips it.** When the action throws, the Finalizer does not run for that chunk. With ContinueOnError, statements that already ran keep their changes.
