---
template: add-ons
context: BeforeDelete
description: "The optional interfaces a before delete Handler can add, which ones are missing here, and where to find them instead."
---

# BeforeDelete Add-ons

Add-ons are the optional interfaces a `BeforeDelete.Handler` implements next to its role in **before delete**: read the old parent's fields (lookup, parent fields), query children and related records, skip (bypass, disable) the handler, run once after its records for bulk DML, or keep the delete going after an error.

## Add-ons in BeforeDelete {#available}

<!--@include: @/_parts/generated/before-delete/add-ons-available.md-->

In delete contexts the PriorParentQuery method is named `queryParentsOnBeforeDelete()`, without "Prior".

## Not Available Here {#not-available}

<!--@include: @/_parts/generated/before-delete/add-ons-not-available.md-->

## Which Roles Honour Them {#works-with}

<!--@include: @/_parts/generated/before-delete/add-ons-works-with.md-->

BeforeDelete has one role, so every add-on here works with the Handler.

## See Also {#see-also}

- [BeforeDelete](/before-delete/): the context overview.
- [BeforeDelete.Handler](/before-delete/handler)
- [Add-ons in AfterDelete](/after-delete/add-ons/): the add-ons after the rows are gone, including OwnUnitOfWork.
- [Contexts at a Glance](/contexts#method-names): every add-on method in every context.
