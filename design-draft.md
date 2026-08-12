# Apex Trigger Framework — Feature Analysis

> **Purpose.** Design input for a *new* Apex trigger framework, derived by reverse-engineering an
> existing handler layer. This is an analysis artifact — no code is proposed here, only the
> use cases, edge cases, and feature requirements the new framework must satisfy.
>
> **Method.** Mined **313 non-test handler classes across 22 objects** in the audited org's handler
> source tree, plus the shared base framework it sits on (the context layer, the typed record
> wrapper, the populator base class and its dispatcher, the change-detection wrapper, and the
> dispatcher itself) and the org's metadata-driven trigger-action framework. Findings were
> cross-checked by an adversarial completeness pass; corrections from that pass are folded in below.

---

## 1. Design intent (the constraints the framework must encode)

| Context | Rule |
|---|---|
| **Before-insert / before-update** | **No DML.** May only populate / mutate fields on the trigger records themselves. |
| **Before-delete** | May perform DML on **other** objects (cascade / junction cleanup) and may `addError`. The no-DML rule does **not** apply here. |
| **After-insert / after-update** | Trigger record is **read-only**; DML on other objects is allowed (via an injected UoW/DML facade). |
| **After-delete** | Read-only; lookup fields on the deleted records are still populated (nullification hasn't happened) — exclude already-deleted parents by Id when key-building. |
| **After-undelete** | Behaves like after-insert: read-only restored record, DML allowed on others. Must re-run derivations / rollups / sharing on restored records. |

> **Key correction from the review:** the "before = no DML" rule must be **scoped to
> before-insert/before-update only**. Before-delete legitimately performs cross-object DML and is
> a first-class place for cascade cleanup and `addError`.

---

## 2. Existing framework primitives (confirmed against source)

- **The context layer** (abstract) — a keyed registry of context data providers. Each provider runs a
  mockable selector query **once per trigger** and caches the result. Three retrieval shapes:
  - by Id → `Map<Id, SObject>`
  - by unique text field → `Map<String, SObject>` (built on demand via `Type.forName` dynamic map)
  - aggregated by text field → `Map<String, List<SObject>>`
  - **Cache is a `static Map<String, …>` keyed by the bare provider-key string**,
    invalidated only when the new/old record-list `hashCode` changes.
  - **Contract nuance:** an **unregistered key throws** a context exception;
    an empty Map is returned only when both record lists are null; present-but-empty → empty.
    (It does **not** "never NPE".)
- **The typed record wrapper** — subclasses expose strongly-typed `record` (newSObject) /
  `recordPrior` (oldSObject) accessors.
- **The populator base class** (abstract) + one subtype per before context (before-insert,
  before-update, …) — each populator exposes:
  - a bypass hook — feature-flag gate resolved through a feature-checker factory
  - `isQualifiedForPopulation(new[, old], ctx)` — qualification + change detection
  - `populate(new[, old], ctx)` — mutates the record. **No error API and no DML primitive** is
    exposed here by design.
- **The populator dispatcher** (abstract) — binds a context implementation type, returns **ordered
  lists** of populators per context, runs qualify-then-populate with **per-populator exception
  isolation**, and supports metadata override removal of a populator **by Apex class-name string**.
- **The change-detection wrapper** — null-safe change-detection family: `isChanged`,
  `isChangedToTrue/False`, `isChangedFromNull`, `isChangedToNotNull`, `isAnyFieldChanged`. The
  transition predicates depend on `isChanged()` returning `false` when either record is null
  (load-bearing short-circuit).
- **The dispatcher** (from the org's metadata-driven trigger-action framework) — dispatches all **7
  contexts including `AFTER_UNDELETE`**, orders registered actions by the order field on the
  action-registration metadata, and provides:
  - object-level `bypass(sObjectName/Type)` (partial centralized recursion guard)
  - per-record times-seen counters — **only initialized for before-update and after-update**
    (no times-seen tracking for insert / delete / undelete)
  - bypass and permission flags on the action-registration metadata
- **The end-of-transaction finalizer subsystem** — runs after all handlers:
  ordered by its own finalizer metadata, permission-gated, with an opt-in "wait, then flush later"
  async deferral, and a guard that throws if a finalizer consumes DML statements.
  **⚠️ Known bug:** bypass uses `return` instead of `continue`, so one bypassed finalizer silently
  skips **every later-ordered finalizer**.
- **A widely deployed open-source rollup library** is **already wired as a registered trigger
  action** (order 1 in the action-registration metadata) implementing all 7 context interfaces and
  delegating to the library's from-trigger entry point.

---

## 3. Common use cases

### Before context — *field-only, no DML*

| Use case | Prevalence | Notes / evidence |
|---|---|---|
| **Field population / denormalization / derivation** | ubiquitous | Dominant case across all 22 objects. Qualify-then-mutate; separate insert (always-qualify) and update (change-gated) overloads. Whole field-populator subtrees — Lead (~30), Quote / quote line item (~20), OrderItem, etc. |
| **Lazy bulk fetch/cache of related data** | ubiquitous | Context data providers query once, cache, distribute. Providers add Ids from **both** new and old maps to capture lookup transitions. Backbone of bulk-safety + testability. |

### After context — *read-only trigger record, DML elsewhere allowed*

| Use case | Prevalence | Evidence |
|---|---|---|
| **Sync to related/parent objects** (smart-skip, `allOrNone(false)`) | common | Lifecycle-event → parent-account sync, account → contact status sync, subscription → contract sync |
| **Related-record creation with parent→child linking** (two-phase insert) | common | Quote line-item creation, lifecycle-event related-account creation, companion-product creation on insert, discount-extension creation |
| **Email + chat notifications** (no business DML; chat via platform event) | common | Lifecycle-event chat notifications, quote finance-approval email, inactive account-manager escalation email |
| **Apex sharing recalculation** (coordinator/strategy, system-mode bulk DML) | common | Opportunity sharing, usage-record sharing, lifecycle-event sharing |
| **Platform-event publish to decouple async work** | common | Compensation-split creation publisher, User-object event issuer, discount → payments-provider sync |
| **Rollup / aggregate recalculation** | common | The registered open-source rollup trigger action, plus hand-rolled bundle-parent and usage rollups |
| **Approval submission / reset** | occasional | Discount approval submission (`Approval.process(..,false)`) and a paired before-context approval-reset populator |
| **Validation / `addError`** (block save) | occasional | Billing-request validation; companion-product delete blocking |

### Before-delete — *cross-object cascade / cleanup*

| Use case | Evidence |
|---|---|
| **Junction / cascade cleanup** (delete related rows) | A bundle-relationship cleanup handler deletes rows of a junction object |
| **Block deletion** via `addError` | A companion-product before-delete action |

### After-undelete — *recycle-bin restore*

| Use case | Evidence |
|---|---|
| **Re-run rollups / derivations on restored records** | The registered rollup trigger action implements after-undelete and re-runs the same aggregation path |

### Async — *post-commit / idempotent / callout*

| Use case | Prevalence | Evidence |
|---|---|---|
| **Queueable deferral** (re-query for idempotence) | common | Quote-line-creation job, entitlement-provisioning job, contact-sync job |
| **Callout-from-trigger deferral** (`Queueable` + `Database.AllowsCallouts`) | occasional | Data-enrichment vendor callout handler, contact enrichment through integration middleware |
| **Flow / invocable-action bulk bridging** (migration window) | occasional | Managed lead-routing and contract-lifecycle packages plus an in-house invocable-action batching bridge |
| **Lifecycle/signal event emission** (a custom lifecycle-event object, volume caps) | occasional | Usage → lifecycle-event sync from an external marketing platform; intent-data vendor signal ingestion job |

---

## 4. Edge cases (the hard, recurring problems)

| Edge case | Why it's hard |
|---|---|
| **Recursion hand-rolled multiple incompatible ways** | static `Set<Id>`, `timesSeen == 1`, and object-level `bypass()` guard *different* failure modes and don't compose per-record. Times-seen exists **only for before/after-update**. |
| **Static context cache keyed by bare provider-key string** | (a) staleness — invalidated only by record-list `hashCode`; (b) **cross-object/context key collision** in a multi-object transaction; no transaction-boundary reset. |
| **No enforcement of before=no-DML / after=read-only** | convention-only; existing TODO debt where a discount-expiry handler does DML in after-insert that "should be before". |
| **Change-detection null-safety is load-bearing** | the whole transition-predicate family relies on `isChanged()` short-circuiting to `false` when a record is null; changing that semantic would NPE `isChangedFromNull` et al. |
| **Two-phase parent→child insert** | child references a parent Id not yet existing; sequencing + back-ref refresh hand-rolled; bundle rollups must re-run at the right phase. |
| **`allOrNone` is a per-handler judgement call** | resilient sync uses `false`+log; atomic updates use `true`; Queueables lose `allOrNone`/access-level config on serialization and must re-apply in their work method. |
| **Mixed-DML + FLS** | sharing/role/compensation/audit writes need system mode (trigger users lack FLS); setup vs non-setup splitting is manual. |
| **Callout + lock-row contention** | forces async + retry; the shared retryable async base has a fixed delay, no backoff/jitter → thundering-herd risk. |
| **Gating at 3 independent layers** | populator bypass hook + handler early-return + metadata override **by class-name string** (not type-safe); can disagree. |
| **Governor limits** | aggregate queries miss same-batch siblings (must merge DB counts + in-batch counts); volume caps must count in-batch records; sharing needs `Limits.getQueryRows` pre-checks. |
| **Ordering split across 2 mechanisms** | the metadata order field (cross-action) vs literal list position (intra-handler), plus brittle timestamp-trigger-field chaining (parent writes a timestamp trigger field, child populator reacts). |
| **Delete-context timing** | after-delete lookups still populated; before-delete is a legitimate DML context. |
| **After-undelete dispatch asymmetry** | undelete has no inverse context, so end-of-trigger stack unwinding is special-cased — finalization timing differs. |
| **Finalizer ordering hazard** | finalizer bypass uses `return` not `continue`, aborting all later finalizers; finalizers must not consume DML statements (guarded). |
| **Context-data lookup contract** | an unregistered key **throws**; no-records → empty. Not "never NPE". |
| **Dedup / first-wins pushed into each provider** | most-recent-by-date kept via ordered map + `!containsKey`; equal-key ties resolved by arbitrary stable key (Id string) tests must not pin. |
| **Test isolation leaks** | static SOQL mocks + static context cache + recursion guards must be reset or leak; fake-id collisions; anti-pattern of skipping logic only in test context. |
| **Expected-error suppression** | `DUPLICATE_VALUE` dedupe rejections must be filtered (message-fallback parsing); DML/event results correlated to source records by index. |

---

## 5. Recommended framework features (prioritized)

### Must-have

1. **Typed before/after trigger-record wrappers that encode the invariant in the type system.**
   - `BeforeRecord`: field setters/getters + change-detection + **`addError`** (validation belongs
     here — `addError` *does* work in before contexts; the populator interface simply chose not to
     expose it). **No** DML/UoW handle.
   - `AfterRecord`: read-only view of the trigger record + injected DML/UoW facade for other objects.
   - Scope no-DML to before-insert/update; before-delete keeps DML + `addError`.
2. **Keyed, lazy, bulk-safe context data providers** with by-Id / by-unique-text / aggregated-by-text
   shapes, mockable selectors, Ids gathered from **both** new and old records. Decide the
   unregistered-key contract (throw vs empty) deliberately.
3. **Transaction-correct context cache lifecycle** — replace hash-only static invalidation. Scope by
   `(contextImplType, sObjectType, providerKey)` or per-dispatch instance; clear at a defined
   end-of-trigger hook (fixes both staleness and cross-object key collision).
4. **Null-safe field-change predicate library** (`isChanged` family + value comparisons), with
   explicit, documented null semantics.
5. **Ordered populator orchestration** — qualify-then-populate, per-record gating, per-populator
   exception isolation, no UoW handle in `populate()`.
6. **Unified composable recursion-guard service** — `markProcessed/wasProcessed(scope)`, times-seen
   counters **for all contexts** (not just update), scoped `bypass()` with auto-clear at trigger end
   + test reset.
7. **Injected DML/UoW facade for after/async** — `allOrNone` policy, user-mode default with explicit
   logged escalation to system mode, `commitWork()` returning inspectable results, built-in failure
   logging **correlated to source records by index**, and an "expected error" predicate hook
   (e.g. `DUPLICATE_VALUE` on a named unique field).
8. **Async deferral primitives** — Queueable enqueue via a shared async library (no `@future`),
   platform-event publish helper (index-correlated failure logging), callout-deferral base
   (`Queueable` + `Database.AllowsCallouts`, on top of a shared callout framework). Async jobs
   re-apply security/`allOrNone` after serialization and re-query for idempotence.
9. **Multi-layer gating with type-safe metadata override** — keep per-populator flag + handler
   early-return + metadata override, but reference overridden populators by a **type-safe identifier,
   not a class-name string**. Standardize flow-migration polarity (flag OFF ⇒ bypass Apex, flow
   handles).
10. **`AFTER_UNDELETE` as a first-class context** — dispatch + rollup/recalc/sharing seam; restored
    record = "new"; after-insert semantics; handle the stack-unwinding asymmetry.
11. **End-of-transaction DML finalizer hook** — post-all-handlers, metadata-ordered, permission-gated,
    wait/flush deferral, DML-statement guard. **Fix the `return`→`continue` bypass
    bug** so one bypassed finalizer doesn't skip the rest.
12. **First-class validation/`addError` in before contexts** — eliminate the two-phase
    populate-then-addError hack by exposing an error API on the before-record wrapper.
13. **First-class test isolation** — auto-reset of cache / recursion guards / bypass sets / selector
    mocks; collision-free fake IDs; make invocations mockable instead of skipping logic in test
    context.
14. **Structured fault-path cross-cut** (an open-source logging framework) — framework-managed
    try/catch per after/async action with a guaranteed log flush; per-populator isolation in before
    context.

### Should-have

- **Metadata-registered rollup trigger action** — a widely deployed open-source rollup library as the
  canonical aggregation path across all 7 contexts (incl. after-undelete) — promote from
  "nice-to-have"; it is **already deployed and registered**.
- **Two-phase / sequenced DML** for parent-then-child creation within one UoW.
- **Retryable async base** with configurable max attempts, exponential backoff + jitter, pluggable
  `isRetryableException` classifier (e.g. `UNABLE_TO_LOCK_ROW`), and a circuit-breaker/abandon path.
- **Notification abstraction** (email template-method hooks — should-send / content-config /
  recipient resolution — plus chat notifications emitted as platform events for recursion safety).
- **Sharing-recalc hook** with governor-aware bulk share DML (`allOrNone(false)`, per-result logging,
  `Limits.getQueryRows` pre-check; explicit logged system mode).
- **In-batch counting + volume-cap utilities** (merge historical aggregate counts with current-batch
  counts; day/week/month caps; smart-skip).
- **Declarative cross-action ordering / dependency graph** — let a populator declare "runs-after"
  another instead of relying on list position; discourage timestamp-trigger-field recalc chaining.

### Nice-to-have

- **Flow / invocable-action bulk-bridging helper** for the migration window (note flow recursion
  depth 3 < trigger depth 16).

---

## 6. Open design questions

1. **Enforcement of the invariant** — withhold the DML handle in before + read-only record view in
   after (structural) vs runtime DML-statement assertions vs static analysis. Convention alone has
   already failed (the discount-expiry TODO debt above).
2. **After-context DML routing** — one shared transaction-scoped UoW across all after-handlers
   (cross-handler atomicity) vs per-handler UoW (isolation; current behavior).
3. **Recursion model** — standardize on one guard or expose all three (they guard different failure
   modes)? Define the auto-clear point and test-reset semantics; extend times-seen to all contexts.
4. **Context cache lifetime** — per-dispatch instance vs operation-token vs transaction-scoped;
   namespacing to prevent cross-object key collision.
5. **Ordering & dependencies** — keep dual mechanisms or introduce a declarative dependency graph?
   Bless or replace the timestamp-trigger-field chaining pattern.
6. **Async expression** — imperative enqueue/publish/callout vs a declarative "runs async/after-commit"
   marker with standard idempotent re-query and retry/backoff policy.
7. **Notification & integration modeling** — platform-event publishers vs flow-invocable bridges vs
   first-class typed notification actions (each exists today).
8. **Security-mode default** for after-context DML — user-mode-first vs system-mode reality for
   sharing/role/compensation/audit; how escalations are declared/logged; mixed setup/non-setup batching.
9. **Type-safety of metadata overrides** — replace class-name-string matching.
10. **Gating layering** — single evaluation order + documented flow-migration polarity; which package
    owns flags (a platform feature-management package vs ad-hoc feature-flag metadata queries).
11. **Validation ergonomics** — make `addError` first-class in before contexts; document blocking-save
    vs after-context error-reporting contract.
12. **Bulk/governor enforcement** — build in in-batch counting / volume caps / smart-skip / query-row
    pre-checks as utilities, or leave to handlers.
13. **Test-isolation contract** — which statics the framework guarantees to reset; eliminate the
    skip-in-test anti-pattern.
14. **Undelete semantics** — confirm after-insert-equivalent behavior and finalization timing for
    restored records.

---

## Appendix A — Evidence index (pattern shapes by concern)

Class names are deliberately omitted; what follows is the recurring *shape* observed for each
concern across the audited handler layer.

| Concern | Pattern shape observed |
|---|---|
| Field populators | One class per field (or per tightly coupled field group), registered in an ordered per-context list; qualify-then-mutate with separate always-qualify insert and change-gated update entry points. |
| Context data providers | One provider per related-object lookup, addressed by a string key; a single cached selector query per trigger; by-Id, dual-indexed by-unique-text, and aggregated-by-text shapes; chained providers with explicit first-wins dedup. |
| Sync to related objects | After-context handler pulls parents/children from a provider, diffs only the fields it owns, skips no-op records, and issues a partial-success update. |
| Related-record creation | Two-phase insert: insert parents first, refresh back-references from the returned Ids, then insert children in the same transaction. |
| Notifications | Template-method email actions (should-send predicate, content config, recipient resolution) plus chat notifications emitted as platform events so the outbound path cannot re-enter the trigger. |
| Sharing | Thin trigger action → coordinator that selects among pluggable sharing strategies behind a common abstract base; bulk share DML in system mode with per-result logging. |
| Platform events | Publisher action converts qualifying records into events; publish results correlated back to source records by index. |
| Async / Queueable | Handler enqueues a job that re-queries its own working set for idempotence and re-applies security and partial-success settings lost across serialization. |
| Callouts | Callout deferred to a callouts-allowed queueable; the response is mapped back onto records in a separate DML pass. |
| Retry | Retryable job base with a fixed attempt cap and fixed delay (5 attempts, 1-minute delay), triggered on lock-row failures. |
| Rollups | A metadata-registered trigger action from an open-source rollup library wired into all 7 contexts, coexisting with hand-rolled parent rollups and a batch backfill over the same aggregates. |
| Approvals | Approval submission from an after context with partial-success semantics, paired with a before-context populator that resets approval state when the driving fields change. |
| Before-delete cascade | Deletion of junction / dependent rows from before-delete, alongside `addError`-based delete blocking in the same context. |
| Recursion guards | Three incompatible idioms side by side: a static processed-Id set, a times-seen == 1 check, and the dispatcher's object-level bypass. |
| Governor / bulk | Historical aggregate counts merged with current-batch counts before volume caps are applied; `Limits.getQueryRows` pre-check ahead of bulk share queries. |
| Expected-error handling | DML/publish results walked by index; expected failures (e.g. `DUPLICATE_VALUE` from a dedupe rule) filtered by status code with a message-text fallback; the remainder logged. |
| Base framework | Context layer + typed record wrappers + populator base class and dispatcher + change-detection wrapper, layered on a metadata-driven dispatcher and its end-of-transaction finalizer subsystem. |

## Appendix B — Method & provenance

Generated from a multi-agent analysis of one production org's handler layer: 12 per-area surveys + 3
cross-cutting infrastructure deep-dives → synthesis → adversarial completeness/correctness critique.
Corrections applied from the critique (notably: `addError` works in before contexts; before-delete is
a DML context; after-undelete and the DML-finalizer subsystem are first-class; the open-source rollup
library is already a registered trigger action; context-data lookup throws on unknown keys; context
cache key collision risk; times-seen tracking limited to update contexts).
