---
description: Every Trigger Lib context side by side. The exact interface and method names for before insert, after insert, before update, after update, before delete, after delete and after undelete, the facts that differ between them, and how page URLs are built.
---

# Contexts at a Glance

Find the trigger event you need, the role that runs there and the exact method names to implement. Every method name carries its context, so the tables below also show where a feature exists and where it does not.

## Trigger Events {#events}

Salesforce has seven trigger events, and Trigger Lib has one context for each of them. Each context is a class of interfaces, such as `BeforeInsert` or `AfterUpdate`. Each context also has a registration interface on the orchestrator, such as `TriggerOrchestrator.BeforeInsert`. Every context runs once per chunk of up to 200 records.

| Trigger event | `Trigger.operationType` | Context | Roles |
|---|---|---|---|
| before insert | `BEFORE_INSERT` | [BeforeInsert](/before-insert/) | [Populator](/before-insert/populator), [Validator](/before-insert/validator) |
| after insert | `AFTER_INSERT` | [AfterInsert](/after-insert/) | [Writer](/after-insert/writer), [Dispatcher](/after-insert/dispatcher) |
| before update | `BEFORE_UPDATE` | [BeforeUpdate](/before-update/) | [Populator](/before-update/populator), [Validator](/before-update/validator) |
| after update | `AFTER_UPDATE` | [AfterUpdate](/after-update/) | [Writer](/after-update/writer), [Dispatcher](/after-update/dispatcher) |
| before delete | `BEFORE_DELETE` | [BeforeDelete](/before-delete/) | [Handler](/before-delete/handler) |
| after delete | `AFTER_DELETE` | [AfterDelete](/after-delete/) | [Writer](/after-delete/writer), [Dispatcher](/after-delete/dispatcher) |
| before undelete | none: Salesforce has no such event | [No BeforeUndelete](/before-undelete) | none |
| after undelete | `AFTER_UNDELETE` | [AfterUndelete](/after-undelete/) | [Writer](/after-undelete/writer), [Dispatcher](/after-undelete/dispatcher) |

A handler class implements one role of a context. It adds as many of that context's add-ons (ParentQuery, Bypassable, Finalizer and the others) as it needs, and is listed in the orchestrator's handler method for that context.

## Method Names {#method-names}

Each cell shows the method or the predicate / action pair that you implement, and links to its page. A dash means that the context does not declare the interface.

<!--@include: @/_parts/generated/matrix-methods.md-->

## Facts {#facts}

These are the rows that differ between contexts. Each context overview repeats its own column under At a Glance.

<!--@include: @/_parts/generated/matrix-facts.md-->

## URL Rules {#url-rules}

Every context page sits at a predictable address, so you can type a URL or link to one without searching:

| Page | URL | Example |
|---|---|---|
| Context overview | `/<context>/` | [/after-update/](/after-update/) |
| Role | `/<context>/<role>` | [/after-update/writer](/after-update/writer) |
| Add-ons of a context | `/<context>/add-ons/` | [/after-update/add-ons/](/after-update/add-ons/) |
| One add-on | `/<context>/add-ons/<add-on>` | [/after-delete/add-ons/finalizer](/after-delete/add-ons/finalizer) |
| Record API of a context | `/<context>/record-api` | [/before-update/record-api](/before-update/record-api) |

- **Names become kebab-case.** `BeforeInsert` becomes `before-insert`, `PriorParentQuery` becomes `prior-parent-query` and `ContinueOnError` becomes `continue-on-error`.
- **Titles are qualified.** Role and add-on pages are titled `<Context>.<Interface>`, for example AfterDelete.Finalizer, so searching for the qualified name finds the page.
- **Section anchors are fixed.** Every page of one kind has the same sections with the same anchors in every context. For example, [/after-delete/add-ons/finalizer#gotchas](/after-delete/add-ons/finalizer#gotchas) and [/before-insert/add-ons/finalizer#gotchas](/before-insert/add-ons/finalizer#gotchas) both exist.

| Page kind | Section anchors |
|---|---|
| Context overview | `#at-a-glance` `#pick-a-role` `#add-ons` `#records` `#register` `#how-it-runs` `#switching-off` `#gotchas` `#not-available` `#see-also` |
| Role | `#when-to-use` `#interface` `#example` `#how-it-runs` `#register` `#records` `#works-with` `#gotchas` `#test` `#other-contexts` `#see-also` |
| Add-on | the role anchors without `#register` |
| Add-ons of a context | `#available` `#not-available` `#works-with` `#see-also` |
| Record API | `#receive` `#accessors` `#change-detection` `#predicates` `#comparisons` `#record-type` `#parents` `#collections` `#trigger-variables` `#gotchas` `#see-also` |

Some pages add sub-sections under `#how-it-runs` or `#interface`:

| Page | Extra anchors |
|---|---|
| Writer | `#unit-of-work-methods` `#which-unit` `#when-it-commits` `#platform-events` |
| Dispatcher | `#platform-events` |
| ParentQuery, PriorParentQuery | `#choosing-fields` `#parent-vs-prior` |
| RelatedQuery | `#records-provider` `#key-patterns` |
| OwnUnitOfWork | `#configuring` |
| Bypassable | `#other-ways` `#data-migration` |
| RecursionGuard | `#edge-values` |
| ContinueOnError | `#still-throws` `#logging` |
| AfterUndelete overview | `#no-before-undelete` |

## See Also {#see-also}

- [How do I…](/how-do-i): tasks mapped to the page that answers them.
- [Your First Handler](/guide/first-handler): a trigger, an orchestrator and two handlers, step by step.
- [Trigger & Orchestrator](/guide/orchestrator): how the trigger body and the handler lists work.
- [Execution Order & Cost](/guide/execution-order): what runs when, and what it costs.
