---
outline: deep
---

# Introduction

Apex trigger framework for Salesforce with record filtering, automatic parent enrichment, bypasses, and recursion control.

Trigger Lib is part of [Apex Fluently](https://apexfluently.beyondthecloud.dev/), a suite of production-ready Salesforce libraries by [Beyond the Cloud](https://beyondthecloud.dev).

## Features

- **Orchestrator & Handlers** - One orchestrator per SObject, one handler per concern, wired in Apex
- **Record Filtering** - Handlers run only against records that qualify, so logic never guards itself
- **Parent Enrichment** - Related data is pulled up front, so handlers make no SOQL queries of their own
- **Bypasses** - Disable an individual handler or a whole orchestrator when you need to
- **Recursion Control** - Depth limiting built in, defaulting to 3
- **No Required Metadata** - Works with zero custom metadata records; metadata only overrides defaults

## Deploy to Salesforce

<a href="https://githubsfdeploy.herokuapp.com?owner=beyond-the-cloud-dev&repo=trigger-lib&ref=main">
  <img alt="Deploy to Salesforce" src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
