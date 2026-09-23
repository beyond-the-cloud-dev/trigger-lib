---
template: add-on
context: BeforeInsert
interface: ParentQuery
description: Read parent (lookup) fields in a before insert Populator or Validator without writing SOQL.
---

# BeforeInsert.ParentQuery

Read fields of the record a lookup points to (parent fields, such as the account's industry or the owner's status) in a **before insert** Populator or Validator, without SOQL in your handler. The row being inserted carries only the lookup Id, so this is how you reach the parent.

<!--@include: @/_parts/generated/before-insert/parent-query/available-in.md-->

## When to Use {#when-to-use}

- Default fields from the parent, such as a contact's mailing address from its account.
- Reject a record based on its parent, such as a child account under a prospect.
- Read a grandparent field, such as the account owner's `IsActive`.

Use a [RelatedQuery](/before-insert/add-ons/related-query) instead for children, siblings or records not reached through a lookup of the record itself.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/parent-query/signature.md-->

<!--@include: @/_parts/generated/before-insert/parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/account/before-insert/populator/AccountParentDefaultsPopulator.cls [In a Populator]

<<< @/../examples/main/default/classes/account/before-insert/validator/AccountParentTypeValidator.cls [In the predicate]

<<< @/../examples/main/default/classes/contact/before-insert/populator/ContactMailingAddressPopulator.cls [Chained with]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/parent-query.md#before-->

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

In before insert only ParentQuery exists: an insert has no old row, so there is no previous parent to load.

## Records Here {#records}

`queryParentsOnBeforeInsert()` receives no records: it only declares what to load, once per run. The loaded parents then reach every record:

- per record, in the predicate, the action and the Validator's error method: `record.getNewParent('Account')`;
- in bulk, in a RelatedQuery provider or the Finalizer: `records.getIdsOf('Account', Account.OwnerId)` and `records.getValuesOf('Account', Account.Industry)`.

`InsertRecord` has no `getOldParent`.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/parent-query/works-with.md-->

## Gotchas {#gotchas}

- **The row's own relationship field stays empty.** `((Contact) record.getNewSObject()).Account` is null in before insert, even when the parent is loaded. Always read `getNewParent('Account')`.
- **Check for null.** A record with an empty lookup has no parent, and a handler that runs on it must not dereference one. The `[In a Populator]` example returns early; the `[In the predicate]` example reads `parent?.Type`.

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

For the `[In a Populator]` example:

```apex
@IsTest
static void populateOnBeforeInsertCopiesParentIndustry() {
    // Setup
    Account child = new Account(Name = 'Child', ParentId = new TriggerHandler.RandomIdGenerator().get(Account.SObjectType));
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(child, null);
    record.enrichNew('Parent', new Account(Industry = 'Energy'));

    // Test
    new AccountParentDefaultsPopulator().populateOnBeforeInsert(record);

    // Verify
    Assert.areEqual('Energy', child.Industry, 'The industry should come from the parent.');
}
```

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/parent-query/other-contexts.md-->

## See Also {#see-also}

- [TriggerHandler.ParentFields](/api/field-selection): every `with` overload.
- [BeforeInsert.RelatedQuery](/before-insert/add-ons/related-query) for records that are not parents.
- [BeforeUpdate.PriorParentQuery](/before-update/add-ons/prior-parent-query) for the parent a lookup pointed to before an update.
- [Execution Order & Cost](/guide/execution-order): what each run queries.
