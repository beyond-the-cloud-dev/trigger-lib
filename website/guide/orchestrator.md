---
description: Wire a Salesforce trigger to Trigger Lib - the one-line trigger body, the orchestrator and its handler lists, run order, one class in several contexts, handler instances per chunk, constructor arguments and the before to after handoff.
---

# Trigger & Orchestrator

An orchestrator is a class that lists the handlers of one object, context by context, in the order they run. The trigger passes it to `TriggerOrchestrator.run(…)`, and the library does the rest.

## Trigger {#trigger}

Give each object one trigger, and keep its body to a single line:

<<< @/../examples/main/default/triggers/AccountTrigger.trigger

- **List all seven events.** The orchestrator decides which contexts do work. A context it does not implement returns before any handler code runs, so you add handlers later without touching the trigger.
- **Nothing else goes in the body.** Every handler, bypass and error rule lives behind `run(…)`. Code placed next to it runs outside the library: it is not switched off by the bypasses and its errors never reach the Logger.
- **One trigger per object.** Salesforce does not guarantee the order of several triggers on one object, while the orchestrator's list order is the run order.

## Orchestrator {#orchestrator}

The orchestrator implements one registration interface per context it handles. Each has one method that returns the handlers of that context:

| Registration interface | Method | List element type |
|---|---|---|
| `TriggerOrchestrator.BeforeInsert` | `beforeInsertHandlers()` | `BeforeInsert.Handler` |
| `TriggerOrchestrator.AfterInsert` | `afterInsertHandlers()` | `AfterInsert.Handler` |
| `TriggerOrchestrator.BeforeUpdate` | `beforeUpdateHandlers()` | `BeforeUpdate.Handler` |
| `TriggerOrchestrator.AfterUpdate` | `afterUpdateHandlers()` | `AfterUpdate.Handler` |
| `TriggerOrchestrator.BeforeDelete` | `beforeDeleteHandlers()` | `BeforeDelete.Handler` |
| `TriggerOrchestrator.AfterDelete` | `afterDeleteHandlers()` | `AfterDelete.Handler` |
| `TriggerOrchestrator.AfterUndelete` | `afterUndeleteHandlers()` | `AfterUndelete.Handler` |

These seven are the whole set. Salesforce has no before undelete event: see [There Is No BeforeUndelete](/before-undelete).

<<< @/../examples/main/default/classes/account/AccountTriggerOrchestrator.cls

The list element type is the context's `Handler` interface. Except in before delete, where `BeforeDelete.Handler` is the role itself, it is an empty marker that the roles extend: Populator and Validator in the before insert and update contexts, Writer and Dispatcher in the after contexts. The classes you list implement a role. A class that implements only the marker compiles, fits in the list and never runs. A class that implements both roles of a context runs only as the first one: Populator over Validator, Writer over Dispatcher. Nothing warns you in either case. The roles and their method names per context are on [Contexts at a Glance](/contexts#method-names).

### Names That Look Alike {#name-collisions}

<!--@include: @/_parts/notes/name-collisions.md-->

## Unimplemented Contexts {#unimplemented}

Implement only the registration interfaces you need. When the trigger fires in a context the orchestrator does not implement, `run(…)` returns before any handler code runs and the save goes on. There is no error and nothing is logged, so a trigger that declares all seven events with an orchestrator that implements two is an ordinary setup.

