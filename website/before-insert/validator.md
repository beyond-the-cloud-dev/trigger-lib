---
template: role
context: BeforeInsert
interface: Validator
description: Reject records before insert with a record-level or field-level error message, like a validation rule written in Apex.
---

# BeforeInsert.Validator

Rejects new records before they are saved, with an error on the record or on a field. It works like a validation rule written in Apex.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/validator/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/validator/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/before-insert/validator/OpportunityAmountValidator.cls [Field error]

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactEmailFormatValidator.cls [Two messages]

:::

## Good to Know {#good-to-know}

- **Every branch must add an error.** If the error method returns without one, the library throws and the whole chunk fails, even with [ContinueOnError](/before-insert/add-ons/continue-on-error).
- **Errors add up.** `addError` does not stop the run. Later handlers still run for the record, and each Validator that rejects it adds its own message.
- **Name and address fields lose the field.** On `Name` or a compound address field such as `BillingCity`, `record.addError(field, message)` shows the message at record level. Use `((Account) record.getNewSObject()).Name.addError(message)` instead.
- **Populator wins.** A class that also implements `BeforeInsert.Populator` runs only as a Populator. List Validators after the Populators, so they check the final values.
- **No DML.** If the handler runs DML or publishes an event, the library throws.

## Test {#test}

```apex
@IsTest
static void addErrorOnBeforeInsertAttachesErrorToAmount() {
    // Setup
    Opportunity newOpportunity = new Opportunity(Amount = -100);

    // Test
    new OpportunityAmountValidator().addErrorOnBeforeInsert(new TriggerHandler.TriggerRecord(newOpportunity, null));

    // Verify
    Assert.areEqual(new List<String>{ 'Amount' }, newOpportunity.getErrors()[0].getFields(), 'The error should be attached to Amount.');
}
```
