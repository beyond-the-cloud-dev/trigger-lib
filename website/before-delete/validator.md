---
template: role
context: BeforeDelete
interface: Validator
description: Block a delete with a record-level or field-level error before the records are removed, like a validation rule written in Apex.
---

# BeforeDelete.Validator

Reject a delete before the records are removed, like a validation rule written in Apex.

**Signature**

<!--@include: @/_parts/generated/before-delete/validator/signature.md-->

**Example**

::: code-group

<!--@include: @/_parts/generated/before-delete/validator/skeleton.md-->

```apex [Block the delete]
public with sharing class AccountDeletionGuardValidator implements BeforeDelete.Validator, BeforeDelete.RelatedQuery {
    public Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete() {
        return new Map<String, BeforeDelete.RecordsProvider>{ 'openOpportunities' => new OpenOpportunitiesProvider() };
    }

    public Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record) {
        return record.getRelated('openOpportunities').getFirstWhereKeyEquals(record.getId()) != null;
    }

    public void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record) {
        record.addError('Close or move the open opportunities before you delete this account.');
    }

    private without sharing class OpenOpportunitiesProvider implements BeforeDelete.RecordsProvider {
        public List<SObject> query(TriggerTypes.DeleteRecords records) {
            return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :records.getIds() AND IsClosed = FALSE];
        }

        public String keyOf(SObject row) {
            return ((Opportunity) row).AccountId;
        }
    }
}
```

:::

## Rules {#rules}

- **Block with `record.addError`.** `addError(message)` or `addError(field, message)` attaches the error to the row being deleted, and its delete fails.
- **Every qualified record must get an error.** If `addErrorOnBeforeDelete` attaches none, the library throws a [`TriggerTypes.TriggerLibException`](/api/trigger-orchestrator#triggerlibexception), even with ContinueOnError.
- **Errors add up.** A record with an error still reaches every later handler in the list.
- **Validator wins.** A class that also implements `BeforeDelete.Writer` runs only as a Validator.

::: warning
A guard must see every row. A `with sharing` provider misses rows the user cannot see, and a missed row lets the delete through. Never add [ContinueOnError](/before-delete/add-ons/continue-on-error) to a guard: a swallowed exception lets the delete through too.
:::

## Test {#test}

```apex
@IsTest
static void addErrorOnBeforeDeleteWithoutOpenOpportunities() {
    // Setup
    Account acme = new Account(Name = 'Acme');

    TriggerOrchestrator.mock().beforeDeleteFor(AccountDeletionGuardValidator.class).with(acme);

    // Test
    TriggerOrchestrator.runTestFor(new AccountDeletionGuardValidator());

    // Verify
    Assert.isFalse(acme.hasErrors(), 'An account without open opportunities can be deleted.');
}
```
