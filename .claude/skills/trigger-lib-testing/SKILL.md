---
name: trigger-lib-testing
description: Apex unit tests for Trigger Lib handlers and orchestrators that run the real handler pipeline with TriggerOrchestrator.mock() and TriggerOrchestrator.runTestFor(), with no trigger and no DML. Use when writing, fixing or reviewing @IsTest classes for Populator, Validator, Writer or Dispatcher classes or an <Object>TriggerOrchestrator, when mocking new and old trigger rows, parent records, RecordsProvider queries, the unit of work with DML.mock('triggerUow'), bypass metadata or the Logger, or when a trigger test inserts records only to fire the trigger, in a project that uses Trigger Lib (TriggerOrchestrator), from source or as the btcdev package. Not for production handler code (use trigger-lib-handler).
---

# Trigger Lib: Testing

Queue a mocked trigger context for a handler class with `TriggerOrchestrator.mock()`, then run an instance in it with `TriggerOrchestrator.runTestFor(...)`. The whole pipeline runs, with no trigger and no DML: bypasses, parent loading, providers, the predicate, the action, the Finalizer and the commit. Then assert on the rows you passed in, or on what the unit of work registered.

## Rules

1. Run the handler with `runTestFor`. Don't call `populateOn...`, `writeOn...` or the other methods directly: a direct call skips the library's part of the run, so a wrong lookup, a dropped `implements` or a missing parent field can pass the test and fail in production.
2. Queue the context for the class you run: `TriggerOrchestrator.mock().<ctx>For(X.class)` pairs with `runTestFor(new X())`. Without a queued context, `runTestFor` throws a `TriggerTypes.TriggerLibException`.
3. Build the rows in memory and never insert them. Pass them with `with(row)` or `with(rows)`, and with `with(newRow, oldRow)` in the update contexts. Use fake Ids from `new TriggerTypes.RandomIdGenerator().get(Account.SObjectType)` for lookups and parents.
4. In every Writer test, mock the unit the Writer commits through and read the result under the same identifier: `DML.mock('triggerUow').allDmls()` and `DML.retrieveResultFor('triggerUow')` for the shared unit and a ContinueOnError Writer's unit, or the identifier that its `ownUnitOfWorkOn<Ctx>()` sets.
5. Give parents with `withParent(lookupField, parent)`. Each parent carries the Id that the row's lookup holds.
6. Test one behaviour per method, including the records the predicate must skip. Name the method after the handler method it proves and the case, such as `populateOnBeforeInsertWithMixedCaseEmail`, `writeOnAfterInsertWithInactiveOwner` or `bypassOnAfterInsertWhenFlagIsSet`, and mark the parts with `// Setup`, `// Test` and `// Verify`.
7. Add `Test.startTest()` and `Test.stopTest()` only when the test needs fresh limits or must run async work.
8. If Trigger Lib is installed as the `btcdev` package (existing code calls `btcdev.TriggerOrchestrator`, or `sfdx-project.json` or `sf package installed list` shows the Trigger Lib package), prefix the library types and the custom metadata: `btcdev.TriggerOrchestrator.mock()`, `btcdev.TriggerTypes.RandomIdGenerator`, `btcdev.DML.mock('triggerUow')`, `btcdev.SOQL.mock(...)`, `btcdev__TriggerObject__mdt`, `btcdev__Bypass__c`. Keep the mock keys `'triggerUow'`, `'TriggerObject__mdt'`, `'TriggerHandler__mdt'` and `'ApexTypeImplementor'` unprefixed: they are text inside the package. Mock the library's queries and commit through `btcdev.SOQL` and `btcdev.DML` even when the project has its own `SOQL` or `DML` class, and mock a provider's query through the SOQL class the provider uses.

## Test API

| Member | Does |
|---|---|
| `TriggerOrchestrator.mock().beforeInsertFor(X.class)`, and `afterInsertFor`, `beforeUpdateFor`, `afterUpdateFor`, `beforeDeleteFor`, `afterDeleteFor`, `afterUndeleteFor` | Queues a trigger context for the handler or orchestrator class `X` |
| `.with(row)`, `.with(rows)` | Sets the trigger rows. The update contexts take `.with(newRow, oldRow)` and `.with(newRows, oldRows)`. The delete contexts take the old rows |
| `.withParent(lookupField, parent)`, `.withParent(lookupField, parents)` | Sets the parents that the library's parent query returns |
| `TriggerOrchestrator.runTestFor(handlerOrOrchestrator)` | Runs it in the next context queued for its class |
| `new TriggerTypes.RandomIdGenerator().get(SObjectType)` | Builds a fake Id |

