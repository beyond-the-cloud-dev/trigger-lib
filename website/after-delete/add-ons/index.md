---
template: add-ons
context: AfterDelete
description: The add-ons an after delete Writer or Dispatcher can implement — former parent fields (lookup), related queries, own unit of work, bypass, finalizer, continue on error — and which roles honour them.
---

# AfterDelete Add-ons

Add-ons are extra interfaces that an **after delete** Writer or Dispatcher implements next to its role: load the former parent's fields (lookup) without SOQL, query the records that remain, give a Writer its own unit of work, skip (bypass) a handler, run one step per chunk, or keep the delete going after an error.

## Add-ons in AfterDelete {#available}

<!--@include: @/_parts/generated/after-delete/add-ons-available.md-->

In delete contexts the PriorParentQuery method is named `queryParentsOn<Ctx>()`: here it is `queryParentsOnAfterDelete()`.

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-delete/add-ons-not-available.md-->

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/after-delete/add-ons-works-with.md-->

## See Also {#see-also}

- [AfterDelete](/after-delete/) overview
- [AfterDelete.Writer](/after-delete/writer) and [AfterDelete.Dispatcher](/after-delete/dispatcher)
- [Contexts at a Glance](/contexts), for the same add-ons in every context
