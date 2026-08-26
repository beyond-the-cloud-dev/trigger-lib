// Chain and stack regression for TriggerOrchestrator. Requires the `regression`
// package directory deployed to a dev org (never production) — it contains the
// probe triggers on 10 standard objects plus the Probe_Campaign_Resave flow.
//
//   sf project deploy start --source-dir regression
//   sf apex run --file scripts/apex/chain-regression.apex
//
// Prints "REGRESSION PASS" or fails with every broken expectation listed.
// Needs at least 2 existing Contacts in the org (the example ContactTrigger
// blocks Contact inserts in orgs without record types on Contact).

class Verify {
    List<String> failures = new List<String>();
    String current;

    void scenario(String name) {
        this.current = name;
        TriggerStackProbe.maxDepth = 200;
        TriggerStackProbe.chainEnabled = false;
        TriggerStackProbe.failMarkedRecords = false;
        TriggerStackProbe.throwInCampaignHandler = false;
        TriggerStackProbe.dmlFromBeforeUpdate = false;
        TriggerStackProbe.twoInsertsFromAccount = false;
        TriggerStackProbe.remainingLaps = 0;
        TriggerStackProbe.bulkMode = false;
        TriggerStackProbe.start();
    }

    Integer count(String prefix) {
        Integer matches = 0;

        for (String line : TriggerStackProbe.trace) {
            if (line.startsWith(prefix)) {
                matches++;
            }
        }

        return matches;
    }

    Integer sequenceCount() {
        Set<String> sequences = new Set<String>();

        for (String line : TriggerStackProbe.trace) {
            if (!line.startsWith('INVOKE') && !line.startsWith('FLUSH')) {
                continue;
            }

            Integer at = line.indexOf(' seq');

            if (at == -1) {
                continue;
            }

            String digits = '';

            for (Integer i = at + 4; i < line.length() && line.substring(i, i + 1).isNumeric(); i++) {
                digits += line.substring(i, i + 1);
            }

            if (digits != '') {
                sequences.add(digits);
            }
        }

        return sequences.size();
    }

    String tree(Integer index) {
        Integer seen = 0;

        for (String line : TriggerStackProbe.trace) {
            if (!line.startsWith('TREE')) {
                continue;
            }

            if (seen == index) {
                return line;
            }

            seen++;
        }

        return '(no TREE line ' + index + ')';
    }

    void expect(String what, Object actual, Object expected) {
        if (String.valueOf(actual) != String.valueOf(expected)) {
            this.failures.add(this.current + ': ' + what + ' — expected ' + expected + ', got ' + actual);
        }
    }

    void expectContains(String what, String actual, String fragment) {
        if (!actual.contains(fragment)) {
            this.failures.add(this.current + ': ' + what + ' — missing "' + fragment + '" in "' + actual + '"');
        }
    }

    void shape(Integer invocations, Integer flushes, Integer sequences) {
        this.expect('INVOKE count', this.count('INVOKE'), invocations);
        this.expect('FLUSH count', this.count('FLUSH'), flushes);
        this.expect('distinct chains', this.sequenceCount(), sequences);
    }
}

class Records {
    Account account() {
        Account created = new Account(Name = 'Regression Account');
        insert created;
        return created;
    }

