---
template: add-ons
context: BeforeUpdate
description: The optional interfaces a before update Populator or Validator can add, which roles honour each one, and what is not available in before update.
---

# BeforeUpdate Add-ons

Add-ons are optional interfaces that a **before update** Populator or Validator implements next to its role: load parent (lookup) fields and previous parents, query related records, skip (bypass) the handler, cap recursion, run once after the records, or keep going after an error.

## Add-ons in BeforeUpdate {#available}

<!--@include: @/_parts/generated/before-update/add-ons-available.md-->

A handler implements as many add-ons as it needs next to its one role. The example `ContactAccountTransferPopulator` implements `BeforeUpdate.Populator, BeforeUpdate.ParentQuery, BeforeUpdate.PriorParentQuery, BeforeUpdate.RecursionGuard`.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/before-update/add-ons-not-available.md-->

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/before-update/add-ons-works-with.md-->

An add-on that a role ignores still compiles: the library never calls it for that role, and nothing warns you.

## See Also {#see-also}

- [BeforeUpdate overview](/before-update/)
- [Populator](/before-update/populator) and [Validator](/before-update/validator)
- [AfterUpdate Add-ons](/after-update/add-ons/)
- [Contexts at a Glance](/contexts)
