---
template: context
context: AfterDelete
description: After delete in Trigger Lib - clean up or recompute other records with a Writer, or hand work to a job once per chunk with a Dispatcher, after records are deleted.
---

# AfterDelete

Runs in **after delete**, after records are deleted and before the transaction commits.

## Roles {#roles}

- [Writer](/after-delete/writer): change other records or publish events through a unit of work.
- [Dispatcher](/after-delete/dispatcher): make one bulk call per chunk, such as enqueueing a Queueable.

## Register {#register}

<!--@include: @/_parts/generated/after-delete/register.md-->

## Rules {#rules}

- **The rows are gone.** `getId()` returns the deleted Id, but SOQL no longer finds the row. Key queries by the old lookups: `records.getIdsOf(Contact.AccountId)`.
- **Merge losers arrive here.** The records that lose a merge fire the delete triggers with `MasterRecordId` set. Skip them with `record.isNull(Contact.MasterRecordId)`.
- **Stop deletes in BeforeDelete.** `getOldSObject().addError(…)` here rolls the delete back, but only after earlier handlers did their work. Use a [BeforeDelete.Validator](/before-delete/validator).
- **One role per class.** A class that implements both roles runs only as a Writer.

::: warning
Cascade deletes never arrive. Records that the platform deletes with their parent, such as master-detail children, fire no delete triggers. Put that logic on the parent's delete.
:::
