---
outline: deep
---

# Context Interfaces

Each trigger context has its own top-level class that groups the interfaces a handler can implement: `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete` and `AfterUndelete`.

Method names carry the context name, so one class can implement several contexts without clashes.

Before insert and before update are the two contexts with **roles**: a handler there implements `Populator` or `Validator`, never a plain `Handler`. The other five contexts have a single working `Handler` interface. Every other interface on this page is optional and works the same way whichever of the three a handler is.

## Availability Matrix

| Interface          | Before Insert | After Insert | Before Update | After Update | Before Delete | After Delete | After Undelete |
| ------------------ | :-----------: | :----------: | :-----------: | :----------: | :-----------: | :----------: | :------------: |
| `Populator`        |      ✅       |              |      ✅       |              |               |              |                |
| `Validator`        |      ✅       |              |      ✅       |              |               |              |                |
| `Handler`          |    marker     |      ✅      |    marker     |      ✅      |      ✅       |      ✅      |       ✅       |
| `ParentQuery`      |      ✅       |      ✅      |      ✅       |      ✅      |               |              |       ✅       |
| `PriorParentQuery` |               |              |      ✅       |      ✅      |      ✅       |      ✅      |                |
| `RelatedQuery`     |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |
| `Bypassable`       |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |
| `RecursionGuard`   |               |              |      ✅       |      ✅      |               |              |                |
| `Finalizer`        |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |
| `ContinueOnError`  |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |

"marker" means `Handler` exists in that context only as an empty interface that `Populator` and `Validator` extend, so the orchestrator list has a type. You never implement it directly.

