<!-- #region parent -->

Attach the parents yourself instead of letting the library query them. Build the record from in-memory rows, then call the predicate or the action with it:

```apex
TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(newRow, oldRow);

record.enrichNew('Account', new Account(Name = 'Acme'));
record.enrichOld('Account', new Account(Name = 'Globex'));
```

- Pass `null` for the side the context does not have: `oldRow` on insert and undelete, `newRow` on delete.
- `enrichNew` sets what `getNewParent` returns, and `enrichOld` what `getOldParent` returns. Use the one your add-on reads. Neither runs a query.
- For a grandparent, nest it: `new Account(Owner = new User(IsActive = true))`. For a field you cannot write, such as `User.Name`, build the parent with `JSON.deserialize`.
- For fake Ids, use `new TriggerHandler.RandomIdGenerator().get(Account.SObjectType)`.

`enrichNew` and `enrichOld` are public, but `TriggerHandler` lists them under an internal-use comment, so they may change in a later version. More in [Testing](/guide/testing).

<!-- #endregion parent -->

<!-- #region related -->

Hand the handler its provider results yourself instead of running the query. `record` is a `TriggerHandler.TriggerRecord` built from in-memory rows:

```apex
Account existing = new Account(Id = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType), Name = 'Acme');
TriggerHandler.ProvidedRecords provided = new TriggerHandler.ProvidedRecords(new List<SObject>{ existing });
provided.groupUnderKey('acme', existing);

record.setProvidedRecords(new Map<String, TriggerHandler.RelatedRecords>{ '<provider name>' => provided });
```

- Group each row under the key your `keyOf` returns for it, because the handler reads by that key.
- Test `keyOf` on its own with an in-memory row, for example `new <YourProvider>().keyOf(new Account(Name = 'ACME'))`.
- `query` runs real SOQL. A provider that queries through SOQL Lib can be served with `SOQL.mock(<Object>.SObjectType).thenReturn(rows)`; an inline `[SELECT …]` cannot be mocked.

`setProvidedRecords` is public, but `TriggerHandler` lists it under an internal-use comment, so it may change in a later version. More in [Testing](/guide/testing).

<!-- #endregion related -->

<!-- #region bypass -->

Call the method directly. It takes no records:

```apex
<YourHandler>.isDisabled = true;

Assert.isTrue(new <YourHandler>().bypassOn<Ctx>When(), 'The handler should be bypassed.');
```

Every test method starts with fresh static values, so a flag set in one test does not leak into another. To test a `TriggerOrchestrator.bypass()` switch or a metadata record, run the orchestrator in the test, which works in the same namespace only: [Testing](/guide/testing#mock-metadata).

<!-- #endregion bypass -->

<!-- #region uow -->

Test what the Writer registers by passing its action a small class of your own that implements `TriggerHandler.UnitOfWork` and keeps what it receives. Test the unit your method returns by mocking its identifier and committing it directly:

```apex
DML.mock('<your identifier>').allInserts();

new <YourWriter>().ownUnitOfWorkOn<Ctx>().toInsert(new Task(Subject = 'Review')).commitWork();

Assert.areEqual(1, DML.retrieveResultFor('<your identifier>').insertsOf(Task.SObjectType).records().size(), 'One task should be inserted.');
```

The mocked insert never reaches the database. Running the whole Writer through the orchestrator works in the same namespace only: [Testing](/guide/testing).

<!-- #endregion uow -->

<!-- #region finalizer -->

Call the Finalizer directly with the records your predicate would qualify, because those are the only records it receives:

```apex
List<TriggerHandler.TriggerRecord> qualified = new List<TriggerHandler.TriggerRecord>{
    new TriggerHandler.TriggerRecord(newRow, oldRow)
};

new <YourHandler>().finalize<Ctx>(new TriggerHandler.<X>TriggerRecords(qualified));
```

`<X>` is `Insert`, `Update`, `Delete` or `Undelete`. Pass `null` for the side the context does not have. For a Writer that registers from its Finalizer, call the action first with a small class of your own that implements `TriggerHandler.UnitOfWork`, so the unit field is set.

<!-- #endregion finalizer -->
