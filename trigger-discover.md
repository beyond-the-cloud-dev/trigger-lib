# Trigger Contexts — Discovery

> **Method.** Every behavioral claim in this document was executed and verified on a developer org
> (API 67.0) on 2026-08-11: a probe trigger on Opportunity covering all seven events, driven by
> ~40 anonymous Apex scripts, with persistence confirmed by independent post-commit queries and
> surprising results re-run. This is org evidence, not documentation paraphrase.
>
> **Audited 2026-08-12** against a large production org (~1700 classes, 36 triggers, 27 objects,
> 391 non-test handler classes, 168 field populators). The production code corroborated every
> platform-semantics claim it was capable of testing and contradicted none outright. Corrections
> and additions from that audit are marked **[AUDIT]** inline. The derived ruleset lives in
> `trigger-rules.md`.
>
> **Trust boundary.** The org probe is authoritative for platform *semantics* — what throws, what
> persists, what re-enters. The production codebase is authoritative for *prevalence*, for which
> mistakes people actually make, and for anything that varies by org *configuration*. A disciplined
> org never attempts the forbidden things, so absence of violations is proof of practice, not of
> platform.

---

## 1. The big picture

**There are exactly 7 trigger events, not 8.** `before undelete` does not exist:

- Deploying a trigger with `before undelete` fails at compile time:
  `Trigger Usage Before Undelete is not supported`.
- At runtime, an undelete DML fires **only** `AFTER_UNDELETE`.
- `System.TriggerOperation` has 7 members; `String.valueOf(Trigger.operationType)` equals the enum
  name (`BEFORE_INSERT`, `AFTER_INSERT`, `BEFORE_UPDATE`, `AFTER_UPDATE`, `BEFORE_DELETE`,
  `AFTER_DELETE`, `AFTER_UNDELETE`).

**Before events** run while the record is in flight — not yet saved. `Trigger.new` is *writable*:
assign a field and it persists with zero DML, zero extra save cycle, zero recursion. This is the
home of field population, defaulting, derivation, and validation.

**After events** run once the record is saved (not yet committed): it has an Id, audit fields are
populated, and the row is *read-only* — writing to it throws `System.FinalException` that **no
try/catch inside the trigger can catch**. Changing the record now requires a new DML on a fresh
instance (`new Opportunity(Id = ...)`), which synchronously re-enters the update triggers. This is
the home of related-record creation, syncs, rollups, notifications, and async deferral.

**`addError` works in all 7 contexts** — including after events, where it still fully reverts the
operation. It never throws at the call site; it marks the record and the platform fails that
record's save when the trigger returns.

---

## 2. Capability matrix

| Capability | BEFORE_INSERT | BEFORE_UPDATE | BEFORE_DELETE | AFTER_INSERT | AFTER_UPDATE | AFTER_DELETE | AFTER_UNDELETE |
|---|---|---|---|---|---|---|---|
| `Trigger.new` / `newMap` | ✓ / **null** | ✓ / ✓ | null | ✓ / ✓ | ✓ / ✓ | null | ✓ / ✓ |
| `Trigger.old` / `oldMap` | null | ✓ / ✓ | ✓ / ✓ | null | ✓ / ✓ | ✓ / ✓ | null |
| Record `Id` present | null | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Write `Trigger.new` fields (no DML) | ✓ persists | ✓ persists | — | ✕ FinalException | ✕ FinalException | — | ✕ FinalException |
| Write `Trigger.old` fields | — | ✕ FinalException | ✕ FinalException | — | ✕ ¹ | ✕ FinalException | — |
| DML on `Trigger.new`/`old` instances | ✕ SObjectException ² | ✕ SObjectException ² | ✕ ² | ✕ ² | ✕ ² | ✕ ² | ✕ ² |
| UPDATE same record (fresh instance) | no Id | ✕ SELF_REFERENCE | ✓ ³ (surprise) | ✓ re-enters | ✓ re-enters | ✕ ENTITY_IS_DELETED | ✓ re-enters |
| DELETE same record (fresh instance) | no Id | untested | ✕ SELF_REFERENCE | ✓ ⁴ (surprise) | untested | ✕ SELF_REFERENCE ⁵ | ✕ SELF_REFERENCE |
| DML on other records | ✓ risky ⁶ | ✓ risky ⁶ | ✓ **legit** | ✓ | ✓ | ✓ | ✓ ⁷ |
| `addError` on `Trigger.new` | ✓ blocks | ✓ blocks | — | ✓ blocks | ✓ blocks | — | ✓ blocks (vetoes undelete) |
| `addError` on `Trigger.old` | — | ✕ FinalException | ✓ blocks | — | untested | ✓ blocks | — |
| Synchronous callout | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ | ✕ |
| `enqueueJob` / savepoint / `sendEmail` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