- The handler gets your row instances, so the fields a Populator set and the errors a Validator added are on them after the run.
- Rows get Ids where the context has them. In after insert, after undelete and both delete contexts, a row without an Id gets a fake one, set on your own row object by `with(...)`, so `doe.Id` is usable right after that call. In the update contexts, the new and the old row share one Id.
- Fake Ids are random, so separate `RandomIdGenerator` calls don't collide.
- Queue every context before the first `runTestFor`. Each run takes the next context queued for the class, and the last one stays for every later run. Parents of one object type pile up in one shared queue, so when several queued contexts pass parents of the same type, give every context the same parents or split the test.

## Templates

These test the handlers from the `trigger-lib-handler` skill's examples.

**Populator in an update context**, with the old row second:

```apex
@IsTest
private class AccountHotRatingPopulatorTest {
    @IsTest
    static void populateOnBeforeUpdateWithRevenueRaisedToOneMillion() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 1000000);
        Account acmeBefore = new Account(Name = 'Acme', AnnualRevenue = 500000);

        TriggerOrchestrator.mock().beforeUpdateFor(AccountHotRatingPopulator.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.runTestFor(new AccountHotRatingPopulator());

        // Verify
        Assert.areEqual('Hot', acme.Rating, 'The rating should be Hot.');
    }

    @IsTest
    static void populateOnBeforeUpdateWithUnchangedRevenue() {
        // Setup
        Account acme = new Account(Name = 'Acme', AnnualRevenue = 2000000);
        Account acmeBefore = new Account(Name = 'Acme', AnnualRevenue = 2000000);

        TriggerOrchestrator.mock().beforeUpdateFor(AccountHotRatingPopulator.class).with(acme, acmeBefore);

        // Test
        TriggerOrchestrator.runTestFor(new AccountHotRatingPopulator());

        // Verify
        Assert.isNull(acme.Rating, 'The rating should not change.');
    }
}
```

**Validator:**

```apex
@IsTest
static void addErrorOnBeforeInsertWithBirthdateInFuture() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe', Birthdate = Date.today().addDays(1));

    TriggerOrchestrator.mock().beforeInsertFor(ContactBirthdateValidator.class).with(doe);

    // Test
    TriggerOrchestrator.runTestFor(new ContactBirthdateValidator());

    // Verify
    Assert.areEqual(new List<String>{ 'Birthdate' }, doe.getErrors()[0].getFields(), 'The error should be on Birthdate.');
}
```

Assert a rejection with `row.hasErrors()`, `row.getErrors()[0].getMessage()` or `getFields()`, and a skipped row with `Assert.isFalse(row.hasErrors(), ...)`.

**Handler with a parent and a grandparent:**

```apex
@IsTest
static void populateOnBeforeInsertWithAccount() {
    // Setup
    User jane = new User(Id = new TriggerTypes.RandomIdGenerator().get(User.SObjectType), Email = 'jane@example.com');
    Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme', OwnerId = jane.Id, Owner = jane);
    Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

    TriggerOrchestrator.mock().beforeInsertFor(ContactDescriptionPopulator.class).with(doe).withParent(Contact.AccountId, acme);

    // Test
    TriggerOrchestrator.runTestFor(new ContactDescriptionPopulator());

    // Verify
    Assert.areEqual('Acme, managed by jane@example.com', doe.Description, 'The description should name the account and its owner.');
}
```

**Writer**, with a mocked provider query and the unit of work mocked:

