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
      text: View on GitHub
      link: https://github.com/beyond-the-cloud-dev/trigger-lib

features:
  - title: Orchestrator & Handlers
    details: One orchestrator per SObject, one handler per concern, wired in Apex.
  - title: Record Filtering
    details: Handlers run only against records that qualify, so logic never guards itself.
  - title: Parent Enrichment
    details: Related data is pulled up front, so handlers make no SOQL queries of their own.
  - title: Bypasses
    details: Disable an individual handler or a whole orchestrator when you need to.
  - title: Recursion Control
    details: Depth limiting built in, defaulting to 3.
  - title: No Required Metadata
    details: Works with zero custom metadata records; metadata only overrides defaults.
---

<BTCFooter context="trigger-lib" />
