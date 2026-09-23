- **From Apex, for one transaction.** `TriggerOrchestrator.bypass()` switches off:
  - `.sObject(Account.SObjectType)`: every run on that object;
  - `.orchestrator(X.class)`: every run of that orchestrator;
  - `.handler(X.class)`: one handler, in every context;
  - `.all()`: every run.

  The first three return the builder, so they chain; `all()` and `clear()` return nothing. A switch lasts until `TriggerOrchestrator.bypass().clear()` or the end of the transaction, nested saves included, so call `clear()` in a `finally` block. `clear()` removes every switch.
- **By class: top-level classes only.** `handler(X.class)` and `orchestrator(X.class)` store the class's full name, `Outer.Inner` for an inner class, but compare it with the running class's simple name, `Inner`. An inner class therefore never matches. For an inner class, use a `TriggerHandler__mdt` record or the handler's Bypassable. Matching in a namespaced installation has not been verified.
- **From custom metadata, org-wide, without deploying code.** A `TriggerObject__mdt` record whose `ObjectAPIName__c` names the object and whose `Bypass__c` is checked switches off every handler on that object. A `TriggerHandler__mdt` record under it, with the class name in `ApexClassName__c` (`Outer.Inner` or `Inner` for an inner class) and `Bypass__c` checked, switches off that one handler. Both apply in every context and for every user. They are read once per transaction and cost no SOQL against the limit. See [Custom Metadata](/api/custom-metadata).
- **On a condition.** Implement the context's Bypassable. When `bypassOn<Ctx>When()` returns true, the handler is skipped for that run.
- **For some records.** Return false from the predicate.
- **For one context only.** No switch works per context: metadata and `handler(X.class)` switch a class off in every context it serves. To skip one context, implement that context's Bypassable, or leave the class out of that context's handler list.
- **For one user or permission.** There is no per-user, per-profile or per-permission switch. Metadata applies to the whole org, and `TriggerOrchestrator.bypass()` lasts one transaction. For one handler, check `FeatureManagement.checkPermission('<Custom Permission>')` in its Bypassable method. For every handler of a context, return an empty list from the orchestrator's `<ctx>Handlers()` method when the permission is assigned.
- **Only Trigger Lib handlers.** Every switch skips only handlers that run through Trigger Lib. Flows, validation rules, duplicate rules, workflow rules and triggers not built on Trigger Lib still run.