¹ Not probed in AFTER_UPDATE; inferred from identical behavior in the three probed contexts.
² `System.SObjectException: DML statement cannot operate on trigger.new or trigger.old` — thrown
before any DML runs, catchable. The guard rides the record *instances*: copying the list
(`new List<Opportunity>(Trigger.new)`) does not evade it.
³ Succeeds, fires nested update triggers mid-delete, and the value commits on the deleted row
(visible via `ALL ROWS`). Confirmed across 3 runs.
⁴ Succeeds — the caller's insert returns an Id for a record already in the recycle bin.
⁵ Self-*undelete* in AFTER_DELETE is also `SELF_REFERENCE_FROM_TRIGGER`; no AFTER_UNDELETE fires.
⁶ Executes, but fully rolled back if any record in the chunk later fails (see §4, rollback scope).
⁷ Same-record update proven; other-object DML not separately probed in this context.

---

## 3. Context by context

### BEFORE_INSERT — shape the record before it exists

- **Goal:** defaults, derivations, formatting, validation. The cheapest place to set fields.
- **State:** only `Trigger.new` populated. `Trigger.newMap` is **null** (no Ids). `Id = null`.
  Audit fields (`CreatedDate`, `CreatedById`) are readable without exception but null.
- **Do:** write fields on `Trigger.new` directly — persists with no DML. Both direct assignment and
  dynamic `.put()` work; last write wins. `addError` blocks the insert
  (`DmlException` / `FIELD_CUSTOM_VALIDATION_EXCEPTION` at the caller; record never created).
- **Don't / can't:**
  - DML on the trigger records → catchable `SObjectException` (there is no Id for a fresh-instance
    write anyway).
  - DML on other records: works, but rolls back entirely if any record in the chunk later fails
    (proven: an in-trigger Task vanished when `addError` fired). Keep before-insert side-effect free.
  - Keyed logic on `newMap` — it doesn't exist here.
- **Design consequence:** parent enrichment in before-insert cannot use one relationship query keyed
  by the record — each parent type needs its own query by lookup Ids.

> **[AUDIT] Correction — audit fields are *normally* null here, not universally.** When the org
> enables "Set Audit Fields upon Record Creation" and the caller supplies `CreatedDate`, it is
> non-null in before-insert. The audited org has this enabled.
>
> **[AUDIT] The consequence matters more than the fact: readable-but-null means a *method call* on
> the field is an NPE, not a null result.** `discount.CreatedDate.date()` is a guaranteed NPE on the
> qualifying insert path — found live, masked by a blanket dispatcher catch, committing the record
> with the derived field silently null *and* skipping every populator registered after it for the
> whole chunk. Its test passed because assigning `CreatedDate` on an in-memory sObject compiles when
> the org permits audit-field creation. Never use an in-memory audit-field assignment in a test as
> coverage for a before-insert path.
>
> **[AUDIT] The join key is frequently not an Id.** 14 of the audited org's 94 enrichment providers
> (~15%) join by a text or external key — a website, an employee number from an HR system, an
> external system Id — rather than a lookup. Resolving a lookup from a foreign key is a first-class
> before-insert workload, and an enrichment API typed as `Map<lookupField, fields>` cannot express it.
>
> **[AUDIT] Relationship (dot-path) fields are never populated on `Trigger.new` or `Trigger.old` in
> *any* context.** The query is mandatory, not an optimisation — zero of the audited org's classes
> traverse a parent relationship path off a trigger row.

