---
description: Tutorial that wires a Contact trigger and orchestrator, adds a before insert Populator and Validator, tries them in anonymous Apex, and unit-tests them without DML.
---

# Your First Handler

In this tutorial you lowercase Contact emails and reject impossible birthdates when contacts are inserted. You add one trigger, one orchestrator, a Populator and a Validator, try them in anonymous Apex, and test them with two unit tests that run no DML.

Before you start, [install Trigger Lib](/installation) in a scratch org or sandbox.

## 1. Add the Trigger {#trigger}

Each object gets one trigger, and its body is one line that hands the work to an orchestrator:

<<< @/../examples/main/default/triggers/ContactTrigger.trigger

List all seven events now. A context the orchestrator does not implement returns before any handler code runs, so you can add handlers later without touching the trigger. More in [Trigger & Orchestrator](/guide/orchestrator#trigger).

## 2. Add the Orchestrator {#orchestrator}

The orchestrator says which handlers run in each context, and in which order. For before insert, it implements `TriggerOrchestrator.BeforeInsert` and returns the handlers from `beforeInsertHandlers()`:

```apex
public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{ new ContactEmailNormalizationPopulator(), new ContactBirthdateValidator() };
    }
}
```

List order is run order. Put Populators before Validators, so the Validators check the values the Populators have set.

If you deployed the examples, `ContactTriggerOrchestrator` already exists and registers these two handlers among others:

::: details The example orchestrator

<<< @/../examples/main/default/classes/contact/ContactTriggerOrchestrator.cls

:::

## 3. Write a Populator {#populator}

A Populator changes the record being saved. It has two methods: a predicate that picks the records, and an action that changes them.

<<< @/../examples/main/default/classes/contact/before-insert/populator/ContactEmailNormalizationPopulator.cls

- `populateOnBeforeInsertWhen` runs for each record. When it returns true, `populateOnBeforeInsert` runs for that record right away.
- `record.put(field, value)` sets the field on the row being saved. There is no DML and nothing to commit: the platform saves the value with the record.
- The record is a `TriggerHandler.InsertRecord`. Besides `put`, it has null-safe predicates such as `isBlank`, `equals` and `startsWith`: see [Record API in BeforeInsert](/before-insert/record-api).

More in [BeforeInsert.Populator](/before-insert/populator).

## 4. Write a Validator {#validator}

A Validator rejects records. Its predicate decides which records are invalid, and its error method attaches the error:

<<< @/../examples/main/default/classes/contact/before-insert/validator/ContactBirthdateValidator.cls

- `record.addError(message)` attaches a record-level error, and `record.addError(field, message)` attaches it to a field, as here.
- When `errorShouldBeAttachedOnBeforeInsertWhen` returns true, `addErrorOnBeforeInsert` must attach an error. If it attaches none, the library throws and the save fails.
- A Validator should not change the record: its error method receives a `RejectableInsertRecord`, which has no `put`. The predicate receives an `InsertRecord`, where `put` compiles, but keep writes in Populators.

On Name and address fields, the field form loses the field attribution. More in [BeforeInsert.Validator](/before-insert/validator#gotchas).

## 5. Try It {#try-it}

Run this in anonymous Apex:

```apex
Contact jane = new Contact(LastName = 'Doe', Email = 'Jane.Doe@Example.COM');
insert jane;
System.debug([SELECT Email FROM Contact WHERE Id = :jane.Id].Email);
```

The debug log shows `jane.doe@example.com`: the Populator lowercased the email before the save. Now insert a contact born tomorrow:

```apex
insert new Contact(LastName = 'Roe', Email = 'rick.roe@example.com', Birthdate = Date.today().addDays(1));
```

The insert fails with a `DmlException`. Its message carries the Validator's text, attached to the Birthdate field, and nothing is saved.

## 6. Test It {#test}

Handlers are plain classes, so you test them by calling their methods with rows built in memory: no trigger, no DML. Wrap a row in `new TriggerHandler.TriggerRecord(newRow, oldRow)` and pass `null` for the side the context does not have, which on insert is the old row.

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

Test the predicates the same way: call `populateOnBeforeInsertWhen` or `errorShouldBeAttachedOnBeforeInsertWhen` with an in-memory row and assert the Boolean. When a test needs an Id, use `new TriggerHandler.RandomIdGenerator().get(Contact.SObjectType)`.

To check that the orchestrator registers a handler, or to run the whole orchestrator in a test, see [Testing](/guide/testing#registration).

## Next Steps {#next-steps}

- Read Account fields from the contact's lookup: [BeforeInsert.ParentQuery](/before-insert/add-ons/parent-query).
- Create or update other records after the save: [AfterInsert.Writer](/after-insert/writer).
- See every context, role and method name: [Contexts at a Glance](/contexts).
- Find the page for a task: [How do I…](/how-do-i).
