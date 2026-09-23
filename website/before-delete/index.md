---
template: context
context: BeforeDelete
description: Before delete in Trigger Lib - block a delete or clean up related records while the rows and their links still exist.
---

# BeforeDelete

Runs in **before delete**, before records are removed. The rows are still in the database and still linked. Block a delete here, or clean up the records that point at it.

## Roles {#roles}

- [Handler](/before-delete/handler): the only role here. Block a delete with `addError`, or clean up related records.

## Add-ons {#add-ons}

<!--@include: @/_parts/generated/before-delete/add-ons-list.md-->

## Register {#register}

<!--@include: @/_parts/generated/before-delete/register.md-->

## Good to Know {#good-to-know}

- **Ids are set.** `record.getId()` and `records.getIds()` return the Ids of the records being deleted. Their children can still be queried.
- **DML is allowed.** There is no DML guard and no unit of work. A statement runs at once and fires the triggers of the records it writes. Collect in `onBeforeDelete` and write once in a [Finalizer](/before-delete/add-ons/finalizer).
- **Leave the records being deleted alone.** DML on a `Trigger.old` row throws. Deleting a fresh instance of one fails with `SELF_REFERENCE_FROM_TRIGGER`.
- **Cascade deletes fire no child triggers.** Records removed by a cascade delete, such as an account's contacts, do not run their own delete triggers. Read them here with a [RelatedQuery](/before-delete/add-ons/related-query).
- **Merges look like deletes.** The records that lose a merge fire before delete like a plain delete. `MasterRecordId` is set only in [AfterDelete](/after-delete/).