### BEFORE_UPDATE — change-gated population and validation

- **State:** all four collections populated; `new` = pending values, `old` = database values; Ids
  present and identical across both.
- **Do:** write fields on `Trigger.new` (persists, no DML). `addError` on `Trigger.new` blocks the
  update — even field mutations made in the *same* trigger invocation do not persist.
- **Don't / can't:**
  - Write `Trigger.old` → `System.FinalException: Record is read-only`, **uncatchable in-frame**;
    the trigger dies and the caller's update fails with `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY`.
  - `addError` on `Trigger.old` → uncatchable `FinalException: SObject row does not allow errors`.
    Old rows accept errors only in delete contexts.
  - Fresh-instance update of the same record → catchable `SELF_REFERENCE_FROM_TRIGGER`. Write the
    field on `Trigger.new` instead — that is the entire point of this context.

> **[AUDIT] Do not re-query the triggering sObject to read its own field values here.** The query
> returns **committed** database values, not the pending `Trigger.new` values. Querying it for
> immutable or parent data (`CreatedBy`, a parent relationship) is fine; reading its own mutable
> fields is not. A live handler queries the same sObject as `Trigger.new` and stamps children with
> the parent's *pre-update* value whenever the parent is in the same batch. This is the specific trap
> that §5.7's "a single query with relationship fields is possible from before-update onward"
> invites — see the rewritten §5.7 below.
>
> **[AUDIT] The best-documented deliberate pattern in the audited org is the two-context handoff:**
> one class implements both before-update and after-update; `beforeUpdate` stamps a marker field on
> `Trigger.new` (free), and `afterUpdate` detects the marker changed and performs the integration DML
> or enqueue (post-commit). A framework should make that pairing easy to express.
>
> **[AUDIT] `Trigger.new`/`Trigger.old` index alignment is undocumented.** ~100 production sites
> rebuild `new Map<Id, SObject>(oldRecords)` and pair by Id; only 4 classes plus one vendor framework
> pair by list index. Neither this document nor Salesforce guarantees index alignment — pair by Id.

### BEFORE_DELETE — veto deletions, clean up dependents

- **Goal:** the one before-context where cross-record DML is *legitimate* (cascade / junction
  cleanup) plus deletion blocking.
- **State:** only `old`/`oldMap` populated; `Trigger.new` reads as null without exception.
- **Do:**
  - `addError` on old rows — the delete fails, `AFTER_DELETE` never fires, the record stays alive.
  - SOQL + DML on other records — works and commits. Deleting a sibling of the same object re-enters
    the trigger **synchronously**: the sibling's full before+after delete cycle completes inside the
    primary's before-delete (stack depth 2).
- **Don't / can't:** write `Trigger.old` fields (uncatchable `FinalException`); re-delete the same
  record (catchable `SELF_REFERENCE_FROM_TRIGGER`).
- **Org surprise:** *updating* the record being deleted (fresh instance) **succeeds** — nested
  update triggers fire mid-delete, then the delete completes and the written value is committed on
  the deleted row. Legal, but almost certainly an application bug; a framework should treat it as a
  smell.

### AFTER_INSERT — react to a record that now exists

- **Goal:** create children (they need the parent Id), sync parents, rollups, notifications, async.
- **State:** `new`/`newMap` populated; Ids and audit fields (`CreatedDate`, `CreatedById`,
  `SystemModstamp`) set; record **read-only**.
- **Do:**
  - Insert related records with lookups to the new Ids — the canonical use case.
  - Modify the record via **fresh instance + update** — succeeds, synchronously fires
    BEFORE_UPDATE + AFTER_UPDATE (costs a full extra save cycle; prefer before-insert when the
    field is yours to set).
  - `addError` — still vetoes the insert: record absent post-commit, and trigger-made DML (a Task)
    rolled back with it.
