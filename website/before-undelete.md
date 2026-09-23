---
description: Salesforce has no before undelete trigger event, so Trigger Lib has no BeforeUndelete context. Block or react to a restore from the Recycle Bin in AfterUndelete instead.
---

# There Is No BeforeUndelete

Salesforce has no before undelete trigger event, so Trigger Lib has no BeforeUndelete context and no Populator or Validator for a restore. To check, block or react to records restored from the Recycle Bin, use [AfterUndelete](/after-undelete/).

## Why It Does Not Exist {#why}

- **Seven trigger events.** Salesforce triggers have before and after insert, update and delete, and only after undelete. A trigger that lists `before undelete` does not compile: "Trigger Usage Before Undelete is not supported".
- **Only `AFTER_UNDELETE` fires.** Restoring records, whether a user does it from the Recycle Bin or code calls `undelete` or `Database.undelete`, runs the after undelete trigger and nothing before it. `Trigger.isUndelete` is only ever true together with `Trigger.isAfter`.
- **Nothing to populate.** The restored rows come back with the values they had when they were deleted. In after undelete they are read-only, and `TriggerHandler.UndeleteRecord` has no `put`.

## Block a Restore {#block-a-restore}

Reject the restore from an [AfterUndelete.Writer](/after-undelete/writer) or [AfterUndelete.Dispatcher](/after-undelete/dispatcher):

1. In the handler's predicate, qualify the records that must stay deleted.
2. In the action, call `record.getNewSObject().addError('…')` on each of them.
3. List the handler in the orchestrator's `afterUndeleteHandlers()`.

The platform rolls back the restore of every record that has an error. The record stays in the Recycle Bin with `IsDeleted = true`, and the caller gets your message. An `undelete` statement fails as a whole; `Database.undelete(records, false)` still restores the other records. A complete Writer that lets only users with a custom permission restore accounts is on the AfterUndelete overview, under [There Is No BeforeUndelete](/after-undelete/#no-before-undelete).

Later handlers still run for a rejected record. Their unit-of-work writes roll back with it, but a Publish Immediately event goes out anyway. A handler can skip such records with `record.getNewSObject().hasErrors()` in its predicate.

## What to Use Instead {#instead}

| You wanted to… | In AfterUndelete |
|---|---|
| Validate the restore | `record.getNewSObject().addError(…)` from a [Writer](/after-undelete/writer) or [Dispatcher](/after-undelete/dispatcher), [as above](#block-a-restore) |
| Set a field on the restored record | a Writer's `toUpdate(new Account(Id = record.getId(), …))`, which fires the update triggers again: see [AfterUndelete Gotchas](/after-undelete/#gotchas) |
| Read the parent of a restored record | [AfterUndelete.ParentQuery](/after-undelete/add-ons/parent-query) |
| Skip a handler during restores | [AfterUndelete.Bypassable](/after-undelete/add-ons/bypassable) |
| Run the same logic as on insert | one class that implements both contexts' interfaces: see [One Class in Several Contexts](/guide/orchestrator#one-class-several-contexts) |

## See Also {#see-also}

- [AfterUndelete](/after-undelete/): the context that runs when records are restored.
- [AfterDelete](/after-delete/): the context that runs when records go to the Recycle Bin.
- [Contexts at a Glance](/contexts): every context and its method names.
