The method returns a DML Lib unit, `DML.Committable`. Build it with `new DML()` and chain the settings you need:

```apex
return new DML()
    .userMode()
    .allowPartialSuccess()
    .identifier('<your identifier>');
```

| Setting | Effect |
|---|---|
| `userMode()` | The running user's object permissions, field-level security and sharing apply. This is the default of `new DML()`. |
| `systemMode()` | Object permissions and field-level security are ignored. Sharing follows `withSharing()` or `withoutSharing()`. |
| `withSharing()`, `withoutSharing()` | Enforce or ignore record sharing in system mode. Without either, sharing is inherited from the calling code. |
| `allowPartialSuccess()` | A failing row no longer fails the commit, and the other rows are saved. Failed rows do not throw, so read them with `commitHook` or `DML.retrieveResultFor`. |
| `combineOnDuplicate()` | A second `toUpdate` or `toDelete` of the same Id is merged into the first. Without it, the second registration throws "Duplicate records found during registration. Fix the code or use the combineOnDuplicate() method." |
| `skipDuplicateRules()` | Rows that a duplicate rule flags with an alert are saved anyway. |
| `identifier('<name>')` | Names the unit. `DML.retrieveResultFor('<name>')` returns its results later in the transaction, and a test can mock its statements with `DML.mock('<name>')`. |
| `commitHook(DML.Hook)` | Your `DML.Hook` runs inside the commit: `before()` before the first statement and `after(DML.Result)` after the last one, with the result of every row. `after` does not run when a statement throws. |
| `new DML(List<DML.OperationType>)` | Sets the statement order, for example deletes before inserts. Registering an operation that the list leaves out throws at registration. |

The shared unit uses `new DML().combineOnDuplicate().systemMode().withoutSharing().identifier('triggerUow')`. A plain `new DML()` differs from it: it runs in user mode, inherits its sharing, and throws on duplicate registrations.
