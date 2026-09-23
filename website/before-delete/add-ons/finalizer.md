---
template: add-on
context: BeforeDelete
interface: Finalizer
description: "Run once per chunk after a before delete Handler, with the qualified records; the place for one bulk DML statement or one query."
---

# BeforeDelete.Finalizer

Run code once per chunk after a **before delete** handler has processed its records, with the records that qualified: the place for one bulk DML statement (cleanup, archive, reassign) or one query over all of them, while the rows being deleted still exist.

<!--@include: @/_parts/generated/before-delete/finalizer/available-in.md-->

## When to Use {#when-to-use}

- Collect Ids or values in `onBeforeDelete`, then write other records with one DML statement here, instead of one statement per record.
- Run one query over all qualified records, for example to find the records that still point at them.
- It is not a hook that runs once after the whole `delete` statement: each chunk of up to 200 records gets its own call.

## Interface {#interface}

<!--@include: @/_parts/generated/before-delete/finalizer/signature.md-->

<!--@include: @/_parts/generated/before-delete/finalizer/method-table.md-->

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

The Skeleton stamps the accounts of deleted contacts. The cleanup example moves the direct reports of each deleted contact up to that contact's own manager, before the platform clears their `ReportsToId`.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#before-delete-->

## Records Here {#records}

`TriggerHandler.DeleteRecords` with only the qualified records. `getIds()` returns their Ids, and `getIdsOf` and `getValuesOf` read the old rows. `getRecords()` returns the library's internal list, not a copy: see [Record Collections](/api/record-collections).

## Works With {#works-with}

<!--@include: @/_parts/generated/before-delete/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **The DML fires triggers.** Records written here run their own triggers at once, nested inside this run, and every statement counts against the transaction's limits.
- **Leave the records being deleted alone.** Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`, and an update of one is lost when the delete goes through.
- **An exception skips it.** When the action throws, the Finalizer does not run for that chunk. With ContinueOnError the exception is swallowed, and records written by statements that already ran stay, because the library sets no savepoint.
- **Partial deletes run it twice.** With `Database.delete(records, false)` and a failing record, the platform re-runs the handlers for the surviving records, so the Finalizer runs again; the DML of the first attempt is rolled back.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

Here the collection is `DeleteTriggerRecords`, built from `new TriggerHandler.TriggerRecord(null, oldRow)`. A Finalizer that queries and updates, like the cleanup example, needs real records: test it in a separate integration test class.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-delete/finalizer/other-contexts.md-->

## See Also {#see-also}

- [BeforeDelete.Handler](/before-delete/handler)
- [BeforeDelete gotchas](/before-delete/#gotchas): DML on the records being deleted.
- [AfterDelete.Finalizer](/after-delete/add-ons/finalizer): after the rows are gone, with a unit of work.
- [Execution Order & Cost](/guide/execution-order)
