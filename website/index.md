---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
description: Apex trigger framework for Salesforce with one role per trigger context, record filtering, declared parent and related queries, a unit of work, bypasses and recursion control.

hero:
  name: 'Trigger Lib'
  text: 'Salesforce Apex Trigger Framework'
  tagline: One role per trigger context, record filtering, declared parent and related queries, a unit of work for DML, three bypass layers and recursion control.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/first-handler
    - theme: alt
      text: Contexts at a Glance
      link: /contexts

features:
  - title: Orchestrator & Handlers
    details: One trigger and one orchestrator per object. The orchestrator lists the handlers of each context in run order, in plain Apex.
    link: /guide/orchestrator
  - title: One Role per Context
    details: Populator and Validator before insert and update, Writer and Dispatcher after the save, Handler before delete. Every method name carries its context.
    link: /contexts
  - title: Record Filtering
    details: Every role declares a predicate, and only the records that qualify reach the action. A Dispatcher gets them all at once, every other role one record at a time, so handlers never loop.
    link: /api/record
  - title: Parent Queries
    details: Declare the lookups and parent fields you need. The library loads them before the first handler runs and attaches them to each record, with no SOQL in your code.
    link: /api/field-selection
  - title: RelatedQuery Providers
    details: Children, siblings or configuration records come from a named provider. It queries once per handler for all the records, and the handler reads the results by key.
    link: /guide/related-records
  - title: Writers, Dispatchers & Unit of Work
    details: Writers register inserts, updates, deletes and events on a shared DML Lib unit that commits once, after the last handler. Dispatchers hand work to Queueables, events or email.
    link: /guide/unit-of-work
  - title: Three Bypass Layers
    details: TriggerOrchestrator.bypass() for one transaction, custom metadata for an org-wide switch without a deploy, and Bypassable for a condition in the handler.
    link: /guide/bypasses
  - title: Recursion Guard
    details: In before update and after update, Populators, Writers and Dispatchers act on the same record at most three times per transaction by default. Set the limit per handler.
    link: /after-update/add-ons/recursion-guard
  - title: No Required Metadata
    details: Works with zero custom metadata records. Metadata only switches an object or a handler off, and reading it costs no SOQL against the limit.
    link: /api/custom-metadata
---

<BTCFooter context="trigger-lib" />
