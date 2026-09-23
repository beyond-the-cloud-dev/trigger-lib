---
template: add-on
context: AfterUpdate
interface: Finalizer
description: 'Run once after an after update Writer or Dispatcher has processed its records, with the qualified records, for bulk queries, aggregates and registrations per chunk.'
---

# AfterUpdate.Finalizer

Run code once after an **after update** Writer or Dispatcher has processed its records, with the records that qualified: one aggregate query, one bulk registration or one summary per chunk, instead of work per record.

<!--@include: @/_parts/generated/after-update/finalizer/available-in.md-->

## When to Use {#when-to-use}

- The work needs the whole set of qualified records, such as one aggregate query over their accounts.
- A per-record query would hit governor limits: collect in the action, query once here.
- Use the Dispatcher's dispatch method instead for one call per chunk with no writes, and the action for work that concerns one record.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/finalizer/signature.md-->

<!--@include: @/_parts/generated/after-update/finalizer/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/finalizer/skeleton.md-->

```apex [Aggregate once per chunk]
public with sharing class OpportunityAccountPipelineWriter implements AfterUpdate.Writer, AfterUpdate.Finalizer {
    private TriggerHandler.UnitOfWork unitOfWork;

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isAnyChanged(Opportunity.Amount, Opportunity.StageName);
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        this.unitOfWork = unitOfWork;
    }

    public void finalizeAfterUpdate(TriggerHandler.UpdateRecords records) {
        for (AggregateResult pipeline : [
            SELECT AccountId, SUM(Amount) total
            FROM Opportunity
            WHERE AccountId IN :records.getIdsOf(Opportunity.AccountId) AND IsClosed = FALSE
            GROUP BY AccountId
        ]) {
            this.unitOfWork.toUpdate(new Account(Id = (Id) pipeline.get('AccountId'), Description = 'Open pipeline: ' + pipeline.get('total')));
        }
    }
}
```

:::

The action only keeps the unit; the Finalizer runs one query for the whole chunk and registers one update per account. The query sees the saved amounts and stages of this update.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/finalizer.md#after-->

## Records Here {#records}

`finalizeAfterUpdate` receives `TriggerHandler.UpdateRecords` with the qualified records only, without those the recursion guard skipped. `getIds()`, `getIdsOf(…)`, `getOldIdsOf(…)`, `getValuesOf(…)` and `getOldValuesOf(…)` work here. `getRecords()` returns the library's own list, not a copy.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/finalizer/works-with.md-->

## Gotchas {#gotchas}

- **Do not clear `getRecords()` in a Writer's Finalizer.** The list is the Writer's own list of qualified records. Emptied, it makes the Writer's own or private unit skip its commit, silently.
- **Direct DML bypasses the unit.** DML here runs at once: it is not merged with the registrations and costs its own statements.
- **Not once per statement.** It runs once per chunk of up to 200 records, so an aggregate across a larger statement is recomputed per chunk. The last chunk's query sees every earlier chunk's saved rows.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

For the example, call `writeOnAfterUpdate` first with the small recording class shown under [AfterUpdate.Writer](/after-update/writer#test), then `finalizeAfterUpdate`. Its aggregate query is inline SOQL, which a test cannot mock, so in a test without DML it returns no rows.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/finalizer/other-contexts.md-->

## See Also {#see-also}

- [Execution Order & Cost](/guide/execution-order)
- [Record Collections](/api/record-collections)
- [AfterUpdate.Writer](/after-update/writer#when-it-commits): when the registrations commit.
