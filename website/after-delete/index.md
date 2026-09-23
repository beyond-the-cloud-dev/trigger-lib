---
template: context
context: AfterDelete
description: After delete in Trigger Lib - clean up or recompute other records with a Writer, or hand work to a job once per chunk with a Dispatcher, after records are deleted.
---

# AfterDelete

Runs in **after delete**, after records are deleted and before the transaction commits. Only the old values exist. Change other records with a Writer or hand work to a job with a Dispatcher.

## Roles {#roles}

- [Writer](/after-delete/writer): create, update or delete other records through a unit of work.
- [Dispatcher](/after-delete/dispatcher): enqueue a job, send an email or publish events once per chunk.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/after-delete/add-ons-list.md-->

## Register {#register}

<!--@include: @/_parts/generated/after-delete/register.md-->

## Good to Know {#good-to-know}

- **The rows are gone.** `getId()` returns the deleted Id, but SOQL no longer finds the row. Key queries by the old lookups: `records.getIdsOf(Contact.AccountId)`.
- **Merge losers arrive here.** The records that lose a merge fire the delete triggers with `MasterRecordId` set. Skip them with `record.isNull(Contact.MasterRecordId)`.
- **Cascade deletes never arrive.** Records that the platform deletes with their parent, such as master-detail children, fire no delete triggers. Put that logic on the parent's delete.
- **Stop deletes in BeforeDelete.** `getOldSObject().addError(…)` here rolls the delete back, but only after earlier handlers did their work. Use a [BeforeDelete.Handler](/before-delete/handler).
- **One role per class.** A class that implements both roles runs only as a Writer.
