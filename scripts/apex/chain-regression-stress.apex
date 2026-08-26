// Stress chain regression: 201 records at every depth of a four-level cascade.
// Uses over half the synchronous CPU budget — run alone, never combined.
// Companion to chain-regression.apex — see its header for setup.
//
//   sf apex run --file scripts/apex/chain-regression-stress.apex

class Verify {
    List<String> failures = new List<String>();

    Integer count(String prefix) {
        Integer matches = 0;

        for (String line : TriggerStackProbe.trace) {
            if (line.startsWith(prefix)) {
                matches++;
            }
        }

        return matches;
    }

    Integer countContaining(String prefix, String fragment) {
        Integer matches = 0;

        for (String line : TriggerStackProbe.trace) {
            if (line.startsWith(prefix) && line.contains(fragment)) {
                matches++;
            }
        }

        return matches;
    }

    void expect(String what, Object actual, Object expected) {
        if (String.valueOf(actual) != String.valueOf(expected)) {
            this.failures.add(what + ' — expected ' + expected + ', got ' + actual);
        }
    }
}

Verify verify = new Verify();

List<Account> accounts = new List<Account>();
List<Case> cases = new List<Case>();
List<Campaign> campaigns = new List<Campaign>();
for (Integer i = 0; i < 201; i++) {
    accounts.add(new Account(Name = 'Regression Stress ' + i));
    cases.add(new Case(Subject = 'Regression Stress ' + i));
    campaigns.add(new Campaign(Name = 'Regression Stress ' + i));
}
insert accounts;
insert cases;
insert campaigns;

List<Opportunity> opportunities = new List<Opportunity>();
for (Integer i = 0; i < 201; i++) {
    opportunities.add(new Opportunity(Name = 'Regression Stress ' + i, StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = accounts[i].Id));
}
insert opportunities;

TriggerStackProbe.bulkOpportunityIds = new List<Id>(new Map<Id, Opportunity>(opportunities).keySet());
TriggerStackProbe.bulkCaseIds = new List<Id>(new Map<Id, Case>(cases).keySet());
TriggerStackProbe.bulkCampaignIds = new List<Id>(new Map<Id, Campaign>(campaigns).keySet());

for (Account account : accounts) {
    account.Description = 'stress cascade';
}

TriggerStackProbe.maxDepth = 200;
TriggerStackProbe.start();
TriggerStackProbe.bulkMode = true;

update accounts;

verify.expect('INVOKE count', verify.count('INVOKE'), 69);
verify.expect('every invocation in chain 1', verify.countContaining('INVOKE', 'seq1'), 69);
verify.expect('FLUSH count (uncertain size: one per root after chunk)', verify.count('FLUSH'), 2);

TriggerStackProbe.enabled = false;
TriggerStackProbe.bulkMode = false;
delete opportunities;
delete cases;
delete campaigns;
delete accounts;

if (!verify.failures.isEmpty()) {
    Assert.fail(verify.failures.size() + ' regression failure(s):\n' + String.join(verify.failures, '\n'));
}

System.debug(
    LoggingLevel.ERROR,
    'REGRESSION PASS — stress cascade, CPU ' + Limits.getCpuTime() + 'ms, ' + Limits.getDmlStatements() + ' DML statements, ' + Limits.getDmlRows() + ' rows'
);
