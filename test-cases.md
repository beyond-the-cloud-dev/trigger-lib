# Test Cases

Behaviour the library is expected to guarantee. Every row is a scenario that should be covered by a test.

| Test name | Description | Expected result |
| --- | --- | --- |
| **Dispatch** | | |
| Before insert dispatch | Trigger fires `before insert`, orchestrator implements `TriggerOrchestrator.BeforeInsert` | Handlers from `beforeInsertHandlers()` run |
| After insert dispatch | Trigger fires `after insert`, orchestrator implements `TriggerOrchestrator.AfterInsert` | Handlers from `afterInsertHandlers()` run |
| Before update dispatch | Trigger fires `before update`, orchestrator implements `TriggerOrchestrator.BeforeUpdate` | Handlers from `beforeUpdateHandlers()` run |
| After update dispatch | Trigger fires `after update`, orchestrator implements `TriggerOrchestrator.AfterUpdate` | Handlers from `afterUpdateHandlers()` run |
| Before delete dispatch | Trigger fires `before delete`, orchestrator implements `TriggerOrchestrator.BeforeDelete` | Handlers from `beforeDeleteHandlers()` run |
| After delete dispatch | Trigger fires `after delete`, orchestrator implements `TriggerOrchestrator.AfterDelete` | Handlers from `afterDeleteHandlers()` run |
| After undelete dispatch | Trigger fires `after undelete`, orchestrator implements `TriggerOrchestrator.AfterUndelete` | Handlers from `afterUndeleteHandlers()` run |
| Unimplemented context | Trigger declares all seven events, orchestrator implements only some | Unimplemented events are a silent no-op, DML succeeds |
| Called outside a trigger | `TriggerOrchestrator.run()` invoked from anonymous Apex or a service class | `TriggerOrchestratorException` stating it was called outside trigger context |
| **Roles** | | |
| Populator populates | Before-context populator sets a field on the trigger record | Field value persists after save |
| Populator qualification | Populator's `populateOn...When` returns false for a record | Populator's action method is never called for that record |
| Validator blocks | Validator's `errorShouldBeAttachedOn...When` returns true | Record is blocked and carries the validator's message |
| Validator passes | Validator's predicate returns false | Record saves untouched |
| Validator message source | Validator supplies the message via `...ValidationMessage` | That exact string is the DML error message |
| Registration order | Handlers execute in the order returned by the orchestrator's list | Execution order matches list order, regardless of role |
| No main interface | Class implements only the marker `Handler` for a context that has roles | Rejected with a `TriggerOrchestratorException` naming the class and both interfaces it could implement |
| Two main interfaces, same context | Class implements both `Populator` and `Validator` for the same context | Rejected with a `TriggerOrchestratorException` naming the class and both interfaces |
| Two main interfaces, different contexts | Class implements `BeforeInsert.Populator` and `BeforeUpdate.Populator` | Allowed, each context runs its own method and each lifecycle callback fires once |
| **Enrichment** | | |
| Parent enrichment, new side | Handler declares `ParentQuery` for a lookup field | `getNewRelated` returns the parent with the declared fields |
| Parent enrichment, old side | Handler declares `PriorParentQuery` for a lookup field | `getOldRelated` returns the prior parent |
| Enrichment not declared | Handler reads a relationship it never declared | `getNewRelated` returns null, no query is issued |
| Lookup field unset | Trigger record has no value in the declared lookup | No parent is fetched for that record, no error |
| Enrichment query count | Several handlers declare the same parent field | One query per parent field per invocation |
| Lookup re-pointed by a handler | A before-context handler changes a declared lookup, a later handler reads that relationship | The later handler receives the parent the record now points at, not the original one |
| Lookup populated from null | A before-context handler sets a declared lookup that was empty | The later handler receives the newly referenced parent instead of null |
| Re-point query cost | Two hundred records each re-pointed to a different parent, then read | One additional query for the whole chunk, covering only the changed lookup field. Never one query per record |
| No re-point, many handlers | Ten handlers run and none changes a declared lookup | No extra queries at all. The cost stays at one query per parent field for the whole invocation |
| Parent already fetched | A handler re-points a record to a parent already loaded for another record | No query is issued. Parents are cached by id for the invocation, hits and misses alike |
| Old side never refreshes | A handler changes a lookup that is also declared for the old side | `getOldRelated` is unchanged. `Trigger.old` is immutable, so the old side is resolved on the first pass and never re-queried, in every context |
| Refresh only where records can change | Handlers run in after insert, after update, a delete context or after undelete | Parents are resolved once. No re-check happens between handlers, because no handler can change a record in those contexts |
| Both sides in one pass | After-update handler declares the same lookup for both sides and the lookup changed | `getOldRelated` returns the prior parent and `getNewRelated` the current one, resolved together in a single query |
| **Qualification** | | |
| Qualified record registered | Handler's qualify method returns true | Handler's action runs for that record |
| Unqualified record skipped | Handler's qualify method returns false | Handler's action never runs for that record |
| **Bypass** | | |
| Bypassable handler | Handler implements `Bypassable` and returns true | Handler is skipped entirely, others still run |
| Metadata handler bypass | `TriggerHandler__mdt` names the class with `Bypass__c` true | That handler is skipped, others still run |
| Metadata object bypass | `TriggerObject__mdt` for the object has `Bypass__c` true | No handler runs for that object, DML succeeds |
| Metadata inner class, qualified name | Metadata names an inner-class handler as `Outer.Inner` | Handler is bypassed |
| Metadata inner class, simple name | Metadata names the same handler as `Inner` | Handler is bypassed. Two inner classes sharing a simple name are bypassed together |
| Zero metadata records | No `TriggerObject__mdt` records exist | Every handler runs, no behaviour change, no SOQL consumed |
| Metadata query cost | Metadata is read during a trigger invocation | Zero SOQL queries consumed against the governor limit |
| **Recursion** | | |
| Default recursion depth | Update handler re-enters without a `RecursionGuard` | Handler stops after three passes per record |
| Custom recursion depth | Update handler implements `RecursionGuard` returning two | Handler stops after two passes per record |
| Orchestrator recursion depth | Orchestrator implements `TriggerOrchestrator.RecursionGuard` returning five, handler declares none | Every handler of that orchestrator stops after five passes per record instead of three |
| Handler depth beats orchestrator depth | Orchestrator returns five, one handler implements the context `RecursionGuard` returning two | That handler stops after two passes, every other handler of the orchestrator stops after five |
| No guard anywhere | Neither orchestrator nor handler implements a `RecursionGuard` | The framework default of three passes per record applies |
| Validators are not counted | A before update `Validator` re-enters, with or without a `RecursionGuard` | It runs on every pass. A validator that qualifies ends its record's save, so it cannot re-enter and needs no cap. `BeforeUpdate.RecursionGuard` on a validator is inert |
| Depth below one | A `RecursionGuard` returns zero or a negative number | `TriggerOrchestratorException` naming the class and the method that returned it, stating the minimum is one. Never a silently disabled handler |
| Depth of null | A `RecursionGuard` returns null | `TriggerOrchestratorException` naming the class and the method. Never an unguarded handler |
| Depth of one | A `RecursionGuard` returns one | The handler runs once per record and is skipped on every re-entry. This is the value for run-exactly-once, not zero |
| Counter scope | Two records updated in one DML, handler guarded at two passes | Each record carries its own budget. The handler runs twice for each record, four times in total. The counter is keyed by handler class, operation and record id, so one record exhausting its budget never affects another |
| Counter is per handler | Two handlers in the same context, one re-enters | Each handler has its own independent budget for the same record. One handler exhausting its passes does not consume another handler's |
| Limit reached | A record reaches the handler more times than its guard allows | The handler is skipped silently for that record. No exception is thrown, nothing reaches the `Logger`, and the DML succeeds |
| Chunking is not recursion | One DML of 201 records | Depth counter is unaffected, all records processed |
| **Errors and logging** | | |
| ContinueOnError swallows handler failures | Handler implements `ContinueOnError` and its own logic throws | DML succeeds, remaining handlers still run |
| Without ContinueOnError | Handler throws and does not implement `ContinueOnError` | DML is aborted and the exception propagates |
| Logger receives continue-on-error | A `ContinueOnError` handler throws, a `Logger` is implemented | Logger receives the error with handler name and operation |
| Logger receives uncaught error | A handler throws without `ContinueOnError`, a `Logger` is implemented | Logger receives the error before the exception propagates |
| Logger receives guard violations | A before-context handler performs DML while a `Logger` is implemented | Logger receives the `TriggerOrchestratorException` before it propagates |
| Logger finalize scope | A `Logger` is implemented and a DML fires a trigger | `finalize` runs once per top-level invocation, meaning once per trigger phase per chunk, not once per transaction |
| Logger finalize ignores nested DML | A handler performs DML that fires another trigger through the orchestrator | The nested invocation does not call `finalize`. Only the outermost invocation does |
| Multiple Logger implementations | Two classes implement `TriggerOrchestrator.Logger` | `TriggerOrchestratorException` stating only one is allowed |
| Empty handler list | Orchestrator returns an empty list | Nothing runs, DML succeeds |
| **Before-context DML guard** | | |
| DML in a populator | Before-context populator performs DML | `TriggerOrchestratorException` naming the handler, DML rolled back |
| DML in a validator | Before-context validator performs DML | `TriggerOrchestratorException` naming the handler |
| DML in a finalizer | Before-context finalizer performs DML | `TriggerOrchestratorException` naming the handler |
| DML in a qualification predicate | Before-context handler performs DML inside its `...When` method | `TriggerOrchestratorException` naming the handler, DML rolled back. The guard spans the handler's whole turn, qualification included |
| Immediate platform event | Before-context handler publishes an immediate event | Treated as DML and rejected |
| DML in an after context | After-context handler performs DML on other records | Allowed, no exception |
| ContinueOnError does not suppress the guard | Before-context handler implements `ContinueOnError` and performs DML | Guard still throws, DML is aborted, nothing is committed. `ContinueOnError` covers a handler's own exceptions, never a framework contract violation |
| Guard survives a handler exception | Before-context handler performs DML and then throws, with `ContinueOnError` | Guard still throws and names the handler, DML is aborted, nothing is committed. Throwing after the DML must not be a way past the guard |
| Handler exception without DML | Before-context handler throws and performs no DML, with `ContinueOnError` | Guard stays silent, the handler's error is swallowed and the DML succeeds |
| Framework exceptions are never suppressible | Any `TriggerOrchestratorException` is raised while the handler implements `ContinueOnError` | Exception propagates and the DML is aborted |
| **Exceptions** | | |
| `put` in an after context | After-insert or after-update handler calls `put` | Raises `System.FinalException: Record is read-only`. Uncatchable, so the handler's own try and catch cannot stop it and the whole transaction is lost. Not prevented by the type system, because `InsertRecord` and `UpdateRecord` serve both the before and after phases |
| Framework failures use one type | Any contract violation the framework itself detects | Raised as `TriggerOrchestratorException`, never as a bare platform exception |
| Framework failures are never suppressed | A `TriggerOrchestratorException` is raised while the handler implements `ContinueOnError` | Logged, then rethrown. `ContinueOnError` covers a handler's own exceptions only |
| Platform exceptions are not translated | A handler triggers a platform error such as an invalid field or a bad cast | Propagates unchanged, so the original Salesforce message and type reach the caller |
| **Finalizers** | | |
| Finalizer runs once | Handler implements `Finalizer` and qualifies records | Finalizer fires exactly once after the handler's records |
| Finalizer with no records | Handler qualifies no records | Finalizer does not fire |
| **Bulk and chunking** | | |
| 201 records | Single DML crossing the 200-record chunk boundary | Every record processed exactly once per attempt |
| Statics across chunks | Handler keeps state in a static across chunks | Records beyond 200 are not skipped |
| Partial save retry | `Database.insert(records, false)` with one record failing | Survivors commit, handlers remain correct under the re-run |
| **Delete and undelete** | | |
| Delete context record shape | Handler runs in before or after delete | New record is null, old record is populated |
| Insert context record shape | Handler runs in before or after insert | Old record is null, new record is populated |
| After undelete | Records are restored | Handlers run with an empty old side |
| Merge frame | Losing records fire delete triggers during a merge | Handler can detect the merge and reach the winning record id |
| **Record API** | | |
| Change detection | `isChanged`, `isChangedTo`, `isChangedFrom` on an update | Reflect the difference between old and new values |
| Null and blank helpers | `isNull`, `isBlank`, `isEmpty` and their negations | Match the field value on the relevant record side |
| Numeric comparison | `greaterThan` and `lessThan` across Integer, Long, Decimal, Date | Correct result, no precision loss for Long values |
| Record type helpers | `isRecordTypeEqual` or `isRecordTypeNotEqual` on an object with no record types beyond Master | `TriggerHandlerException` naming the SObject, not a raw `SObjectException: Invalid field RecordTypeId` |
| Record type helpers on a record-typed object | `isRecordTypeEqual` on an object that does have record types | Compares the record's `RecordTypeId` against the named developer name |
| Field write | `put` on a before-context record | Value is visible to later handlers and persists |