```apex
@IsTest
static void writeOnAfterUpdateWithFormerCustomer() {
    // Setup
    Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), Type = 'Former Customer');
    Account acmeBefore = new Account(Id = acme.Id, Type = 'Customer - Direct');
    Case openCase = new Case(Id = new TriggerTypes.RandomIdGenerator().get(Case.SObjectType), AccountId = acme.Id);

    SOQL.mock('AccountFormerCustomerCaseWriter.openCases').thenReturn(new List<Case>{ openCase });
    DML.mock('triggerUow').allDmls();

    TriggerOrchestrator.mock().afterUpdateFor(AccountFormerCustomerCaseWriter.class).with(acme, acmeBefore);

    // Test
    TriggerOrchestrator.runTestFor(new AccountFormerCustomerCaseWriter());

    // Verify
    Case closedCase = (Case) DML.retrieveResultFor('triggerUow').updatesOf(Case.SObjectType).records()[0];
    Assert.areEqual('Closed', closedCase.Status, 'The open case should be closed.');
}
```

For a skipped record, assert that nothing was registered: `Assert.areEqual(0, DML.retrieveResultFor('triggerUow').updatesOf(Case.SObjectType).records().size(), 'No case should be updated.');`. The result also has `insertsOf`, `upsertsOf`, `deletesOf` and `eventsOf`. `records()` returns a `List<SObject>` in registration order, and an empty list when nothing was registered, also when the handler was bypassed.

**Dispatcher:**

```apex
@IsTest
static void dispatchOnAfterInsertWithEmail() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe', Email = 'jane.doe@example.com');

    TriggerOrchestrator.mock().afterInsertFor(ContactSyncDispatcher.class).with(doe);

    // Test
    TriggerOrchestrator.runTestFor(new ContactSyncDispatcher());

    // Verify
    Assert.areEqual(1, Limits.getQueueableJobs(), 'One job should be enqueued for the chunk.');
}
```

An enqueued job runs when the test method ends, so mock its callouts with `Test.setMock(...)`. Test the job itself in its own test class.

## Parents

- Give each parent the Id that the row's lookup holds. Each row picks its own parent by that Id, and a parent without a match is never read.
- Nest a grandparent inside the parent, as `Owner = jane` above, when the handler declares `with('Owner', User.Email)`.
- For a PriorParentQuery, set the lookup on the old row too, and pass both parents: `withParent(Account.OwnerId, new List<User>{ newOwner, oldOwner })`.
- Parents of one object type share one mock, so two lookups to Account work side by side.
- No query reaches the org: `runTestFor` mocks the parent query, including the one query on the trigger records that after insert, after update and after undelete normally run.
- Set only the parent fields the handler declares, so the test matches what the real query returns.

## Related records

`runTestFor` runs a RecordsProvider's `query` for real.

- A provider written with SOQL Lib can be mocked. Give its query a `mockId(...)`, then call `SOQL.mock('<mock id>').thenReturn(rows)` before `runTestFor`. A `mockId` replaces the default key, so `SOQL.mock(Case.SObjectType)` doesn't reach that query.
- An inline `[SELECT ...]` can't be mocked. It reads the test's own data, which is empty unless the test inserts records. Rewrite the provider with SOQL Lib, or cover it with an integration test.
- Set the key field on every mocked row, because `keyOf` reads it.

```apex
SOQL.mock('AccountFormerCustomerCaseWriter.openCases').thenReturn(new List<Case>{ new Case(Id = caseId, AccountId = acme.Id) });
```

## Units of work

- `DML.mock('triggerUow').allDmls()` replaces the commit of the shared unit of work and of the automatic unit a ContinueOnError Writer gets. Read both with `DML.retrieveResultFor('triggerUow')`.
- A Writer with OwnUnitOfWork commits under the identifier its `ownUnitOfWorkOn<Ctx>()` gives `DML`, such as `DML.mock('OpportunityLossReviewWriter').allDmls()`. A Dispatcher that writes through DML Lib works the same way, with the identifier it gives its `DML` instance.
- `Limits.getQueueableJobs()` counts the jobs a Dispatcher enqueued.

## Orchestrators and registration

Mock the orchestrator's class to run all its handlers of a context, in order:

```apex
@IsTest
static void beforeInsertHandlersCopyBillingAddress() {
    // Setup
    Account acme = new Account(Name = 'Acme', BillingCity = 'Berlin', BillingCountry = 'Germany');

    TriggerOrchestrator.mock().beforeInsertFor(AccountTriggerOrchestrator.class).with(acme);

    // Test
    TriggerOrchestrator.runTestFor(new AccountTriggerOrchestrator());

    // Verify
    Assert.areEqual('Berlin', acme.ShippingCity, 'The populator should copy the billing city.');
}
```