An empty list behaves the same way: `return new List<AfterInsert.Handler>();` runs nothing. A handler that is missing from the list never runs either, even though it compiles, which is why a registration test is worth having: see [Testing](/guide/testing#registration).

## Handler Order {#order}

Handlers run in the order the list returns them, whatever their role. Each handler finishes before the next one starts: its RelatedQuery providers, its predicate and action for every record, and its Finalizer. A Writer that does not use the shared unit of work also commits its own unit before the next handler starts.

- **Later handlers see earlier changes.** In before insert and before update, a Validator listed after a Populator sees the fields the Populator set, in its predicate and in its error method. List the Populators first.
- **Predicates run at the handler's turn.** A predicate is evaluated record by record, right before that record's action, not in one pass up front. Moving a handler in the list changes what the handlers below it see.
- **Some work happens before the first handler.** Every handler's bypass check runs, and the parents that all active handlers declared are loaded, before the first handler starts.
- **After contexts commit last.** In the after contexts, the shared unit of work commits once, after the last handler, so a Dispatcher always runs before the Writers' registrations on that unit are saved.

The full sequence, and what each step costs, is on [Execution Order & Cost](/guide/execution-order).

## One Class in Several Contexts {#one-class-several-contexts}

One class can implement the interfaces of several contexts, for example the same rule on insert and on update:

```apex
public with sharing class ContactBirthdateRangeValidator implements BeforeInsert.Validator, BeforeUpdate.Validator {
    private static final String MESSAGE = 'Birthdate must be in the past.';

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateRangeValidator.MESSAGE);
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Contact.Birthdate) && this.isInFuture((Contact) record.getNewSObject());
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        record.addError(Contact.Birthdate, ContactBirthdateRangeValidator.MESSAGE);
    }

    private Boolean isInFuture(Contact contactRecord) {
        return contactRecord.Birthdate != null && contactRecord.Birthdate > Date.today();
    }
}
```

- **Method names carry the context**, so the methods of different contexts never clash.
- **Register it in each context's list**, here in `beforeInsertHandlers()` and in `beforeUpdateHandlers()`. A context whose list does not contain it does not run it.
- **Share logic through the row.** `TriggerHandler.InsertRecord`, `UpdateRecord` and `UndeleteRecord`, and the two Rejectable types, are unrelated interfaces. Pass `record.getNewSObject()` to a private method, as `isInFuture` does here.
- **Add-ons are per context too.** `BeforeInsert.ParentQuery` declares parents for before insert only; for before update the class also implements `BeforeUpdate.ParentQuery`. The same holds for every add-on, such as `AfterInsert.ParentQuery` and `AfterUndelete.ParentQuery` on a Writer that handles insert and undelete.
- **The role is chosen per context.** A class can be a Populator in before update and a Writer in after update, which suits the [handoff below](#before-after-handoff).
- **Switches cover every context.** A `TriggerHandler__mdt` record, or `TriggerOrchestrator.bypass().handler(X.class)` for a top-level class, switches the class off in every context it serves. To skip one context, use that context's Bypassable, or leave the class out of that list.

A Writer for both after insert and after undelete is a common pair: see [AfterUndelete](/after-undelete/#pick-a-role).

## Instances per Chunk {#instances-per-chunk}

The trigger builds a new orchestrator every time it fires, and the library calls the context's handler list method on every run. An orchestrator that returns `new` handlers, as the examples do, therefore gives you fresh handler instances on every run:

- **Instance fields reset** for each context (before and after the save are separate runs), for each chunk of up to 200 records, and for each nested run.
- **Static fields last for the transaction**, across all chunks, contexts and nested runs. A handler kept in a static field of the orchestrator keeps its instance fields for the transaction too.
- **Per-run state belongs in instance fields.** A Writer that keeps the unit of work from its action for its Finalizer, or an action that collects values for its Finalizer, is fine.
- **Cross-run state belongs in statics, deliberately.** A static collection keeps growing across chunks and nested runs until the transaction ends, so clear what you no longer need.
- **A static "already ran" flag skips later chunks.** A statement of 201 records runs the trigger twice in one transaction, so a static Boolean set during the first chunk skips every record of the second. To act once per record, gate the predicate on a change such as `isChanged`, or use RecursionGuard in the update contexts, which counts per record Id.

The library's own transaction-wide state works the same way: the recursion budgets of the update contexts and the `TriggerOrchestrator.bypass()` switches last for the transaction. In a test, every test method starts with fresh static values.

## Constructor Arguments {#constructor-args}

Your orchestrator builds the handlers, so a handler can take constructor arguments:

```apex
public with sharing class AccountHotRatingPopulator implements BeforeInsert.Populator {
    private Decimal minimumRevenue;

    public AccountHotRatingPopulator(Decimal minimumRevenue) {
        this.minimumRevenue = minimumRevenue;
    }

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.greaterThanOrEqualTo(Account.AnnualRevenue, this.minimumRevenue);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        record.put(Account.Rating, 'Hot');
    }
}
```

Register it with the value: `new AccountHotRatingPopulator(1000000)` in `beforeInsertHandlers()`.

- **Arguments are evaluated on every run**, because the list method is called on every run of its context. Reading a custom setting there is cheap. A SOQL query there runs once per chunk, and an exception it throws is never passed to the Logger.
- **Two instances are one handler.** Two instances of the same class, even with different arguments, share the class name, so a metadata switch turns both off, they share one recursion budget, and the Logger sees one name. See [Names That Look Alike](#name-collisions).

## Before to After Handoff {#before-after-handoff}

To decide something before the save and act on it after the save, stamp the decision on the record in a BeforeUpdate Populator, and let an AfterUpdate Writer or Dispatcher qualify on the stamp:

::: code-group

```apex [AccountHotRatingUpdatePopulator.cls]
public with sharing class AccountHotRatingUpdatePopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.AnnualRevenue) && record.greaterThanOrEqualTo(Account.AnnualRevenue, 1000000);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        record.put(Account.Rating, 'Hot');
    }
}
```

```apex [AccountHotRatingTaskWriter.cls]
public with sharing class AccountHotRatingTaskWriter implements AfterUpdate.Writer {
    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Account.Rating, 'Hot');
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        unitOfWork.toInsert(new Task(WhatId = record.getId(), Subject = 'Call the account: its rating is now Hot'));
    }
}
```

:::

- **The stamp is saved with the record**, so the after update run sees it: `isChangedTo` compares the saved row with the row as it was before this update.
- **A stamp also catches manual edits.** Here a user who sets Rating to Hot by hand gets a Task too. When only the Populator's decision should count, stamp a field that users cannot edit.
- **A static `Set<Id>` works too**, because statics last for the transaction: the Populator adds `record.getId()`, and the Writer qualifies on `contains(record.getId())`. Remove each Id once it is handled, or a later update in the same transaction finds it again.
- **Instance fields do not carry over.** Before update and after update are separate runs, and an orchestrator that returns `new` handlers gives each run new instances, even when both roles live in one class.

## Nested Triggers {#nested}

DML inside a run, such as the unit of work's commit in an after context, fires the triggers of the objects it writes, and those triggers call `TriggerOrchestrator.run(…)` again. Each nested run has its own orchestrator, handler instances, parents and shared unit, and it finishes before the outer run goes on.

- **The Logger is finalized by the outermost run.** Its `finalize()` is called at the end of each outermost run, that is, once for each context and chunk the orchestrator handles. A nested run never calls it.
- **Transaction-wide state is shared.** Recursion budgets and `TriggerOrchestrator.bypass()` switches apply to nested runs as well.

## Outside a Trigger {#outside-a-trigger}

`TriggerOrchestrator.run(…)` works only inside a trigger. Called from anonymous Apex, a service class or a test method without DML, it throws a `TriggerOrchestratorException` with this message:

```text
Called outside of a trigger context, or the trigger operation is not supported.
```

It is thrown before any handler code, so it is not passed to the Logger. The exception class is private and cannot be caught by type: catch `Exception` and match the message. See [TriggerOrchestratorException](/api/trigger-orchestrator#triggerorchestratorexception).

To exercise a handler in a unit test, call its methods with records built in memory, or run DML so the trigger calls `run(…)` for you: see [Testing](/guide/testing).
