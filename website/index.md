---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
description: Apex trigger framework for Salesforce with one role per trigger context, record filtering, declared queries, a unit of work, bypasses and recursion control.

hero:
  name: 'Trigger Lib'
  text: 'Salesforce Apex Trigger Framework'
  tagline: One small class per concern, run only for the records that qualify.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/first-handler
    - theme: alt
      text: Contexts at a Glance
      link: /contexts

features:
  - title: One Orchestrator per Object
    details: List each context's handlers in plain Apex. List order is run order.
    link: /guide/orchestrator
  - title: One Role per Context
    details: Populator, Validator, Writer, Dispatcher or Handler. Every method name carries its context.
    link: /contexts
  - title: Record Filtering
    details: A predicate picks the records each handler acts on.
    link: /api/record
  - title: Declared Queries
    details: Declare parent fields and related records. No SOQL in your handler.
    link: /api/field-selection
  - title: Unit of Work
    details: Writers register DML. By default it commits once, after the last handler.
    link: /guide/unit-of-work
  - title: Bypasses and Recursion Control
    details: Switch handlers off in Apex or custom metadata. Update contexts cap recursion.
    link: /guide/bypasses
---

<BTCFooter context="trigger-lib" />