A handler missing from the orchestrator never runs. Test the list:

```apex
@IsTest
static void afterInsertHandlersContainsWelcomeTaskWriter() {
    // Test
    List<AfterInsert.Handler> handlers = new AccountTriggerOrchestrator().afterInsertHandlers();

    // Verify
    Assert.isInstanceOfType(handlers[0], AccountWelcomeTaskWriter.class, 'The welcome task writer should run first.');
}
```

A trigger that calls `runFromMetadata()` has no orchestrator to run. Test its handlers one by one, and test that every deployed `TriggerHandler__mdt` record names a class that exists, can be created with no arguments and implements the `Handler` of the context whose field the record fills:

```apex
@IsTest
static void handlerRecordsResolve() {
    // Setup
    List<String> brokenClasses = new List<String>();

    // Test
    for (TriggerHandler__mdt handlerRecord : [
        SELECT ApexClassName__c, BeforeInsert__c, AfterInsert__c, BeforeUpdate__c, AfterUpdate__c, BeforeDelete__c, AfterDelete__c, AfterUndelete__c
        FROM TriggerHandler__mdt
    ]) {
        Object handler = Type.forName(handlerRecord.ApexClassName__c.trim())?.newInstance();

        if (
            (handlerRecord.BeforeInsert__c != null && !(handler instanceof BeforeInsert.Handler)) ||
            (handlerRecord.AfterInsert__c != null && !(handler instanceof AfterInsert.Handler)) ||
            (handlerRecord.BeforeUpdate__c != null && !(handler instanceof BeforeUpdate.Handler)) ||
            (handlerRecord.AfterUpdate__c != null && !(handler instanceof AfterUpdate.Handler)) ||
            (handlerRecord.BeforeDelete__c != null && !(handler instanceof BeforeDelete.Handler)) ||
            (handlerRecord.AfterDelete__c != null && !(handler instanceof AfterDelete.Handler)) ||
            (handlerRecord.AfterUndelete__c != null && !(handler instanceof AfterUndelete.Handler))
        ) {
            brokenClasses.add(handlerRecord.ApexClassName__c);
        }
    }

    // Verify
    Assert.areEqual(new List<String>(), brokenClasses, 'Every registered class should implement the context its record names.');
}
```

A class without a public no-argument constructor makes `newInstance()` throw, which fails the test as well.

## Bypasses, metadata and the Logger

Tests see the org's `TriggerObject__mdt` and `TriggerHandler__mdt` records and its real Logger. The templates leave that alone. Add both mocks as the first lines of a test when its result must not depend on the org, such as a test of a bypass, a CI org, or an org whose Logger has side effects. They must come before anything refers to `TriggerOrchestrator`, so before `TriggerOrchestrator.mock()`:

```apex
SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
```

The handler records come from a second query, `'TriggerHandler__mdt'`. Each is attached to the object record whose Id its context field holds, and the org's records can't hold a mocked record's Id, so the `'TriggerObject__mdt'` mock above keeps them out of the test too. Mock `'TriggerHandler__mdt'` only when the test wants handler records. Each mocked row is a plain constructor with the object record's fake Id in its one context field, one row per context, and the list order is the run order:

```apex
TriggerObject__mdt accountSetting = new TriggerObject__mdt(Id = new TriggerTypes.RandomIdGenerator().get(TriggerObject__mdt.SObjectType), ObjectAPIName__c = 'Account', Bypass__c = false);

SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ accountSetting });
SOQL.mock('TriggerHandler__mdt').thenReturn(new List<TriggerHandler__mdt>{ new TriggerHandler__mdt(ApexClassName__c = 'AccountHotRatingPopulator', Bypass__c = true, BeforeUpdate__c = accountSetting.Id) });
SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
```

With the `btcdev` package, the mock keys stay the same and the types and fields get the prefix: `btcdev.SOQL.mock('TriggerObject__mdt').thenReturn(new List<btcdev__TriggerObject__mdt>());`, `btcdev__TriggerHandler__mdt`, `btcdev__BeforeUpdate__c`.

