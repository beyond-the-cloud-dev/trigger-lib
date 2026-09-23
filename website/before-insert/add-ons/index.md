---
template: add-ons
context: BeforeInsert
description: The add-ons a before insert Populator or Validator can implement - parent fields, related records, bypass, finalizer and continue on error.
---

# BeforeInsert Add-ons

Add-ons are extra interfaces a **before insert** Populator or Validator implements next to its role: read parent (lookup) fields or other records without SOQL in the loop, skip or bypass the handler on a condition, run once after its records, or let it fail without failing the save.

## Add-ons in BeforeInsert {#available}

<!--@include: @/_parts/generated/before-insert/add-ons-available.md-->

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/before-insert/add-ons-not-available.md-->

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/before-insert/add-ons-works-with.md-->

## See Also {#see-also}

- [BeforeInsert](/before-insert/) overview, with the [Add-ons](/before-insert/#add-ons) summary.
- [BeforeInsert.Populator](/before-insert/populator) and [BeforeInsert.Validator](/before-insert/validator).
- [Contexts at a Glance](/contexts#method-names): every add-on's method name in every context.
