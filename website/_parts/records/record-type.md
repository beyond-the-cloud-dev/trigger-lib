`isRecordTypeEqual(developerName)` and `isRecordTypeNotEqual(developerName)` compare the record's `RecordTypeId` with the Id of the record type that has that developer name, the API name shown as Record Type Name in Setup, not the label. They read the same row as the value predicates. The lookup uses the cached schema describe, so it costs no SOQL.

```apex
return record.isRecordTypeEqual('Partner') && record.isNotBlank(Account.Website);
```

- **Objects without record types throw.** When the object has only the master record type, both methods throw `TriggerHandler.TriggerHandlerException` ("`<Object>` has no record types, so isRecordTypeEqual cannot be used on it."). ContinueOnError does not swallow it, so the save fails → [`TriggerHandlerException`](/api/record#triggerhandlerexception).
- **An unknown name does not throw.** A misspelled developer name, or a label passed instead, resolves to no Id, so `isRecordTypeEqual` is false and `isRecordTypeNotEqual` is true for every record that has a record type.
- **A change of record type** needs change detection on `RecordTypeId`, and change detection exists only in the update contexts.
- **In a unit test**, set `RecordTypeId` on the row you pass to `new TriggerHandler.TriggerRecord(…)`, for example from `Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId()`. A row without it matches no record type.
