| Value | Effect |
|---|---|
| 3 | The default, when the handler does not implement RecursionGuard. |
| 1 | One qualifying pass per record per transaction. A partial-save retry uses it up (see below). |
| 0 or negative | The handler never runs: every record is skipped before its predicate. |
| null | No limit: a comparison with null is false, so no record is ever skipped. |

**A limit of 1 and partial saves.** When `Database.update(list, false)`, Data Loader or the Bulk API saves a batch that contains a failing record, the platform rolls back the first attempt and runs the triggers again for the records that did not fail. The count lives in a static, and the rollback does not reset it. The first attempt uses up the only pass, so the retry skips every surviving record, silently. The work of the first attempt is rolled back and never redone: in after update, the handler's unit-of-work registrations are lost. In before update, the Populator's field values are most likely lost the same way (not verified in an org). Prefer a change gate such as `isChanged`. If you need a guard and callers may save partially, use 2 or more.
