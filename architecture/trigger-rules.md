# Trigger Context Rules

> **Sources.** Two independent bodies of evidence.
> **(A) Org probe** — `trigger-discover.md`: ~40 anonymous-Apex experiments on a developer org
> covering all 7 contexts, every persistence claim verified by post-commit query.
> **(B) Production audit** — a large production org: ~1700 classes, 36 triggers, 27 objects, 391
> non-test handler classes, 168 field populators, dispatched by a metadata-driven trigger-action
> framework. Ten mining agents, each followed by an adversarial verifier whose job was to refute its
> findings; three findings were refuted and are excluded here.
>
> **Trust boundary.** The probe is authoritative for platform *semantics* — what throws, what
> persists, what re-enters. The codebase is authoritative for *prevalence*, for which mistakes people
> actually make, and for anything that varies by org *configuration*. A disciplined org never attempts
> the forbidden things, so **absence of violations is proof of practice, not of platform.**

---

## 1. Verdict: are the assumptions in `trigger-discover.md` correct?

**Substantially yes.** Across ~60 claim checks against production code, every platform-semantics
claim the codebase was capable of testing was **corroborated**; **none was contradicted outright**.
What came back was two factual corrections, one materially misleading piece of guidance, one
insufficient rule, and fifteen "true but incomplete" findings.

Notably, the codebase is *silent* on several claims — depth-16 and its uncatchable frames, the
before-delete self-update surprise, the after-insert self-delete surprise, `ENTITY_IS_DELETED`,
`SELF_REFERENCE_FROM_TRIGGER`, and `addError` in after-insert/after-delete/after-undelete — precisely
because a disciplined org never attempts them. That silence is not disagreement.

### 1.1 Corrections (the doc was wrong)

| # | Claim | What is actually true |
|---|---|---|
| C1 | "Emails, platform events, and enqueued jobs from attempt 1 would not roll back" | Split three ways. **Platform events** depend on `publishBehavior`: `PublishAfterCommit` events **do** roll back — and *every* event published from a live trigger action in the audited org is PublishAfterCommit, so in practice this protection is real but is one admin edit away from vanishing. The notable exception is the log event of an open-source logging framework, which *is* `PublishImmediately` and therefore genuinely duplicates. **Queueables** are enqueued transactionally, so a rolled-back attempt leaks no jobs — the doc overstates this. **Email is the one side effect with no protection at all.** |
| C2 | Matrix: "Record Id present" in AFTER_INSERT; and that AFTER_INSERT is one uniform context | False for platform-event (`__e`) and CDC objects — **~22% of the audited org's triggers**. There after-insert is the *only* declarable event: no before phase, no `Trigger.old`, no update/delete/undelete, and the row carries a `ReplayId`, not a queryable record Id. Retry is EventBus replay, not the partial-save re-run. |
| C3 | "Audit fields readable without exception but null" | Null is normal, **not universal**. With "Set Audit Fields upon Record Creation" enabled and the caller supplying `CreatedDate`, it is non-null in before-insert. The audited org has this enabled. |
| C4 | §5.7: "from before-update onward a single query with relationship fields is possible" | True as a capability, **misleading as guidance**. Re-querying the *triggering* sObject in before-update returns **committed** values, not pending `Trigger.new` values — safe for immutable/parent data, wrong for the record's own fields. And relationship dot-path fields are never populated on trigger rows in *any* context, so there is no traversal to exploit. All 68 context-using before-update populators use the same per-parent-type shape as before-insert. |
| C5 | Implication 4: "Guard per record Id per operation" | **Necessary but not sufficient, and the gap is worse than the bug it fixes.** A guard armed *before* the guarded work completes survives attempt 1's rollback while the work does not — attempt 2 sees the mark and skips. Duplication becomes **silent permanent loss**. Three live production instances found: lost compensation-split updates, unprovisioned entitlements, unsent compensation events. |

### 1.2 Material additions (true, but the doc omits something real code needs)

- **Delete contexts and SOQL visibility.** Deleted rows are already excluded from ordinary SOQL
  *inside* after-delete. This is the single most load-bearing practical property of the delete
  contexts — it is what makes recompute-by-requery correct, and its absence silently broke a
  production rollup that re-queried the deleted Ids and always got zero rows.
- **The stale-inbound-lookup window.** In after-delete, *other* records' lookups pointing **at** the
  deleted rows are not yet nullified. Related-record queries return a pre-nullification view.
- **Merge.** A "delete" frame may be a merge: losing records fire delete triggers with
  `MasterRecordId` on `Trigger.old`, and custom lookups to the loser are not auto-reparented.
