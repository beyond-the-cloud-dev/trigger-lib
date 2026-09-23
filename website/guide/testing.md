---
description: Unit-test Trigger Lib handlers without DML - TriggerRecord, the record collections, ProvidedRecords and RandomIdGenerator, a purpose-built unit of work, registration tests, running the whole orchestrator with mocked metadata, Logger, SOQL and DML (same namespace only), and what needs real integration tests.
---

# Testing

Unit-test a handler without DML (mock, stub, fake Ids): build the trigger records in memory, call the handler's methods directly, and check the result. To test the whole run, with bypasses, parents and the shared unit of work, drive the orchestrator in a test, which works in the library's namespace only.

## Test Style {#style}

The examples on this site follow one style:

- **One thing per test, one assertion.** About ten lines, with the expected value as a literal and a short, generic assertion message.
- **Named after the API member plus a variant,** such as `populateOnBeforeInsertWhenEmailBlank`, never a sentence.
- **Data inline, zero DML.** Rows are built in memory, and fake Ids come from `new TriggerHandler.RandomIdGenerator().get(…)`.
- **Small purpose-built classes, no spy frameworks.** A Writer gets a class of your own that implements `TriggerHandler.UnitOfWork` and keeps what it receives.
- **Only three comments:** `// Setup`, `// Test` and `// Verify`.

## Supported Test API {#test-api}

These members are public and meant for your tests:

| Member | Gives you |
|---|---|
| `new TriggerHandler.TriggerRecord(SObject newRow, SObject oldRow)` | A record for any predicate, action, error method or Bypassable test. It implements every record type, `Rejectable…` included. Pass `null` for the side the context does not have: `oldRow` on insert and undelete, `newRow` on delete. |
| `new TriggerHandler.InsertTriggerRecords(List<TriggerHandler.TriggerRecord>)`, and `UpdateTriggerRecords`, `DeleteTriggerRecords`, `UndeleteTriggerRecords` | The collection a Finalizer, a dispatch method or a provider's `query` receives |
| `new TriggerHandler.ProvidedRecords(List<SObject>)` and `groupUnderKey(String key, SObject row)` | Provider results, grouped under the keys your `keyOf` would return |
| `new TriggerHandler.RandomIdGenerator().get(SObjectType)`, `get(String keyPrefix)` | A fake Id with the object's key prefix |
| `record.enrichNew(String relationshipName, SObject parent)`, `record.enrichOld(…)` | The parent that `getNewParent` or `getOldParent` returns |
| `record.setProvidedRecords(Map<String, TriggerHandler.RelatedRecords>)` | The provider results that `getRelated` returns |

