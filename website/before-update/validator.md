---
template: role
context: BeforeUpdate
interface: Validator
description: Reject an update with a record-level or field-level error before it is saved, such as a forbidden transition or a cleared value.
---

# BeforeUpdate.Validator

Reject an update before it is saved, like a validation rule written in Apex.

**Signature**

<!--@include: @/_parts/generated/before-update/validator/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-update/validator/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-update/validator/OpportunityWinAmountValidator.cls [Error on a field]

<<< @/../examples/main/default/classes/account/before-update/validator/AccountDemotionValidator.cls [Block a transition]

:::

## Rules {#rules}

- **Gate on a change.** A Validator runs on every update, nested ones included, with no recursion limit. Without `isChanged`, a record that fails the check cannot be updated at all, not even by automation.
- **Name and address fields lose the field.** On them, `record.addError(field, message)` shows the message at record level. To keep it on the field, call `((Account) record.getNewSObject()).BillingCountry.addError(message)`.
- **Never call `addError` on `getOldSObject()`.** It throws a `FinalException` that nothing in the trigger can catch.
- **Populator wins.** A class that also implements `BeforeUpdate.Populator` runs only as a Populator.

::: warning
No DML. If the handler runs DML or publishes an event, the library throws.
:::

## Test {#test}

```apex
@IsTest
static void errorShouldBeAttachedOnBeforeUpdateWhenWonWithZeroAmount() {
    // Setup
    TriggerHandler.UpdateRecord record = new TriggerHandler.TriggerRecord(
        new Opportunity(StageName = 'Closed Won', Amount = 0),
        new Opportunity(StageName = 'Negotiation/Review')
    );

    // Test
    Boolean result = new OpportunityWinAmountValidator().errorShouldBeAttachedOnBeforeUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should be rejected.');
}
```
