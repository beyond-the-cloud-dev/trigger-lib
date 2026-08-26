// Bulk chain regression: 200-record chunking and untracked-DML size detection.
// Companion to chain-regression.apex — see its header for setup.
//
//   sf apex run --file scripts/apex/chain-regression-bulk.apex

class Verify {
    List<String> failures = new List<String>();
    String current;

    void scenario(String name) {
        this.current = name;
        TriggerStackProbe.maxDepth = 200;
        TriggerStackProbe.chainEnabled = false;
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
            this.failures.add(this.current + ': ' + what + ' — expected ' + expected + ', got ' + actual);
        }
    }
}

Verify verify = new Verify();

List<Account> accounts = new List<Account>();
for (Integer i = 0; i < 201; i++) {
    accounts.add(new Account(Name = 'Regression Bulk ' + i));
}
insert accounts;

// --- 201 records: chunks BEFORE(200)/AFTER(200)/BEFORE(1)/AFTER(1), one chain ---
for (Account account : accounts) {
    account.Description = 'chunked';
}
verify.scenario('201-record chunking');
update accounts;
verify.expect('INVOKE count', verify.count('INVOKE'), 2);
verify.expect('FLUSH count', verify.count('FLUSH'), 2);

// --- the same 201 records, CERTAIN size: the previous root finish re-baselined the
// --- statement counter, so this update is exactly +1 statement and the countdown alone
// --- must end the chain — one flush, one ending=true, no short-chunk rescue involved.
for (Account account : accounts) {
    account.Description = 'chunked certain';
}
verify.scenario('201 records, certain size');
update accounts;
verify.expect('INVOKE count', verify.count('INVOKE'), 2);
verify.expect('FLUSH count', verify.count('FLUSH'), 1);
verify.expect('ending=true invocations', verify.countContaining('INVOKE', 'ending=true'), 1);

// --- exactly 200, CERTAIN size: no chunk is short, only the countdown can end this one ---
List<Account> exactly200Certain = new List<Account>();
for (Integer i = 0; i < 200; i++) {
    accounts[i].Description = 'exact 200 certain';
    exactly200Certain.add(accounts[i]);
}
verify.scenario('exact-200, certain size');
update exactly200Certain;
verify.expect('INVOKE count', verify.count('INVOKE'), 1);
verify.expect('FLUSH count', verify.count('FLUSH'), 1);

// --- one statement, two objects: the Account trigger sees 1 of the statement's 2 rows.
// --- Pins the recordCount < 200 pin on expectedRows.
Pricebook2 mixedPricebook = new Pricebook2(Name = 'Regression Mixed');
insert mixedPricebook;
update new Account(Id = accounts[0].Id, Description = 'rebaseline');
accounts[1].Description = 'mixed statement';
mixedPricebook.Name = 'Regression Mixed renamed';
verify.scenario('mixed-object statement, certain size');
update new List<SObject>{ accounts[1], mixedPricebook };
verify.expect('INVOKE count', verify.count('INVOKE'), 1);
verify.expect('FLUSH count', verify.count('FLUSH'), 1);

// --- upsert 201 existing + 50 new through an update-only trigger: one statement,
// --- 251 rows counted up front, only 201 ever reach the trigger. Pins the short-chunk clause.
List<Account> upserted = new List<Account>();
for (Account account : accounts) {
    account.Description = 'upserted';
    upserted.add(account);
}
for (Integer i = 0; i < 50; i++) {
    upserted.add(new Account(Name = 'Regression Bulk new ' + i));
}
update new Account(Id = accounts[0].Id, Description = 'rebaseline again');
verify.scenario('upsert 201 existing + 50 new, certain size');
upsert upserted;
verify.expect('INVOKE count', verify.count('INVOKE'), 2);
verify.expect('FLUSH count', verify.count('FLUSH'), 1);

// --- untracked DML then an exact-200 update: the silent-loss case, must still flush ---
List<Pricebook2> untrackedA = new List<Pricebook2>();
for (Integer i = 0; i < 50; i++) {
    untrackedA.add(new Pricebook2(Name = 'Regression Untracked A' + i));
}
List<Account> exactly200 = new List<Account>();
for (Integer i = 0; i < 200; i++) {
    accounts[i].Description = 'exact 200';
    exactly200.add(accounts[i]);
}
verify.scenario('exact-200 after untracked DML');
insert untrackedA;
update exactly200;
verify.expect('INVOKE count', verify.count('INVOKE'), 1);
verify.expect('FLUSH count', verify.count('FLUSH'), 1);

// --- untracked DML then a multi-chunk update: one chain, provisional flush per chunk ---
List<Pricebook2> untrackedB = new List<Pricebook2>();
for (Integer i = 0; i < 50; i++) {
    untrackedB.add(new Pricebook2(Name = 'Regression Untracked B' + i));
}
for (Account account : accounts) {
    account.Description = 'multi-chunk uncertain';
}
verify.scenario('201 records after untracked DML');
insert untrackedB;
update accounts;
verify.expect('INVOKE count', verify.count('INVOKE'), 2);
verify.expect('FLUSH count', verify.count('FLUSH'), 2);

TriggerStackProbe.enabled = false;
delete untrackedA;
delete untrackedB;
delete [SELECT Id FROM Account WHERE Name LIKE 'Regression Bulk%'];
delete [SELECT Id FROM Pricebook2 WHERE Name LIKE 'Regression Mixed%'];

if (!verify.failures.isEmpty()) {
    Assert.fail(verify.failures.size() + ' regression failure(s):\n' + String.join(verify.failures, '\n'));
}

System.debug(LoggingLevel.ERROR, 'REGRESSION PASS — 7 bulk scenarios, CPU ' + Limits.getCpuTime() + 'ms, ' + Limits.getDmlRows() + ' rows');
