---
template: add-on
context: AfterUpdate
interface: ParentQuery
description: 'Read parent (lookup) fields, such as the account or the owner of the record, in an after update Writer or Dispatcher without SOQL in the handler.'
---

# AfterUpdate.ParentQuery

Read fields of the record a lookup points to now (the account of an opportunity, the owner of an account, a grandparent) in an **after update** Writer or Dispatcher, without writing SOQL in your handler.

<!--@include: @/_parts/generated/after-update/parent-query/available-in.md-->

## When to Use {#when-to-use}

- A predicate or an action needs a field of the current parent, such as `Account.Type` or `Owner.IsActive`.
- Several handlers read the same parent: their declarations are pooled into one query.
- Use [PriorParentQuery](/after-update/add-ons/prior-parent-query) for the parent the record pointed to before the update, and [RelatedQuery](/after-update/add-ons/related-query) for children, siblings or unrelated records.

## Interface {#interface}

<!--@include: @/_parts/generated/after-update/parent-query/signature.md-->

<!--@include: @/_parts/generated/after-update/parent-query/method-table.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/after-update/parent-query/skeleton.md-->

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityWinTaskWriter.cls [In the action]

<<< @/../examples/main/default/classes/opportunity/after-update/writer/OpportunityAccountTypeWriter.cls [In the predicate]

:::

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/parent-query.md#core-->

<!--@include: @/_parts/add-ons/parent-query.md#after-->

In after update, a lookup that a handler declares with PriorParentQuery as well gets one merged field list, and a previous parent that the trigger-object query already returned is reused instead of queried again. Polymorphic lookups have their own limits; see [Gotchas](#gotchas).

### Choosing Fields {#choosing-fields}

<!--@include: @/_parts/add-ons/field-selection.md-->

### ParentQuery vs PriorParentQuery {#parent-vs-prior}

<!--@include: @/_parts/add-ons/parent-vs-prior.md-->

## Records Here {#records}

- `queryParentsOnAfterUpdate()` takes no records. It returns the declaration once per run.
- Read the parent per record with `record.getNewParent('Account')`, and a grandparent through it, for example `((Account) record.getNewParent('Account')).Owner.IsActive`.
- In a provider, a dispatch or a Finalizer, `records.getIdsOf('Account', Account.OwnerId)` and `records.getValuesOf('Account', Account.Type)` collect values of the loaded parents.

## Works With {#works-with}

<!--@include: @/_parts/generated/after-update/parent-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/parent-query.md#gotchas-->

- **The row itself has no parent.** `((Opportunity) record.getNewSObject()).Account` stays null; only `getNewParent('Account')` has the data.
- **Loaded before the first handler.** A parent that an earlier Writer registered for update on the shared unit still shows its old values, because the unit commits after the last handler.
- **Nested runs query again.** A self-update's nested BeforeUpdate and AfterUpdate runs load their own parents; nothing is shared with this run.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#parent-->

For `OpportunityAccountTypeWriter`, which reads `Account.Type` in its predicate:

```apex
@IsTest
static void writeOnAfterUpdateWhenAccountIsProspect() {
    // Setup
    TriggerHandler.TriggerRecord record = new TriggerHandler.TriggerRecord(
        new Opportunity(StageName = 'Closed Won'),
        new Opportunity(StageName = 'Negotiation/Review')
    );
    record.enrichNew('Account', new Account(Type = 'Prospect'));

    // Test
    Boolean result = new OpportunityAccountTypeWriter().writeOnAfterUpdateWhen(record);

    // Verify
    Assert.isTrue(result, 'The record should qualify.');
}
```

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/after-update/parent-query/other-contexts.md-->

## See Also {#see-also}

- [Field Selection](/api/field-selection): every `TriggerHandler.ParentFields` overload.
- [AfterUpdate.PriorParentQuery](/after-update/add-ons/prior-parent-query)
- [Parents and Related in AfterUpdate](/after-update/record-api#parents)
- [Testing](/guide/testing)
