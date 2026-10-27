---
description: How Trigger Lib handlers get data without a query per record - parent fields with ParentQuery, configuration in static variables, and children, siblings or other records with RelatedQuery, and what each one costs.
---

# Queries

The library calls a handler's predicate and action once per record, so your own SOQL there throws a [`TriggerTypes.TriggerLibException`](/api/trigger-orchestrator#triggerlibexception). Pick the way that fits the data instead:

| You need | Use | It costs |
|---|---|---|
| Fields of the record a lookup points to | [ParentQuery](#parents) | at most 1 query per lookup per chunk, shared by all handlers |
| Configuration that doesn't depend on the trigger records | [A static variable](#configuration) | 1 query per transaction, or none |
| Children, siblings, records matched by value, or configuration that depends on the trigger records | [RelatedQuery](#related) | what its `query` runs, once per handler per chunk |

## Parents {#parents}

Declare each lookup with the parent fields you read, then read the parent with `record.getNewParent(…)`:

```apex
public with sharing class ContactDescriptionPopulator implements BeforeInsert.Populator, BeforeInsert.ParentQuery {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Contact.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isNotNull(Contact.AccountId) && record.isBlank(Contact.Description);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        Account parentAccount = (Account) record.getNewParent(Contact.AccountId);

        record.put(Contact.Description, parentAccount?.Name);
    }
}
```

- **Declarations merge.** The library collects the lookups and fields of every handler in the run, and queries each lookup's parents once.
- **Loaded on the first read.** Nothing is queried until a handler calls `getNewParent` or `getOldParent`. A read in a predicate queries even when no record qualifies, so put cheaper conditions first: Apex stops evaluating `&&` at the first false operand.
- **Every record at once.** The first read loads the parents of every record in the chunk, qualified or not. Later handlers read them from memory.
- **One query in after insert, after update and after undelete.** The library queries the trigger records once and reads every ParentQuery parent through relationship fields, such as `SELECT Account.Name, Owner.Email FROM Contact WHERE Id IN :ids`.
- **The parent before the save.** In the update and delete contexts, declare a PriorParentQuery and read `record.getOldParent(…)`.

Fields and grandparents: [TriggerTypes.ParentFields](/api/parent-fields).

## Configuration {#configuration}

Load configuration that doesn't depend on the trigger records into a static variable of the handler:

```apex
public with sharing class ContactDepartmentPopulator implements BeforeInsert.Populator {
    private static User runningUser = [SELECT Department FROM User WHERE Id = :UserInfo.getUserId()];

    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isBlank(Contact.Department);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        record.put(Contact.Department, ContactDepartmentPopulator.runningUser.Department);
    }
}
```

- **Static, not in the constructor.** A static variable is set once per transaction. The library calls `<ctx>Handlers()` on every run, per context, per chunk of up to 200 records and per nested run, so a query in the constructor runs every time. Under `runFromMetadata()`, every registered class is created in every context.
- **Custom settings and custom metadata need no SOQL.** Read them with `getOrgDefaults()`, `getInstance()` or `getAll()`. SOQL on custom metadata doesn't count toward the 100-query limit either, unless it selects a long text area field.
- **Outside the guard.** The static variable is set when the handler is created, before the record loop.

Configuration that depends on the trigger records, such as the region of each billing country, belongs in a [RelatedQuery](#related).

## Related Records {#related}

For everything else, implement RelatedQuery and return named providers. A provider's `query` runs once for the chunk, and `keyOf` returns the key each row is stored under. Read the rows per record by name and key:

```apex
public with sharing class AccountFormerCustomerCaseWriter implements AfterUpdate.Writer, AfterUpdate.RelatedQuery {
    public Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate() {
        return new Map<String, AfterUpdate.RecordsProvider>{ 'openCases' => new OpenCases() };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Account.Type, 'Former Customer');
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        for (SObject row : record.getRelated('openCases').getAllWhereKeyEquals(record.getId())) {
            unitOfWork.toUpdate(new Case(Id = row.Id, Status = 'Closed'));
        }
    }

    private with sharing class OpenCases implements AfterUpdate.RecordsProvider {
        public List<SObject> query(TriggerTypes.UpdateRecords records) {
            return [SELECT Id, AccountId FROM Case WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
        }

        public String keyOf(SObject row) {
            return ((Case) row).AccountId;
        }
    }
}
```

- **Loaded on the first read.** A provider runs when its handler first calls `getRelated` with its name. A provider the handler never reads costs nothing.
- **Every record of the chunk.** `query` gets all trigger records, qualified or not.
- **Once per handler.** Two handlers that use the same provider class query twice. A shared class saves code, not queries.
- **Your query, your sharing.** Use inline SOQL, SOQL Lib or a selector, and declare a sharing keyword on every provider class.

Siblings, text keys, composite keys and more: [RelatedQuery Recipes](/guide/related-query).

## Where SOQL Is Allowed {#where-soql}

| Where | SOQL |
|---|---|
| A predicate or an action | throws |
| A provider's `query` | allowed, once per handler per chunk |
| A static variable | allowed, once per transaction |
| A Finalizer | allowed, once per handler per chunk |
| A Dispatcher's dispatch method | allowed, once per chunk |
| A constructor or `<ctx>Handlers()` | allowed, but runs again on every run |