`enrichNew`, `enrichOld` and `setProvidedRecords` are public, but `TriggerHandler` lists them under an `// Internal use only` comment, so they may change in a later version. The library itself uses them to attach parents and provider results. The full list, with the members that are not meant for you: [Record API](/api/record#test-api).

"Public" reaches your tests only when your code shares the library's namespace, as in a source install. Every class is `public`, none is `global`, so from another namespace nothing here is visible: [Visibility and Namespace](/installation#visibility).

## Test a Handler Directly {#handler}

### Predicates and Actions {#predicates-actions}

Build a `TriggerHandler.TriggerRecord` from an in-memory row and call the method. `put` writes to the row, and an error added in a test stays on the row, where `hasErrors()` and `getErrors()` read it:

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

For the update contexts pass both rows, `new TriggerHandler.TriggerRecord(newRow, oldRow)`, so change detection has something to compare.

### Writers {#writers}

Pass the action a small class of your own that implements `TriggerHandler.UnitOfWork` and keeps what it receives. It never commits, so nothing is saved:

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

Keep what your Writers register: add lists to the methods they call.

### Dispatchers {#dispatchers}

Call the dispatch method with the records your predicate would qualify, in the context's collection, such as `new TriggerHandler.UpdateTriggerRecords(qualified)`. Then check what it started:

- **A Queueable:** `Limits.getQueueableJobs()` counts the jobs enqueued in the test. Enqueueing is not DML.
- **A publish or DML through DML Lib:** give the `DML` instance an `identifier`, mock it with `DML.mock('<identifier>').allPublishes()` or `.allDmls()`, and read it back with `DML.retrieveResultFor('<identifier>')`. The mocked statements never reach the database.

### Parents {#parents}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

A grandparent goes inside the parent. This predicate reads `Account.Owner.IsActive`:

```apex
@IsTest
static void writeOnAfterInsertWhenAccountOwnerActive() {
    // Setup
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(new Contact(LastName = 'Doe'), null);
    record.enrichNew('Account', new Account(OwnerId = new TriggerHandler.RandomIdGenerator().get(User.SObjectType), Owner = new User(IsActive = true)));

    // Test
    Boolean result = new ContactOwnerAlignmentWriter().writeOnAfterInsertWhen(record);

    // Verify
    Assert.isTrue(result, 'A contact under an active account owner should qualify.');
}
```

### Related Records {#related}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

### Bypassable {#bypassable}

```apex
@IsTest
static void bypassOnBeforeInsertWhenDisabled() {
    // Setup
    ContactReachabilityValidator.isDisabled = true;

    // Test
    Boolean result = new ContactReachabilityValidator().bypassOnBeforeInsertWhen();

    // Verify
    Assert.isTrue(result, 'The validator should be bypassed.');
}
```

Every test method starts with fresh static values, so the flag does not leak into other tests.

### Finalizers {#finalizers}

<!--@include: @/_parts/add-ons/test-techniques.md#finalizer-->

### Own Unit of Work {#own-unit}

<!--@include: @/_parts/add-ons/test-techniques.md#uow-->

## Registration Tests {#registration}

A handler that is missing from the orchestrator never runs, and an orchestrator that does not implement a context's registration interface skips that context silently. Two short tests catch both:

::: code-group

```apex [Context]
@IsTest
static void afterInsertHandlersIsImplemented() {
    // Test
    Object orchestrator = new AccountTriggerOrchestrator();

    // Verify
    Assert.isInstanceOfType(orchestrator, TriggerOrchestrator.AfterInsert.class, 'Account should register after insert handlers.');
}
```

```apex [Handler]
@IsTest
static void afterInsertHandlersContainsWelcomeTaskWriter() {
    // Test
    List<AfterInsert.Handler> handlers = new AccountTriggerOrchestrator().afterInsertHandlers();

    // Verify
    Assert.isInstanceOfType(handlers[0], AccountWelcomeTaskWriter.class, 'The welcome task writer should run first.');
}
```

:::

## Run the Orchestrator in a Test {#orchestrator}

::: warning Same namespace only
These seams are `@TestVisible` private members. `@TestVisible` opens them to test code in the library's own namespace only, so they work in a source install, where your tests share the library's namespace, and never from another namespace. They may change in a later version.
:::

| Seam | What it does |
|---|---|
| `new TriggerOrchestrator(Object orchestrator)` | builds a run for your orchestrator without a trigger |
| `orchestrator.context.triggerOperation`, `.newRecords`, `.oldRecords` | the context the run sees: the `System.TriggerOperation`, and the lists a trigger has in `Trigger.new` and `Trigger.old` |
| `orchestrator.run()` | runs it, the same way `TriggerOrchestrator.run(…)` does in a trigger |
| `TriggerOrchestrator.triggerLogger.logger` | the transaction's Logger; set it to a class of your own |
| `TriggerHandler.IdGenerator.get(…)` | the same Ids as `new TriggerHandler.RandomIdGenerator().get(…)`, which is public and needs no seam |

Two helpers keep each test short. `newRecords` and `oldRecords` must be typed lists, such as `new List<Account>{ … }`, because the run reads the object from the list's type. In after contexts and in delete contexts, give every row an Id:

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
```

```apex
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

**Recursion.** The recursion count of the update contexts is a static that lasts for the whole test method and cannot be reset. To check a RecursionGuard, build two runs with `runFor(System.TriggerOperation.AFTER_UPDATE, …)` for rows with the same Ids, call `run()` on both, and assert that the handler acted only once when its limit is 1. Every test method starts with a fresh count.

### Mock the Metadata and the Logger {#mock-metadata}

This works in the same namespace only, like every seam above.

Start every orchestrator test with the two mocks in `mockFramework()`, before anything else refers to `TriggerOrchestrator`, `TriggerOrchestrator.bypass()` included. The library reads the bypass metadata and looks for the org's Logger once, when a test first uses `TriggerOrchestrator`. Without the mocks, the org's deployed `TriggerObject__mdt` and `TriggerHandler__mdt` records and its real Logger apply to your test.

**A metadata bypass.** Return a row instead of the empty list. An object row can be built directly:

```apex
SOQL.mock('TriggerObject__mdt').thenReturn(new List<TriggerObject__mdt>{ new TriggerObject__mdt(ObjectAPIName__c = 'Account', Bypass__c = true) });
SOQL.mock('ApexTypeImplementor').thenReturn(new List<ApexTypeImplementor>());
```

A handler row is a child record of the object row, which Apex cannot set on a new record, so build the object row from JSON. Building every key from a field or object token keeps it correct in a namespaced org:

```apex
static TriggerObject__mdt objectRowWithBypassedHandler(String objectName, String className) {
    String prefix = String.valueOf(TriggerObject__mdt.SObjectType).removeEnd('TriggerObject__mdt');
    Map<String, Object> handlerRow = new Map<String, Object>{
        'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerHandler__mdt.SObjectType) },
        String.valueOf(TriggerHandler__mdt.ApexClassName__c) => className,
        String.valueOf(TriggerHandler__mdt.Bypass__c) => true
    };
    Map<String, Object> objectRow = new Map<String, Object>{
        'attributes' => new Map<String, Object>{ 'type' => String.valueOf(TriggerObject__mdt.SObjectType) },
        String.valueOf(TriggerObject__mdt.ObjectAPIName__c) => objectName,
        String.valueOf(TriggerObject__mdt.Bypass__c) => false,
        prefix + 'TriggerHandlers__r' => new Map<String, Object>{ 'totalSize' => 1, 'done' => true, 'records' => new List<Object>{ handlerRow } }
    };
    return (TriggerObject__mdt) JSON.deserialize(JSON.serialize(objectRow), TriggerObject__mdt.class);
}
```

A row with a wrong key comes back with no fields set, and no error says so.

**A `TriggerOrchestrator.bypass()` switch.** Set it after the mocks and before `run()`:

```apex
@IsTest
static void beforeInsertHandlersWhenAccountBypassed() {
    // Setup
    mockFramework();
    TriggerOrchestrator.bypass().sObject(Account.SObjectType);
    Account acme = new Account(Name = 'Acme', BillingCity = 'Berlin', BillingCountry = 'Germany');

    // Test
    runFor(System.TriggerOperation.BEFORE_INSERT, new List<Account>{ acme }, null).run();

    // Verify
    Assert.isNull(acme.ShippingCity, 'No Account handler should run.');
}
```

**A Logger.** Set a class of your own after the mocks. It receives every logged error and counts `finalize()` calls:

```apex
private class CollectingLogger implements TriggerOrchestrator.Logger {
    public List<TriggerOrchestrator.Error> errors = new List<TriggerOrchestrator.Error>();
    public Integer finalizeCalls = 0;

    public void log(TriggerOrchestrator.Error error) {
        this.errors.add(error);
    }

    public void finalize() {
        this.finalizeCalls++;
    }
}
```

```apex
CollectingLogger logger = new CollectingLogger();
TriggerOrchestrator.triggerLogger.logger = logger;
```

This is how to test a ContinueOnError handler: the save goes on, and `logger.errors` holds the swallowed exception.

### Mock Queries and DML {#mock-queries-dml}

- **Parents and SOQL Lib providers.** `SOQL.mock(Account.SObjectType).thenReturn(rows)` serves every SOQL Lib query on Account in the test that sets no identifier of its own: the per-lookup parent queries and any provider written with SOQL Lib. A provider with an inline `[SELECT …]` cannot be mocked.
- **Parents in after insert, update and undelete.** The new parents come from one query on the trigger object, so mock the trigger object's type and return its rows with the parent attached, such as `SOQL.mock(Contact.SObjectType).thenReturn(new Contact(Id = contactId, Account = acme))`. A parent-type mock serves the parents that query did not return and, in after update, the previous parents.
- **The shared unit.** `DML.mock('triggerUow').allDmls()` replaces the shared commit, and every private commit of a ContinueOnError Writer, which use the same identifier. Read the registrations with `DML.retrieveResultFor('triggerUow').insertsOf(Task.SObjectType).records()`.
- **An own unit or a Dispatcher's DML.** Mock the identifier the handler gives its `DML` instance, `DML.mock('<identifier>')`. That is public DML Lib API and needs no seam.
- **Tripping the DML guard.** `Database.setSavepoint()` counts as a DML statement, so a handler that sets a savepoint trips the guard without writing data.

### Namespaced Orgs {#namespace}

SOQL Lib's mock keeps only the fields the query selected and matches them by name. In an org with a namespace, custom field and relationship names carry its prefix: build the keys of hand-made rows from field tokens with `String.valueOf(…)`, and add the prefix to relationship names yourself, as in `objectRowWithBypassedHandler` above. Typed rows such as `new TriggerObject__mdt(ObjectAPIName__c = 'Account')` need nothing extra.

## Integration Tests {#integration}

Some behaviour exists only in a real save, so it needs real DML. Keep those tests in separate test classes:

- 201 or more records, split into 200-record chunks;
- partial saves, where the platform runs the handlers a second time;
- real nested triggers, where one object's commit fires another object's handlers.

To insert test data there without running the handlers, switch the object off first: `TriggerOrchestrator.bypass().sObject(Account.SObjectType)` ([Bypassing](/guide/bypasses#testing)).

## See Also {#see-also}

- [Record API](/api/record#test-api): the supported test members
- [Unit of Work](/guide/unit-of-work#testing): registrations and commits
- [Bypassing](/guide/bypasses#testing): switches in tests
- [Errors & Logging](/guide/error-handling#logger): what the Logger receives
