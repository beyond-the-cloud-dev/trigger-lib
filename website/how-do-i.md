---
description: Task index for Trigger Lib. Each question gets a one-line answer and links to the page in every context that covers it, from registering handlers to bypassing triggers during a data migration.
---

# How do I…

Find your task below. Each question has a one-line answer and links to the page that covers it, one link per trigger context where the answer differs, so pick the context you are working in.

## Wire & Register {#wire-and-register}

### What do I deploy (dependencies, SOQL Lib, DML Lib)? {#deploy}

The `force-app` folder: library classes, two metadata types, SOQL Lib, DML Lib.

[Installation](/installation)

### What goes in the trigger body? {#trigger-body}

One call, `TriggerOrchestrator.run(new AccountTriggerOrchestrator());`, with all seven events listed.

[Trigger & Orchestrator](/guide/orchestrator#trigger)

### Register handlers for a context (orchestrator, handler list, order) {#register}

Implement the context's `TriggerOrchestrator` interface; list handlers in run order.

<!--@include: @/_parts/generated/chips/overview/register.md-->

### A context my orchestrator does not implement, or an empty list {#unimplemented}

Nothing runs: the context is skipped silently, with no error.

[Trigger & Orchestrator](/guide/orchestrator#unimplemented)

### Call `run()` outside a trigger (anonymous Apex, service class) {#outside-a-trigger}

It throws `TriggerOrchestratorException`; call it only while a trigger is running.

[Trigger & Orchestrator](/guide/orchestrator#outside-a-trigger)

### One class in several contexts (insert and update, insert and undelete) {#one-class-several-contexts}

Implement each context's interfaces and add one instance per context list.

[Trigger & Orchestrator](/guide/orchestrator#one-class-several-contexts) · [AfterUndelete: Pick a Role](/after-undelete/#pick-a-role)

### Are handler instances reused across chunks (instance fields, statics)? {#instances-per-chunk}

The list method runs every chunk: new instances reset fields; statics persist.

[Trigger & Orchestrator](/guide/orchestrator#instances-per-chunk)

### Pass constructor arguments to a handler {#constructor-args}

Pass them where you build the handler list in the orchestrator.

[Trigger & Orchestrator](/guide/orchestrator#constructor-args)

### Check that a handler is registered (registration test) {#registration-test}

Assert the orchestrator's handler list method returns an instance of your class.

[Testing](/guide/testing#registration)

## Choose Where Code Goes {#choose-where-code-goes}

### Which context and role do I need? {#which-context}

Find your trigger event and job in the method-name matrix.

[Contexts at a Glance](/contexts#method-names)

### Writer or Dispatcher (DML or async)? {#writer-or-dispatcher}

Writer: DML per record. Dispatcher: one bulk call for async work.

<!--@include: @/_parts/generated/chips/writer/when-to-use.md-->

### A class with two roles, or only the marker (Populator and Validator, Writer and Dispatcher) {#two-roles}

Populator beats Validator, Writer beats Dispatcher; marker-only classes never run.

<!--@include: @/_parts/generated/chips/overview/pick-a-role.md-->

### Before delete or after delete? {#before-or-after-delete}

Before delete to veto or read children; after delete for unit-of-work writes.

[BeforeDelete: Pick a Role](/before-delete/#pick-a-role) · [AfterDelete: Pick a Role](/after-delete/#pick-a-role)

### Decide before update, act after update (stamp a marker, handoff) {#before-after-handoff}

Stamp a field in a BeforeUpdate Populator; qualify on it after update.

[Trigger & Orchestrator](/guide/orchestrator#before-after-handoff)

## Set Fields {#set-fields}

### Set, default or derive a field before save (populate, stamp) {#set-a-field}

A Populator in before insert or update calls `record.put(field, value)`.

<!--@include: @/_parts/generated/chips/populator/interface.md-->

### Which record type do I get, and how do I read or write a field? {#record-types}

`InsertRecord`, `UpdateRecord`, `DeleteRecord` or `UndeleteRecord`, by operation; accessors differ per context.

<!--@include: @/_parts/generated/chips/record-api/accessors.md-->

### Call `put()` after insert or after update {#put-after-save}

It compiles but throws an uncatchable `FinalException`; register a `toUpdate` instead.

<!--@include: @/_parts/generated/chips/record-api/accessors.md-->

### Update the record I just inserted (self-update) {#self-update}

Prefer a BeforeInsert Populator; otherwise a Writer `toUpdate` with a new instance.

[AfterInsert Gotchas](/after-insert/#gotchas)

### Did a field change (old value, `isChanged`, cleared)? {#did-it-change}

Update contexts only: `isChanged`, `isChangedTo(field, null)` for cleared, `getOldSObject()`.

<!--@include: @/_parts/generated/chips/record-api/change-detection.md-->

### Value predicates, null and case sensitivity (`equals`, `contains`) {#predicates}

`equals` ignores case; `contains`, `startsWith` and `endsWith` are case-sensitive.

<!--@include: @/_parts/generated/chips/record-api/comparisons.md-->

### Check the record type {#check-record-type}

`record.isRecordTypeEqual('Developer_Name')` compares developer names without SOQL.

<!--@include: @/_parts/generated/chips/record-api/record-type.md-->

### `Trigger.new`, `newMap` and `oldMap` equivalents (bulk, pairing) {#trigger-variables}

One row per call: `record.getNewSObject()`; no maps, key by `record.getId()`.

<!--@include: @/_parts/generated/chips/record-api/trigger-variables.md-->

## Validate & Block {#validate-and-block}

### Block a save with an error message (validation, reject) {#block-a-save}

Implement a Validator; call `record.addError(message)` in its error method.

<!--@include: @/_parts/generated/chips/validator/interface.md-->

### Attach the error to a field (field-level error) {#field-error}

`record.addError(Account.Industry, message)`; Name and address fields lose field attribution.

<!--@include: @/_parts/generated/chips/validator/gotchas.md-->

### Translated error message (custom label) {#translated-message}

Pass a custom label, such as `System.Label.MyMessage`, as the message.

<!--@include: @/_parts/generated/chips/validator/gotchas.md-->

### Several validators fail on one record; use parent or related data {#several-validators}

Each rejecting Validator adds its message; ParentQuery and RelatedQuery supply data.

<!--@include: @/_parts/generated/chips/validator/how-it-runs.md-->

### Validate after save (needs the Id or saved state) {#validate-after-save}

No after Validator: call `record.getNewSObject().addError(…)` from a Writer.

[AfterInsert: Not Available Here](/after-insert/#not-available) · [AfterUpdate: Not Available Here](/after-update/#not-available)

### Prevent a delete (veto, block) {#prevent-delete}

A BeforeDelete Handler calls `record.getOldSObject().addError(message)`.

[BeforeDelete.Handler](/before-delete/handler)

### Block an undelete (restore, before undelete) {#block-undelete}

No before undelete: `record.getNewSObject().addError(…)` in AfterUndelete vetoes the restore.

[AfterUndelete: There Is No BeforeUndelete](/after-undelete/#no-before-undelete) · [No BeforeUndelete](/before-undelete)

## Read Parents {#read-parents}

### Read parent (lookup) fields {#parent-fields}

Declare a ParentQuery, then read `record.getNewParent('Account')`; no SOQL in handlers.

<!--@include: @/_parts/generated/chips/parent-query/how-it-runs.md-->

[BeforeDelete: PriorParentQuery](/before-delete/add-ons/prior-parent-query#how-it-runs) · [AfterDelete: PriorParentQuery](/after-delete/add-ons/prior-parent-query#how-it-runs)

### Read the previous parent (old lookup, prior owner) {#previous-parent}

Update and delete contexts: declare a PriorParentQuery, read `record.getOldParent('Account')`.

<!--@include: @/_parts/generated/chips/prior-parent-query/how-it-runs.md-->

### Read grandparent fields (`Account.Owner.IsActive`) {#grandparent-fields}

Add `.with('Owner', User.IsActive)` to the parent's `TriggerHandler.ParentFields`.

<!--@include: @/_parts/generated/chips/parent-query/choosing-fields.md-->

### A populator re-points a lookup: which parent do later handlers see? {#re-pointed-lookup}

The new parent: parents are re-queried after each Populator re-points a lookup.

[BeforeUpdate.ParentQuery: How It Runs](/before-update/add-ons/parent-query#how-it-runs)

### Parent sharing, FLS and polymorphic lookups {#parent-sharing}

System mode without sharing; polymorphic lookups have type and field limits.

<!--@include: @/_parts/generated/chips/parent-query/gotchas.md-->

## Read Other Records {#read-other-records}

### Query children, siblings or unrelated records (related records) {#related-records}

Declare a RelatedQuery with named providers; read `record.getRelated('name')`.

<!--@include: @/_parts/generated/chips/related-query/key-patterns.md-->

### Match on a text key or a composite key; load config {#text-key}

Return the key from `keyOf`; look it up with `getFirstWhereKeyEquals(key)`.

<!--@include: @/_parts/generated/chips/related-query/key-patterns.md-->

### Read formula or system fields of the records being saved (re-query) {#requery-self}

A provider re-queries `WHERE Id IN :records.getIds()` after insert, update, undelete.

<!--@include: @/_parts/generated/chips/related-query/key-patterns.md-->

### Query related records in after delete {#related-after-delete}

Deleted rows are invisible to SOQL; key providers by the old lookups.

[AfterDelete.RelatedQuery: How It Runs](/after-delete/add-ons/related-query#how-it-runs)

### Does a provider see all records, share results, respect sharing? {#provider-scope}

Yes, all records; no, private per handler; its own class's sharing.

<!--@include: @/_parts/generated/chips/related-query/how-it-runs.md-->

## Write Other Records {#write-other-records}

### Insert, update, upsert, delete or publish (unit of work) {#unit-of-work}

A Writer's unit: `toInsert`, `toUpdate`, `toUpsert`, `toDelete` or `toPublish`.

<!--@include: @/_parts/generated/chips/writer/unit-of-work-methods.md-->

### When does the unit commit, and in what order (duplicates, statement order)? {#commit-order}

Once after the last handler; DML Lib orders statements, merges duplicate updates.

<!--@include: @/_parts/generated/chips/writer/when-it-commits.md-->

### User mode, sharing, partial success, DML results (own unit of work) {#own-unit}

Implement OwnUnitOfWork and return a configured `new DML()`.

<!--@include: @/_parts/generated/chips/own-unit-of-work/configuring.md-->

### Write from a Finalizer (register in bulk) {#write-from-finalizer}

Keep the action's unit in a field; register from the Finalizer.

<!--@include: @/_parts/generated/chips/finalizer/how-it-runs.md-->

### DML in a before context (before insert, update, delete) {#dml-in-before}

Forbidden in before insert and update; allowed in before delete.

[BeforeInsert Gotchas](/before-insert/#gotchas) · [BeforeDelete.Finalizer](/before-delete/add-ons/finalizer)

### Run something once after the last chunk (end of DML) {#after-last-chunk}

No such hook: Finalizers and commits run once per 200-record chunk.

<!--@include: @/_parts/generated/chips/overview/not-available.md-->

## Async, Callouts, Events {#async-callouts-events}

### Enqueue a job, call out or send email (Queueable, async) {#enqueue}

Use a Dispatcher: enqueue one Queueable per chunk; callouts need async.

<!--@include: @/_parts/generated/chips/dispatcher/how-it-runs.md-->

### Publish a platform event (after commit, immediately) {#publish-event}

Writer `toPublish` or direct `EventBus.publish`; the event's Publish Behavior decides delivery.

<!--@include: @/_parts/generated/chips/writer/platform-events.md-->

### Trigger on a platform event or Change Data Capture object (subscribe, `__e`, `ChangeEvent`) {#event-triggers}

Only after insert exists; untested here, so treat as unsupported.

[AfterInsert Gotchas](/after-insert/#gotchas)

## Switch Off {#switch-off}

### Skip a handler on a condition (bypass, disable, skip records, in a batch) {#skip-a-handler}

Bypassable skips the whole handler per run; predicates skip single records.

<!--@include: @/_parts/generated/chips/bypassable/how-it-runs.md-->

### Turn everything off for a data load (migration, Data Loader) {#data-load}

Check `TriggerObject__mdt.Bypass__c` for the object, load, then uncheck it.

<!--@include: @/_parts/generated/chips/bypassable/data-migration.md-->

[Bypassing: During a Data Migration](/guide/bypasses#data-migration)

### Switch off one handler in production (metadata, no deploy) {#switch-off-in-production}

Check `Bypass__c` on the class's `TriggerHandler__mdt` record; no deploy needed.

[Custom Metadata: TriggerHandler__mdt](/api/custom-metadata#trigger-handler)

### Bypass from Apex (object, orchestrator, one handler, one DML) {#bypass-from-apex}

`TriggerOrchestrator.bypass()`: `sObject`, `orchestrator`, `handler`, `all`; inner classes: metadata or Bypassable.

<!--@include: @/_parts/generated/chips/bypassable/other-ways.md-->

[Bypassing: From Apex](/guide/bypasses#apex)

### Bypass for one user, profile or permission set {#bypass-per-user}

No built-in switch: check `FeatureManagement.checkPermission` in a Bypassable.

<!--@include: @/_parts/generated/chips/bypassable/other-ways.md-->

[Bypassing: Per User](/guide/bypasses#per-user)

### Bypass only one context (only after update) {#bypass-one-context}

Implement that context's Bypassable; metadata switches a class off everywhere.

<!--@include: @/_parts/generated/chips/overview/switching-off.md-->

### Do bypasses affect Flows or validation rules? {#bypass-scope}

No: bypasses skip only Trigger Lib handlers.

<!--@include: @/_parts/generated/chips/bypassable/other-ways.md-->

## Recursion {#recursion}

### Stop recursion (run once per record, re-fire, loop) {#stop-recursion}

Update Populators, Writers, Dispatchers: max 3 passes per record; RecursionGuard changes it.

<!--@include: @/_parts/generated/chips/recursion-guard/edge-values.md-->

### Are validators counted; can the orchestrator set a depth? {#recursion-validators}

Validators are never counted; each handler sets its own depth.

<!--@include: @/_parts/generated/chips/recursion-guard/works-with.md-->

### A recursion guard in insert, delete or undelete {#recursion-elsewhere}

Not available: RecursionGuard exists in BeforeUpdate and AfterUpdate only.

<!--@include: @/_parts/generated/chips/overview/add-ons.md-->

## Errors & Logging {#errors-and-logging}

### Let a handler fail without failing the save (ContinueOnError) {#continue-on-error}

Add ContinueOnError: most exceptions are logged and swallowed.

<!--@include: @/_parts/generated/chips/continue-on-error/still-throws.md-->

### Log errors (Logger, Error payload) {#log-errors}

Implement `TriggerOrchestrator.Logger` in one class; it is found automatically.

[Errors & Logging](/guide/error-handling#logger)

### Which library exceptions can I catch? {#library-exceptions}

`TriggerHandlerException` by type; `TriggerOrchestratorException` is private, so match its message.

[TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception) · [TriggerHandlerException](/api/record#triggerhandlerexception)

### Fail one record, not the whole save (uncaught exception) {#fail-one-record}

Catch it in the handler and call `addError` on that record.

[Errors & Logging: One Record](/guide/error-handling#one-record)

### Partial success (`Database.insert(list, false)`, retries) {#partial-success}

Salesforce re-runs handlers for surviving records; side effects can repeat.

<!--@include: @/_parts/generated/chips/overview/gotchas.md-->

## Delete & Undelete {#delete-and-undelete}

### What does before delete give me? {#before-delete}

Old rows, a Handler role, direct DML, and a veto with `addError`.

[BeforeDelete Gotchas](/before-delete/#gotchas)

### Update or re-delete the deleted record; merges {#deleted-record}

Updating it fails with `ENTITY_IS_DELETED`; merge losers carry `MasterRecordId`.

[AfterDelete Gotchas](/after-delete/#gotchas)

### What about after undelete (restored lookups)? {#after-undelete}

Restored rows are read-only; inbound lookups may not be back yet.

[AfterUndelete Gotchas](/after-undelete/#gotchas)

## Testing {#testing}

### Unit-test a handler without DML (fake Ids, parents, providers, unit of work) {#unit-test}

Wrap rows in `TriggerHandler.TriggerRecord` with `RandomIdGenerator` Ids; call methods directly.

[Populator](/guide/testing#predicates-actions):

<!--@include: @/_parts/generated/chips/populator/test.md-->

[Validator](/guide/testing#predicates-actions):

<!--@include: @/_parts/generated/chips/validator/test.md-->

[BeforeDelete.Handler](/before-delete/handler#test):

<!--@include: @/_parts/generated/chips/handler/test.md-->

[Writer](/guide/testing#writers):

<!--@include: @/_parts/generated/chips/writer/test.md-->

[Dispatcher](/guide/testing#dispatchers):

<!--@include: @/_parts/generated/chips/dispatcher/test.md-->

[Testing: Test a Handler Directly](/guide/testing#handler)

[Record API: Test API](/api/record#test-api)

### Run the whole orchestrator in a test (mock queries, metadata, logger) {#orchestrator-test}

Mock the metadata queries first; seams work in the same namespace only.

[Testing: Run the Orchestrator in a Test](/guide/testing#orchestrator) · [Mock Metadata](/guide/testing#mock-metadata)

### Test 201-record chunking {#chunking-test}

Use real DML in a separate integration test class.

[Testing: Integration Tests](/guide/testing#integration)

## Limits & Cost {#limits-and-cost}

### How much SOQL does one invocation cost (Logger discovery included)? {#soql-cost}

Parents and providers query per run; Logger discovery once per transaction.

[Execution Order & Cost: Query Cost](/guide/execution-order#query-cost)

### Can I query or do DML inside a predicate or action? {#query-in-predicate}

Avoid it: both run per record; declare add-ons or use a unit.

<!--@include: @/_parts/generated/chips/populator/how-it-runs.md-->

<!--@include: @/_parts/generated/chips/writer/how-it-runs.md-->

### What does chunking multiply; how many DML statements? {#chunking-cost}

Everything runs per 200-record chunk; each chunk commits its own shared unit.

[Execution Order & Cost: What Chunking Multiplies](/guide/execution-order#chunking) · [DML Cost](/guide/execution-order#dml-cost)

### Are parents cached across chunks or nested runs? {#parent-cache}

No: parents are cached for one run only.

[Execution Order & Cost: Parents Are Cached for One Run](/guide/execution-order#parent-cache)

### What is missing in before insert, before update and after insert or update? {#missing-per-context}

Before insert: no Id. Before: no DML. After: no `put`.

<!--@include: @/_parts/generated/chips/overview/gotchas.md-->