No interface opts a handler out of the before-context DML guard. DML in a before insert or before update handler is always rejected. See [No DML in Before Contexts](/guide/handlers#no-dml-in-before-contexts).

## Populator

Available in before insert and before update. Writes fields on the triggering record.

```apex
public interface Populator extends Handler {
  Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record);
  void populateOnBeforeInsert(TriggerHandler.InsertRecord record);
}
```

| Context       | Methods                                                | Record                        |
| ------------- | ------------------------------------------------------ | ----------------------------- |
| Before Insert | `populateOnBeforeInsertWhen`, `populateOnBeforeInsert` | `TriggerHandler.InsertRecord` |
| Before Update | `populateOnBeforeUpdateWhen`, `populateOnBeforeUpdate` | `TriggerHandler.UpdateRecord` |

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

## Validator

Available in before insert and before update. Returns the message for records that must be blocked. The framework attaches it with `addError`; the validator never calls `addError` itself and has no action method.

```apex
public interface Validator extends Handler {
  Boolean errorShouldBeAttachedOnBeforeInsertWhen(
    TriggerHandler.InsertRecord record
  );
  String beforeInsertValidationMessage(TriggerHandler.InsertRecord record);
}
```

| Context       | Methods                                                                    | Record                        |
| ------------- | -------------------------------------------------------------------------- | ----------------------------- |
| Before Insert | `errorShouldBeAttachedOnBeforeInsertWhen`, `beforeInsertValidationMessage` | `TriggerHandler.InsertRecord` |
| Before Update | `errorShouldBeAttachedOnBeforeUpdateWhen`, `beforeUpdateValidationMessage` | `TriggerHandler.UpdateRecord` |

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

The returned string is the DML error message, verbatim.

::: warning Exactly one role per context
A class in `beforeInsertHandlers()` or `beforeUpdateHandlers()` must implement exactly one of `Populator` and `Validator` for that context. Implementing both, or neither, aborts the invocation with a `TriggerOrchestratorException` naming the class and both interfaces, before any handler runs. Roles in different contexts are independent: `BeforeInsert.Populator` and `BeforeUpdate.Validator` on one class is allowed.
:::

## Handler

In after insert, after update, before delete, after delete and after undelete, `Handler` is the interface a handler implements. It qualifies records and processes each qualified one.

```apex
public interface Handler {
  Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record);
  void onAfterInsert(TriggerHandler.InsertRecord record);
}
```

| Context        | Methods                                            | Record                          |
| -------------- | -------------------------------------------------- | ------------------------------- |
| After Insert   | `qualifiesForAfterInsertWhen`, `onAfterInsert`     | `TriggerHandler.InsertRecord`   |
| After Update   | `qualifiesForAfterUpdateWhen`, `onAfterUpdate`     | `TriggerHandler.UpdateRecord`   |
| Before Delete  | `qualifiesForBeforeDeleteWhen`, `onBeforeDelete`   | `TriggerHandler.DeleteRecord`   |
| After Delete   | `qualifiesForAfterDeleteWhen`, `onAfterDelete`     | `TriggerHandler.DeleteRecord`   |
| After Undelete | `qualifiesForAfterUndeleteWhen`, `onAfterUndelete` | `TriggerHandler.UndeleteRecord` |

In before insert and before update the same name is an empty interface:

```apex
public interface Handler {
}
```

`BeforeInsert.Handler` and `BeforeUpdate.Handler` are the element types of `beforeInsertHandlers()` and `beforeUpdateHandlers()` and nothing more.

See [Handlers](/guide/handlers) and [Record Qualification](/guide/qualification).

## ParentQuery

Declares parent fields to query for the new version of each record. Read them with `record.getNewParent(relationshipName)`.

```apex
public interface ParentQuery {
  Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert();
}
```

| Context        | Method                        |
| -------------- | ----------------------------- |
| Before Insert  | `queryParentsOnBeforeInsert`  |
| After Insert   | `queryParentsOnAfterInsert`   |
| Before Update  | `queryParentsOnBeforeUpdate`  |
| After Update   | `queryParentsOnAfterUpdate`   |
| After Undelete | `queryParentsOnAfterUndelete` |

See [Parent Enrichment](/guide/enrichment) and [TriggerHandler.ParentFields](/api/field-selection).

## PriorParentQuery

Declares parent fields to query for the old version of each record. Read them with `record.getOldParent(relationshipName)`.

```apex
public interface PriorParentQuery {
  Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate();
}
```

| Context       | Method                            |
| ------------- | --------------------------------- |
| Before Update | `queryPriorParentsOnBeforeUpdate` |
| After Update  | `queryPriorParentsOnAfterUpdate`  |
| Before Delete | `queryParentsOnBeforeDelete`      |
| After Delete  | `queryParentsOnAfterDelete`       |

The two sides are declared independently. Declaring a lookup on the new side does not attach a parent to the old record.

## RelatedQuery

Names the providers a handler reads. The framework runs each one once, before the first record, and the handler reads the result with `record.getRelated(providerName)`.

```apex
public interface RelatedQuery {
  Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate();
}
```

| Context        | Method                        |
| -------------- | ----------------------------- |
| Before Insert  | `queryRelatedOnBeforeInsert`  |
| After Insert   | `queryRelatedOnAfterInsert`   |
| Before Update  | `queryRelatedOnBeforeUpdate`  |
| After Update   | `queryRelatedOnAfterUpdate`   |
| Before Delete  | `queryRelatedOnBeforeDelete`  |
| After Delete   | `queryRelatedOnAfterDelete`   |
| After Undelete | `queryRelatedOnAfterUndelete` |

## RecordsProvider

One query and one key. Declared per context, so `query` receives that context's collection.

```apex
public interface RecordsProvider {
  List<SObject> query(TriggerHandler.UpdateRecords records);
  String keyOf(SObject record);
}
```

See [Related Records](/guide/related-records) and [the API](/api/related-records).

## Bypassable

Skips the handler for the current invocation when the method returns `true`. It is asked once per invocation, not per record.

```apex
public interface Bypassable {
  Boolean bypassOnBeforeInsertWhen();
}
```

| Context        | Method                      |
| -------------- | --------------------------- |
| Before Insert  | `bypassOnBeforeInsertWhen`  |
| After Insert   | `bypassOnAfterInsertWhen`   |
| Before Update  | `bypassOnBeforeUpdateWhen`  |
| After Update   | `bypassOnAfterUpdateWhen`   |
| Before Delete  | `bypassOnBeforeDeleteWhen`  |
| After Delete   | `bypassOnAfterDeleteWhen`   |
| After Undelete | `bypassOnAfterUndeleteWhen` |

A handler already bypassed in metadata never has this method called. See [Bypasses](/guide/bypasses).

## RecursionGuard

Available in before update and after update only. Overrides how many times the handler may process one record in a transaction.

```apex
public interface RecursionGuard {
  Integer maxRecursionDepthOnBeforeUpdate();
}
```

| Context       | Method                            |
| ------------- | --------------------------------- |
| Before Update | `maxRecursionDepthOnBeforeUpdate` |
| After Update  | `maxRecursionDepthOnAfterUpdate`  |

The depth is resolved in three steps, each overriding the one before it: the framework default of `3`, then [`TriggerOrchestrator.RecursionGuard`](/api/trigger-orchestrator#recursionguard) on the orchestrator, then this interface on the handler, which always wins. A record over the budget is skipped silently for that handler, with no exception and nothing logged.

See [Recursion Control](/guide/recursion-control).

## Finalizer

Runs once after the handler processed its last qualified record, and before the next handler in the list starts. It does not run when the handler qualified no records.

```apex
public interface Finalizer {
  void finalizeBeforeInsert();
}
```

| Context        | Method                  |
| -------------- | ----------------------- |
| Before Insert  | `finalizeBeforeInsert`  |
| After Insert   | `finalizeAfterInsert`   |
| Before Update  | `finalizeBeforeUpdate`  |
| After Update   | `finalizeAfterUpdate`   |
| Before Delete  | `finalizeBeforeDelete`  |
| After Delete   | `finalizeAfterDelete`   |
| After Undelete | `finalizeAfterUndelete` |

In before insert and before update the DML guard covers the finalizer as well, so a finalizer there cannot perform DML either. See [Finalizers](/guide/finalizers).

## ContinueOnError

Marker interface. An exception raised by the handler's own code is passed to the logger and the orchestrator continues with the next handler, so the DML succeeds.

```apex
public interface ContinueOnError {
}
```

It covers a handler's own exceptions only. A `TriggerOrchestratorException` and a `TriggerHandler.TriggerHandlerException` are logged and then rethrown even for a handler that implements it, and the DML is aborted. See [Error Handling](/guide/error-handling).
