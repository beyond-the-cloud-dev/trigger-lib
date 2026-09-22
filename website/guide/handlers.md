---
outline: deep
---

# Handlers

A handler is a class that implements the interfaces of one or more trigger contexts. Each context lives in its own top-level class: `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete` and `AfterUndelete`.

Contexts come in two shapes. Before insert and before update have **roles**: a handler is either a `Populator` or a `Validator`. The other five contexts have a single `Handler` interface.

## Roles in Before Contexts

A before insert or before update handler either writes fields on the triggering record or blocks it with a message. The framework asks you to say which, by implementing one of two interfaces.

### Populator

```apex
public interface Populator extends Handler {
  Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record);
  void populateOnBeforeInsert(TriggerHandler.InsertRecord record);
}
```

```apex
public with sharing class AccountDefaultsPopulator implements BeforeInsert.Populator {
  public Boolean populateOnBeforeInsertWhen(
    TriggerHandler.InsertRecord record
  ) {
    return record.isBlank(Account.Rating);
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Account.Rating, 'Warm');
  }
}
```

### Validator

A validator has no action method. It supplies the message and the framework attaches it with `addError` on the records the predicate qualified.

```apex
public interface Validator extends Handler {
  Boolean errorShouldBeAttachedOnBeforeInsertWhen(
    TriggerHandler.InsertRecord record
  );
  String beforeInsertValidationMessage(TriggerHandler.InsertRecord record);
}
```

```apex
public with sharing class AccountIndustryValidator implements BeforeInsert.Validator {
  public Boolean errorShouldBeAttachedOnBeforeInsertWhen(
    TriggerHandler.InsertRecord record
  ) {
    return record.isBlank(Account.Industry);
  }

  public String beforeInsertValidationMessage(
    TriggerHandler.InsertRecord record
  ) {
    return 'Industry is required on new accounts.';
  }
}
```

The string returned by `beforeInsertValidationMessage` is the DML error message, verbatim. When the predicate returns `false` the record saves untouched.

The before update names follow the same pattern:

| Context       | Role        | Predicate                                 | Second method                   |
| ------------- | ----------- | ----------------------------------------- | ------------------------------- |
| Before Insert | `Populator` | `populateOnBeforeInsertWhen`              | `populateOnBeforeInsert`        |
| Before Insert | `Validator` | `errorShouldBeAttachedOnBeforeInsertWhen` | `beforeInsertValidationMessage` |
| Before Update | `Populator` | `populateOnBeforeUpdateWhen`              | `populateOnBeforeUpdate`        |
| Before Update | `Validator` | `errorShouldBeAttachedOnBeforeUpdateWhen` | `beforeUpdateValidationMessage` |

### Exactly One Role Per Context

`BeforeInsert.Handler` and `BeforeUpdate.Handler` are empty markers. `Populator` and `Validator` extend them so the orchestrator list has a type. You never implement the marker directly.

A class listed in `beforeInsertHandlers()` or `beforeUpdateHandlers()` must implement exactly one role for that context. Both of the other outcomes are rejected with a `TriggerOrchestratorException` that names the class and both interfaces.

Implementing both:

```
AccountDefaultsPopulator implements both BeforeInsert.Populator and BeforeInsert.Validator. A class can implement only one main interface per context.
```

Implementing neither, for example a class that declares `implements BeforeInsert.Handler` and nothing else:

```
AccountDefaultsPopulator implements neither BeforeInsert.Populator nor BeforeInsert.Validator. A class must implement one main interface per context.
```

The check runs while the handler list is being collected, before bypasses are applied. A handler that would have been bypassed still fails the invocation when its roles are wrong.

### One Class, Several Contexts

The rule is per context, not per class. A class may hold a role in before insert and another in before update, and it may implement the plain `Handler` of after contexts at the same time. Each context calls only its own methods, and each context's lifecycle callbacks, such as its finalizer, fire once for that context.

