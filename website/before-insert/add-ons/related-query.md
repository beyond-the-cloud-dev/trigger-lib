---
template: add-on
context: BeforeInsert
interface: RelatedQuery
description: Query children, siblings, duplicates or configuration once per before insert run and read them per record, without SOQL in the loop.
---

# BeforeInsert.RelatedQuery

Query other records once per **before insert** run, such as existing duplicates, siblings under the same parent or configuration rows, and read them per record with `record.getRelated(name)`, without SOQL in the per-record loop.

<!--@include: @/_parts/generated/before-insert/related-query/available-in.md-->

## When to Use {#when-to-use}

- Reject a record that duplicates one already in the database, such as a contact with the same email.
- Default a field from a count or a list of other records, such as the contacts already on the account.
- Look up configuration, such as custom metadata rows keyed by country.

Use a [ParentQuery](/before-insert/add-ons/parent-query) instead for fields of the record a lookup points to, and a Populator's [Finalizer](/before-insert/add-ons/finalizer) to compare the records of one save with each other: SOQL never sees them.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/related-query/signature.md-->

<!--@include: @/_parts/generated/before-insert/related-query/method-table.md-->

### RecordsProvider {#records-provider}

<!--@include: @/_parts/generated/before-insert/related-query/records-provider.md-->

## Example {#example}

::: code-group

<!--@include: @/_parts/generated/before-insert/related-query/skeleton.md-->

```apex [Duplicate email]
public with sharing class ContactDuplicateEmailValidator implements BeforeInsert.Validator, BeforeInsert.RelatedQuery {
    public Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert() {
        return new Map<String, BeforeInsert.RecordsProvider>{ 'existingContacts' => new ExistingContactsProvider() };
    }

    public Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        Contact newContact = (Contact) record.getNewSObject();

        return record.isNotBlank(Contact.Email) && record.getRelated('existingContacts').getFirstWhereKeyEquals(newContact.Email.toLowerCase()) != null;
    }

    public void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record) {
        record.addError(Contact.Email, 'A contact with this email already exists.');
    }

    private without sharing class ExistingContactsProvider implements BeforeInsert.RecordsProvider {
        public List<SObject> query(TriggerHandler.InsertRecords records) {
            return [SELECT Id, Email FROM Contact WHERE Email IN :records.getValuesOf(Contact.Email)];
        }

        public String keyOf(SObject record) {
            return ((Contact) record).Email?.toLowerCase();
        }
    }
}
```

:::

The `[Duplicate email]` provider is `without sharing`, so the check also finds contacts the running user cannot see. SOQL matches emails without regard to case, but keys are compared exactly, so both `keyOf` and the predicate lowercase them.

## How It Runs {#how-it-runs}

<!--@include: @/_parts/add-ons/related-query.md#core-->

<!--@include: @/_parts/add-ons/related-query.md#ids-before-insert-->

### Key Patterns {#key-patterns}

::: details Provider recipes: children, siblings, text and composite keys, configuration, dependent queries

<!--@include: @/_parts/add-ons/related-query-patterns.md-->

:::

## Records Here {#records}

- **`query(records)`** receives a `TriggerHandler.InsertRecords` with every record in the chunk, qualified or not. `records.getIds()` is empty here; filter with `records.getValuesOf(…)` or `records.getIdsOf(…)`.
- **The handler** reads the results through `record.getRelated('<provider name>')` in its predicate, its action, the Validator's error method and its Finalizer: `getFirstWhereKeyEquals(key)`, `getAllWhereKeyEquals(key)`, `getRecords()` and `isEmpty()`.

## Works With {#works-with}

<!--@include: @/_parts/generated/before-insert/related-query/works-with.md-->

## Gotchas {#gotchas}

- **Providers see what earlier handlers put.** Providers run at their handler's turn, so `records.getValuesOf(Contact.Email)` returns the values as the Populators listed earlier left them. List a normalizing Populator before the Validator whose provider queries by that field.

<!--@include: @/_parts/add-ons/related-query.md#gotchas-->

## Test It {#test}

<!--@include: @/_parts/add-ons/test-techniques.md#related-->

For the `[Duplicate email]` example, group the existing contact under its lowercased email with `groupUnderKey('jane@example.com', existing)`, pass the map under `'existingContacts'`, and assert that `errorShouldBeAttachedOnBeforeInsertWhen` returns true for a new contact with `Email = 'Jane@Example.com'`.

## In Other Contexts {#other-contexts}

<!--@include: @/_parts/generated/before-insert/related-query/other-contexts.md-->

## See Also {#see-also}

- [RelatedQuery Recipes](/guide/related-records): the full recipes.
- [RelatedRecords & RecordsProvider](/api/related-records): the reference.
- [BeforeInsert.ParentQuery](/before-insert/add-ons/parent-query) for fields of the record a lookup points to.
- [Execution Order & Cost](/guide/execution-order): what each run queries.
