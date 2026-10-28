---
name: trigger-lib-handler
description: Apex trigger logic written as Trigger Lib handlers, the Populator, Validator, Writer and Dispatcher classes that a TriggerOrchestrator runs for each record. Use when adding, changing or reviewing what happens when records are inserted, updated, deleted or undeleted in a project that uses Trigger Lib (TriggerOrchestrator), from source or as the btcdev package, including defaulting or deriving fields, validation errors, blocking deletes, creating or updating related records, publishing platform events, enqueueing async work, reading parent, child or sibling records without SOQL in a loop, unit of work DML, recursion, bypass flags and error handling inside a handler. Not for creating the trigger, the orchestrator or the custom metadata records (use trigger-lib-orchestrator) or for test classes (use trigger-lib-testing).
---

# Trigger Lib: Handlers

A handler is a small class with one role in one trigger context. For every record in the chunk, the library calls the role's predicate (`...When`) and runs the role's action only when the predicate returns true. So a handler never loops over `Trigger.new`, never queries and never runs DML inside that loop. It declares the parents and related records it reads and registers its writes on a unit of work, and the library loads and commits them in bulk, once per chunk. Inserts and updates arrive in chunks of up to 200 records, while an Apex `delete` or `undelete` can deliver all its rows in one run.

## Rules

