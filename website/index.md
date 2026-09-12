---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: 'Trigger Lib'
  text: 'Salesforce Apex Trigger Framework'
  tagline: Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control
  actions:
    - theme: brand
      text: Get Started
      link: /introduction
    - theme: alt
      text: Installation
      link: /installation

features:
  - title: Orchestrator & Handlers
    details: One orchestrator per SObject, one handler per concern, wired in Apex.
    link: /guide/orchestrator
  - title: Record Filtering
    details: Handlers run only against records that qualify, so logic never guards itself.
    link: /guide/qualification
  - title: Parent Enrichment
    details: Related data is pulled up front, so handlers make no SOQL queries of their own.
    link: /guide/enrichment
  - title: Bypasses
    details: Skip one handler from code, or a handler or a whole object from metadata.
    link: /guide/bypasses
  - title: Recursion Control
    details: Depth limiting built in, defaulting to three passes per record.
    link: /guide/recursion-control
  - title: No Required Metadata
    details: Works with zero custom metadata records; metadata only overrides defaults.
    link: /introduction/design-principles
---

<BTCFooter context="trigger-lib" />
