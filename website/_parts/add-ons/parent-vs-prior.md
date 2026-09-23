| | ParentQuery | PriorParentQuery |
|---|---|---|
| Loads the parent that the lookup | points to now, on the new row | pointed to before this save, on the old row |
| Read it with | `record.getNewParent('<relationship>')` | `record.getOldParent('<relationship>')` |
| Declared by | `queryParentsOn<Ctx>()` | `queryPriorParentsOn<Ctx>()`, named `queryParentsOn<Ctx>()` in before delete and after delete |
| Contexts | before insert, after insert, before update, after update, after undelete | before update, after update, before delete, after delete |

- **One field list per lookup.** Both interfaces return the same map shape. Fields declared for one lookup on either side are merged, so both sides of that lookup carry every declared field.
- **Unchanged lookups share one record.** In before update and after update, when a lookup did not change, `getNewParent` and `getOldParent` return the same loaded record.
- **Declare the side you read.** A handler that compares the old and the new parent implements both interfaces.
