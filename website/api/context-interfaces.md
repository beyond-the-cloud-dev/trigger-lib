---
outline: deep
---

# Context Interfaces

Each trigger context has its own top-level class that groups the interfaces a handler can implement: `BeforeInsert`, `AfterInsert`, `BeforeUpdate`, `AfterUpdate`, `BeforeDelete`, `AfterDelete` and `AfterUndelete`.

Method names carry the context name, so one class can implement several contexts without clashes.

## Availability Matrix

| Interface             | Before Insert | After Insert | Before Update | After Update | Before Delete | After Delete | After Undelete |
| --------------------- | :-----------: | :----------: | :-----------: | :----------: | :-----------: | :----------: | :------------: |
| `Handler`             |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |
| `NewRecordEnrichment` |      ✅       |      ✅      |      ✅       |      ✅      |               |              |       ✅       |
| `OldRecordEnrichment` |               |              |      ✅       |      ✅      |      ✅       |      ✅      |                |
| `Bypassable`          |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |
| `RecursionGuard`      |               |              |      ✅       |      ✅      |               |              |                |
| `Finalizer`           |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |
| `AllowDmls`           |      ✅       |              |      ✅       |              |               |              |                |
| `ContinueOnError`     |      ✅       |      ✅      |      ✅       |      ✅      |      ✅       |      ✅      |       ✅       |

## Handler

Required. Qualifies records and processes each qualified one.

```apex
public interface Handler {
  Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record);
  void onBeforeInsert(TriggerHandler.Record record);
}
```

| Context        | Methods                                            |
| -------------- | -------------------------------------------------- |
| Before Insert  | `qualifiesForBeforeInsertWhen`, `onBeforeInsert`   |
| After Insert   | `qualifiesForAfterInsertWhen`, `onAfterInsert`     |
| Before Update  | `qualifiesForBeforeUpdateWhen`, `onBeforeUpdate`   |
| After Update   | `qualifiesForAfterUpdateWhen`, `onAfterUpdate`     |
| Before Delete  | `qualifiesForBeforeDeleteWhen`, `onBeforeDelete`   |
| After Delete   | `qualifiesForAfterDeleteWhen`, `onAfterDelete`     |
| After Undelete | `qualifiesForAfterUndeleteWhen`, `onAfterUndelete` |

See [Handlers](/guide/handlers) and [Record Qualification](/guide/qualification).

## NewRecordEnrichment

Declares parent fields to query for the new version of each record. Read them with `record.getNewRelated(relationshipName)`.

```apex
public interface NewRecordEnrichment {
  Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert();
}
```

| Context        | Method                             |
| -------------- | ---------------------------------- |
| Before Insert  | `newFieldsToEnrichOnBeforeInsert`  |
| After Insert   | `newFieldsToEnrichOnAfterInsert`   |
| Before Update  | `newFieldsToEnrichOnBeforeUpdate`  |
| After Update   | `newFieldsToEnrichOnAfterUpdate`   |
| After Undelete | `newFieldsToEnrichOnAfterUndelete` |

See [Parent Enrichment](/guide/enrichment).

## OldRecordEnrichment

Declares parent fields to query for the old version of each record. Read them with `record.getOldRelated(relationshipName)`.

```apex
public interface OldRecordEnrichment {
  Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeUpdate();
}
```

| Context       | Method                            |
| ------------- | --------------------------------- |
| Before Update | `oldFieldsToEnrichOnBeforeUpdate` |
| After Update  | `oldFieldsToEnrichOnAfterUpdate`  |
| Before Delete | `oldFieldsToEnrichOnBeforeDelete` |
| After Delete  | `oldFieldsToEnrichOnAfterDelete`  |

## Bypassable

Skips the handler for the current invocation when the method returns `true`.

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

See [Bypasses](/guide/bypasses).

## RecursionGuard

Overrides the default depth of 3 for update contexts.

```apex
public interface RecursionGuard {
  Integer maxRecursionDepthOnBeforeUpdate();
}
```

| Context       | Method                            |
| ------------- | --------------------------------- |
| Before Update | `maxRecursionDepthOnBeforeUpdate` |
| After Update  | `maxRecursionDepthOnAfterUpdate`  |

See [Recursion Control](/guide/recursion-control).

## Finalizer

Runs once after all qualified records were processed.

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

See [Finalizers](/guide/finalizers).

## AllowDmls

Marker interface. Disables the DML guard for a before insert or before update handler.

```apex
public interface AllowDmls {
}
```

See [Before Context DML](/guide/handlers#before-context-dml).

## ContinueOnError

Marker interface. Exceptions from the handler are logged and the orchestrator continues with the next handler.

```apex
public interface ContinueOnError {
}
```

See [Error Handling](/guide/error-handling).