- **Don't / can't:** write `Trigger.new` fields → uncatchable `FinalException`, whole insert rolls
  back.
- **Org surprise:** deleting the just-inserted record from its own AFTER_INSERT **succeeds** — the
  caller's insert "succeeds" and returns the Id of a record already in the recycle bin.

> **[AUDIT] Correction — AFTER_INSERT is not one uniform context.** For platform-event (`__e`) and
> Change Data Capture objects — ~22% of the audited org's triggers — after-insert is the **only**
> declarable event: no before phase, no update/delete/undelete, no `Trigger.old`, and the row carries
> a `ReplayId` rather than a queryable record Id. Self-update and re-query are meaningless there, and
> retry is EventBus replay via `setResumeCheckpoint`, not the partial-save re-run. A `BeforeInsert`
> surface is as dead for these objects as `BeforeUndelete` is everywhere.
>
> **[AUDIT] Deferred lookup resolution is the real after-insert primitive**, and this document does
> not name it. The dominant bucket (24 of 71 implementations) is parent/related sync via fresh
> instance; three distinct mechanisms coexist for linking records whose parent Id does not exist
> until commit. The one legitimate self-update from after-insert is exactly this case — pointing the
> just-inserted row at a parent created in the same unit of work.
>
> **[AUDIT] After-insert rows carry no relationship fields**, so every handler needing parent data
> pays a mandatory re-query keyed by the new Id. The audited org built a whole caching layer for it.
>
> **[AUDIT] Pass record Ids to async work, never trigger rows.** Serializing `Trigger.new` into
> Queueable state carries a stale snapshot into the async frame *and* silently converts read-only
> trigger rows into writable deserialized copies — an accidental clone of the thing that must not be
> mutated. 14 of the org's 16 async after-insert handlers pass Id sets; the 2 that serialize rows are
> the ones carrying risk.

### AFTER_UPDATE — react to committed changes (the recursion context)

- **State:** all four collections populated; `old` = pre-update, `new` = post-update; read-only.
- **Do:** DML on other records; self-update via fresh instance (re-enters synchronously — see
  recursion below); `addError` — reverts the update (DB shows pre-update values afterwards).
- **Don't / can't:** write `Trigger.new` → uncatchable `FinalException`.
- **Recursion, measured:**
  - Each nested self-update fires BEFORE_UPDATE + AFTER_UPDATE and unwinds LIFO.
  - Unbounded self-update ran **exactly 16** AFTER_UPDATE frames; the 17th re-entrant DML was
    refused with `maximum trigger depth exceeded`.
  - That error is **uncatchable in frames 2–16** (identical try/catch in every frame never ran;
    FATAL "Internal Salesforce.com Error" lines) and catchable **only in the outermost frame**.
  - If the outermost frame swallows it, the caller's update **succeeds** while every nested write is
    silently rolled back — the most dangerous failure mode found in this study.

### AFTER_DELETE — post-deletion bookkeeping

- **State:** only `old`/`oldMap`; **lookup fields on old rows are still populated** (`AccountId` was
  non-null), so parent keys are available for rollups. Relationship objects (`old.Account`) are null
  but readable.
- **Do:** DML on other records; `addError` on old rows — still aborts the deletion; the record never
  enters the recycle bin.
- **Don't / can't:**
  - Update the deleted record → catchable `ENTITY_IS_DELETED` (the row already counts as deleted
    inside its own after-delete, pre-commit).
  - Undelete it from its own trigger → catchable `SELF_REFERENCE_FROM_TRIGGER`; no AFTER_UNDELETE
    fires.
  - Write `Trigger.old` fields → uncatchable `FinalException` (in the probe this killed the entire
    transaction including earlier setup DML).

