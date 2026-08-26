# Transaction Lifecycle

A save in Salesforce is rarely one trigger firing once. A user edits an Account, its handler updates Contacts, the Contact handler updates Opportunities, and an Opportunity handler updates the Account again. Every one of those is a separate trigger invocation, and none of them can tell whether it is the first, the last, or somewhere in the middle.

Trigger Lib tracks that shape for you. It maintains a stack of the invocations currently executing, groups them into the top-level DML statement that caused them, and tells you when that statement has finished — after everything it set off has run.

## Invocations and the stack

Every **after-context** call to `TriggerOrchestrator.run()` pushes an **invocation** onto a stack and pops it when that call returns. An invocation records the operation, the object, how many records it received, and how deep it sits.

Before contexts run without an invocation. The library assumes a before handler performs no DML — its job is to populate and validate the rows it was handed — so nothing can nest under it and it needs no place on the stack, in the tree, or in the chain's arithmetic. Chains are measured from the after phase alone.

**Depth 1** means a top-level DML statement — one your code, a Flow, or the UI issued directly. Anything deeper was caused by a handler performing DML that re-entered a trigger synchronously.

```apex
public with sharing class AccountAuditHandler implements TriggerHandler.AfterUpdate {
    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record) {
        return true;
    }

    public void onAfterUpdate(TriggerHandler.Record record) {
        for (TriggerOrchestrator.Invocation invocation : TriggerOrchestrator.getStack()) {
            System.debug(invocation.getDepth() + ': ' + invocation.getSObjectType() + ' ' + invocation.getOperation());
        }
    }
}
```

Updating one Account that cascades through Contact and Opportunity and back produces:

```
1: Account AFTER_UPDATE
2: Contact AFTER_UPDATE
3: Opportunity AFTER_UPDATE
4: Account AFTER_UPDATE
```

`TriggerOrchestrator.getDepth()` returns the current depth directly. Salesforce stops the cascade at depth 16 with an error you cannot catch, so a stack approaching that number is a design problem, not something to handle at runtime. Depth counts invocations, and two trigger-lib triggers on one object produce two invocations inside a single platform recursion frame — so read it as a guide, not as a budget to compute against.

## Chains

Invocations are grouped into **chains**. A chain is one top-level DML statement and everything it causes, however deep. Every invocation in the cascade above shares one sequence number, available as `Invocation.getChainSequence()`.

One user action is not always one chain. Each of these starts a new one:

- Each separate DML in your code — `update accounts; update contacts;` is two chains.
- Each Update Records element in a record-triggered Flow, and each after-save Flow that writes back.
- Each attempt of a partial save, usually. `Database.update(records, false)` rolls back completely when a record is vetoed and re-runs for the survivors; the retry starts a new chain when the statement's size was certain, and otherwise re-arms the same sequence. Either way both attempts flush, and the vetoed attempt may report `isChainEnding()` — the platform re-runs every handler on a retry, so side effects must already be idempotent.

To correlate everything in one transaction, pair the sequence with `TriggerOrchestrator.getRequestId()`, which is constant for the whole request.

::: tip
`getChainSequence()` numbers the chains this library tracked. It is not `Limits.getDmlStatements()`, which also counts DML on objects that have no orchestrated trigger.
:::

## Knowing when the work is finished

There is no end-of-transaction hook in Apex. What Trigger Lib gives you instead is the end of a chain, which is the moment after the last chunk of the last trigger in the cascade has run.

### Logger.flush()

Implement `TriggerOrchestrator.Logger` and the orchestrator finds it automatically — no registration. `log()` receives each error as it happens; `flush()` is where you write them out.

```apex
public with sharing class TriggerLogger implements TriggerOrchestrator.Logger {
    private static List<Log__c> buffer = new List<Log__c>();

    public void log(TriggerOrchestrator.Error error) {
        buffer.add(new Log__c(
            Message__c = error.getException().getMessage(),
            Object__c = String.valueOf(error.getSObjectType()),
            Operation__c = String.valueOf(error.getOperation()),
            Statement__c = error.getStack()[0].getChainSequence()
        ));
    }

    public void flush() {
        if (buffer.isEmpty()) {
            return;
        }

        insert buffer;
        buffer.clear();
    }
}
```

`flush()` is called **at least once per chain**, in these situations:

| When                                                                           | Stack during the call                       |
| ------------------------------------------------------------------------------ | ------------------------------------------- |
| The chain's final chunk finishes                                               | The root invocation is on the stack         |
| An exception escapes a root invocation                                         | The failing root invocation is on the stack |
| A root invocation closes with errors logged but not yet flushed                | The closing invocation is on the stack      |
| The previous chain's end could not be detected, flushed late at the next chain | Empty                                       |

Inside `flush()`, `TriggerOrchestrator.getChainTree()` returns the chain's full map — root invocations with their `getChildren()` subtrees — so a Logger can persist the entire cascade, not just the path that was live when an error happened.

Two rules follow from "at least once":

- **Make `flush()` idempotent.** Clear your buffer as the example does. It can be called with nothing to write, and a chain whose size cannot be determined flushes at each chunk.
- **Group by `getChainSequence()`, never by counting `flush()` calls.** The sequence is stable; the call count is not.

### isChainEnding()

