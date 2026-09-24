---
template: context
context: BeforeDelete
description: Before delete in Trigger Lib - block a delete or clean up related records while the rows and their links still exist.
---

# BeforeDelete

Runs in **before delete**, before records are removed.

## Roles {#roles}

- [Handler](/before-delete/handler): the only role here. Block a delete with `addError`, or clean up related records.

## Register {#register}

<!--@include: @/_parts/generated/before-delete/register.md-->

## Rules {#rules}

- **DML is allowed.** There is no unit of work: a statement runs at once and fires the triggers of the records it writes.
- **Cascade deletes fire no child triggers.** Records removed by a cascade delete, such as an account's contacts, do not run their own delete triggers. Read them here with a [RelatedQuery](/before-delete/add-ons/related-query).
- **Merges look like deletes.** The records that lose a merge fire before delete like a plain delete. `MasterRecordId` is set only in [AfterDelete](/after-delete/).