- To test an object bypass, return `new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true)` instead of the empty list.
- To test a handler bypass, return a `TriggerHandler__mdt` row with `Bypass__c = true`, as above. It switches its class off only in the context whose field holds the object record's Id, and a row that holds no mocked Id is ignored.
- A mock ignores `WHERE` and `ORDER BY`, so a save in an integration test of a `runFromMetadata()` trigger runs the mocked rows in list order, whatever their `Order__c`.
- To test an Apex bypass, call `TriggerOrchestrator.bypass().handler(X.class)` or `.sObject(...)` before `runTestFor`. `.orchestrator(...)` has no effect under `runTestFor`.
- To test a Bypassable that reads a static flag, set the flag in `// Setup` and assert that nothing happened.
- To test ContinueOnError, set `TriggerOrchestrator.triggerLogger.logger` to a test class of your own that collects the errors. This works only when the Trigger Lib source is in the project: in the `btcdev` package that member isn't visible to your tests.

## What a mocked run doesn't catch

A mocked run is close to a save, but not the same:

- The rows are your own writable objects in every context. A `put` in after insert or after update passes the test and throws an uncatchable `FinalException` in a real save.
- The SOQL and DML guards count real queries and statements. A query or DML in a predicate or an action that `SOQL.mock` or `DML.mock` answers passes the test and throws a `TriggerLibException` in a real save.
- No trigger fires, so the platform's own validation, other automation and real nested saves don't run.

The integration test below covers these.

## Integration tests

Only a real save shows chunking, nested triggers and the platform's own validation. Test those with DML, in separate test classes. Insert their setup data with `TriggerOrchestrator.bypass().sObject(...)` set, and `clear()` it before the DML under test.

Mocked tests never fire the trigger itself, and a production deployment fails while a trigger has no test coverage. So for every new trigger, keep at least one test that saves a record of its object with DML, such as `<Object>TriggerTest`.

Name each unit test class `<Handler>Test` and keep it next to the handler, unless the project's tests live elsewhere.

## Common mistakes

| Symptom | Cause | Fix |
|---|---|---|
| `runTestFor` throws a TriggerLibException that names the class | No context is queued for that class | `TriggerOrchestrator.mock().<ctx>For(X.class)` before the run, with the class you run |
| A later `runTestFor` repeats the first context | The last queued context stays | Queue every context before the first run |
| The handler reads a `null` parent | The parent's Id doesn't match the row's lookup, or `withParent` is missing | Give the lookup and the parent the same fake Id |
| A parent field reads `null` in the test, or the test passes and the real save throws an `SObjectException` | The ParentQuery doesn't declare that field. The mock drops undeclared fields, but when the lookup also declares a grandparent field it returns the parent exactly as the test built it | Add the field to the ParentQuery, and set only declared fields on test parents |
| A Writer test fails in the commit | The unit of work isn't mocked, so real DML runs with fake Ids | `DML.mock('triggerUow').allDmls()` |
| `retrieveResultFor('triggerUow')` misses an OwnUnitOfWork Writer's records | It commits under its own identifier | Mock and read that identifier |
| Provider rows never arrive | The provider uses inline SOQL, or the mock key differs from its `mockId` | SOQL Lib with `mockId`, and `SOQL.mock('<mock id>')` |
| A handler is skipped in one org and runs in another | The org's `TriggerObject__mdt` and `TriggerHandler__mdt` records apply to tests | Mock `'TriggerObject__mdt'` before the first reference to `TriggerOrchestrator`. The org's handler records can't point at a mocked object record |
| A mocked `TriggerHandler__mdt` row has no effect | Its context field doesn't hold the mocked object record's Id | Set a fake Id on the object record and put it in the row's context field, one row per context |
| `bypass().orchestrator(...)` has no effect | It doesn't apply under `runTestFor` | `bypass().handler(...)` or `sObject(...)` |
| The test fails after the last line with a callout error | A job the Dispatcher enqueued runs when the test ends | `Test.setMock(...)` for the callout |
| A test inserts records to fire the trigger | Old trigger testing habit | Queue the context with `mock()` and run with `runTestFor`. Keep DML for integration tests |
