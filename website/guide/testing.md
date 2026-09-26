---
description: Unit-test Trigger Lib handlers and orchestrators without DML - mock a trigger context with TriggerOrchestrator.mock(), run it with runTestFor, and mock parents, related records, the unit of work, the metadata and the Logger.
---

# Testing

Mock a trigger context with `TriggerOrchestrator.mock()`, then run a handler or an orchestrator in it with `TriggerOrchestrator.runTestFor(…)`. The whole pipeline runs, with no trigger and no DML.

## Test API {#test-api}

| Member | Does |
|---|---|
| `TriggerOrchestrator.mock().beforeInsertFor(X.class)`, and `afterInsertFor`, `beforeUpdateFor`, `afterUpdateFor`, `beforeDeleteFor`, `afterDeleteFor`, `afterUndeleteFor` | queues a trigger context for the handler or orchestrator class `X` |
| `.with(row)`, `.with(rows)` | sets the trigger rows; the update contexts take `.with(newRow, oldRow)` and `.with(newRows, oldRows)` |
| `.withParent(lookupField, parent)`, `.withParent(lookupField, parents)` | sets the parents the library's parent query returns |
| `TriggerOrchestrator.runTestFor(handlerOrOrchestrator)` | runs it in the next context queued for its class |
| `new TriggerTypes.RandomIdGenerator().get(SObjectType)` | builds a fake Id |

::: warning Test classes only
`mock()` and `runTestFor()` are `@TestVisible` private members of TriggerOrchestrator.
:::

## Test a Handler {#handler}

::: code-group

```apex [Populator]
@IsTest
static void populateOnBeforeInsertWithMixedCaseEmail() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe', Email = 'Jane.Doe@Example.com');

    TriggerOrchestrator.mock().beforeInsertFor(ContactEmailNormalizationPopulator.class).with(doe);

    // Test
    TriggerOrchestrator.runTestFor(new ContactEmailNormalizationPopulator());

    // Verify
    Assert.areEqual('jane.doe@example.com', doe.Email, 'The email should be lowercased.');
}
```

```apex [Validator]
@IsTest
static void addErrorOnBeforeInsertWithoutContactDetails() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe');

    TriggerOrchestrator.mock().beforeInsertFor(ContactReachabilityValidator.class).with(doe);

    // Test
    TriggerOrchestrator.runTestFor(new ContactReachabilityValidator());

    // Verify
    Assert.isTrue(doe.hasErrors(), 'The unreachable contact should be rejected.');
}
```

```apex [Update]
@IsTest
static void populateOnBeforeUpdateWithSmallAmount() {
    // Setup
    Opportunity renewal = new Opportunity(StageName = 'Prospecting', Amount = 4999);

    TriggerOrchestrator.mock().beforeUpdateFor(OpportunityForecastPopulator.class).with(renewal, new Opportunity(StageName = 'Prospecting', Amount = 10000));

    // Test
    TriggerOrchestrator.runTestFor(new OpportunityForecastPopulator());

    // Verify
    Assert.areEqual('Omitted', renewal.ForecastCategoryName, 'The forecast category should be omitted.');
}
```

:::

- **Assert on your own rows.** The handler gets the same instances, so the fields a Populator set and the errors a Validator added are on them after the run.
- **The predicate, the add-ons and the Finalizer run too.** A row the predicate rejects is skipped, as in a real save.
- **Mock the class you run.** `beforeInsertFor(X.class)` pairs with `runTestFor(new X())` by class name. Without a mock, `runTestFor` throws a `TriggerTypes.TriggerLibException`.
- **Rows get Ids where the context has them.** In after insert, after undelete and both delete contexts, a row without an Id gets a fake one. In the update contexts, the new and the old row share one Id. Objects without an `Id` field, such as platform events, keep their rows as they are.
- **Queue several contexts before the first run.** Each `runTestFor` takes the next context queued for the class, and the last one stays for every later call.

## Parents {#parents}

Pass the parents with `withParent`. The library's parent query returns them:

```apex
@IsTest
static void writeOnAfterInsertWithActiveAccountOwner() {
    // Setup
    User jane = new User(Id = new TriggerTypes.RandomIdGenerator().get(User.SObjectType), IsActive = true);
    Account acme = new Account(Id = new TriggerTypes.RandomIdGenerator().get(Account.SObjectType), OwnerId = jane.Id, Owner = jane);
    Contact doe = new Contact(LastName = 'Doe', AccountId = acme.Id);

    DML.mock('triggerUow').allDmls();

    TriggerOrchestrator.mock().afterInsertFor(ContactOwnerAlignmentWriter.class).with(doe).withParent(Contact.AccountId, acme);

    // Test
    TriggerOrchestrator.runTestFor(new ContactOwnerAlignmentWriter());

    // Verify
    Contact updated = (Contact) DML.retrieveResultFor('triggerUow').updatesOf(Contact.SObjectType).records()[0];
    Assert.areEqual(jane.Id, updated.OwnerId, 'The contact should get the account owner.');
}
```

- **Give each parent the Id the row's lookup holds.** Each row picks its own parent by that Id.
- **Nest a grandparent** inside the parent, as `Owner` above.
- **Pass the old parents too for a PriorParentQuery.** Set the lookup on the old row and pass both parents, such as `withParent(Account.OwnerId, new List<User>{ newOwner, oldOwner })`.
- **Parents of one type share one mock.** Each lookup still picks its parent by Id, so two lookups to Account work side by side.
- **No query reaches the org.** In after insert, after update and after undelete, parents are normally read through one query on the saved rows. `runTestFor` mocks that query too, so every parent comes from `withParent`.

## Related Records {#related}

`runTestFor` runs your RecordsProvider's `query` for real.

- **A provider written with SOQL Lib can be mocked.** Give its query a `mockId(…)` and call `SOQL.mock('<mock id>').thenReturn(rows)` before `runTestFor`.
- **An inline `[SELECT …]` cannot be mocked.** It reads the test's own data, which is empty unless the test inserts records.
- **Test `keyOf` on its own** with an in-memory row.

## Writers and Dispatchers {#writers}

Mock the shared unit of work, then read what the Writers registered:

```apex
@IsTest
static void writeOnAfterInsertWithCustomer() {
    // Setup
    Account acme = new Account(Name = 'Acme', Type = 'Customer - Direct');

    DML.mock('triggerUow').allDmls();

    TriggerOrchestrator.mock().afterInsertFor(AccountWelcomeTaskWriter.class).with(acme);

    // Test
    TriggerOrchestrator.runTestFor(new AccountWelcomeTaskWriter());

    // Verify
    Task onboardingCall = (Task) DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()[0];
    Assert.areEqual('Onboarding call - Acme', onboardingCall.Subject, 'The task should name the account.');
}
```

- **`DML.mock('triggerUow').allDmls()` replaces the commit.** It covers the shared unit of work and the one a ContinueOnError Writer gets. Read them with `DML.retrieveResultFor('triggerUow')`.
- **OwnUnitOfWork or a Dispatcher's DML.** Mock the identifier the handler gives its `DML` instance.
- **Dispatchers.** `Limits.getQueueableJobs()` counts the jobs a Dispatcher enqueued. The jobs run when the test method ends, so mock their callouts with `Test.setMock`.

## Run the Orchestrator {#orchestrator}

Mock the orchestrator's class to run all its handlers for that context, in order:

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

## Registration Tests {#registration}

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

## Mock the Metadata and the Logger {#mock-metadata}

Mock the bypass metadata and the Logger search before anything refers to `TriggerOrchestrator`, so before `TriggerOrchestrator.mock()`. Otherwise the org's deployed bypass records and its real Logger apply to your test:

```apex
SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
```

- **A metadata bypass.** Return `new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true)` instead of the empty list.
- **An Apex bypass.** Call `TriggerOrchestrator.bypass().handler(…)` or `.sObject(…)` before `runTestFor`. `.orchestrator(…)` does not apply under `runTestFor`.
- **A Logger.** Set `TriggerOrchestrator.triggerLogger.logger` to a class of your own that collects the errors. Use it to test ContinueOnError.

## Integration Tests {#integration}

Only a real save shows 200-record chunks and real nested triggers. Test those with DML, in separate test classes. Insert their data with `TriggerOrchestrator.bypass().sObject(…)` set.