`TriggerOrchestrator.isChainEnding()` is true while the currently executing invocation is the final chunk of its chain. It is deliberately narrow:

- It is true only at depth 1. A nested handler asking "is the whole thing ending?" gets `false`, because more work may follow when it returns. Nested code that genuinely needs the root's state can read `getStack()[0].isChainEnding()`.
- Handlers registered after yours in the same invocation still run. True means "this is the last chunk", not "nothing else will happen".

For a real end-of-work hook, use `Logger.flush()`. Use `isChainEnding()` for decisions inside a handler, such as skipping work that only makes sense on the final chunk.

## Where flush() cannot help

Two cases have no detectable end, and no framework can fix them from inside a trigger:

- **A trigger that declares only before events.** It never opens a chain at all — no invocation, no sequence, no `flush()`. An exception thrown there is logged and flushed immediately, because the statement dies with it.
- **A save aborted without an Apex exception** — a validation rule, a duplicate rule, or a row lock. The triggers never see it.

For an aborted save the flush happens late, at the next chain, or not at all if none follows. Never make `flush()` the only delivery path for something that must not be lost. Pair it with a platform event or a Queueable finalizer when the content matters.

::: warning
DML from a before-context handler is unsupported. It is platform-legal, but the trigger it fires starts with an empty stack, so it is recorded as a chain of its own rather than as a child of the statement that caused it. Do related-record work in an after context or in `flush()`.
:::

## Bulk behaviour

Salesforce splits DML into chunks of 200 records and fires the whole trigger cycle per chunk. Trigger Lib treats all chunks of one statement as one chain, so `flush()` is called once for a 201-record update, not twice.

This matters most for nested work, because chunking multiplies it. Consider 201 records at every level of a four-level cascade:

```
201 Accounts  →  2 chunks  →  2 Opportunity statements
                            →  4 Case statements
                            →  8 Campaign statements
```

That is 15 DML statements and 3,015 rows from a single `update`, and it consumed over half the synchronous CPU budget in testing. All 59 invocations were correctly reported as one chain with a single `flush()` — but the multiplication itself is real, and it is why side effects belong in `flush()` rather than in a handler. A handler that enqueues a job runs once per chunk per level; a `flush()` runs once.

## How the end is detected

The platform does not tell a trigger whether another chunk is coming, so Trigger Lib infers it. You do not need this to use the library, but it explains the guarantees above.

Two platform facts do the work. Every row of a DML statement is counted in `Limits.getDmlRows()` the moment its first chunk fires, so the row count at that moment gives the statement's size. And only the _final_ chunk of a statement can be shorter than 200 records.

From those, the statement is finished when the after phase has seen every row, or when an after chunk is short. Three situations complicate it:

**A partial save also produces a short after chunk.** When a record is vetoed with `addError` under `allOrNone = false`, the after phase runs for the survivors only. That chunk is short but not final — the platform is about to roll everything back and re-run. It is told apart by comparing the phases: a real final chunk has seen as many rows after as before, while a partial save is missing the vetoed ones. Without this the library would flush work that was about to be discarded.

**DML on objects without an orchestrated trigger is invisible.** Its rows still land in `Limits.getDmlRows()`, so the size reading includes rows that are not part of the statement. `Limits.getDmlStatements()` reveals this: if more than one statement elapsed since the last measurement, the reading cannot be trusted. The statement is then treated as ending at every chunk, and a further chunk extends it and re-arms the flush. That is where the extra `flush()` calls come from — the sequence number stays the same.

**More than one trigger on the same object.** Each trigger calling `run()` opens its own invocation for the same records in the same context. These are recognised by matching the operation and record set against the invocation that just closed, with no DML in between. They are folded into the same statement, and the recursion guard counts them once rather than once per trigger.

::: warning
When two trigger-lib triggers exist on one object, `flush()` is called when the _first_ one's invocation closes — nothing can tell the library that a second trigger is about to run. One trigger per object avoids this entirely.
:::

## Errors and the stack

`TriggerOrchestrator.Error` carries `getStack()`, a snapshot of the invocation stack taken where the exception was caught, so a failure four levels down records the whole path that led to it rather than just the object that threw.

An exception propagates through every invocation it passes, and each one logs it. A failure five levels deep produces five entries for one root cause, each wrapping the last in a `DmlException`. This is intentional — an invocation cannot tell a fresh error from one already recorded — so deduplicate in your `Logger` if you only want the origin. The innermost entry has the shortest stack.

## Reference

| Member                                | Returns            | Description                                        |
| ------------------------------------- | ------------------ | -------------------------------------------------- |
| `TriggerOrchestrator.getStack()`      | `List<Invocation>` | Snapshot of executing invocations, outermost first |
| `TriggerOrchestrator.getChainTree()`  | `List<Invocation>` | Full map of the current chain, roots with children |
| `TriggerOrchestrator.getDepth()`      | `Integer`          | Current nesting depth; 1 is top-level              |
| `TriggerOrchestrator.isChainEnding()` | `Boolean`          | True in the final chunk of a top-level statement   |
| `TriggerOrchestrator.getRequestId()`  | `String`           | Platform request id, constant for the transaction  |

See the [API reference](/api/trigger-orchestrator) for `Invocation`, `Logger`, and `Error`.