```apex
public with sharing class AccountNameFormatPopulator implements BeforeInsert.Populator, BeforeUpdate.Populator {
  public Boolean populateOnBeforeInsertWhen(
    TriggerHandler.InsertRecord record
  ) {
    return record.isNotBlank(Account.Name);
  }

  public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    record.put(Account.Name, ((Account) record.getNewSObject()).Name.trim());
  }

  public Boolean populateOnBeforeUpdateWhen(
    TriggerHandler.UpdateRecord record
  ) {
    return record.isChanged(Account.Name);
  }

  public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
    record.put(Account.Name, ((Account) record.getNewSObject()).Name.trim());
  }
}
```

## Handler Interface

The other five contexts have no roles. Their `Handler` interface has two methods: a qualification predicate and an action.

```apex
public with sharing class CaseOwnerNotificationHandler implements AfterUpdate.Handler {
  public Boolean qualifiesForAfterUpdateWhen(
    TriggerHandler.UpdateRecord record
  ) {
    return record.isChanged(Case.OwnerId);
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    // ...
  }
}
```

The method names follow the context:

| Context        | Qualification                   | Action            | Record type                     |
| -------------- | ------------------------------- | ----------------- | ------------------------------- |
| After Insert   | `qualifiesForAfterInsertWhen`   | `onAfterInsert`   | `TriggerHandler.InsertRecord`   |
| After Update   | `qualifiesForAfterUpdateWhen`   | `onAfterUpdate`   | `TriggerHandler.UpdateRecord`   |
| Before Delete  | `qualifiesForBeforeDeleteWhen`  | `onBeforeDelete`  | `TriggerHandler.DeleteRecord`   |
| After Delete   | `qualifiesForAfterDeleteWhen`   | `onAfterDelete`   | `TriggerHandler.DeleteRecord`   |
| After Undelete | `qualifiesForAfterUndeleteWhen` | `onAfterUndelete` | `TriggerHandler.UndeleteRecord` |

## Optional Capabilities

Capabilities are opt-in interfaces from the same context class. Implement the ones a handler needs. They work the same for a `Populator`, a `Validator` and a plain `Handler`. See [Context Interfaces](/api/context-interfaces) for the full matrix.

| Capability         | Purpose                                                   | Available in                         | Guide                                         |
| ------------------ | --------------------------------------------------------- | ------------------------------------ | --------------------------------------------- |
| `ParentQuery`      | Declare parent fields to query for the new record         | every context except the two deletes | [Parent Enrichment](/guide/enrichment)        |
| `PriorParentQuery` | Declare parent fields to query for the old record         | update and delete contexts           | [Parent Enrichment](/guide/enrichment)        |
| `RelatedQuery`     | Query children, siblings, value matches and configuration | all contexts                         | [Related Records](/guide/related-records)     |
| `Bypassable`       | Skip the handler for the whole invocation                 | all contexts                         | [Bypasses](/guide/bypasses)                   |
| `RecursionGuard`   | Override the per-record pass limit                        | before update and after update       | [Recursion Control](/guide/recursion-control) |
| `Finalizer`        | Run once after all qualified records were processed       | all contexts                         | [Finalizers](/guide/finalizers)               |
| `ContinueOnError`  | Log the exception and continue with the next handler      | all contexts                         | [Error Handling](/guide/error-handling)       |

## One Record at a Time

The action method is called once per qualified record. The handler never sees `Trigger.new` and has no loop of its own. This keeps handlers short, but it means any DML or callout must be collected and executed once, in a [finalizer](/guide/finalizers).

```apex
public with sharing class CaseEscalationHandler implements AfterUpdate.Handler, AfterUpdate.Finalizer {
  private List<Task> tasksToInsert = new List<Task>();

  public Boolean qualifiesForAfterUpdateWhen(
    TriggerHandler.UpdateRecord record
  ) {
    return record.isChangedTo(Case.Priority, 'High');
  }

  public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
    tasksToInsert.add(
      new Task(WhatId = record.getId(), Subject = 'Escalated case')
    );
  }

  public void finalizeAfterUpdate() {
    insert tasksToInsert;
  }
}
```

When the predicate qualifies no records, neither the action nor the finalizer runs.

Data the handler needs from other records is not queried here either. It is declared as a [provider](/guide/related-records) and read from memory, one record at a time.

## Handler Instances

