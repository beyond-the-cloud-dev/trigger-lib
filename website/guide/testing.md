---
description: Unit-test Trigger Lib handlers without DML - TriggerRecord, the record collections, ProvidedRecords and RandomIdGenerator, a recording unit of work, registration tests, and running the whole orchestrator with mocked metadata, Logger, SOQL and DML.
---

# Testing

Test a handler without DML: build records in memory, call its methods and assert the result.

## Test API {#test-api}

| Member | Gives you |
|---|---|
| `new TriggerHandler.TriggerRecord(newRow, oldRow)` | a record of any type; pass `null` for the side the context lacks |
| `new TriggerHandler.InsertTriggerRecords(records)`, and the `Update`, `Delete` and `Undelete` variants | the collection a Finalizer, dispatch or `query` receives |
| `new TriggerHandler.ProvidedRecords(rows)` with `groupUnderKey(key, row)` | provider results |
| `new TriggerHandler.RandomIdGenerator().get(SObjectType)` | a fake Id |
| `record.enrichNew(relationshipName, parent)`, `record.enrichOld(…)` | what `getNewParent` and `getOldParent` return |
| `record.setProvidedRecords(providers)` | what `getRelated` returns |

`enrichNew`, `enrichOld` and `setProvidedRecords` are marked internal use only and may change.

## Predicates and Actions {#handler}

::: code-group

```apex [Populator]
@IsTest
static void populateOnBeforeInsertCopiesBillingCity() {
    // Setup
    Account acme = new Account(Name = 'Acme', BillingCity = 'Berlin', BillingCountry = 'Germany');

    // Test
    new AccountShippingAddressPopulator().populateOnBeforeInsert(new TriggerHandler.TriggerRecord(acme, null));

    // Verify
    Assert.areEqual('Berlin', acme.ShippingCity, 'The shipping city should be copied.');
}
```

```apex [Validator]
@IsTest
static void addErrorOnBeforeInsertWhenUnreachable() {
    // Setup
    Contact doe = new Contact(LastName = 'Doe');

    // Test
    new ContactReachabilityValidator().addErrorOnBeforeInsert(new TriggerHandler.TriggerRecord(doe, null));

    // Verify
    Assert.isTrue(doe.hasErrors(), 'The contact should be rejected.');
}
```

```apex [Predicate]
@IsTest
static void errorShouldBeAttachedOnBeforeInsertWhenNoPhoneOrEmail() {
    // Setup
    TriggerHandler.InsertRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);

    // Test
    Boolean result = new ContactReachabilityValidator().errorShouldBeAttachedOnBeforeInsertWhen(record);

    // Verify
    Assert.isTrue(result, 'A contact without email or phone should qualify.');
}
```

:::

In the update contexts, pass both rows so change detection has something to compare.

## Writers {#writers}

Pass the action a small class of your own that implements `TriggerHandler.UnitOfWork` and keeps what it receives. It never commits:

```apex
@IsTest
static void writeOnAfterInsertAlignsOwner() {
    // Setup
    Id ownerId = new TriggerHandler.RandomIdGenerator().get(User.SObjectType);
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(Id = new TriggerHandler.RandomIdGenerator().get(Contact.SObjectType)), null);
    record.enrichNew('Account', new Account(OwnerId = ownerId));
    RecordingUnitOfWork unitOfWork = new RecordingUnitOfWork();

    // Test
    new ContactOwnerAlignmentWriter().writeOnAfterInsert(record, unitOfWork);

    // Verify
    Assert.areEqual(ownerId, ((Contact) unitOfWork.updated[0]).OwnerId, 'The contact should get the account owner.');
}
```

::: details The recording unit of work

```apex
private class RecordingUnitOfWork implements TriggerHandler.UnitOfWork {
    public List<SObject> inserted = new List<SObject>();
    public List<SObject> updated = new List<SObject>();

    public TriggerHandler.UnitOfWork toInsert(SObject record) {
        this.inserted.add(record);
        return this;
    }

    public TriggerHandler.UnitOfWork toUpdate(SObject record) {
        this.updated.add(record);
        return this;
    }

    public TriggerHandler.UnitOfWork toInsert(DML.Record record) { return this; }
    public TriggerHandler.UnitOfWork toUpdate(DML.Record record) { return this; }
    public TriggerHandler.UnitOfWork toUpsert(SObject record, SObjectField externalIdField) { return this; }
    public TriggerHandler.UnitOfWork toDelete(SObject record) { return this; }
    public TriggerHandler.UnitOfWork toPublish(SObject event) { return this; }
}
```