> **[AUDIT] The decisive corollary the probe never stated: the deleted rows are also already
> excluded from ordinary SOQL inside after-delete.** This is the most load-bearing practical
> property of the delete contexts. It is what makes recompute-by-requery correct, and it silently
> broke a production rollup that re-queried the deleted Ids instead of their parents — always zero
> rows, a permanent no-op with no error.
>
> **[AUDIT] The stale-inbound-lookup window.** During after-delete, *other* records' lookups
> pointing **at** the deleted row have not been nullified or reparented yet. Any handler that queries
> related records here gets a pre-nullification view and must exclude the in-transaction deleted Ids
> by hand. Two independent codebases document this, one with a named regression test.
>
> **[AUDIT] A "delete" frame may actually be a MERGE.** On merge the losing records fire delete
> triggers with `MasterRecordId` populated on `Trigger.old`, and custom lookups to the loser are
> **not** auto-reparented. This is the only reason a widely deployed open-source rollup library
> implements after-delete at all.
>
> **[AUDIT] Choose the delete context by recomputation strategy, not by habit.**
> Recompute-by-requery needs the doomed rows already invisible → **after-delete**. Arithmetic
> subtraction needs them still present and still linked → **before-delete**. The audited org runs
> both and both are correct; neither errors when placed wrong, they just produce wrong aggregates.

### AFTER_UNDELETE — re-establish derived state on restored records

- **Goal:** re-run derivations, rollups, sharing on restored records. Behaves like after-insert.
- **State:** only new-side vars (`new`/`newMap`), restored rows keep their original Id; `IsDeleted`
  reads false in-trigger; read-only.
- **Do:**
  - Update restored records via fresh instances — allowed, nested update triggers fire, commits.
  - `addError` — an effective **undelete veto**: the caller's undelete throws and the record stays
    in the recycle bin (`IsDeleted = true` post-commit).
- **Don't / can't:** write `Trigger.new` (uncatchable `FinalException`, undelete fully rolls back);
  delete the restored record from its own trigger (catchable `SELF_REFERENCE_FROM_TRIGGER` —
  asymmetric with self-update, which works).
- Since there is no before-undelete, undelete is the one operation whose record state cannot be
  adjusted in flight — any fix on a restored record costs a second save cycle.

> **[AUDIT] Restored rows keep their Id, but undelete does not restore *inbound* lookups** from
> records that were not part of the same delete. The audited org paid a schema field for this: an
> a Text(20) shadow copy of the real parent lookup, whose field description names
> the undelete use case, with the delete path querying the real lookup and the undelete path querying
> the shadow. The practical answer to "there is no before-undelete" is therefore **precompute the
> survivable state in the before contexts** rather than pay a second save cycle on restore. (That
> pattern carries its own obligation: the org never backfilled the shadow, so records untouched since
> the field was added silently under-count on restore.)
>
> **[AUDIT] The bigger risk is the empty default.** After-undelete is *declared* on 20-22 of 36
> triggers and *implemented* on ~3 objects — that is not a decision, it is copy-paste plus neglect.
> Where nothing is registered, restoring a record from the recycle bin runs **zero Apex**: no
> derivation, no rollup, no sharing, no sync. Values stay frozen at delete time forever. Every
> after-insert handler needs an explicit yes/no about whether it also runs on restore.

---

## 4. Cross-cutting mechanics

### Event order (full lifecycle of one record)

```
insert   → BEFORE_INSERT, AFTER_INSERT
update   → BEFORE_UPDATE, AFTER_UPDATE
delete   → BEFORE_DELETE, AFTER_DELETE
undelete → AFTER_UNDELETE            // only event; "before undelete" fails to compile
```

### Chunking at 200 — statics survive, order interleaves

One DML of 201 records fired **4 invocations**: `BEFORE(200) → AFTER(200) → BEFORE(1) → AFTER(1)`.

- Each chunk completes its full before/after cycle before the next chunk starts — a
  "before phase is over" state machine is invalid.
- **Static variables persist across chunks.** A naive `if (hasRun) return;` guard silently skips
  records 201+.
- `stackDepth` stayed 1 throughout: chunking is sequential re-invocation, **not** recursion, and
  must not trip a depth-based guard.
- Identical pattern proven for insert and update.

