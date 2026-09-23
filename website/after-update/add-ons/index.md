---
template: add-ons
context: AfterUpdate
description: 'Every add-on an after update Writer or Dispatcher can implement: parent fields, previous parents, related records, its own unit of work, bypass, recursion guard, finalizer and continue on error.'
---

# AfterUpdate Add-ons

Add-ons are extra interfaces that an **after update** Writer or Dispatcher implements next to its role: load lookup (parent) fields of the current or the previous parent, query related records, bring its own unit of work, skip (bypass) itself, cap recursion, run once after its records, or keep going after an error. All eight exist in after update.

## Add-ons in AfterUpdate {#available}

<!--@include: @/_parts/generated/after-update/add-ons-available.md-->

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/after-update/add-ons-not-available.md-->

Add-ons belong to one context. `AfterUpdate.ParentQuery` does nothing when the same class also runs in before update; implement `BeforeUpdate.ParentQuery` there as well.

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/after-update/add-ons-works-with.md-->

OwnUnitOfWork is the only add-on a Dispatcher ignores: the library never calls its method, because a Dispatcher never receives a unit of work.

## See Also {#see-also}

- [AfterUpdate](/after-update/): the context overview.
- [AfterUpdate.Writer](/after-update/writer) and [AfterUpdate.Dispatcher](/after-update/dispatcher)
- [Contexts at a Glance](/contexts): which add-ons exist in which context, with the exact method names.
