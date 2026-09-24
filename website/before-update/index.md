---
template: context
context: BeforeUpdate
description: Before update in Trigger Lib - set fields with a Populator or reject changes with a Validator, with the old and new values side by side.
---

# BeforeUpdate

Runs in **before update**, before the changes are saved, with the old and new values side by side.

## Roles {#roles}

- [Populator](/before-update/populator): set, derive or clear fields, usually when another field changed.
- [Validator](/before-update/validator): reject a change with an error message.

## Register {#register}

<!--@include: @/_parts/generated/before-update/register.md-->

## Rules {#rules}

- **The old row is read-only.** Writing to `getOldSObject()` or calling `addError` on it throws a `FinalException` that no `catch` stops. The update fails.
- **Updates re-enter.** A later update of the same records in the transaction runs BeforeUpdate again. A Populator acts on a record at most 3 times per transaction by default. A Validator runs on every pass.
- **Lookups hold only the Id.** `((Contact) record.getNewSObject()).Account` is null. Declare a [ParentQuery](/before-update/add-ons/parent-query) and read `record.getNewParent('Account')`.
- **One role per class.** A class that implements both roles runs only as a Populator. List Populators first, so Validators see the values they set.

::: warning
No DML. If a handler runs DML or publishes an event, the library throws. Set fields with `record.put`, and change other records from an [AfterUpdate.Writer](/after-update/writer).
:::
