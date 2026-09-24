---
description: The rules behind Trigger Lib's API - one handler per concern, one role per context, declared queries instead of SOQL, a unit of work for DML, explicit qualification and guard rails that cannot be switched off.
---

# Design Principles

## One Handler per Concern {#one-handler-per-concern}

Each object has one trigger and one orchestrator. Each handler does one thing, so it is easy to name, test and switch off.

## One Role per Context {#one-role-per-context}

A role says what a class does. Keep one role per class in each context: a class with two roles runs only as the first, and nothing warns you.

## List Order Is the Dependency {#registration-order}

Handlers run in list order. Each predicate runs at its handler's turn, so it sees what earlier handlers wrote.

## No Loops, No SOQL per Record {#no-loops}

The library loops over the records. Handlers declare the parents and related records they need, and the library loads them before the handler runs.

## Before Contexts Populate, After Contexts Act {#before-populates-after-acts}

In before insert and before update, DML or an event publish fails the save. Change other records from a Writer in an after context.

## Qualification Is Explicit {#qualification-is-explicit}

Every role declares which records it wants. An action never runs for a record its predicate rejected.

## Library Errors Always Surface {#library-errors}

ContinueOnError swallows a handler's own exception. It never swallows a `TriggerOrchestratorException` or a `TriggerHandler.TriggerHandlerException`: a broken contract is a bug.

## Safe by Default {#safe-by-default}

In the update contexts, a Populator, Writer or Dispatcher acts on the same record at most three times per transaction by default.

## No Required Metadata {#no-required-metadata}

The library works with zero custom metadata records. Metadata only switches an object or a handler off.