    Opportunity opportunity(Id accountId) {
        Opportunity created = new Opportunity(Name = 'Regression Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = accountId);
        insert created;
        return created;
    }

    Case supportCase() {
        Case created = new Case(Subject = 'Regression Case');
        insert created;
        return created;
    }

    Campaign campaign() {
        Campaign created = new Campaign(Name = 'Regression Campaign');
        insert created;
        return created;
    }
}

Verify verify = new Verify();
Records records = new Records();

List<Contact> contacts = [SELECT Id FROM Contact LIMIT 2];
Assert.isTrue(contacts.size() == 2, 'This org needs at least 2 Contacts for the cycle scenarios.');

// --- simple: one record, one chunk, one chain ---
Account simple = records.account();
verify.scenario('simple update');
update new Account(Id = simple.Id, Description = 'simple');
verify.shape(1, 1, 1);
verify.expectContains('tree', verify.tree(0), 'Account.aupdate[1]');

// --- cycle at default recursion depth: Account -> Contact -> Opportunity -> Account ---
Account cycleAccount = records.account();
Opportunity cycleOpp = records.opportunity(cycleAccount.Id);
TriggerStackProbe.accountId = cycleAccount.Id;
TriggerStackProbe.contactId = contacts[0].Id;
TriggerStackProbe.opportunityId = cycleOpp.Id;
verify.scenario('cycle, one lap, default depth 3');
TriggerStackProbe.chainEnabled = true;
TriggerStackProbe.remainingLaps = 1;
TriggerStackProbe.maxDepth = 3;
update new Account(Id = cycleAccount.Id, Description = 'cycle');
verify.shape(6, 1, 1);

// --- runaway cycle: the recursion guard must stop it, every level logs ---
Account runawayAccount = records.account();
Opportunity runawayOpp = records.opportunity(runawayAccount.Id);
TriggerStackProbe.accountId = runawayAccount.Id;
TriggerStackProbe.contactId = contacts[1].Id;
TriggerStackProbe.opportunityId = runawayOpp.Id;
verify.scenario('runaway cycle hits guard');
TriggerStackProbe.chainEnabled = true;
TriggerStackProbe.remainingLaps = 20;
TriggerStackProbe.maxDepth = 3;
Boolean guardFired = false;
try {
    update new Account(Id = runawayAccount.Id, Description = 'runaway');
} catch (DmlException e) {
    guardFired = e.getMessage().contains('Maximum recursion depth');
}
verify.expect('guard fired', guardFired, true);
verify.shape(9, 1, 1);
verify.expect('LOG count (one per level)', verify.count('LOG'), 10);

// --- deep chain: Lead -> Task -> Case -> Campaign -> Product2 -> Asset -> Event ---
Lead chainLead = new Lead(LastName = 'Regression Lead', Company = 'Regression Co');
Case chainCase = records.supportCase();
Campaign chainCampaign = records.campaign();
Product2 chainProduct = new Product2(Name = 'Regression Product');
insert new List<SObject>{ chainLead, chainProduct };
Asset chainAsset = new Asset(Name = 'Regression Asset', AccountId = simple.Id);
insert chainAsset;
TriggerStackProbe.caseId = chainCase.Id;
TriggerStackProbe.campaignId = chainCampaign.Id;
TriggerStackProbe.productId = chainProduct.Id;
TriggerStackProbe.assetId = chainAsset.Id;
verify.scenario('seven-object chain');
TriggerStackProbe.chainEnabled = true;
update new Lead(Id = chainLead.Id, Description = 'chain');
verify.shape(8, 1, 1);

// --- two statements on the same record: two chains ---
verify.scenario('two consecutive updates');
update new Account(Id = simple.Id, Description = 'first');
update new Account(Id = simple.Id, Description = 'second');
verify.shape(2, 2, 2);

// --- partial save: the vetoed attempt flushes, the retry re-arms the same chain and flushes again ---
List<Account> partial = new List<Account>{ records.account(), records.account(), records.account() };
partial[0].Description = 'ok';
partial[1].Description = 'FAIL me';
partial[2].Description = 'ok';
verify.scenario('partial save');
TriggerStackProbe.failMarkedRecords = true;
List<Database.SaveResult> results = Database.update(partial, false);
Integer failed = 0;
for (Database.SaveResult result : results) {
    if (!result.isSuccess()) {
        failed++;
    }
}
verify.expect('vetoed records', failed, 1);
verify.shape(2, 2, 1);
verify.expect('before chunks seen', verify.count('BEFORE'), 2);
verify.expectContains('attempt 1 tree shows the survivors only', verify.tree(0), 'Account.aupdate[2]');

// --- three orchestrators across two triggers: one chunk, one chain ---
Campaign coCampaign = records.campaign();
verify.scenario('co-trigger and multi-orchestrator');
update new Campaign(Id = coCampaign.Id, Description = 'co-trigger');
verify.shape(3, 1, 1);

// --- after-save flow re-updates the same record: a second chain ---
Campaign flowCampaign = records.campaign();
verify.scenario('flow re-save');
update new Campaign(Id = flowCampaign.Id, Description = 'flow kick');
verify.shape(6, 2, 2);

// --- DML from a before context is unsupported: the nested trigger becomes its own chain ---
Account beforeDmlAccount = records.account();
Case beforeDmlCase = records.supportCase();
TriggerStackProbe.caseId = beforeDmlCase.Id;
verify.scenario('before-context DML');
TriggerStackProbe.dmlFromBeforeUpdate = true;
update new Account(Id = beforeDmlAccount.Id, Description = 'before dml');
verify.shape(2, 2, 2);
verify.expectContains('Case is its own root', verify.tree(0), 'Case.aupdate[1]');

// --- before-only object: two before-insert triggers run, no invocation and no chain exist ---
verify.scenario('before-insert co-trigger with mutation');
Event probeEvent = new Event(Subject = 'Regression Event', StartDateTime = System.now(), DurationInMinutes = 15);
insert probeEvent;
verify.shape(0, 0, 0);
verify.expect('before chunks seen', verify.count('BEFORE'), 2);

// --- a before-only trigger opened no chain, so nothing is left to flush late ---
verify.scenario('no late flush after a before-only statement');
update new Account(Id = simple.Id, Description = 'follows the before-only statement');
verify.expect('own flush only', verify.count('FLUSH'), 1);
verify.expect('INVOKE count', verify.count('INVOKE'), 1);

// --- handler throws two levels deep: statement fails, both levels log, one flush ---
Case failingCase = records.supportCase();
Campaign failingCampaign = records.campaign();
TriggerStackProbe.caseId = failingCase.Id;
TriggerStackProbe.campaignId = failingCampaign.Id;
verify.scenario('nested exception');
TriggerStackProbe.chainEnabled = true;
TriggerStackProbe.throwInCampaignHandler = true;
Boolean threw = false;
try {
    update new Case(Id = failingCase.Id, Description = 'will explode');
} catch (DmlException e) {
    threw = true;
}
verify.expect('exception propagated', threw, true);
verify.shape(2, 1, 1);
verify.expect('LOG count', verify.count('LOG'), 2);

// --- two statements from one handler: siblings under the same parent ---
Account siblingsAccount = records.account();
verify.scenario('two inserts from one handler are siblings');
TriggerStackProbe.twoInsertsFromAccount = true;
update new Account(Id = siblingsAccount.Id, Description = 'two inserts');
verify.shape(2, 1, 1);
verify.expect('before chunks seen', verify.count('BEFORE'), 3);
verify.expectContains('after-context child under Account', verify.tree(0), 'Account.aupdate[1](Task.ainsert[1])');

// --- cleanup (no probe trigger listens to deletes) ---
TriggerStackProbe.enabled = false;
delete [SELECT Id FROM Account WHERE Name = 'Regression Account'];
delete [SELECT Id FROM Case WHERE Subject = 'Regression Case'];
delete [SELECT Id FROM Campaign WHERE Name = 'Regression Campaign'];
delete [SELECT Id FROM Lead WHERE Company = 'Regression Co'];
delete [SELECT Id FROM Product2 WHERE Name = 'Regression Product'];
delete [SELECT Id FROM Event WHERE Subject IN ('Regression Event', 'Probe event')];
delete [SELECT Id FROM Task WHERE Subject = 'Probe task'];

if (!verify.failures.isEmpty()) {
    Assert.fail(verify.failures.size() + ' regression failure(s):\n' + String.join(verify.failures, '\n'));
}

System.debug(
    LoggingLevel.ERROR,
    'REGRESSION PASS — 13 scenarios, CPU ' + Limits.getCpuTime() + 'ms, ' + Limits.getDmlStatements() + ' DML statements, ' + Limits.getDmlRows() + ' rows'
);