:::

## Parents and Related Records {#parents}

Attach them yourself. Nothing is queried:

```apex
record.enrichNew('Account', new Account(Name = 'Acme', Owner = new User(IsActive = true)));

Account existing = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
TriggerHandler.ProvidedRecords provided = new TriggerHandler.ProvidedRecords(new List<SObject>{ existing });
provided.groupUnderKey('acme', existing);
record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ '<provider name>' => provided });
```

- **Nest a grandparent** inside the parent, as `Owner` above.
- **Group each row under the key your `keyOf` returns.** Test `keyOf` on its own with an in-memory row.

## Finalizers and Dispatchers {#finalizers}

Call `finalize<Ctx>` or `dispatchOn<Ctx>` directly with the records your predicate would qualify:

```apex
List<TriggerHandler.TriggerRecord> qualified = new List<TriggerHandler.TriggerRecord>{ new TriggerHandler.TriggerRecord(newRow, oldRow) };

new <YourHandler>().finalize<Ctx>(new TriggerHandler.<X>TriggerRecords(qualified));
```

`<X>` is `Insert`, `Update`, `Delete` or `Undelete`. `Limits.getQueueableJobs()` counts the jobs a Dispatcher enqueued.

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

## Run the Orchestrator in a Test {#orchestrator}

::: warning Private API
`new TriggerOrchestrator(…)`, `context` and `run()` are `@TestVisible` private members and may change.
:::

Set the trigger context on a `new TriggerOrchestrator(…)` and call `run()`. Use typed lists, and give every row an Id in after and delete contexts:

```apex
static void mockFramework() {
    SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>());
    SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
}

static TriggerOrchestrator runFor(System.TriggerOperation operation, List<SObject> newRecords, List<SObject> oldRecords) {
    TriggerOrchestrator orchestrator = new TriggerOrchestrator(new AccountTriggerOrchestrator());
    orchestrator.context.triggerOperation = operation;
    orchestrator.context.newRecords = newRecords;
    orchestrator.context.oldRecords = oldRecords;
    return orchestrator;
}

@IsTest
static void beforeInsertHandlersCopyBillingAddress() {
    // Setup
    mockFramework();
    Account acme = new Account(Name = 'Acme', BillingCity = 'Berlin', BillingCountry = 'Germany');

    // Test
    runFor(System.TriggerOperation.BEFORE_INSERT, new List<Account>{ acme }, null).run();

    // Verify
    Assert.areEqual('Berlin', acme.ShippingCity, 'The populator should copy the billing city.');
}
```

### Mock the Metadata and the Logger {#mock-metadata}

Call `mockFramework()` first, before anything refers to `TriggerOrchestrator`. Otherwise the org's deployed bypass records and its real Logger apply to your test.

- **A metadata bypass.** Return `new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true)` instead of the empty list.
- **An Apex bypass.** Call `TriggerOrchestrator.bypass()` after the mocks and before `run()`.
- **A Logger.** Set `TriggerOrchestrator.triggerLogger.logger` to a class of your own that collects the errors. Use it to test ContinueOnError.

### Mock Queries and DML {#mock-queries-dml}

- **Parents.** `SOQL.mock(Account.SObjectType).thenReturn(rows)` serves the parent queries on Account. In after insert, update and undelete, mock the trigger object instead and return its rows with the parent attached.
- **Providers.** Only a provider written with SOQL Lib can be mocked. An inline `[SELECT …]` cannot.
- **The default unit of work.** `DML.mock('triggerUow').allDmls()` replaces its commit. Read it with `DML.retrieveResultFor('triggerUow')`.
- **OwnUnitOfWork or a Dispatcher's DML.** Mock the identifier the handler gives its `DML` instance.

## Integration Tests {#integration}

Only a real save shows 200-record chunks and real nested triggers. Test those with DML, in separate test classes. Insert their data with `TriggerOrchestrator.bypass().sObject(…)` set.
