Some of your code runs outside every handler's `try` block. An exception thrown there is never passed to `TriggerOrchestrator.Logger`, ContinueOnError does not apply to it, and it propagates out of `TriggerOrchestrator.run()` and fails the DML statement:

- the orchestrator's `<ctx>Handlers()`;
- the add-on methods called while the handler list is adapted, even for a handler that is switched off right after: `ownUnitOfWorkOn<Ctx>()` on an after-context Writer, and `maxRecursionDepthOn<Ctx>()` on a BeforeUpdate Populator or an AfterUpdate Writer or Dispatcher;
- `bypassOn<Ctx>When()`;
- the ParentQuery and PriorParentQuery methods that declare parents, and the parent SOQL they cause;
- the parent query after a Populator (before insert and before update only);
- the shared unit of work's commit (after contexts; in before contexts it is always empty).

"Never logged" refers to `TriggerOrchestrator.Logger` only. A DML statement that fails inside a unit's commit is still reported to a DML Lib `DML.Logger` implementation, if the org has one.
