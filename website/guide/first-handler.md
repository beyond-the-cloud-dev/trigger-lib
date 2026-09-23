---
description: Tutorial that wires a Contact trigger and orchestrator, adds a before insert Populator and Validator, tries them in anonymous Apex, and unit-tests them without DML.
---

# Your First Handler

In this tutorial you lowercase Contact emails and reject impossible birthdates on insert. You add a trigger, an orchestrator, a Populator and a Validator, then test them without DML.

First, [install Trigger Lib](/installation) in a scratch org or sandbox.

## 1. Add the Trigger {#trigger}

Each object gets one trigger with a one-line body:

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

List all seven events now. A context the orchestrator does not implement does nothing, so you can add handlers later without touching the trigger.

## 2. Add the Orchestrator {#orchestrator}

The orchestrator lists the handlers of each context in run order. For before insert, implement `TriggerOrchestrator.BeforeInsert` and return the handlers from `beforeInsertHandlers()`:

```apex
public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{ new ContactEmailNormalizationPopulator(), new ContactBirthdateValidator() };
    }
}
```

List Populators before Validators, so the Validators check the values the Populators set.

## 3. Write a Populator {#populator}

A Populator changes the record being saved. Its predicate picks the records, and its action changes them:

<<< @/../examples/main/default/classes/contact/before-insert/populator/ContactEmailNormalizationPopulator.cls

- `populateOnBeforeInsertWhen` runs for each record. When it returns true, `populateOnBeforeInsert` runs for that record.
- `record.put(field, value)` sets the field on the row being saved. No DML is needed.

See [BeforeInsert.Populator](/before-insert/populator) and the [Record API](/before-insert/record-api).

## 4. Write a Validator {#validator}

A Validator rejects records. Its predicate finds the invalid records, and its error method attaches the error:

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactBirthdateValidator.cls

- `record.addError(message)` attaches a record error. `record.addError(field, message)` attaches it to a field.
- When the predicate returns true, `addErrorOnBeforeInsert` must attach an error. Otherwise the library throws and the save fails.

See [BeforeInsert.Validator](/before-insert/validator).

## 5. Try It {#try-it}

Run this in anonymous Apex:

```apex
Contact jane = new Contact(LastName = 'Doe', Email = 'Jane.Doe@Example.COM');
insert jane;
System.debug([SELECT Email FROM Contact WHERE Id = :jane.Id].Email);
```

The log shows `jane.doe@example.com`. Now insert a contact born tomorrow:

```apex
insert new Contact(LastName = 'Roe', Email = 'rick.roe@example.com', Birthdate = Date.today().addDays(1));
```

The insert fails with a `DmlException` that carries the Validator's message.

## 6. Test It {#test}

Handlers are plain classes. Call their methods with rows built in memory: no trigger, no DML. Wrap a row in `new TriggerHandler.TriggerRecord(newRow, oldRow)`, with `null` for the old row on insert.

::: code-group

```apex [ContactEmailNormalizationPopulatorTest.cls]
@IsTest
private class ContactEmailNormalizationPopulatorTest {
    @IsTest
    static void populateOnBeforeInsertWithMixedCaseEmail() {
        // Setup
        Contact newContact = new Contact(LastName = 'Doe', Email = 'Jane.Doe@Example.COM');

        // Test
        new ContactEmailNormalizationPopulator().populateOnBeforeInsert(new TriggerHandler.TriggerRecord(newContact, null));

        // Verify
        Assert.areEqual('jane.doe@example.com', newContact.Email, 'The email should be lowercase.');
    }
}
```

```apex [ContactBirthdateValidatorTest.cls]
@IsTest
private class ContactBirthdateValidatorTest {
    @IsTest
    static void addErrorOnBeforeInsertOnBirthdate() {
        // Setup
        Contact newContact = new Contact(LastName = 'Doe', Birthdate = Date.today().addDays(1));

        // Test
        new ContactBirthdateValidator().addErrorOnBeforeInsert(new TriggerHandler.TriggerRecord(newContact, null));

        // Verify
        Assert.areEqual(new List<String>{ 'Birthdate' }, newContact.getErrors()[0].getFields(), 'The error should be on Birthdate.');
    }
}
```

:::

Test the predicates the same way and assert the Boolean. More in [Testing](/guide/testing).

## Next Steps {#next-steps}

- Read Account fields from the contact: [BeforeInsert.ParentQuery](/before-insert/add-ons/parent-query).
- Change other records after the save: [AfterInsert.Writer](/after-insert/writer).
