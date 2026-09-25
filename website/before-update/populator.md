---
template: role
context: BeforeUpdate
interface: Populator
description: Set, derive or clear fields on records being updated, usually when another field changed - no DML and no second save.
---

# BeforeUpdate.Populator

Set fields on records being updated before they are saved.

**Signature**

<!--@include: @/_parts/generated/before-update/populator/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/populator/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/populator/OpportunityForecastPopulator.cls [Set on change]

<<< @/../examples/main/default/classes/account/before-update/populator/AccountShippingSyncPopulator.cls [Read the old row]

:::

## Rules {#rules}

- **`put` counts as a change.** Handlers listed later see the value, and `isChanged` is true for them. Putting the old value back makes the field unchanged.
- **Gate on a change.** The Populator runs again when the same records are updated again in the transaction. There, `isChanged` compares with the values the previous update saved. The default limit is 3 passes per record; change it with a [RecursionGuard](/before-update/add-ons/recursion-guard).
- **Never write to `getOldSObject()`.** The `FinalException` cannot be caught and fails the update.
- **Populator wins.** A class that also implements `BeforeUpdate.Validator` runs only as a Populator.

::: warning
No DML. If the handler runs DML or publishes an event, the library throws. Change other records from an [AfterUpdate.Writer](/after-update/writer).
:::

## Test {#test}

```apex
@IsTest
static void populateOnBeforeUpdateWithSmallAmount() {
    // Setup
    Opportunity renewal = new Opportunity(StageName = 'Prospecting', Amount = 4000);

    TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Amount = 9000));

    // Test
    TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

    // Verify
    Assert.areEqual('Omitted', renewal.ForecastCategoryName, 'The forecast category should be Omitted.');
}
```
