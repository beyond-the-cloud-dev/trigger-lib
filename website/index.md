---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
description: Apex trigger framework for Salesforce with one role per trigger context, record filtering, declared queries, a unit of work, bypasses and recursion control.

hero:
  name: 'Trigger Lib'
  text: 'Apex Trigger Framework'
  tagline: One small class per concern, run only for the records that qualify.
  actions:
    - theme: brand
      text: Get Started
      link: /introduction
    - theme: alt
      text: Contexts at a Glance
      link: /contexts
    - theme: alt
      text: Unit of Work
      link: /guide/unit-of-work
    - theme: alt
      text: Testing
      link: /guide/testing

features:
  - title: One Orchestrator per Object
    details: List each context's handlers in plain Apex, in run order.
    link: /guide/orchestrator
  - title: One Role per Context
    details: Populator, Validator, Writer or Dispatcher, each acting only on the records its predicate picks.
    link: /contexts
  - title: Declared Queries
    details: Declare parent fields and related records, with no SOQL in your handler.
    link: /api/parent-fields
  - title: Unit of Work
    details: Writers register DML, committed once after the last handler by default.
    link: /guide/unit-of-work
  - title: Bypasses and Recursion Control
    details: Switch handlers off in Apex or custom metadata, and cap recursion on update.
    link: /guide/bypasses
  - title: Unit Tests Without DML
    details: Run handlers in a mocked trigger context, with no trigger and no DML.
    link: /guide/testing
---

