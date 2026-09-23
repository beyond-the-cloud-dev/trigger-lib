---
template: add-on
context: BeforeInsert
interface: RelatedQuery
description: Query children, siblings, duplicates or configuration once per before insert chunk and read them per record, without SOQL in the loop.
---

# BeforeInsert.RelatedQuery

Queries other records once per chunk, such as existing duplicates, contacts on the same account or configuration rows. Read them per record with `record.getRelated(name)`.

## Interface {#interface}

<!--@include: @/_parts/generated/before-insert/related-query/signature.md-->

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

## Good to Know {#good-to-know}

- **No Ids yet.** `records.getIds()` is empty. Filter by field values with `records.getValuesOf(…)` or by lookups with `records.getIdsOf(…)`.
- **SOQL cannot see this save.** The new records are not in the database yet. Compare them with each other in a Populator's [Finalizer](/before-insert/add-ons/finalizer).
- **Keys match exactly, case included.** Normalize text keys the same way in `keyOf` and in the lookup, as `[Duplicate email]` does with `toLowerCase()`.
- **Providers query even when nothing qualifies.** They run before the first predicate. Return an empty list from `query` when no record can qualify, to skip the SOQL.
- **Each provider has its own sharing.** Declare a keyword on every provider class; an inner class does not inherit it. A `with sharing` duplicate check misses records the user cannot see.
