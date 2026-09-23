---
template: add-on
context: BeforeUpdate
interface: RelatedQuery
description: BeforeUpdate.RelatedQuery loads children, siblings, configuration or other records once per handler for the whole before update chunk, keyed for fast reads.
---

# BeforeUpdate.RelatedQuery

Load children, siblings, configuration or other records of the same object (related records, text-key lookup, duplicate check) once per handler for the whole **before update** chunk, keyed for fast reads, instead of a query per record.

<!--@include: @/_parts/generated/before-update/related-query/available-in.md-->

## When to Use {#when-to-use}

- Check a changed value against other records: an email or a name that must stay unique.
- Read the children or siblings of the records being updated.
- Look up configuration rows, such as custom metadata, by a value on the record.

For fields of a lookup's parent you need no provider: use [ParentQuery](/before-update/add-ons/parent-query) or [PriorParentQuery](/before-update/add-ons/prior-parent-query).

## Interface {#interface}

<!--@include: @/_parts/generated/before-update/related-query/signature.md-->

<!--@include: @/_parts/generated/before-update/related-query/method-table.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/before-update/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-update/related-query/skeleton.md-->

```apex [Duplicate email]
public with sharing class ContactEmailTakenValidator implements BeforeUpdate.Validator, BeforeUpdate.RelatedQuery {
    public Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate() {
        return new Map<String, BeforeUpdate.RecordsProvider>{ 'sameEmail' => new SameEmailProvider() };
    }

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        String email = ((Contact) record.getNewSObject()).Email?.toLowerCase();

        return record.isChanged(Contact.Email) && email != null && record.getRelated('sameEmail').getFirstWhereKeyEquals(email) != null;
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        record.addError(Contact.Email, 'Another contact already uses this email.');
    }

    private without sharing class SameEmailProvider implements BeforeUpdate.RecordsProvider {
        public List<SObject> query(TriggerHandler.UpdateRecords records) {
            return [SELECT Id, Email FROM Contact WHERE Email IN :records.getValuesOf(Contact.Email) AND Id NOT IN :records.getIds()];
        }

        public String keyOf(SObject record) {
            return ((Contact) record).Email?.toLowerCase();
        }
    }
}
```

:::

The Duplicate email tab is a sketch; it is not one of the example classes. Its provider is `without sharing`, so the check also sees contacts that the user cannot see, and `Id NOT IN :records.getIds()` keeps a contact from finding itself.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-before-update-->

In before update, providers run on every pass: a nested update of the same records runs them again, whether or not the handler's recursion budget is used up.

### Key Patterns {#key-patterns}

::: details Key patterns: children, siblings, text key, composite key, configuration, dependent query, the trigger records themselves

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

`query(records)` receives `TriggerHandler.UpdateRecords` with every record in the chunk, qualified or not, including records a Populator will skip for recursion. The handler reads the results with `record.getRelated('<provider name>')` and its `getFirstWhereKeyEquals`, `getAllWhereKeyEquals`, `getRecords` and `isEmpty`.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-update/related-query/works-with.md-->

## Gotchas {#gotchas}

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

- **Pending values are not in the database.** Two records in the same chunk that change to the same email do not find each other through the provider. Compare them in memory, in a [Finalizer](/before-update/add-ons/finalizer) on a Populator.

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

For the Duplicate email sketch, register the provided records as `'sameEmail'` and group the row under the lowercased email.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-update/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records)
- [RelatedRecords & RecordsProvider](/api/related-records)
- [Record Collections](/api/record-collections)