1. One concern per top-level class, and one role per context. A class that implements two roles of one context runs only as the first (Populator, then Validator, then Writer, then Dispatcher), and nothing warns you.
2. No SOQL and no DML in a predicate, or in the per-record action of a Populator, Validator or Writer. Both throw a `TriggerTypes.TriggerLibException` and fail the save. Read other records as shown in [Reading other records](#reading-other-records), and register DML on the action's `unitOfWork`. A Dispatcher's dispatch method and a Finalizer run once per chunk, outside that check.
3. Change the record being saved only from a Populator, with `record.put(field, value)`, in before insert or before update. In the after contexts the rows are read-only: `put` throws a `System.FinalException` that no `catch` stops.
4. Before insert and before update allow no DML and no event publish anywhere in a handler, its Finalizer included. Change other records from a Writer in before delete or an after context.
5. In before update and after update, make the predicate require a change, with `isChanged`, `isChangedTo` or another change check. Every later update of the record in the transaction runs the update handlers again. After 3 actions on a record in the transaction, each later run logs an error, and only a RecursionGuard stops the loop.
6. When a Validator's predicate returns true, its error method must call `record.addError(...)`, or the library throws for the whole chunk. Put the whole condition in the predicate.
7. A new handler runs only once it is registered: add it to the object's orchestrator in run order (Populators before Validators), or add its `TriggerHandler__mdt` record when the trigger calls `runFromMetadata()`. The `trigger-lib-orchestrator` skill covers both.
8. Pass fields as `SObjectField` tokens (`Account.Rating`). Cast a row to read its fields: `(Account) record.getNewSObject()`.

## Before writing

1. Find the object's trigger and orchestrator (usually `<Object>TriggerOrchestrator`) and read one or two existing handlers. Follow the project's class names, folders and sharing keyword where they differ from this skill. If the object has no trigger yet, create it first with the `trigger-lib-orchestrator` skill.
2. If Trigger Lib is installed as the `btcdev` package (existing code calls `btcdev.TriggerOrchestrator`, or `sfdx-project.json` or `sf package installed list` shows the Trigger Lib package), prefix every library type with `btcdev.`: `btcdev.BeforeInsert.Populator`, `btcdev.TriggerTypes.InsertRecord`, `btcdev.TriggerTypes.UnitOfWork`, `btcdev.DML`, `btcdev.SOQL`.

## Pick the context and role

| You need to | Context | Role |
|---|---|---|
| Default, derive, normalize or clear fields of the record being saved | BeforeInsert, BeforeUpdate | Populator |
| Reject an insert or an update with a message, like a validation rule | BeforeInsert, BeforeUpdate | Validator |
| Block a delete | BeforeDelete | Validator |
| Create, update or delete other records, or publish platform events, as part of the save | AfterInsert, AfterUpdate, AfterDelete, AfterUndelete | Writer |
| Change records that point at the rows being deleted, while the links still exist | BeforeDelete | Writer |
| Make one bulk call per chunk: enqueue a Queueable, send email, publish events at once | AfterInsert, AfterUpdate, AfterDelete, AfterUndelete | Dispatcher |
| Call an external system | an after context | Dispatcher that enqueues a Queueable implementing `Database.AllowsCallouts`. Triggers can't make callouts |
| Set a field of a new record that needs its Id | AfterInsert | Writer that registers `toUpdate(new Contact(Id = record.getId(), ...))`, which saves the record again |
| Block an undelete (there is no before undelete) | AfterUndelete | Writer or Dispatcher, listed first, that calls `record.getNewSObject().addError(...)` |

Name the class `<Object><Concern><Role>`: `AccountRatingPopulator`, `ContactBirthdateValidator`, `AccountWelcomeTaskWriter`, `ContactSyncDispatcher`. Keep it to 36 characters, so that `<Name>Test` fits the 40-character limit for Apex class names.

## Interfaces and method names

Each context is a class that holds that context's role and add-on interfaces: `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete` and `AfterUndelete`. Every method name carries its context (`<Ctx>` below), so one class can implement several contexts without clashes.

| Role | Predicate, called once per record | Action |
|---|---|---|
| `<Ctx>.Populator` | `Boolean populateOn<Ctx>When(record)` | `void populateOn<Ctx>(record)` |
| `<Ctx>.Validator` | `Boolean addErrorOn<Ctx>When(record)` | `void addErrorOn<Ctx>(rejectableRecord)` |
| `<Ctx>.Writer` | `Boolean writeOn<Ctx>When(record)` | `void writeOn<Ctx>(record, TriggerTypes.UnitOfWork unitOfWork)` |
| `<Ctx>.Dispatcher` | `Boolean dispatchOn<Ctx>When(record)` | `void dispatchOn<Ctx>(records)`, called once with every qualified record |

| Context | `record` | `rejectableRecord` | `records` |
|---|---|---|---|
| BeforeInsert, AfterInsert | `TriggerTypes.InsertRecord` | `TriggerTypes.RejectableInsertRecord` | `TriggerTypes.InsertRecords` |
| BeforeUpdate, AfterUpdate | `TriggerTypes.UpdateRecord` | `TriggerTypes.RejectableUpdateRecord` | `TriggerTypes.UpdateRecords` |
| BeforeDelete, AfterDelete | `TriggerTypes.DeleteRecord` | `TriggerTypes.RejectableDeleteRecord` | `TriggerTypes.DeleteRecords` |
| AfterUndelete | `TriggerTypes.UndeleteRecord` | | `TriggerTypes.UndeleteRecords` |

A class that implements only `<Ctx>.Handler` compiles and never runs.

## Templates

**Populator.** Gate the update on a change, then set the field on the row being saved:

```apex
public with sharing class AccountHotRatingPopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Account.AnnualRevenue) && record.greaterThanOrEqualTo(Account.AnnualRevenue, 1000000);
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        record.put(Account.Rating, 'Hot');
    }
}
```

**Validator.** One class can serve several contexts. The predicate holds the whole condition, and the error method always attaches the error:

```apex
public with sharing class ContactBirthdateValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
    private static final String MESSAGE = 'Birthdate must be in the past.';

    public Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateValidator.MESSAGE);
    }

    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Contact.Birthdate) && this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateValidator.MESSAGE);
    }

    private Boolean isInFuture(Contact contactRecord) {
        return contactRecord.Birthdate != null && contactRecord.Birthdate > Date.today();
    }
}
```

**Writer.** Read related rows from a provider and register new instances on the unit of work:

```apex
public with sharing class AccountFormerCustomerCaseWriter implements AfterUpdate.Writer, AfterUpdate.RelatedQuery {
    public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
        return new Map<String, AfterUpdate.RecordsProvider>{ 'openCases' => new OpenCasesProvider() };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Account.Type, 'Former Customer');
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        for (SObject row : record.getRelated('openCases').getAllWhereKeyEquals(record.getId())) {
            unitOfWork.toUpdate(new Case(Id = row.Id, Status = 'Closed'));
        }
    }

    private with sharing class OpenCasesProvider implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return SOQL.of(Case.SObjectType)
                .with(Case.Id, Case.AccountId)
                .whereAre(SOQL.Filter.with(Case.AccountId).isIn(records.getIds()))
                .whereAre(SOQL.Filter.with(Case.IsClosed).isFalse())
                .systemMode()
                .mockId('AccountFormerCustomerCaseWriter.openCases')
                .toList();
        }

        public String keyOf(SObject row) {
            return ((Case) row).AccountId;
        }
    }
}
```

**Dispatcher.** Collect the qualified records and make one call for the chunk. `ContactSyncJob` stands for your own Queueable:

```apex
public with sharing class ContactSyncDispatcher implements AfterInsert.Dispatcher {
    public Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotNull(Contact.Email);
    }

    public void dispatchOnAfterInsert(TriggerTypes.InsertRecords records) {
        System.enqueueJob(new ContactSyncJob(records.getIds()));
    }
}
```

## The record API

| Member | Notes |
|---|---|
| `getId()` | `null` in before insert |
| `getNewSObject()`, `getOldSObject()` | Cast to read fields. The new row is the live row in before insert and before update and read-only elsewhere. The old row exists in the update and delete contexts and is always read-only |
| `put(field, value)` | Sets a field of the row being saved. Populators in before insert and before update only |
| `addError(message)`, `addError(field, message)` | On a Validator's `rejectableRecord` only. On `Name` and compound address fields the error shows at record level; for a field-level message there, call `((Account) record.getNewSObject()).Name.addError(message)` |
| `getNewParent(lookupField)`, `getOldParent(lookupField)` | The parent a ParentQuery or PriorParentQuery loaded, or `null` |
| `getRelated(providerName)` | The rows a RelatedQuery provider loaded |
| `equals`, `doesNotEqual`, `isIn`, `isNotIn`, `contains`, `doesNotContain`, `startsWith`, `endsWith`, `isNull`, `isNotNull`, `isEmpty`, `isNotEmpty`, `isBlank`, `isNotBlank`, `isTrue`, `isFalse`, `greaterThan`, `greaterThanOrEqualTo`, `lessThan`, `lessThanOrEqualTo` | Value checks on the new row, or the old row in the delete contexts. They never throw on `null`, and comparisons are false for `null`. `equals` and `isIn` ignore case for text, while `contains`, `startsWith` and `endsWith` don't. `0` and `false` are values, not blank. In before contexts they see values that earlier handlers set |
| `isChanged`, `isAnyChanged`, `areAllChanged`, `isChangedTo`, `isChangedToNotNull`, `isChangedFrom`, `isChangedFromTo` | Update contexts only. Text compares without case, so `'Doe'` to `'DOE'` is not a change. `isAnyChanged` and `areAllChanged` take 2 to 5 fields or an `Iterable<SObjectField>` |
| `isRecordType(developerName)`, `isNotRecordType(developerName)` | By developer name, with no SOQL. They throw on objects without record types. A misspelled name throws nothing: it matches rows without a `RecordTypeId` and no others |

A member the context lacks, such as `isChanged` in an insert handler, is a compile error. Read [references/record-api.md](references/record-api.md) for every method of the records, the collections, `RelatedRecords`, `ParentFields` and `UnitOfWork`.

## Reading other records

| You need | Implement | Read it with |
|---|---|---|
| Fields of the record a lookup points to | `<Ctx>.ParentQuery` (BeforeInsert, AfterInsert, BeforeUpdate, AfterUpdate, AfterUndelete) | `record.getNewParent(lookupField)` |
| The parent the lookup pointed to before the save | `<Ctx>.PriorParentQuery` (BeforeUpdate, AfterUpdate, BeforeDelete, AfterDelete) | `record.getOldParent(lookupField)` |
| Children, siblings, records matched by a value, configuration that depends on the trigger records | `<Ctx>.RelatedQuery` (every context) | `record.getRelated('<provider name>')` |
| Configuration that doesn't depend on the trigger records | A `private static` variable, or `getInstance()` / `getAll()` of a custom setting or custom metadata type | The variable |

### Parents

```apex
public with sharing class ContactDescriptionPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name).with('Owner', User.Email) };
    }

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotNull(Contact.AccountId) && record.isBlank(Contact.Description);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Account parentAccount = (Account) record.getNewParent(Contact.AccountId);

        record.put(Contact.Description, parentAccount?.Name + ', managed by ' + parentAccount?.Owner?.Email);
    }
}
```

- The map key is the lookup field on the trigger object. Read the parent back with that same field.
- Declare every field you read. The parent holds only the declared fields and its `Id`, and reading another field throws an `SObjectException`. Grandparent fields go in with `with('<relationship name>', field)` and are read as `parentAccount.Owner.Email`.
- The trigger row holds only the lookup Id: `((Contact) record.getNewSObject()).Account` is always `null`.
- `getNewParent` returns `null` when the lookup is empty, so use `?.`. It also returns `null`, with no error, for a lookup that no active handler declared in this context, while `getRelated` throws for an undeclared name. A class that serves two contexts needs each context's ParentQuery.
- The first read loads the parents of every record in the chunk: one query per lookup in the before contexts and after delete, and usually one query on the trigger records in after insert, after update and after undelete. A read in the predicate queries even when no record qualifies, so put cheaper conditions first: `&&` stops at the first false operand.
- Parents are read in system mode without sharing, so a handler can see records the user can't.
- `getOldParent` needs a PriorParentQuery and `getNewParent` needs a ParentQuery, even when the lookup didn't change. Implement both to compare the two parents.

### Related records

A RelatedQuery returns named providers, as in the Writer template above. Each provider has `List<SObject> query(records)` and `String keyOf(SObject row)`.

- `query` gets every record of the chunk, qualified or not. It runs once per handler per chunk, at the handler's first `getRelated` with that name, so a provider the handler never reads costs nothing.
- `keyOf` returns the key a row is stored under, and `getAllWhereKeyEquals(key)` (an empty list when nothing matches) or `getFirstWhereKeyEquals(key)` (`null` when nothing matches) read the rows back. Keys compare as text and exactly, case included, so lowercase text keys in `keyOf` and when you read.
- Two handlers that use the same provider class run two queries. A shared provider class saves code, not queries.
- Write the query with SOQL Lib and a `mockId`, so a unit test can return rows with `SOQL.mock('<mock id>')`. An inline `[SELECT ...]` works as well, but only a test that inserts records can cover it.
- Declare a sharing keyword on every provider class, which inline SOQL follows. A SOQL Lib query runs in user mode, enforcing the running user's sharing and field access whatever the keyword says, until you call `.systemMode()`, as the template does; then the class's keyword decides. A Validator that guards a save must see every row: use a `without sharing` provider class, or call `.systemMode().withoutSharing()`.
- When the rows you need belong only to the qualified records, query once in a Finalizer instead.

Read [references/related-query-recipes.md](references/related-query-recipes.md) for siblings, records under the previous parent, text and composite keys, configuration rows, a declared parent's field, and the trigger records' own formula fields.

### Configuration

```apex
public with sharing class ContactDepartmentPopulator implements BeforeInsert.Populator {
    private static User runningUser = [SELECT Department FROM User WHERE Id = :UserInfo.getUserId()];

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isBlank(Contact.Department);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        record.put(Contact.Department, ContactDepartmentPopulator.runningUser.Department);
    }
}
```

Assign the static in its declaration, as above. The handler class loads when the orchestrator creates it, before the record loop, so the query runs once per transaction and outside the check. A lazily filled static, or a static of another class that a predicate or an action touches first, queries inside the loop and throws. A query in the constructor runs again on every run, because the orchestrator creates new handlers for every context, every chunk and every nested save.

## Writing other records

A Writer's action gets a `TriggerTypes.UnitOfWork`. Register one record per call. The calls chain:

```apex
unitOfWork
    .toInsert(new Task(WhatId = record.getId(), Subject = 'Welcome call'))
    .toUpdate(new Account(Id = record.getId(), Rating = 'Hot'))
    .toPublish(new AccountSync__e(AccountId__c = record.getId()));
```

- The methods are `toInsert`, `toUpdate`, `toUpsert(record, externalIdField)`, `toDelete` and `toPublish(event)`. There are no List overloads and no undelete, merge or hard delete. Run those as direct DML in a Dispatcher or a Finalizer of an after context.
- Register new instances that hold the Id and the changed fields: `new Account(Id = accountId, Type = 'Customer')`. Registering a trigger row, such as `record.getNewSObject()`, makes the commit throw.
- The shared unit of work commits once, after the last handler of the run, with one statement per operation and object type: inserts and upserts first, parents before children, then updates, deletes and event publishes. Handlers listed later don't see your writes. A second `toUpdate` or `toDelete` of the same Id merges into the first, and later fields win. Inserts and upserts never merge: a second `toUpsert` of the same Id makes the commit throw a `DmlException`.
- It runs in system mode without sharing. For user mode, partial success or your own statement order, add OwnUnitOfWork.
- To point a new child at a parent inserted in the same unit, wrap the child in `DML.Record`: `unitOfWork.toInsert(branch).toInsert(DML.Record(new Contact(LastName = 'Doe')).withRelationship(Contact.AccountId, branch));`
- A Dispatcher gets no unit of work. DML, `EventBus.publish(...)` and `System.enqueueJob(...)` in its dispatch method run at once. Pass Ids to async jobs and let the job query what it needs. In after delete the job runs after the rows are gone, so pass values, or the Ids of records that still exist, such as `records.getIdsOf(Contact.AccountId)`.
- A `try` / `catch` in the action catches only what the action itself throws, such as building a record. Registered DML runs at the commit, outside the action, and a failure there fails the whole save. To reject only the record whose own processing failed, call `record.getNewSObject().addError(...)` in the `catch` block (`getOldSObject()` in the delete contexts).

## Add-ons

Implement as many as you need next to the role interface. Each exists only in the contexts listed.

| Add-on | Method | Use it to | Contexts |
|---|---|---|---|
| ParentQuery | `Map<SObjectField, TriggerTypes.ParentFields> queryParentsOn<Ctx>()` | Load lookup parents | BeforeInsert, AfterInsert, BeforeUpdate, AfterUpdate, AfterUndelete |
| PriorParentQuery | `Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOn<Ctx>()` | Load the parents from before the save | BeforeUpdate, AfterUpdate, BeforeDelete, AfterDelete |
| RelatedQuery | `Map<String, <Ctx>.RecordsProvider> queryRelatedOn<Ctx>()` | Load children, siblings or any other records | every context |
| Bypassable | `Boolean bypassOn<Ctx>When()` | Skip the handler for the chunk on a condition that doesn't depend on the records | every context |
| RecursionGuard | `Integer maxRunsPerRecordOn<Ctx>()` | Set the recursion depth and skip the record there, instead of only logging at the default depth of 3 | BeforeUpdate (Populator only), AfterUpdate |
| Finalizer | `void finalizeOn<Ctx>(records)` | Run once per chunk with the qualified records | every context |
| ContinueOnError | none, it's a marker | Log and swallow the handler's own exceptions | every context |
| OwnUnitOfWork | `DML.Committable ownUnitOfWorkOn<Ctx>()` | Give a Writer its own `DML` settings, committed right after it | AfterInsert, AfterUpdate, BeforeDelete, AfterDelete, AfterUndelete |

- **Bypassable** runs once per handler per run and gets no records. Use it for a static flag, `System.isBatch()` or `FeatureManagement.checkPermission('...')`. It's checked before the first handler of the run, so a flag that an earlier handler sets applies from the next run. An exception there isn't logged and fails the save. To skip single records, return false from the predicate instead.
- **RecursionGuard** counts every time the predicate returns true for a record, per class and context, for the whole transaction. When the record comes back at that count, it's skipped and the run logs an error. Without it the depth is 3, and the run logs the same error but the handler keeps going. `null` means no depth and no error, and `0` or less skips every record. Avoid `1`: a partial save, such as `Database.update(rows, false)`, Data Loader or the Bulk API, rolls back and runs the trigger again for the rows that succeeded. The count isn't rolled back, so with a cap of `1` their action is skipped on that re-run. Prefer a change gate in the predicate, which passes again on that re-run, and keep any cap at 2 or more.
- **Finalizer** runs after the handler's records, only when at least one qualified. SOQL is allowed there. It gets no unit of work, so to register more DML, keep the action's `unitOfWork` in an instance field.
- **ContinueOnError** is for nice-to-have work such as a notification. After an exception, the handler's remaining records and its Finalizer are skipped, later handlers still run, and a Writer's registrations are dropped. It never swallows a `TriggerTypes.TriggerLibException`, an `EventBus.RetryableException` that asks for redelivery of a platform event, a `System.LimitException`, the `FinalException` from writing a trigger row, or an error outside the handler's own methods. Never add it to a Validator that guards a save, and add a Logger, or a swallowed failure leaves no trace.
- **OwnUnitOfWork** returns a DML Lib unit, such as `new DML().userMode().allowPartialSuccess().identifier('OpportunityLossReviewWriter')`. A plain `new DML()` runs in user mode and throws on a duplicate registration, unlike the shared unit.

## Context notes

| Context | Know this |
|---|---|
| BeforeInsert | `getId()` is `null` and `records.getIds()` is empty. Key maps by a lookup or a field value |
| BeforeUpdate | The old row is read-only. A Validator runs on every pass; a Populator logs an error when a record comes back after 3 passes |
| BeforeDelete | Writes commit before the delete, while other records still point at the rows. Leave the rows being deleted alone: a `toDelete` of one fails with `SELF_REFERENCE_FROM_TRIGGER`, and an update of one is lost. Cascade-deleted children fire no triggers of their own, so handle them here with a RelatedQuery |
| AfterInsert, AfterUpdate | The rows are read-only. Inserting or updating the same object runs its triggers again, and the insert contexts have no recursion cap |
| AfterDelete | SOQL no longer finds the rows, so query by their old lookups, such as `records.getIdsOf(Contact.AccountId)`. Merge losers arrive here with `MasterRecordId` set |
| AfterUndelete | Cascade-restored children run no trigger of their own. Handle them from the parent's handlers |
| Every context | The orchestrator creates new handler instances on every run: per context, per chunk, per nested save. Instance fields start empty each time, and static fields last the whole transaction, so a static "already ran" flag skips every later chunk. A partial save runs every handler twice for the rows that succeed: the first attempt's DML rolls back, but its emails and Publish Immediately events don't |

## Common mistakes

| Mistake | Fix |
|---|---|
| A query or a selector call in a predicate or an action | ParentQuery, PriorParentQuery, RelatedQuery or a static variable |
| `insert`, `update`, `Database.*` or `EventBus.publish` in a Writer's action | `unitOfWork.toInsert(...)`, `toUpdate(...)`, `toPublish(...)` |
| `record.put(...)` in an after context | A Populator in the matching before context, or a Writer that registers `toUpdate(new Account(Id = record.getId(), ...))` |
| `((Contact) record.getNewSObject()).Account.Name` | Declare a ParentQuery and read `record.getNewParent(Contact.AccountId)` |
| `unitOfWork.toUpdate(record.getNewSObject())` | `unitOfWork.toUpdate(new Account(Id = record.getId(), Rating = 'Hot'))` |
| An update handler whose predicate doesn't check a change | Start the predicate with `record.isChanged(...)` or `isChangedTo(...)` |
| An `if` in the Validator's error method that can skip `addError` | Move the condition into the predicate |
| One class that is both the Populator and the Validator of a context | Two classes |
| `for (Account a : (List<Account>) Trigger.new)` or `Trigger.isInsert` in a handler | Let the library loop. Write one predicate and one action |
| `static Boolean alreadyRan` to stop recursion | A change gate in the predicate, or RecursionGuard |
| A query in the handler's constructor | A `private static` variable |
| A handler written as an inner class | A top-level class: `TriggerOrchestrator.bypass().handler(X.class)` never matches an inner class |
| A synchronous callout from a trigger | A Dispatcher that enqueues a Queueable with `Database.AllowsCallouts` |

For tests, use the `trigger-lib-testing` skill. For the trigger, the orchestrator, bypasses and the Logger, use `trigger-lib-orchestrator`.
