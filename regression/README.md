# Chain Regression Suite

Org-level regression tests for `TriggerOrchestrator`'s invocation stack and chain
tracking. Unit tests cannot exercise this machinery — chunking, co-triggers,
partial-save retries, and flow re-saves only behave truthfully in a real org —
so the suite is probe metadata plus self-asserting anonymous Apex.

**Never deploy this directory to production.** It creates active triggers on ten
standard objects and a record-triggered flow on Campaign. The probe handlers are
inert unless a script enables them, but the orchestrator runs on every DML.

## Run

```bash
sf project deploy start --source-dir force-app --source-dir regression
sf apex run --file scripts/apex/chain-regression.apex          # 12 scenarios, fast
sf apex run --file scripts/apex/chain-regression-bulk.apex     # chunking + untracked DML
sf apex run --file scripts/apex/chain-regression-stress.apex   # 4-level 201-record cascade; run alone
```

Each script prints `REGRESSION PASS` or throws with every broken expectation
listed. Run all three after any change to invocation, chain, or tracker code.

The core script needs at least two existing Contacts (the example
`ContactTrigger` blocks Contact inserts in orgs without Contact record types).

## What the scenarios pin down

Cycles and the recursion guard, seven-object nested chains, co-triggers and
multiple `run()` calls per trigger, partial saves, after-save flow re-saves,
DML from before contexts, before-insert co-triggers with row mutation, the
late flush of before-only chains, 200-record chunking, exact-200 statements
after untracked DML (the silent-loss case), and the bulk cascade. Four real
bugs were found only by these scenarios; expected counts are the org-proven
baseline, so a changed count is a behavior change — understand it before
updating the number.

## Remove from an org

```bash
sf project delete source --source-dir regression --no-prompt
```
