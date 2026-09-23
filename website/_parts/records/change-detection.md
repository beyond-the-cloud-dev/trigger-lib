Change detection compares the new row with the old row, field by field:

| Method | True when |
|---|---|
| `isChanged(field)` | the new value differs from the old one |
| `isAnyChanged(field1, …)` | at least one of 2 to 5 fields changed; also takes an `Iterable<SObjectField>`, and is false for an empty one |
| `areAllChanged(field1, …)` | every one of 2 to 5 fields changed; also takes an `Iterable<SObjectField>`, and is true for an empty one |
| `isChangedTo(field, value)` | the new value equals `value` and the old one does not. `isChangedTo(field, null)` means "cleared". |
| `isChangedFrom(field, value)` | the old value equals `value` and the new one does not. `isChangedFrom(field, null)` means "filled in". |
| `isChangedFromTo(field, from, to)` | the old value equals `from` and the new value equals `to` |

- **`isChangedFromTo` does not require a change.** When `from` and `to` are the same value, it is true for a field that kept that value. Add `isChanged(field)` when you need both.
- **Text comparison ignores case.** `'Doe'` → `'DOE'` is not a change, and `isChangedTo(field, 'doe')` is true for a change from `'Smith'` to `'Doe'`. To catch an edit that only changes letter case, compare the values of `getNewSObject()` and `getOldSObject()` with `String.equals`.
- **Null is a value.** A change from null to a value, or from a value to null, is a change. Null to null is not.
- **Old means before this update statement.** When a handler updates the same records again, the nested run compares with the values the first update saved, so only the new edit counts. A workflow field update is the exception: the update triggers it fires again see the old row from before the original update, so changes the first run already handled are reported again.