- **Undelete does not restore inbound lookups** from records not part of the same delete.
- **Field-level `addError`** (`record.SomeField.addError(...)`) is the majority form in real
  validation code and is absent from the doc.
- **Chunking breaks counting, not just statics** — and **governor limits are per-transaction**, so a
  per-record query dies at the 101st qualifying record overall, aborting the *entire* transaction.
- **Context-restricted interfaces** are a cheaper structural enforcement than cloning.
- **Offering a finalizer seam is not enough** — the audited org ships one with zero users.
- **Invocation source** (`isBatch`/`isQueueable`/`isFuture`) is something handlers demonstrably need.
- **`Trigger.new`/`Trigger.old` index alignment** is nowhere guaranteed; ~100 sites pair by Id.

### 1.3 Independently corroborated by production code

Exactly 7 events (36/36 triggers, both frameworks, 223 metadata registrations) · before-context
writability (the entire 168-class populator layer rests on it, zero DML) · after-context read-only
(zero field writes across 71 after-insert + 101 after-update bodies) · no Ids and null `newMap` in
before-insert (the dispatcher has two different loop shapes because of it) · `addError` works in
after contexts and fully reverts (live, registered, four passing tests) · `addError` never throws at
the call site · old-row `addError` only in delete contexts · before-delete as the legitimate
cross-record DML context · lookup fields still populated on after-delete old rows (4 handlers depend
on it) · null `Trigger.new` in delete contexts · **after-undelete ≡ after-insert** (a widely deployed
open-source rollup library literally rewrites the enum value, with the comment *"an undelete behaves
strictly the same as an insert"*)
· callouts impossible (56 `new Http()` sites, zero synchronous from a trigger) · statics leak across
chunks (two verified live instances) · chunking is not recursion · FinalException is not catchable at
dispatcher level.

---

## 2. What production actually does — the context skew

| Context | Implementations | Reality |
|---|---|---|
| BEFORE_INSERT | 126 populators + 23 actions | Pure function: rows + prefetched parents + config → field writes |
| BEFORE_UPDATE | 140 populators, 125 registered slots | ~95% field population, 4% validation, 1% other |
| BEFORE_DELETE | 3 classes, 4 registrations, 1 legacy call | Tiny. 20 of 36 triggers *declare* it; 4 objects *use* it |
| AFTER_INSERT | 71 | Related-record creation, sync, async deferral, events |
| AFTER_UPDATE | 101 — **the dominant context** | Cross-object propagation, rollups, integration |
| AFTER_DELETE | 6 | Rollup recompute, cascade cleanup, merge reparenting |
| AFTER_UNDELETE | 2 registrations + 2 trigger-body calls | Declared everywhere, implemented almost nowhere |

**Why after-update dominates (101):** update is the only operation that recurs across a record's
life — insert happens once, deletes are rare, and every state transition is an update. Change-gating
is possible only where both collections exist, and cheap change-gating is what makes it affordable to
register many small handlers.

**Why the before contexts look small:** they are not. The org exiled *all* same-record derivation
into a separate 168-class populator layer that does not appear in the trigger-action counts. That
exile is the single most important architectural decision in the codebase, and it is what produces
the zero-violation record in the after contexts.

**The declaration counts are worthless as a signal.** Trigger event lists are copy-pasted: 20 of 36
triggers declare `before delete` and 4 objects run any; 20-22 declare `after undelete` and ~3 do
anything. Read registrations, not trigger headers.

---

## 3. Most common use cases per context

### BEFORE_INSERT — *make the record correct before it exists*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Parent enrichment from a per-invocation context cache** | 68/126 populators; 94 providers across 19 context classes | Writable rows + **no Id and null newMap**, so each parent type needs its own query keyed off a value already on the row |
| **Self-contained defaulting / derivation** | ~45/126 (no query at all); 22 read Custom Metadata | Assignment persists free — the cheapest place to set a field |
| **Initial-value and creation-time stamping** | 31/126 | Semantically "the value at insert"; works around null audit fields |
| **String normalization / canonicalization** | 14 | The canonical form must be what is stored, and dedup rules must see it |
| **Lookup resolution from an external/text key** | 14 of 94 providers key by text | Integration payloads carry foreign keys, not Salesforce Ids |
| **Owner assignment / routing** | 12-16 | Avoids an ownership-change cycle and sharing recalc on a one-second-old record |
| **Pricing / numeric derivation on line items** | 16 + a dedicated package | Prices must be right as saved; a re-price is user-visible and re-enters |
| **Validation via `addError`** | **1** | Rare — and *structurally*, not stylistically: the populator API returns void and exposes no error surface |

The strongest single case for this context: a populator that composes a dedupe key into a unique
external-id field, so the platform's unique index rejects duplicates *during the very insert being
processed* — only possible before the row exists.

### BEFORE_UPDATE — *change-gated derivation with pre-image and writable post-image in one frame*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Change-gated field population** | 140 classes, 125 slots (Lead 25, Contact 16, Quote 14…) | Writes persist free; `Trigger.old` supplies the gate |
| **Parent copy-down from a prefetched cache** | 68/140 (~49%) | Ids exist → bulk query once, write straight onto the row |
| **Timestamp stamping on field change** | 17-23 | Needs both sides in one frame; idempotent under retry for free |
| **Derived-state reset when terms worsen** | ~8 | Ranks old vs new, nulls approval fields on the post-image |
| **Validation via `addError`** | 4 (2 field-level) | Blocks before the save cycle is spent |
| **Marker stamping for an after-update handler** | 3 | *The pattern to teach* — see below |
| **Capacity check: DB aggregate + in-batch count** | 1 | Needs pending values of the whole batch plus committed state |

**The two-context handoff** is the clearest architectural pattern in the codebase: one class
implements *both* before-update and after-update; `beforeUpdate` stamps a sync marker on the row
(free), and `afterUpdate` detects the marker changed and performs the integration DML or enqueue
(post-commit). A framework should make this pairing easy to express.

97 of 140 populators also implement the before-insert interface and **share one `populate()` body**
with a null-guarded old record — proof that the two before contexts want one handler with a nullable
pre-image, not two.

### BEFORE_DELETE — *veto, or act while the relationship graph is still intact*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Deletion veto via `addError` on old rows** | 5 of 12 automations (1 Apex + 4 Flows) | Old rows accept errors here, *and* the record is still queryable so sibling state can be read |
| **Recalculating a parent while links are intact** | 5 of 12 | Pre-delete DB state — a parent-child query only returns rows before the link is torn down |
| **Cross-object cascade / junction cleanup** | 2 of 12 | Cross-record DML being legal here — *the least common of the three, despite being the use case the doc singles out* |

Four forces decide before-vs-after delete, and the doc anticipates one. Note that most of this work
is "before" because **the data is still there**, not because the row is writable.

### AFTER_INSERT — *react to a record that now has an Id*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Parent/related sync via fresh-instance update** | **24/71 — the largest bucket** | The Id and committed lookups; lookups are often set by a before-insert populator, so before-insert is too early |
| **Async deferral of expensive/callout work** | 16/71 | Ids exist to re-query; callouts are impossible in-frame |
| **Child / junction record creation** | 10/71 | The child's lookup needs the parent Id |
| **Platform-event publishing** | 8 touch `__e`, 4 publish directly | Payload is the new Id; breaks a long synchronous chain |
| **Handling a platform event or CDC event** | 4 handlers + 4 raw triggers, ~22% of triggers | **Forced, not chosen** — after-insert is the only event that exists |
| **Notifications, Apex sharing, approval submission** | 5 + 4 + 2 | `__Share.ParentId` and `setObjectId` need a saved record |
| **Self-update via fresh instance** | 2 classes / 4 sites | Split: legitimate when pointing at a parent created in the same unit of work; otherwise misplaced |

One expiry handler performs three fresh-instance self-updates from its own after-insert and annotates
every one `// TODO: It has to be moved to before context`. The doc's advice is literally written in
the codebase as unpaid tech debt.

### AFTER_UPDATE — *react to a committed change by acting on other records*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Cross-object propagation / sync** | ~37/101 perform DML, overwhelmingly to another object | Both collections for gating + committed state for related queries |
| **Change-gated eligibility filtering (preamble)** | 42 use the `Record` wrapper + 17 use a static helper = ~55/101 | Only the update contexts have both sides |
| **Async deferral** | 13/101 | *The org's primary recursion-avoidance strategy* |
| **Platform-event publication** | 8/101 | Deliberate transaction-boundary break |
| **Rollup / aggregate recalculation** | ~8 | The **old-side** lookup, to decrement the previous parent on reparent |
| **Integration / notification / child creation on transition** | ~8 + ~8 + ~6 | The transition is only knowable by diffing |
| **Same-object propagation to siblings** | 3 | Fresh-instance re-entry — all three carry guards |
| **Validation via `addError`** | 1 | Needs a query result that depends on the *new* value |

The change-detection wrapper the org converged on exposes ~45 public methods and **zero setters** —
they independently arrived at the doc's structural-enforcement recommendation.

### AFTER_DELETE — *bookkeeping with keys recovered from old rows*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Rollup recompute-by-requery** | 4 of 6 | **Two** properties: lookups still populated on old rows, *and* the deleted rows already invisible to SOQL |
| **Cascade cleanup of orphans** | 1 | Needs the delete to have happened; must exclude in-transaction deleted Ids |
| **Merge reparenting** | 1 class — but it is the library serving every rollup | `MasterRecordId` on the losing row |

### AFTER_UNDELETE — *re-establish derived state on restored records*

| Use case | Prevalence | Depends on |
|---|---|---|
| **Recompute rollups by treating undelete as insert** | The entire population: 2 registrations + 2 trigger-body calls | Restored rows carry original Ids; only new-side collections exist |
| **Rebuild relationships via a shadow field** | 1 | Undelete not restoring inbound lookups |

---

## 4. The rules

### Per-context

**BEFORE_INSERT**
1. **Write only to `Trigger.new`.** No DML, no `enqueueJob`, no email, no platform event, no callout,
   no savepoint. *(126 populators + 23 actions: zero of every one of these.)* Transactional side
   effects roll back with the chunk; non-transactional ones survive and describe an insert that never
   happened.
2. **Never reference the record's own Id, `Trigger.newMap`, or `Trigger.old`.** They do not exist. A
   null-keyed map lookup silently returns null; a provider iterating `triggerOld` NPEs — and behind a
   swallowing dispatcher neither surfaces.
3. **Null-guard every audit field before calling a method on it.** Readable-but-null means a method
   call is an NPE, not a null result. And never use an in-memory `CreatedDate` assignment in a test as
   coverage for a before-insert path — it compiles only when the org permits audit-field creation, so
   the test passes on a path production never takes.

**BEFORE_UPDATE**

4. **Set the field on `Trigger.new`. Never DML the triggering record's own Id.** That is the entire
   point of the context, and the platform refuses the alternative anyway.
5. **Never write to, or `addError` on, a `Trigger.old` row outside a delete context.** Both raise
   uncatchable `FinalException`. No dispatcher catch can help — the only defence is not handing the
   old row out in a writable shape.
6. **Do not re-query the triggering sObject to read its own field values.** You get committed values,
   not pending ones. Querying it for *immutable or parent* data is fine.
7. **Gate every write on an explicit change or null predicate, answerable from the record's own new
   and old fields alone.** The gate is what makes the handler idempotent under the partial-save re-run
   for free. Keeping related data *out* of the gate is what keeps queries out of the per-record path.

**BEFORE_DELETE**

8. **Use it only for `addError` vetoes on old rows and for cross-record cleanup or recalculation.
   Never write the in-flight row.** All 12 of the org's before-delete automations are one of these two.
9. **If the cleanup is a cascade, use `allOrNone = true`.** With `false`, a rejected child delete is
   only logged, the parent commits deleted, and the junction row survives orphaned — defeating the
   "simulates master-detail cascade" contract the registration itself claims.
10. **Order veto handlers ahead of side-effecting handlers.** `addError` does not short-circuit the
    frame. On OpportunityLineItem a rollup at Order 1 runs ahead of the veto at Order 2, spending SOQL,
    DML and a deferred job on deletes that will never happen.

**AFTER_INSERT**

11. **Never write a field on a trigger row in any after context; mutate only through freshly
    constructed instances.** Uncatchable FinalException; unhandled, the entire transaction is lost.
12. **Do not self-update the triggering record for any field you could have set in before-insert.**
    Cost: a full extra save cycle plus a synchronous BEFORE+AFTER_UPDATE re-entry against the depth-16
    budget, per instance.
13. **Pass record Ids to async work, never trigger rows.** Serializing rows carries a stale snapshot
    *and* silently converts read-only rows into writable deserialized copies.

**AFTER_UPDATE**

14. **Guard same-object writes by excluding Ids already in the current trigger set — not by a
    transaction-scoped flag.** A same-transaction membership test is decidable, needs no state that
    outlives the frame, and is immune to both chunking and the retry. *This is the cleanest guard in
    the entire codebase.*
15. **Read the recursion counter for the context you are executing in.** Counters are per-Id
    *per context*, and the phases legitimately see different record sets — under partial save,
    attempt 1's before phase runs for *all* records while its after phase runs only for survivors.
    Three production handlers gate after-update work on the before-update counter.

**AFTER_DELETE**

16. **Recover parent keys from lookup fields on `Trigger.old`; never re-query the deleted rows.**
    A query for deleted Ids returns zero rows and the handler becomes a silent no-op — a verified live
    production bug (the Account MRR hierarchy rollup never recalculates on child delete).
17. **Choose the delete context by recomputation strategy:** recompute-by-requery → after-delete;
    arithmetic subtraction → before-delete. Neither errors when placed wrong; both just produce wrong
    aggregates.
18. **When querying related records, explicitly exclude records deleted in the same transaction.**
    Inbound lookups are not yet nullified.

**AFTER_UNDELETE**

19. **Treat it as after-insert with an empty old side, and make an explicit yes/no decision for every
    after-insert handler about whether it also runs on restore.** Left implicit, the answer defaults to
    *nothing runs* — values stay frozen at delete time forever.
20. **Do not assume inbound lookups survive an undelete.** If a restore must rebuild a relationship,
    precompute a survivable shadow of it in the before contexts — and backfill it.

### Cross-cutting

21. **Never gate work on a transaction-scoped static. Guard per record Id per operation.** Records
    201+ are silently skipped with no error. Verified live on two of the org's highest-volume objects.
22. **Arm a per-Id guard only *after* the work completes, and treat a repeat appearance of an Id
    within one operation as a retry to re-run, not a recursion to skip.** Otherwise the failure mode
    flips from duplication to silent **loss** — strictly worse, because nothing is observable afterwards.
23. **Never treat the trigger record set as the whole DML.** Any invariant computed by counting or
    aggregating across `Trigger.new` is unsound above 200 records — the DB cannot see the uncommitted
    rows *and* the in-memory tally restarts empty.
24. **A dispatcher must not catch handler exceptions.** Letting it propagate is the only thing that
    turns a broken derivation into a failed save. If isolation is offered, scope it to a single handler
    and state fail-open vs fail-closed explicitly.
25. **Never hand a handler a mutable reference to a row it may not write.** Constrain by *type and API
    surface*, not by convention, documentation, or try/catch. FinalException is uncatchable by design.
26. **Per-handler filtering must never narrow the record set handed to subsequent handlers.**
    Otherwise behaviour becomes a function of registration order — and on a delete context a veto
    receives a subset and *fails open*.
27. **Route `addError` through a context-aware API supporting both record-level and field-level
    errors, refusing old-row errors outside delete contexts.**
28. **Non-transactional side effects must be idempotent or routed through a single end-of-DML seam —
    and that seam must be the *only* path to them.** Providing it is provably insufficient: the audited
    org ships the seam and has zero implementations of it.
29. **Treat automatic logging as a side effect subject to every rule above.** Buffer it, flush once at
    true end-of-DML, and choose its durability deliberately (an after-commit log rolls back exactly
    when it is most needed).
30. **Key any per-invocation prefetch cache on an explicit invocation identity, never on a content
    hash of the record lists.** The surviving-record list is content-identical between partial-save
    attempts, so attempt 2 silently reuses data queried before attempt 1's rollback.
31. **Acquire all related data in a declared bulk prefetch that runs once per invocation. Never query
    inside a per-record qualify or handle method.** 94 providers and 168 populators converge on this;
    only 5 of 168 break it. A per-record query is 200-400 queries per chunk and an uncatchable
    `LimitException` that aborts the *entire* transaction.
32. **Test bulk behaviour at 201 records, not 200.** 200 is the exact boundary at which chunking does
    not appear — the bug class is structurally invisible to the test suite meant to catch it.
33. **Make handler registration verifiable** — derivable from metadata or asserted by a test. 16 fully
    implemented, fully unit-tested Lead populators are never registered and never run, while looking
    completely covered.
34. **The error path is a side effect too.** An exception handler that performs DML or sends email is
    unsafe in before contexts and duplicative under retry. In the audited org the *only* before-context
    DML in 218 registered actions comes from the shared exception handler — which inserts an error-log
    record **and** calls `Messaging.sendEmail` from before-insert. The log row rolls back with the
    failed save while the email does not, so the alert points at an audit record that does not exist.
    Buffer diagnostics; emit once at end of transaction.
35. **Chunking multiplies enqueues, and nothing in the platform stops it.** Chunks share one
    transaction, and each chunk's after context runs a fresh enqueue: a 1,000-record update through one
    handler submits **5 jobs where 1 was intended**. No handler in the audited org buffers Ids across
    chunks. This is a *different* problem from partial-save duplication and is completely undefended —
    it is the strongest argument for the end-of-DML seam.
36. **Never `Database.executeBatch` from trigger context.** One live Account after-update block forks
    into 8 batch call sites; at 1,000 records that block runs 5 times against a shared limit budget,
    reaching the 5-concurrent-batch ceiling from a single data load, uncaught. The org's own newest
    method already carries the rule as a comment: *"Always use Queueable — avoids batch overhead in
    trigger context."*
37. **Platform-event subscriber triggers need an explicit replay decision.** Only 1 of the audited
    org's 9 platform-event triggers calls `setResumeCheckpoint`. Without it an unhandled exception lets
    the platform replay the whole event batch and re-run the handler — a duplication vector entirely
    independent of partial save.
38. **A bypass/enable switch must have one name and two states.** The audited framework's
    `shouldBeExecuted()` returns **`true` when the metadata action is bypassed** — inverted polarity
    that now silently governs whether ~40 legacy code paths run, and issues one SOQL per call.

---

### What production got right — the negative findings

A dedicated violation sweep across all 218 live registered actions found **nothing** for four of the
things you would most expect to find, and these clean results are as informative as the defects:

- **Zero DML inside before-insert / before-update handler paths.** The entire `handlers/` tree
  contains no DML in before contexts. The only before-context DML in the org is the exception-handler
  path (rule 34).
- **Zero writes to `Trigger.old`/`oldMap`, and zero `addError` on old rows outside delete contexts.**
  All 6 `addError` sites are on `Trigger.new` in before contexts, except one registered before-delete
  action on old rows — the one context where that is legal.
- **Zero DML on the `Trigger.new`/`Trigger.old` collections.**
- **Zero synchronous callouts reachable from a trigger path.** Every callout class is
  Queueable/Batchable/Schedulable with `Database.AllowsCallouts`.
- **All 26 live async/side-effect emitters are in AFTER_INSERT or AFTER_UPDATE; zero in any before
  context.** That is the single most correct thing about this codebase's trigger design.

Also worth noting for guard design: of 12 transaction-scoped boolean latches traced, **2 are live
defects, 3 are correctly-shaped latches that restore state on exit, and 7 are test-observability
probes that production never reads.** That ratio is the argument for making a framework-supplied
per-Id counter the *only* available mechanism, so the pattern never gets hand-rolled again.

### Live defects found (what the rules are protecting you from)

| Sev | Defect | Failure |
|---|---|---|
| High | **Populator dispatcher wraps the entire handler loop in one catch-and-log** — the base class for 22 of 22 live before-insert registrations and most of the 31 before-update ones | One populator throwing aborts every *later* populator and the record still saves, half-derived, with only a log entry |
| High | **Shared exception handler does DML + email from before contexts** (76 call sites org-wide) | Up to 4 duplicate alert emails per bulk load; the error-log rows they reference are rolled back |
| High | **A bypass static set `true` and never restored** — no `finally`, no reset anywhere | Every later record in the transaction skips a validity check, producing multiple simultaneously-"active" records where the service exists to enforce exactly one |
| High | **An `isFirstTime*` transaction static on a high-volume object** | Update 500 records → chunk 1 recomputes the parent rollups, chunks 2-3 skipped, parents left stale |
| High | **An expiry handler self-updates from after-insert, 3 times** | Each carries `// TODO: It has to be moved to before context`. Two fields knowable at before-insert cost a second save cycle, re-run all 11 live actions on that object, and burn a recursion frame |
| Med | 8 `Database.executeBatch` call sites in one after-update block; silent `catch` around payment DML; unguarded `enqueueJob` with no emptiness check; log flush once *per action* inside the dispatch loop; two triggers on one object (one self-labelled `!!! DO NOT USE !!!`) | see rules 24, 29, 35, 36 |

### The finalizer-ordering bug — confirmed

The audited framework's end-of-transaction finalizer subsystem sorts registered finalizers ascending
by their order field, then inside the loop does `if (metadata.bypassExecution) { return; }` — exiting
the *entire method* rather than skipping one entry. Bypassing the finalizer at order 10 silently
disables 20, 30, 40 and every one after.

It has never fired in production: there are **zero registration records and zero business
implementations** of the interface (the only ones that exist are inner classes of its own test). The
seam ships fully built and entirely unused — which is exactly the point of rule 28, and also means the
bug would not be caught by the existing tests, since they never register two finalizers where the
lower-ordered one is bypassed.

Two more things to take from that subsystem. **Copy** its DML-row countdown: the dispatcher tracks
`Limits.getDmlRows()` minus an offset so end-of-transaction work fires after the *last* 200-record
chunk rather than once per chunk. That is the single best idea in the framework and the correct answer
to rule 35. **Avoid** its DML guard, which measures `Limits.getDmlStatements()` *after* calling the
finalizer — a post-mortem that only ensures the transaction dies rather than preventing the write, and
which counts DML statements only, so `enqueueJob`, `sendEmail` and callouts sail through. Hand
finalizers a context object with no DML capability instead.

---

## 5. Decision procedure: which context does this work belong in?

1. **Does it set a field on the record being saved?** If yes, and the operation is insert or update →
   the matching **BEFORE** context. Stop. Anywhere else costs a full extra save cycle plus a
   synchronous re-entry, for a field that was yours to set for free.
2. **Does it need the Id, or anything requiring a committed row** (children with a lookup back,
   `__Share` rows, approval submission, an event payload, a related query keyed on this record)? Then
   it cannot be before-insert → **after-insert**, or after-update for a transition-triggered version.
3. **Does it need the prior value?** Only the update contexts have both sides. Choose by where the
   *outcome* lands: on this record → **BEFORE_UPDATE**; on another record → **AFTER_UPDATE**. If both,
   split it deliberately: before stamps a marker, after acts on the marker change.
4. **Is it a veto?** Before context of that operation, on the record being operated on; use
   field-level `addError` when the message belongs to a field. Vetoing from an after context works and
   fully reverts, but you pay for the save first — only when the decision genuinely requires post-save
   state.
5. **Is it a DELETE?** Don't ask "before or after" — ask what your recomputation needs. Rows still
   present and linked (subtraction, reading their children, reading inbound lookups, vetoing, atomic
   dependent deletes) → **BEFORE_DELETE**, `allOrNone = true` for a cascade. Rows already gone
   (recompute-by-requery) → **AFTER_DELETE**, excluding in-transaction deleted Ids by hand. Also ask:
   **could this frame be a merge?**
6. **Is it an UNDELETE?** No before-undelete exists, so: accept a second save cycle, or precompute the
   survivable state in the before contexts. Then decide explicitly, per handler, whether your
   after-insert logic also runs on restore — the default is *nothing*, and that is almost never right.
7. **Does it call out, email, publish an immediate event, enqueue, submit for approval, or launch a
   batch?** Callouts are impossible everywhere. Everything else must leave the per-chunk frame: one
   end-of-DML seam, pass Ids not rows, be idempotent — the retry will run it twice and chunking runs it
   once per 200.
8. **Does it need data not on the trigger row?** Assume it is not there — relationship fields are never
   populated in any context. Declare a bulk prefetch that runs once per invocation, keyed off a value
   already on the rows (a lookup Id, or an external text key — ~15% of real cases).
9. **Does it count or aggregate across the record set?** The record set is not the DML. Above 200 your
   answer is wrong in both directions at once. Derive from committed state, or move to the seam.
10. **Finally:** is anything gated on a static flag, a memo written *before* the work, or a
    "times seen == 1" counter? All three fail. Use a per-Id-per-operation guard armed after success —
    or, for same-object writes, a membership test against the current trigger set.

---

## 6. Implications for `trigger-lib`

### Must

- **Delete the `BeforeUndelete` surface entirely.** `TriggerHandler.BeforeUndelete` (`TriggerHandler.cls:25-28`),
  `TriggerOrchestrator.BeforeUndelete` (`:26-28`) and `BeforeUndeleteHandlerAdapter` (`:356-368`) can
  never execute — and the adapter is *already* unreachable: `run()` has no `BEFORE_UNDELETE` branch and
  cannot have one. Dead code that happens to compile.
- **`Record.getNewSObject()` / `getOldSObject()` are the library's single biggest hazard as written.**
  They hand out the raw trigger rows in exactly the two places the audit proves are fatal —
  `getNewSObject()` is read-only in every after context, `getOldSObject()` is read-only in every
  context that has one. The shipped example already does it: `ContactEnrichmentHandler.onAfterUpdate`
  calls `getNewSObject()`. One assignment by a handler author kills the frame uncatchably.
- **Give the before interfaces a real write API** — `record.set(SObjectField, Object)`, or a
  `WritableRecord` subtype returned only inside `onBeforeInsert`/`onBeforeUpdate`. This is what makes
  the previous point *enforceable* rather than advisory: today the only way to do the library's primary
  job is the hazardous accessor. The shape is already visible in the example:
  `ContactTriggerHandler.cls:18` has the commented-out intent `// record.Description = ...`, and
  `:20`/`:29` do it the only way currently possible — `getNewSObject()` then assign. That is correct
  in before-insert and fatal in an after context, with nothing in the type system telling them apart.
- **Move the logger flush off the per-invocation `finally`.** `TriggerOrchestrator.cls:143-145` calls
  `logger.finalize()` on every `run()` — once per context, per chunk, per retry attempt. That is
  precisely the shape that produced duplicated entries and entries describing inserts that never
  committed in the audited org.
- **Keep `maxDepth = 3`, but make the counter retry-aware and extend it beyond the update contexts.**
  The `recursionDepth` map (`:53-64`) is seeded only for BEFORE_UPDATE and AFTER_UPDATE — the audit
  found the *insert* side has no defence anywhere in a 1700-class org.

### Should

- **Pair new and old rows by Id, not by list index** (`TriggerOrchestrator.cls:102-104`, `:110-112`).
  One map construction removes an undocumented platform assumption.
- **Enrichment must support a non-Id join key.** `fieldsToEnrich()` returns
  `Map<SObjectField, ParentFields>`, so it can only join by a lookup — but ~15% of real providers
  join by an external text key, and that is a first-class before-insert workload.
- **Keep qualification free of related data, and keep the current bypass → qualify → enrich → execute
  ordering.** The TODO at `TriggerOrchestrator.cls:184-185` is answered by the evidence: not one of the
  audited org's ~168 predicates uses related data, and this ordering is what keeps enrichment volume
  proportional to *qualified* records — the exact concern in `DECISION.md`.
- **Use one enrichment shape for all contexts.** `goals&assumptions` line 7 proposes a single
  relationship query from before-update onward; the audit says that is technically true and practically
  a trap (correction C4).
- **Add the deferred side-effect seam and make it the only path** to async, email, events, approvals.
  The `// TODO Asynchronous Actions` at `TriggerOrchestrator.cls:49` is the right instinct — but
  availability is not enough. Build it on a **DML-row countdown** (`Limits.getDmlRows()` minus an
  offset) so it fires once after the last chunk, not once per chunk; iterate a pre-filtered list rather
  than filtering inside the loop (the audited framework's `return`-in-loop bug); and give finalizers a
  context object with **no DML capability** rather than detecting the violation afterwards.
- **Adopt the "Ids in, re-query out, already-done check" contract for async** and sanction no other
  shape. The audited org's entitlement provisioning is the reference implementation: the handler passes
  only Ids, the job re-queries current state and filters out anything already provisioned, so a
  double-fire produces one record. Its counter-example passes trigger records straight into the job —
  a snapshot from a save that may have been rolled back and replayed.
- **Keep `Bypassable.bypassWhen()` as the only bypass mechanism.** Do not add an imperative
  `bypass()`/`clearBypass()` pair; the audited org's one imperative bypass clears its static outside any
  `finally`.
- **Give the delete contexts an old-rows-only API that also states what is still true** — notably
  whether the rows are still returned by SOQL (yes in before-delete, no in after-delete) — and surface
  merge.
- **Decide explicitly what a platform-event/CDC subscriber gets, or declare them out of scope.**
  `Record.getId()` and the whole old/new model break for ~22% of a real org's triggers.

### Nice

- **Offer an `AfterInsertOrUndelete` affordance**, or at least force an explicit undelete decision per
  handler.
- **Make registration verifiable and ship a 201-record bulk test template.** The orchestrator's
  hand-maintained list literals are the same shape that left 16 tested populators inert.

---

## 7. Open questions

Neither the org probes nor the codebase settles these:

1. **Does a `finally` block inside a trigger frame execute when a `FinalException` is raised?**
   `TriggerOrchestrator`'s automatic logging depends entirely on this.
2. **Is `Trigger.new`/`Trigger.old` index alignment guaranteed, or incidental?** trigger-lib currently
   relies on it.
3. **Can a handler distinguish a partial-save retry from a genuine recursion frame?** Both look
   identical to a per-Id counter. Without a signal, "guard per Id" and "be idempotent under retry" are
   in direct tension.
4. **Does the depth-16 budget count the retry's frames, or does the retry start fresh?** The two
   experiments were never combined — and that combination determines whether `maxDepth = 3` is safe.
5. ~~**Do enqueued Queueable/Batchable jobs actually survive a partial-save rollback?**~~ **Settled by
   the violation sweep: they do not.** Enqueue is transactional, so a rolled-back attempt leaks no jobs
   — the doc overstated this. The real, undefended duplication vector is *chunking* (rule 35), not the
   partial-save retry.
6. **Does the `SObjectException` instance guard survive record-level `clone()`?** The probe proved
   copying the *list* does not evade it; an open-source rollup library deep-clones *records* and DMLs
   freely, which implies `clone()` does evade it.
7. **What exactly does an undelete restore?** "Inbound lookups are not restored" is inferred from one
   org's workaround, not probed.
8. **Merge specifics beyond the loser's after-delete** — which contexts fire on the *winning* record,
   and is `MasterRecordId` present in before-delete too?
9. **Is `addError` in AFTER_INSERT / AFTER_DELETE / AFTER_UNDELETE safe to recommend?** All three work
   in the probe, but zero of 391 production classes use them.

---

*Companion documents: `trigger-discover.md` (platform semantics, org-proven) ·
`features.md` (feature analysis) · `DECISION.md` · `goals&assumptions.md`*
