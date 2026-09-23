---
template: role
context: BeforeInsert
interface: Populator
description: Set, default or normalize fields on records before insert with record.put - no DML and no second save.
---

# BeforeInsert.Populator

Sets fields on new records before they are saved. The values save with the record: no DML and no second save.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/populator/signature.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/populator/skeleton.md-->

<<< @/../examples/main/default/classes/contact/before-insert/populator/ContactEmailNormalizationPopulator.cls [Normalize]

<<< @/../examples/main/default/classes/opportunity/before-insert/populator/OpportunityCloseDatePopulator.cls [Default when blank]

:::

## Good to Know {#good-to-know}

- **`put` writes to the row being saved.** Handlers listed later see the value.
- **No SOQL in the loop.** The predicate and the action run once per record. Read parents with a [ParentQuery](/before-insert/add-ons/parent-query) and other records with a [RelatedQuery](/before-insert/add-ons/related-query).
- **No DML.** If the handler runs DML or publishes an event, the library throws. Change other records from an [AfterInsert.Writer](/after-insert/writer).
- **Populator wins.** A class that also implements `BeforeInsert.Validator` runs only as a Populator.
- **Exceptions fail the save.** Without [ContinueOnError](/before-insert/add-ons/continue-on-error), an exception fails every record in the chunk. With it, the exception is logged and the save goes on.

## Test {#test}

```apex
@IsTest
static void populateOnBeforeInsertLowercasesEmail() {
    // Setup
    Contact newContact = new Contact(Email = ' Jane.Doe@Example.com ');

    // Test
    new ContactEmailNormalizationPopulator().populateOnBeforeInsert(new TriggerHandler.TriggerRecord(newContact, null));

    // Verify
    Assert.areEqual('jane.doe@example.com', newContact.Email, 'The email should be trimmed and lowercased.');
}
```