### Partial saves re-run triggers — handlers execute twice

With `Database.insert/update/delete(records, false)` and one record failing via `addError`:

1. Attempt 1 runs: BEFORE for all records, AFTER for survivors only (the failed record is already
   excluded).
2. The platform **rolls attempt 1 back entirely** and re-runs a complete before+after cycle for the
   survivors.
3. Net effect: **every handler runs twice for surviving records** (`totalInvocations = 4` for one
   committed record). Proven for insert, update, and delete.

Attempt 1's DML side effects roll back cleanly — but emails and immediate platform events from
attempt 1 would **not**. Handlers must be idempotent, or side effects must be deferred to
end-of-transaction.

> **[AUDIT] Correction — platform events split on a metadata setting the probe never varied.**
> Events declared `publishBehavior = PublishAfterCommit` **do** roll back with the failed attempt;
> only `PublishImmediately` events survive it. In the audited org 15 of 20 `__e` definitions are
> PublishAfterCommit (the notable exception being the log event of an open-source logging framework,
> which is PublishImmediately). So the hazard
> inverts by event type: PublishAfterCommit events are *lost* on a failed attempt, PublishImmediately
> events are *duplicated* on the retry. Neither is safe by default; both need the seam.
>
> **[AUDIT] Correction — a per-Id guard armed too early turns duplication into silent loss.**
> "Guard per record Id" (implication 4) is necessary but not sufficient. A guard armed *before* the
> guarded work completes survives attempt 1's rollback while the work does not: attempt 2 sees the
> mark and skips, and the work is permanently lost with no error anywhere. Three live production
> instances were found. Arm the guard only **after** success, and treat a repeat appearance of an Id
> within one operation as a retry to re-run, not a recursion to skip.
>
> **[AUDIT] Addition — chunking breaks counting, not just statics.** Anything counted or aggregated
> across `Trigger.new` is unsound above 200 records even with no statics involved: chunk 2's SOQL
> aggregate still cannot see chunk 1's uncommitted rows *and* its in-memory tally restarts empty, so
> the two errors compound rather than cancel. Cross-record caps overshoot with no error.
>
> **[AUDIT] Addition — governor limits are per-transaction, and worse than rollback scope.** The
> SOQL counter does not reset per chunk, so a 1000-record load with a per-record query dies at the
> 101st qualifying record overall. An uncaught `LimitException` is uncatchable and aborts the
> **entire** transaction — no partial save, no chunk isolation.
>
> **[AUDIT] Addition — test bulk behaviour at 201, not 200.** 200 is the exact boundary at which
> chunking does not appear. ~15 of the audited org's bulk tests use exactly 200 and none uses 201,
> which is why every static run-once guard there passes CI and fails in production.
>
> **[AUDIT] Correction — enqueued jobs do NOT survive the rollback.** Enqueue is transactional, so a
> rolled-back attempt leaks no jobs; this bullet overstated the risk. The real and completely
> undefended duplication vector for async work is **chunking**: chunks share one transaction and each
> chunk's after context runs a fresh enqueue, so a 1,000-record update submits **5 jobs where 1 was
> intended**. No handler in the audited org buffers Ids across chunks.
>
> **[AUDIT] Addition — the error path is a side effect.** The only before-context DML in 218 registered
> actions comes from the shared exception handler, which inserts an error-log record *and* calls
> `Messaging.sendEmail` from before-insert. The log row rolls back with the failed save while the email
> does not — so the alert points at an audit record that does not exist, and the retry sends it again.

### The FinalException model

Writing to any read-only trigger row (`Trigger.old` anywhere; `Trigger.new` in after events) — and
`addError` on old rows outside delete contexts — throws `System.FinalException` that **skips every
try/catch inside the trigger frame**. The frame dies; at the caller's DML statement it reappears as
a perfectly catchable `DmlException` (`CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY`) and the operation
rolls back. If the caller doesn't catch it either, the **entire transaction** is lost, including
unrelated earlier work.