The orchestrator's list method is called on every trigger invocation, so the usual `new AccountDefaultsPopulator()` in the list hands the framework a fresh instance each time. Instance fields are therefore a safe place to accumulate work for the finalizer. Use static fields only for state that must survive across invocations in one transaction, and remember that a DML of more than 200 records reaches the handler in chunks of 200, each a separate invocation. A static that decides whether a handler has "already run" will skip every record past the first chunk.

A partial save, `Database.insert(records, false)`, adds a second way for a record to reach a handler twice: the failing records are dropped and the platform runs the trigger again for the survivors, which then commit. Keep the action idempotent so it stays correct under that re-run.

## No DML in Before Contexts

A before insert or before update handler exists to populate or block the triggering records. DML there is not allowed, and there is no opt-out.

The framework compares `Limits.getDmlStatements()` and `Limits.getPublishImmediateDML()` before and after the handler runs and throws a `TriggerOrchestratorException` when either increased:

```
AccountDefaultsPopulator performed DML in a before context. Populate the trigger record instead, or move the DML to an after context.
```

The sharp edges of that guard:

- It applies to populators, validators and their finalizers alike.
- Publishing a platform event with `Publish Immediately` behaviour counts as DML and is rejected.
- The comparison runs in a `finally` block, so a handler that performs DML and then throws its own exception is still caught by the guard.
- `ContinueOnError` does not suppress it. `ContinueOnError` covers a handler's own exceptions, never a framework contract violation, so the exception propagates and the DML is aborted with nothing committed.

Before delete has no such guard. Cascading cleanup of other objects is a valid use of a before delete handler.

## Reading and Writing the Record

Every method receives one record wrapper. Which interface you get is fixed by the context:

| Context        | Record interface                | Accessors it exposes                                                                           |
| -------------- | ------------------------------- | ---------------------------------------------------------------------------------------------- |
| Before Insert  | `TriggerHandler.InsertRecord`   | `getId`, `getNewSObject`, `getNewParent`, `getRelated`, `put`                                  |
| After Insert   | `TriggerHandler.InsertRecord`   | the same, but `put` throws, see below                                                          |
| Before Update  | `TriggerHandler.UpdateRecord`   | `getId`, `getNewSObject`, `getOldSObject`, `getNewParent`, `getOldParent`, `getRelated`, `put` |
| After Update   | `TriggerHandler.UpdateRecord`   | the same, but `put` throws, see below                                                          |
| Before Delete  | `TriggerHandler.DeleteRecord`   | `getId`, `getOldSObject`, `getOldParent`, `getRelated`                                         |
| After Delete   | `TriggerHandler.DeleteRecord`   | `getId`, `getOldSObject`, `getOldParent`, `getRelated`                                         |
| After Undelete | `TriggerHandler.UndeleteRecord` | `getId`, `getNewSObject`, `getNewParent`, `getRelated`                                         |

There is no new record in delete contexts and no old record in insert and undelete contexts, and the interfaces reflect that: `DeleteRecord` has no `getNewSObject`, `InsertRecord` and `UndeleteRecord` have no `getOldSObject`. A change predicate such as `isChanged` lives only on `UpdateRecord`, so reaching for the old side where there is none is a compile error rather than a runtime surprise.

Use `put` to populate a field in a before context, and `getNewSObject` or `getOldSObject` when you need the raw SObject.

```apex
public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
    Contact contact = (Contact) record.getNewSObject();

    record.put(Contact.Description, 'Created from ' + contact.LeadSource);
}
```

`put` returns nothing:

```apex
void put(SObjectField field, Object value);
```

There is no chaining. Call it once per field.

::: danger
`InsertRecord` and `UpdateRecord` serve both the before and the after phase of their operation, so the type system cannot stop you calling `put` in an after insert or after update handler. Doing so raises `System.FinalException: Record is read-only`. That exception is uncatchable: the handler's own `try` and `catch` will not stop it, `ContinueOnError` will not stop it, and the whole transaction is lost. In after contexts, query and update the record yourself, from a finalizer.
:::

The full predicate and accessor API is documented under [the record interfaces](/api/record).
