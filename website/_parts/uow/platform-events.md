A handler in an after context can publish a platform event in two ways, and they differ in when `EventBus.publish` runs:

| Route | Used by | `EventBus.publish` runs |
|---|---|---|
| `unitOfWork.toPublish(event)` | a Writer | inside the unit's commit, after its other statements unless an own unit sets another order, one call per event type |
| `EventBus.publish(events)`, or DML Lib's `new DML().publishImmediately(events)` | a Dispatcher, or any direct call | at once, at the handler's position in the list, before the shared commit |

- **A failed commit stops `toPublish`.** If an earlier statement in the same commit throws, the publish never runs.
- **The event's Publish Behavior decides delivery, not the route.**
  - Publish After Commit: subscribers get the event only if the transaction commits. It rolls back with the save.
  - Publish Immediately: subscribers get the event at once, even if the save later fails. When a partial save (`allOrNone` set to false) re-runs the handlers for the surviving records, the event may be published twice.
- **Limits.** Publishing a Publish After Commit event counts as a DML statement. Publishing a Publish Immediately event counts toward `Limits.getPublishImmediateDML()` instead.
- **Name clash.** DML Lib's `publishImmediately(…)` means "publish now, outside a unit of work". It does not change the event's Publish Behavior. The unit itself has only `toPublish`.
- **Mockable publish.** Give the `DML` instance an `identifier`, and a test can replace the publish with `DML.mock('<identifier>').allPublishes()` and read it back with `DML.retrieveResultFor('<identifier>').eventsOf(…)`.