> A framework cannot protect handlers from this with try/catch around handler execution — the
> exception is uncatchable at that level by design. The only real protection is structural: hand
> after-context handlers a read-only view or a safe clone, never the raw trigger row.

### The self-DML guards, reconciled

1. **Instance guard** — DML on the actual `Trigger.new`/`Trigger.old` objects →
   `System.SObjectException: DML statement cannot operate on trigger.new or trigger.old`. Thrown
   before any DML runs; catchable; copying the list does not evade it (the guard rides the record
   instances).
2. **Same-operation guard** — repeating the in-flight operation on the record via a *fresh*
   instance → catchable `DmlException` / `SELF_REFERENCE_FROM_TRIGGER`
   (update-in-before-update, delete-in-before-delete, undelete-in-after-delete,
   delete-in-after-undelete).
3. **Everything else re-enters** — fresh-instance *update* from AFTER_INSERT / AFTER_UPDATE /
   AFTER_UNDELETE (and even BEFORE_DELETE) runs synchronously, fires the full update cycle, and
   counts against the depth-16 budget.

### addError semantics

- Never throws at the call site — trigger execution continues past it (proven by debug lines after
  the call).
- Surfaces to the caller as catchable `DmlException` with `FIELD_CUSTOM_VALIDATION_EXCEPTION` and
  the addError string as the DML message.
- Blocks the record's operation in **every** context, including after events (full revert of the
  already-performed save) and after-undelete (record stays deleted).
- Rolls back all DML the trigger performed for the failed attempt (side-effect Task rollback proven
  in before-insert and after-insert).
- On `Trigger.old` rows: legal only in delete contexts; elsewhere → uncatchable
  `FinalException: SObject row does not allow errors`.

> **[AUDIT] Field-level `addError` is the majority form and is missing from this document.**
> `record.SomeField.addError(msg)` attaches the error to a specific field in the UI. Of the six
> `addError` call sites in the entire 391-class production codebase, two of the four before-update
> validators use the field-level form, as does the single after-update validator. Any framework
> `addError` API that only supports record-level errors fails to cover most real validation.
>
> **[AUDIT] `addError` does not short-circuit the frame**, so ordering matters: on OpportunityLineItem
> a rollup registered at Order 1 runs ahead of the companion-product veto at Order 2, spending SOQL,
> parent DML and a deferred job on deletes that will never happen. Register vetoes first.
>
> **[AUDIT] Validation via Apex `addError` is rare in practice** (6 sites in 391 classes) because it
> lives in validation rules and Flows instead. Notably, the audited org's before-insert `addError`
> under-use is *structural*, not stylistic: its populator dispatcher's `populate()` returns void and
> exposes no error API, so populators physically cannot veto.

### Also verified

| Operation | Result |
|---|---|
| Synchronous callout | ✕ everywhere — catchable `System.CalloutException: Callout from triggers are currently not supported.` |
| `System.enqueueJob` | ✓ permitted in before and after events (call permissibility proven; execution of anonymous-defined queueables not observable on this org) |
| `Database.setSavepoint` / `rollback` | ✓ allowed inside a trigger |
| `Messaging.sendEmail` | ✓ allowed from trigger context |

---

## 5. Implications for trigger-lib

1. **Delete the BeforeUndelete surface.** `TriggerHandler.BeforeUndelete`,
   `TriggerOrchestrator.BeforeUndelete`, and `BeforeUndeleteHandlerAdapter` can never run —
   `System.TriggerOperation` has no such member and the event doesn't compile in a trigger.
2. **Read-only enforcement must be structural.** Uncatchable `FinalException` means the
   orchestrator cannot try/catch its way to safety; after-context `Record` wrappers should expose no
   setters on the raw row (clone for enrichment — already the chosen design).
3. **Recursion guard calibration.** The platform budget is 16 shared frames with a near-silent
   failure mode, so a default of 3 with an explicit exception is right. Chunking keeps
   `stackDepth = 1` and must not count as recursion (the per-record-Id map handles this correctly),
   but the partial-save retry runs BEFORE/AFTER_UPDATE **twice per surviving record** — with
   `maxDepth = 3`, a single `allOrNone = false` update with one failing record burns 2 of the 3
   counts for every survivor.
