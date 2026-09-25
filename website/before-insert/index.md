---
template: context
context: BeforeInsert
description: Before insert in Trigger Lib - set fields with a Populator or reject records with a Validator before new records are saved.
---

# BeforeInsert

Runs in **before insert**, before new records are saved.

## Roles {#roles}

- [Populator](/before-insert/populator): set, default or normalize fields on the new record.
- [Validator](/before-insert/validator): reject a record with an error message.

## Register {#register}

<!--@include: @/_parts/generated/before-insert/register.md-->

## Rules {#rules}

- **No Id yet.** `record.getId()` is null and `records.getIds()` is empty. Never key a map by the record Id here.
- **Lookups hold only the Id.** `((Contact) record.getNewSObject()).Account` is null. Declare a [ParentQuery](/before-insert/add-ons/parent-query) and read `record.getNewParent(Contact.AccountId)`.
- **One role per class.** A class that implements both roles runs only as a Populator. List Populators first, so Validators see the values they set.
- **Called per chunk.** `beforeInsertHandlers()` runs for every chunk of up to 200 records. Handlers created there start with empty instance fields each time; static fields last the whole transaction.

::: warning
No DML. If a handler runs DML or publishes an event, the library throws. Change other records from an [AfterInsert.Writer](/after-insert/writer).
:::
