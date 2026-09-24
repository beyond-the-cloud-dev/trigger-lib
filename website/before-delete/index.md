---
template: context
context: BeforeDelete
description: Before delete in Trigger Lib - block a delete with a Validator, or change related records with a Writer while the rows and their links still exist.
---

# BeforeDelete

Runs in **before delete**, before records are removed.

## Roles {#roles}

- [Validator](/before-delete/validator): block a delete with `addError`.
- [Writer](/before-delete/writer): change other records or publish events through a unit of work.

## Register {#register}

<!--@include: @/_parts/generated/before-delete/register.md-->

## Rules {#rules}

- **Writes land before the delete.** The shared unit of work commits after the last handler, while the rows and the records that point at them still exist.
- **Cascade deletes fire no child triggers.** Records removed by a cascade delete, such as an account's contacts, do not run their own delete triggers. Read them here with a [RelatedQuery](/before-delete/add-ons/related-query).
- **Merges look like deletes.** The records that lose a merge fire before delete like a plain delete. `MasterRecordId` is set only in [AfterDelete](/after-delete/).
- **One role per class.** A class that implements both roles runs only as a Validator.