4. **Run-once guards are wrong twice over:** statics persist across 200-record chunks (skipping
   records 201+) and across the partial-save re-run. Guard per record Id per operation, never per
   transaction — **[AUDIT] and arm the guard only *after* the work succeeds.** A guard armed before
   the work survives attempt 1's rollback while the work does not, flipping duplication into silent
   loss. For same-object writes the cleanest guard found in production is a membership test:
   exclude Ids already present in the current trigger set.
5. **`addError` belongs in both before and after handler APIs.** It blocks the operation in every
   context, including vetoing undeletes; on old rows it is only legal in delete contexts — the
   wrapper should route it accordingly. **[AUDIT]** It must also support **field-level** errors,
   which are the majority form in real validation code.
6. **Idempotency is a contract, not a nicety:** partial-save retry re-runs handlers whose DML was
   rolled back — anything non-transactional (email, immediate platform event, enqueued callout)
   duplicates. A deferred side-effect / finalizer seam is the clean answer — **[AUDIT] but offering
   the seam is provably not enough.** The audited org ships exactly this seam — an end-of-transaction
   finalizer subsystem fired once at true end-of-DML across all chunks — and has **zero** business
   implementations of it, because handlers can still reach a logger and a mailer directly. The seam
   must be the *only* path to these side effects, not an available alternative.
7. **Before-insert enrichment needs per-parent-type queries** (no Ids, `newMap` null).
   **[AUDIT] — rewritten.** The original clause "from before-update onward a single query with
   relationship fields is possible" is true as a capability and misleading as guidance, twice over:
   (a) re-querying the *triggering* sObject in before-update returns committed values, not the
   pending `Trigger.new` values, so it is safe for immutable/parent data and wrong for the record's
   own fields; and (b) relationship fields are never populated on trigger rows in any context, so
   there is no traversal to exploit. All 68 context-using before-update populators in the audited
   org use the *same* per-parent-type shape as before-insert. Use one enrichment shape for all
   contexts.
8. **[AUDIT] Structural enforcement has a cheaper mechanism than cloning: context-restricted
   interfaces.** The audited org hands out raw `Trigger.new` and still has zero FinalException
   violations across 71 after-insert and 101 after-update handlers — because the only API that
   writes fields, its 168-class populator layer, declares only `BeforeInsert` and `BeforeUpdate`.
   A field-write in an after context is not caught at runtime; it is unrepresentable.
9. **[AUDIT] A dispatcher must not catch handler exceptions.** Letting the exception propagate is
   the only thing that turns a broken derivation into a failed save. The audited populator dispatcher
   wraps context construction, registration lookup, and the entire handler-by-record double loop in
   one catch-and-log — so a single NPE in an early handler silently aborts every remaining handler
   for every record in the chunk, and the record commits half-derived with only a log line.
10. **[AUDIT] Automatic logging is itself a side effect.** The audited dispatcher calls `saveLog()`
    after every action in every context including before-insert, and the default save publishes a
    `PublishImmediately` event — producing log entries describing inserts that never committed, each
    duplicated on the retry. Buffer logs and flush once at true end-of-DML.
11. **[AUDIT] Handlers need a first-class "invocation source" predicate.** Production handlers
    branch on `System.isBatch() || isQueueable() || isScheduled() || isFuture()` to suppress
    notifications or switch sync/async strategy. The context alone does not tell them what they need.
12. **[AUDIT] Registration must be verifiable.** Hand-maintained handler lists have no compile-time
    or metadata link to the classes: 16 fully implemented, fully unit-tested Lead populators in the
    audited org are never registered and never run, while looking completely covered, because their
    tests instantiate the handler directly.

---

*Companion artifact with the same content in interactive form:*
*<https://claude.ai/code/artifact/ebfdd5bb-d6a0-4882-91eb-01acf801c798>*
