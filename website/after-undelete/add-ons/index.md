---
template: add-ons
context: AfterUndelete
description: The optional interfaces an after undelete Writer or Dispatcher can add - parent (lookup) fields, related records, its own unit of work, bypass, finalizer and continue on error.
---

# AfterUndelete Add-ons

Add-ons are the optional interfaces an **after undelete** Writer or Dispatcher implements next to its role: load parent (lookup) fields, query related records, give a Writer its own unit of work, skip (bypass, disable) a handler, run a Finalizer once per chunk, or log and continue on error.

## Add-ons in AfterUndelete {#available}

<!--@include: @/_parts/generated/after-undelete/add-ons-available.md-->

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-undelete/add-ons-not-available.md-->

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/after-undelete/add-ons-works-with.md-->

## See Also {#see-also}

- [AfterUndelete overview](/after-undelete/)
- [AfterUndelete.Writer](/after-undelete/writer) and [AfterUndelete.Dispatcher](/after-undelete/dispatcher)
- [Contexts at a Glance](/contexts): every context's method names
