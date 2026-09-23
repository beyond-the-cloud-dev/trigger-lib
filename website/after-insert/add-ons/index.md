---
template: add-ons
context: AfterInsert
description: The add-on interfaces an after insert Writer or Dispatcher can implement - parent and related queries, its own unit of work, bypass, finalizer and continue on error.
---

# AfterInsert Add-ons

Add-ons are the extra interfaces an **after insert** Writer or Dispatcher can implement next to its role: load parent (lookup) fields or other records without SOQL in the loop, give a Writer its own unit of work, skip or bypass the handler on a condition, run once after its records, or keep going after an error.

## Add-ons in AfterInsert {#available}

<!--@include: @/_parts/generated/after-insert/add-ons-available.md-->

A handler implements as many add-ons as it needs, in any combination. An add-on that its role ignores compiles and does nothing.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-insert/add-ons-not-available.md-->

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/after-insert/add-ons-works-with.md-->

## See Also {#see-also}

- [AfterInsert](/after-insert/): the context overview
- [AfterInsert.Writer](/after-insert/writer) and [AfterInsert.Dispatcher](/after-insert/dispatcher)
- [Contexts at a Glance](/contexts): every add-on method in every context
